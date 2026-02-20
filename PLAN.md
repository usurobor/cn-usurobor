# Implementation Plan: Agent Runtime (AGENT-RUNTIME-v3.md)

## Goal

Replace OpenClaw dependency with a native OCaml runtime. After this, `cn agent --process` directly calls the Claude API — no external LLM orchestrator needed.

## Current State

- **Already implemented:** Queue FIFO, actor FSM loop (`run_inbound`), op execution (`execute_op`), archive IO pairs, GTD lifecycle, all 4 FSMs, `cn_ffi.ml` system bindings
- **Missing:** Claude API client, Telegram client, context packer, config loader, `extract_body` helper
- **To modify:** `wake_agent` (currently shells out to OpenClaw), `run_inbound` (needs to integrate native runtime)
- **To purge:** OpenClaw references in `cn_agent.ml` and `cn_system.ml` (runtime status), plus stale OpenClaw paths in skill kata files

## Dependency Decision

The codebase currently has **zero external OCaml dependencies** (stdlib + Unix only). The design doc suggests `cohttp-lwt-unix`, `yojson`, `lwt`, `tls`, `ca-certs`. This is a major dependency cliff.

**Plan:** Stay dependency-free. Use `curl` as an explicit system dependency for HTTPS calls to Telegram and Anthropic APIs. Parse JSON with a minimal hand-rolled module. This keeps the build trivial and avoids opam dependency management.

**curl is an explicit dependency** — not implicitly present. Git may bundle libcurl internally without exposing the `curl` CLI. We must:
- Check for `curl` in `cn doctor`
- Document `curl` as a prerequisite in `install.sh`
- Fail early with an actionable error if `curl` is not found

**Security: secrets never appear on argv.** The current `Cn_ffi.Child_process.exec` runs shell strings via `Unix.open_process_in`. API keys and untrusted Telegram text must never be interpolated into shell command strings. Before any HTTP work, we add a safe process runner that uses `Unix.create_process` (argv array, no shell interpretation) and passes request bodies + headers via stdin using `curl --config -`.

## Daemon vs Cron Stance

The repo's public framing is cron-driven ("core loop driven by cn on a cron cycle"). AGENT-RUNTIME v3 also documents daemon mode for Telegram ingress.

**Canonical stance:** Cron is the default deployment. `--daemon` is an optional Telegram bridge (projection adapter) for real-time interaction. Both modes use the same `cn_runtime.ml` processing pipeline.

- `cn agent` (no flags) — `Cn_runtime.run_cron` (replaces `run_inbound`)
- `cn agent --process` — single-shot: dequeue one item, pack, call LLM, archive, execute, project
- `cn agent --daemon` — optional Telegram long-poll bridge
- `cn agent --stdio` — interactive testing mode

## Config: `.cn/config.json` (not `agent.yaml`)

Hub discovery already looks for `.cn/config.json` and `.cn/config.yaml` (in `cn_hub.ml:find_hub_path`). We use `.cn/config.json` — it reuses `cn_json.ml` and avoids a YAML parser dep. Agent runtime settings go under a new `runtime` key.

Config is env-var-first (simpler, more Unixy), with `.cn/config.json` for non-secret settings:

**Environment variables (secrets + overrides):**
- `TELEGRAM_TOKEN` — Telegram bot token
- `ANTHROPIC_KEY` — Claude API key
- `CN_MODEL` — model ID (default: `claude-sonnet-4-latest`)

**`.cn/config.json` (non-secrets):**

```json
{
  "runtime": {
    "allowed_users": [498316684],
    "poll_interval": 1,
    "poll_timeout": 30,
    "max_tokens": 8192
  }
}
```

This reuses `cn_json.ml` (Step 3) — one parser for config, API responses, and conversation history. No YAML parsing needed.

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
         cn_config.ml (NEW) — env + .cn/config.json loader
         |
Layer 1  cn_lib.ml — add extract_body, resolve_payload
         cn_json.ml (NEW) — minimal JSON parser/emitter (pure)
         cn_ffi.ml — add safe exec_args + Http module (curl via stdin)
```

## Implementation Steps

### Step 0: Purge OpenClaw references

Remove all OpenClaw fingerprints so "dependency removed" is true both functionally and cosmetically.

Files to clean:
- `src/cmd/cn_agent.ml` — `wake_agent` (replaced in Step 9)
- `src/cmd/cn_system.ml` — `openclaw --version` in runtime status (line 19), `openclaw_version` output (line 50)
- `src/agent/skills/agent/self-cohere/SKILL.md` — stale `/root/.openclaw/` paths
- `src/agent/skills/agent/self-cohere/kata.md` — stale `/root/.openclaw/` paths
- `src/agent/skills/agent/configure-agent/kata.md` — stale `/root/.openclaw/` paths

### Step 1: Add safe process execution to `cn_ffi.ml`

Add `exec_args` that uses `Unix.create_process` (argv array, no shell):

```ocaml
module Process : sig
  (* ... existing ... *)
  val exec_args : prog:string -> args:string list -> ?stdin_data:string -> unit
                  -> (int * string * string)
  (** Run [prog] with [args]. Passes [stdin_data] on stdin if provided.
      Returns (exit_code, stdout, stderr). No shell interpretation. *)
end
```

Then build the `Http` module on top:

```ocaml
module Http : sig
  val post : url:string -> headers:(string * string) list -> body:string
             -> (string, string) result
  val get : url:string -> headers:(string * string) list
            -> (string, string) result
end
```

Implementation: builds a curl config string (url, headers, body) and pipes it to `curl --config -` via `exec_args ~stdin_data`. API keys and request bodies never appear on the command line.

**Curl config injection hardening:** The JSON request body must be serialized as single-line JSON with all newlines escaped before embedding in the curl config `data` directive. This prevents user-provided text (e.g., Telegram messages containing newlines) from producing new curl-config directives. `Cn_json.to_string` must guarantee single-line output.

Also add a `curl` availability check for `cn doctor`.

### Step 2: Add `extract_body` and `resolve_payload` to `cn_lib.ml`

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

Add `resolve_payload` for body consumption rules:

```ocaml
let resolve_payload body = function
  | Reply (id, msg) -> Reply (id, Option.value body ~default:msg)
  | Send (peer, msg, None) -> Send (peer, msg, body)
  | op -> op
```

**Test:** Add cases to `test/lib/cn_test.ml`.

### Step 3: Add minimal JSON module (`cn_json.ml` in `src/lib/`)

Minimal JSON parser/emitter (~200 lines). Types:

```ocaml
type t = Null | Bool of bool | Int of int | Float of float | String of string
       | Array of t list | Object of (string * t) list

val parse : string -> (t, string) result
val to_string : t -> string
val get : string -> t -> t option
val get_string : string -> t -> string option
val get_int : string -> t -> int option
val get_list : string -> t -> t list option
```

**Must handle:**
- Standard escape sequences: `\" \\ \/ \b \f \n \r \t`
- Unicode escapes: `\uXXXX` (Telegram sends these for emoji/non-ASCII)
- Nested objects and arrays (Anthropic response has `content[0].text`)
- Unknown fields ignored (forward compatibility)
- UTF-8 passthrough (don't decode/re-encode)

**Test corpus:** Include real captured responses from Telegram `getUpdates` and Anthropic `/v1/messages` as test fixtures. Test `\uXXXX` handling, escaped quotes in message text, and cache metric fields (`cache_creation_input_tokens`, `cache_read_input_tokens`) being optional.

### Step 4: Create `cn_config.ml` (Layer 2, `src/cmd/`)

Load config from env vars + `.cn/config.json` (parsed via `Cn_json`):

```ocaml
type config = {
  telegram_token : string option;  (* None = no Telegram *)
  anthropic_key : string;
  model : string;
  poll_interval : int;
  poll_timeout : int;
  max_tokens : int;
  allowed_users : int list;
  hub_path : string;
}

val load : hub_path:string -> (config, string) result
```

- Secrets from env only (never from config file)
- Non-secrets from `.cn/config.json` under `runtime` key, with env overrides
- `ANTHROPIC_KEY` required for `--process` / `--daemon`; error if missing
- `TELEGRAM_TOKEN` required only for `--daemon`
- Uses `Cn_json.parse` to read config — same parser as API responses

### Step 5: Create `cn_llm.ml` (Layer 2, `src/cmd/`)

Claude API client. Single function:

```ocaml
type response = {
  content : string;
  stop_reason : string;
  input_tokens : int;
  output_tokens : int;
  cache_creation_input_tokens : int;  (* 0 if not in response *)
  cache_read_input_tokens : int;      (* 0 if not in response *)
}

val call : api_key:string -> model:string -> max_tokens:int -> content:string
           -> (response, string) result
```

Implementation: Build JSON request body, POST to `https://api.anthropic.com/v1/messages`, parse JSON response via `Cn_json`. No tools, no streaming — single user message in, single text response out.

Retry: 3x with exponential backoff (1s, 2s, 4s) on 5xx/timeout. Non-retryable errors (4xx) fail immediately.

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

val get_updates : token:string -> offset:int -> timeout:int -> (message list, string) result
val send_message : token:string -> chat_id:int -> text:string -> (unit, string) result
```

Uses long-polling `getUpdates` with `timeout` param. Filters by `allowed_users` in the caller (cn_runtime), not here.

**Offset persistence (daemon correctness):**
- Persist last `update_id` to `state/telegram.offset` (single integer, overwritten atomically)
- On daemon start: read offset; if missing or unparseable, start from 0
- Advance offset only after successful processing + Telegram reply send (not after enqueue)
- This matches the design doc's idempotence contract: if `process_one` crashes mid-pipeline, the daemon re-fetches and reprocesses the same update on next poll
- The local queue uses destructive dequeue (`queue_pop` unlinks), so Telegram's `update_id` is the retry source of truth

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
val process_one : config:Cn_config.config -> hub_path:string -> name:string
                  -> (unit, string) result
(** Dequeue one item, pack context, call LLM, archive, execute, project.
    Returns Ok () if processed, Error if queue empty or failure. *)

val run_cron : config:Cn_config.config -> hub_path:string -> name:string -> unit
(** Cron entry point. Queues inbox items, checks MCA cycle, processes one item.
    Replaces the current run_inbound. *)
```

**`process_one` pipeline:**
1. **Dequeue** — `Cn_agent.queue_pop`
2. **Pack** — `Cn_context.pack` → write `state/input.md`
3. **Call** — `Cn_llm.call` with packed content
4. **Write** — write `state/output.md`
5. **Archive** — copy input+output to `logs/` (**BEFORE effects**)
6. **Parse** — `Cn_lib.parse_frontmatter` + `Cn_lib.extract_ops` + `Cn_lib.extract_body`
7. **Resolve** — apply body consumption rules via `Cn_lib.resolve_payload`
8. **Execute** — `Cn_agent.execute_op` for each op
9. **Project** — if from Telegram, `Cn_telegram.send_message` with full payload
10. **Conversation** — append exchange to `state/conversation.json`

FSM transitions at each step via `Cn_protocol.actor_transition`.

**`run_cron` replaces `run_inbound`:**
1. Queue inbox items (existing `queue_inbox_items`)
2. Check MCA review cycle (existing logic)
3. Derive actor state from filesystem (existing FSM)
4. If `OutputReady` — archive previous IO pair, auto-save, then `process_one`
5. If `TimedOut` — archive timeout, auto-save, then `process_one`
6. If `Idle` — check for updates, then `process_one`
7. If `Processing` — show progress (agent is mid-call)
8. If `InputReady` — resume: read existing `state/input.md`, call LLM, continue from step 3

This eliminates the current split where `feed_next_input` dequeues/writes `state/input.md` and `wake_agent` shells out to OpenClaw. The runtime owns the entire pipeline: dequeue → pack → call → write → archive → execute → project. No more two-function dance.

**Single-instance lock (cron + daemon safety):**

Cron overlaps and daemon-spawned `--process` calls can race `state/input.md`, `state/output.md`, and queue files. Guard with an atomic lock:
- `process_one` creates `state/agent.lock` using `Unix.openfile` with `O_CREAT|O_EXCL` (atomic, fails if exists)
- If lock exists → exit early with "already running" message (not an error — normal for cron overlap)
- Remove lock on exit (normal path) and best-effort remove on crash (stale lock detection: if lock file is older than `max_age_min`, delete and proceed)

**Why this replaces `run_inbound` (not wraps it):**
The current `run_inbound` calls `feed_next_input` (dequeue + write raw queue content to `state/input.md`) then `wake_agent` (shell to OpenClaw). If we made `wake_agent` call `process_one` (which also dequeues), we'd double-dequeue or overwrite `state/input.md`. Option A avoids this: `run_cron` is the new canonical cron entry point, and `process_one` owns the full dequeue-to-project pipeline. `run_inbound` and `feed_next_input` and `wake_agent` become dead code.

### Step 9: Modify `cn_agent.ml` — deprecate `run_inbound`

Mark `run_inbound`, `feed_next_input`, and `wake_agent` as deprecated. They are replaced by `Cn_runtime.run_cron` and `Cn_runtime.process_one`.

Keep them in the file for one release cycle (they're still called by existing cron setups), but the CLI routing in Step 10 will point to the new runtime.

Expose existing helpers that `cn_runtime.ml` needs:
- `queue_pop`, `queue_add`, `queue_count`, `queue_inbox_items` (already public)
- `archive_io_pair`, `archive_timeout` (already public)
- `execute_op` (already public)
- `auto_save` (already public)
- `input_path`, `output_path` (already public)

### Step 10: Add CLI modes to `cn.ml`

Add routing for agent subcommand modes:
- `cn agent` (no flags) → `Cn_runtime.run_cron` (replaces `run_inbound`)
- `cn agent --process` → single-shot `Cn_runtime.process_one`
- `cn agent --daemon` → Telegram long-poll loop (requires `TELEGRAM_TOKEN`)
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

### Step 13: Update docs

- `ARCHITECTURE.md` — add new modules to structure diagram and dependency layers
- `install.sh` — add `curl` prerequisite check
- `cn doctor` — add `curl --version` health check

### Step 14: Tests

- `test/lib/cn_test.ml` — add `extract_body` tests, `resolve_payload` tests
- `test/lib/cn_json_test.ml` — JSON parser tests with real API response fixtures
- `test/cmd/cn_cmd_test.ml` — add config loading tests
- New `test/cmd/cn_runtime_test.ml` — test context packing logic, pipeline sequencing

## File Change Summary

| File | Action | Est. Lines |
|------|--------|-----------|
| `src/lib/cn_lib.ml` | Edit — add `extract_body`, `resolve_payload` | +30 |
| `src/lib/cn_json.ml` | **New** — minimal JSON parser/emitter | ~200 |
| `src/lib/dune` | Edit — add `cn_json` module | +1 |
| `src/ffi/cn_ffi.ml` | Edit — add `exec_args` + `Http` module | +60 |
| `src/cmd/cn_config.ml` | **New** — env + config.json loader (reuses cn_json) | ~80 |
| `src/cmd/cn_llm.ml` | **New** — Claude API client via curl stdin | ~120 |
| `src/cmd/cn_telegram.ml` | **New** — Telegram Bot API client via curl stdin | ~130 |
| `src/cmd/cn_context.ml` | **New** — context packer | ~180 |
| `src/cmd/cn_runtime.ml` | **New** — orchestrator: `process_one` + `run_cron` (replaces `run_inbound`) | ~200 |
| `src/cmd/cn_agent.ml` | Edit — deprecate `wake_agent`/`run_inbound`/`feed_next_input` | ~10 changed |
| `src/cmd/cn_system.ml` | Edit — remove OpenClaw version check | ~10 changed |
| `src/cmd/dune` | Edit — add new modules | +2 |
| `src/cli/cn.ml` | Edit — add `--daemon`/`--stdio` routing | ~20 |
| `docs/ARCHITECTURE.md` | Edit — add new modules to diagram | ~15 |
| `test/lib/cn_test.ml` | Edit — add tests | +40 |
| `test/lib/cn_json_test.ml` | **New** — JSON parser tests with fixtures | ~100 |
| **Total new code** | | **~1100 lines** |

## Order of Implementation

1. **Step 0:** Purge OpenClaw references (clean slate)
2. **Step 1:** `cn_ffi.ml` safe exec + Http module (security foundation)
3. **Steps 2-3:** `cn_lib.ml` additions + `cn_json.ml` (pure, testable immediately)
4. **Step 4:** `cn_config.ml` (env-based, simple)
5. **Step 5:** `cn_llm.ml` (depends on 1-3)
6. **Step 6:** `cn_telegram.ml` (depends on 1-3)
7. **Step 7:** `cn_context.ml` (depends on 2, uses cn_ffi for file reads)
8. **Step 8:** `cn_runtime.ml` (depends on 5-7, ties everything together)
9. **Step 9:** `cn_agent.ml` wake_agent replacement (depends on 8)
10. **Step 10:** `cn.ml` CLI routing (depends on 8-9)
11. **Steps 11-14:** dune files, docs, tests (incremental)

## Risk Mitigation

- **Secrets on argv:** Mitigated by `exec_args` + `curl --config -` pattern. API keys and untrusted text never appear in process argv or shell strings
- **curl availability:** Explicit dependency — checked in `cn doctor`, documented in `install.sh`, fail-early in `Http.post`/`Http.get`
- **JSON parser correctness:** Test with real captured API responses. Handle `\uXXXX` escapes. Unknown fields ignored. Cache metric fields optional
- **Backward compatibility:** `cn agent` still works but now routes to `Cn_runtime.run_cron` (same behavior, native LLM). Old `run_inbound` kept as deprecated for one release. Config uses `.cn/config.json` (already recognized by hub discovery)
- **Daemon vs cron:** Daemon is opt-in via `--daemon` flag. Cron remains the default documented deployment. No breaking change to existing cron users
