# Implementation Plan: Agent Runtime (AGENT-RUNTIME-v3.md)

## Goal

Replace OpenClaw dependency with a native OCaml runtime. After this, `cn agent --process` directly calls the Claude API — no external LLM orchestrator needed.

## Current State

- **Already implemented:** Queue FIFO, actor FSM loop (`run_inbound`), op execution (`execute_op`), archive IO pairs, GTD lifecycle, all 4 FSMs, `cn_ffi.ml` system bindings
- **Missing:** Claude API client, Telegram client, context packer, config parser, `extract_body` helper
- **To modify:** `wake_agent` (currently shells out to OpenClaw), `run_inbound` (needs to integrate native runtime)

## Dependency Decision

The codebase currently has **zero external OCaml dependencies** (stdlib + Unix only). The design doc suggests `cohttp-lwt-unix`, `yojson`, `lwt`, `tls`, `ca-certs`. This is a major dependency cliff.

**Plan:** Stay dependency-free. Use `Unix` sockets + hand-rolled HTTP for the two API endpoints we need (Telegram Bot API, Anthropic Messages API). Both are simple JSON-over-HTTPS POST/GET calls. This matches the codebase philosophy — `cn_ffi.ml` already wraps `Unix`, and `git.ml` already shells out to `curl` isn't needed either since we can use the existing `Cn_ffi.Child_process.exec` to call `curl` for HTTPS (avoiding TLS library dependency entirely).

**Pragmatic approach:** Use `curl` via `Cn_ffi.Child_process.exec` for HTTPS calls (same pattern as `git.ml` shelling out to `git`). Parse JSON with a minimal hand-rolled parser or a lightweight single-file JSON module. This keeps the build trivial and avoids opam dependency management.

## Architecture (fits existing layer model)

```
Layer 4  cn.ml (dispatch) — add --daemon, --process, --stdio routing
         |
Layer 3  cn_agent.ml — modify wake_agent + run_inbound
         cn_runtime.ml (NEW) — pack → call → write → archive → resolve → project
         |
Layer 2  cn_context.ml (NEW) — load hub artifacts, pack input.md
         cn_telegram.ml (NEW) — getUpdates, sendMessage via curl
         cn_llm.ml (NEW) — Claude Messages API via curl
         cn_config.ml (NEW) — parse agent.yaml (simple key-value, no YAML lib)
         |
Layer 1  cn_lib.ml — add extract_body
         cn_ffi.ml — add curl helper (exec_json_post, exec_json_get)
```

## Implementation Steps

### Step 1: Add `extract_body` to `cn_lib.ml`

Add the body extraction helper specified in the design doc. Pure function, no deps.

```ocaml
let extract_body content =
  match String.split_on_char '\n' content with
  | "---" :: rest ->
      let rec skip = function "---" :: r -> r | _ :: r -> skip r | [] -> [] in
      let body = String.concat "\n" (skip rest) |> String.trim in
      if body = "" then None else Some body
  | _ -> None
```

Also add `resolve_payload` for body consumption rules.

**Test:** Add cases to `test/lib/cn_test.ml`.

### Step 2: Add HTTP helpers to `cn_ffi.ml`

Add `curl`-based HTTP helpers. Two functions:

- `Http.post_json ~url ~headers ~body` → `string option` (shells out to curl)
- `Http.get_json ~url ~headers` → `string option`

Uses `curl -s -X POST -H "..." -d '...'` — same exec pattern as `git.ml`.

### Step 3: Add minimal JSON module (`cn_json.ml` in `src/lib/`)

Minimal JSON parser/emitter (~150 lines). Types:

```ocaml
type t = Null | Bool of bool | Int of int | Float of float | String of string
       | Array of t list | Object of (string * t) list

val parse : string -> t
val to_string : t -> string
val get : string -> t -> t option
val get_string : string -> t -> string option
val get_int : string -> t -> int option
val get_list : string -> t -> t list option
```

Only needs to handle the subset of JSON that Telegram and Anthropic APIs return. No streaming, no unicode escapes beyond `\n\t\"\\`.

### Step 4: Create `cn_config.ml` (Layer 2, `src/cmd/`)

Parse `.cn/agent.yaml` — but since we avoid YAML deps, use a simple line-oriented format or parse the subset of YAML that agent.yaml uses (flat key-value with env var expansion).

Alternatively: read config from environment variables only (simpler, more Unixy):
- `TELEGRAM_TOKEN` — already specified in design doc
- `ANTHROPIC_KEY` — already specified in design doc
- `CN_MODEL` — default `claude-sonnet-4-latest`
- `CN_POLL_INTERVAL` — default 1
- `CN_ALLOWED_USERS` — comma-separated user IDs

```ocaml
type config = {
  telegram_token : string;
  anthropic_key : string;
  model : string;
  poll_interval : int;
  allowed_users : int list;
  hub_path : string;
}
val load : hub_path:string -> config
```

### Step 5: Create `cn_llm.ml` (Layer 2, `src/cmd/`)

Claude API client. Single function:

```ocaml
type response = {
  content : string;
  stop_reason : string;
  input_tokens : int;
  output_tokens : int;
  cache_creation_input_tokens : int;
  cache_read_input_tokens : int;
}

val call : api_key:string -> model:string -> content:string -> (response, string) result
```

Implementation: Build JSON request body, POST to `https://api.anthropic.com/v1/messages`, parse JSON response. Uses `Cn_ffi.Http.post_json`. No tools, no streaming — single user message in, single text response out.

Retry: 3x with exponential backoff (1s, 2s, 4s) on 5xx/timeout.

### Step 6: Create `cn_telegram.ml` (Layer 2, `src/cmd/`)

Telegram Bot API client.

```ocaml
type message = {
  message_id : int;
  chat_id : int;
  user_id : int;
  username : string option;
  text : string;
  date : int;
  update_id : int;
}

val get_updates : token:string -> offset:int -> timeout:int -> message list
val send_message : token:string -> chat_id:int -> text:string -> (unit, string) result
```

Uses long-polling `getUpdates` with `timeout` param. Filters by `allowed_users`.

### Step 7: Create `cn_context.ml` (Layer 2, `src/cmd/`)

Context packer. Loads hub artifacts and assembles `state/input.md`.

```ocaml
type packed = {
  trigger_id : string;
  from : string;
  content : string;     (* full assembled markdown *)
}

val pack : hub_path:string -> trigger_id:string -> message:string -> from:string -> packed
```

Loads in order per design doc:
1. `spec/SOUL.md`
2. `spec/USER.md`
3. Last 3 daily reflections from `threads/reflections/daily/`
4. Current weekly reflection from `threads/reflections/weekly/`
5. Top 3 keyword-matched skills from `src/agent/skills/`
6. Conversation history from `state/conversation.json` (last 10)
7. Inbound message

Skill matching: simple keyword overlap (tokenize message, count matches against skill description lines).

Missing files degrade gracefully (skip, don't error).

### Step 8: Create `cn_runtime.ml` (Layer 3, `src/cmd/`)

The orchestrator. Implements the full pipeline:

```ocaml
val process : config:Cn_config.config -> hub_path:string -> (unit, string) result
```

Pipeline:
1. **Dequeue** — `Cn_agent.queue_pop`
2. **Pack** — `Cn_context.pack` → write `state/input.md`
3. **Call** — `Cn_llm.call` with packed content
4. **Write** — write `state/output.md`
5. **Archive** — copy input+output to `logs/` (BEFORE effects)
6. **Parse** — `Cn_lib.parse_frontmatter` + `Cn_lib.extract_ops` + `Cn_lib.extract_body`
7. **Resolve** — apply body consumption rules
8. **Execute** — `Cn_agent.execute_op` for each op
9. **Project** — if from Telegram, `Cn_telegram.send_message` with full payload

FSM transitions at each step via `Cn_protocol.actor_transition`.

### Step 9: Modify `cn_agent.ml` — replace `wake_agent`

Replace the OpenClaw shell-out with a call to `Cn_runtime.process`:

```ocaml
let wake_agent hub_path config =
  match Cn_runtime.process ~config ~hub_path with
  | Ok () -> print_endline (Cn_fmt.ok "Agent processed input")
  | Error e -> print_endline (Cn_fmt.fail ("Agent processing failed: " ^ e))
```

Update `run_inbound` to pass config through.

### Step 10: Add daemon mode to `cn.ml`

Add `--daemon` flag routing:
- `cn agent --daemon` → `Cn_telegram.poll_loop` (long-running)
- `cn agent --process` → `Cn_runtime.process` (single-shot, existing path)
- `cn agent --stdio` → interactive mode (read stdin, process, print output)

### Step 11: Update dune files

Add new modules to `src/cmd/dune`:
```
(modules cn_fmt cn_hub cn_mail cn_gtd cn_agent cn_mca
         cn_commands cn_system cn_config cn_llm cn_telegram
         cn_context cn_runtime)
```

Add `cn_json` to `src/lib/dune`:
```
(modules cn_lib cn_json)
```

### Step 12: Add conversation history tracking

Add `state/conversation.json` management:
- After each successful process cycle, append `{role, content, timestamp}` to conversation history
- `cn_context.ml` reads last 10 entries when packing
- Simple append-only JSON array file

### Step 13: Update `ARCHITECTURE.md`

Add new modules to the module structure diagram and dependency layers.

### Step 14: Tests

- `test/lib/cn_test.ml` — add `extract_body` tests, JSON parser tests
- `test/cmd/cn_cmd_test.ml` — add config loading tests
- New `test/cmd/cn_runtime_test.ml` — test resolve_payload, context packing logic (mock the LLM call)

## File Change Summary

| File | Action | Est. Lines |
|------|--------|-----------|
| `src/lib/cn_lib.ml` | Edit — add `extract_body`, `resolve_payload` | +30 |
| `src/lib/cn_json.ml` | **New** — minimal JSON parser/emitter | ~200 |
| `src/lib/dune` | Edit — add `cn_json` module | +1 |
| `src/ffi/cn_ffi.ml` | Edit — add `Http.post_json`, `Http.get_json` | +30 |
| `src/cmd/cn_config.ml` | **New** — env-based config loading | ~60 |
| `src/cmd/cn_llm.ml` | **New** — Claude API client via curl | ~120 |
| `src/cmd/cn_telegram.ml` | **New** — Telegram Bot API client via curl | ~130 |
| `src/cmd/cn_context.ml` | **New** — context packer | ~180 |
| `src/cmd/cn_runtime.ml` | **New** — orchestrator pipeline | ~120 |
| `src/cmd/cn_agent.ml` | Edit — replace `wake_agent`, update `run_inbound` | ~30 changed |
| `src/cmd/dune` | Edit — add new modules | +2 |
| `src/cli/cn.ml` | Edit — add `--daemon`/`--stdio` routing | ~20 |
| `docs/ARCHITECTURE.md` | Edit — add new modules to diagram | ~10 |
| `test/lib/cn_test.ml` | Edit — add tests | +40 |
| **Total new code** | | **~900 lines** |

## Order of Implementation

1. `cn_json.ml` + `cn_lib.ml` additions (pure, testable immediately)
2. `cn_ffi.ml` HTTP helpers (curl-based, can test manually)
3. `cn_config.ml` (env-based, simple)
4. `cn_llm.ml` (depends on 1-3)
5. `cn_telegram.ml` (depends on 1-3)
6. `cn_context.ml` (depends on 1, uses cn_ffi for file reads)
7. `cn_runtime.ml` (depends on 4-6, ties everything together)
8. `cn_agent.ml` + `cn.ml` modifications (depends on 7)
9. Tests + docs
10. dune file updates (can be done incrementally)

## Risk Mitigation

- **No OCaml toolchain in CI env:** Code will be written and committed; build verification happens in the real dev environment
- **curl dependency:** Already implicitly required (git uses HTTPS). Document in install.sh
- **JSON parser correctness:** Keep it minimal — only parse what Telegram/Anthropic APIs return. Test with real API response examples
- **Backward compatibility:** `cn agent` without flags still works (existing `run_inbound` path). New flags are additive
