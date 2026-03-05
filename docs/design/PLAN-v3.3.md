# Development Plan: CN Shell v3.3 (Capability Runtime)

**Status:** Draft
**Date:** 2026-03-05
**Spec:** AGENT-RUNTIME-v3.md v3.3.6
**Base:** All Steps 0–14 from PLAN.md are **complete** — native runtime is shipped and running.

---

## Scope

This plan covers the v3.3 spec additions that are **not yet implemented**:

1. CN Shell typed ops (observe + effect)
2. Two-pass execution (Pass A → evidence → Pass B)
3. Receipts and artifacts
4. Path Sandbox enforcement
5. Capability discovery block in context packing
6. Dotenv secrets fallback (`Cn_config.load` ← `.cn/secrets.env`)
7. Projection idempotency markers

Everything below builds on the existing working runtime (`cn_runtime.ml`, `cn_context.ml`, `cn_llm.ml`, `cn_config.ml`, `cn_telegram.ml`).

---

## Current State (what's already implemented)

| Component | Status | Code |
|-----------|--------|------|
| Lock + 3-state recovery | **Done** | `cn_runtime.ml:acquire_lock`, `process_one` |
| Queue FIFO (dequeue/enqueue) | **Done** | `cn_agent.ml:queue_pop/queue_add` |
| Context packing (SOUL/USER/mindsets/reflections/skills/conv) | **Done** | `cn_context.ml:pack` |
| LLM client (structured system+messages, cache hints) | **Done** | `cn_llm.ml:call` |
| Telegram client (getUpdates/sendMessage via curl) | **Done** | `cn_telegram.ml` |
| Config loader (env + .cn/config.json) | **Done** | `cn_config.ml:load` |
| Archive IO pairs before effects | **Done** | `cn_runtime.ml:archive_raw` |
| Coordination ops parsing + execution | **Done** | `cn_lib.ml:extract_ops`, `cn_agent.ml:execute_op` |
| Conversation history (last 50, structured turns) | **Done** | `cn_runtime.ml:append_conversation` |
| Telegram daemon (long-poll, offset persistence) | **Done** | `cn_runtime.ml:run_daemon` |
| Interactive stdio mode | **Done** | `cn_runtime.ml:run_stdio` |
| JSON parser/emitter | **Done** | `cn_json.ml` |
| Safe process exec (no shell, stdin piping) | **Done** | `cn_ffi.ml:exec_args` |
| Frontmatter parsing + body extraction | **Done** | `cn_lib.ml:parse_frontmatter/extract_body` |
| FSM enforcement (4 typed FSMs) | **Done** | `cn_protocol.ml` |
| **CN Shell typed ops** | **Not started** | — |
| **Two-pass execution** | **Not started** | — |
| **Receipts / artifacts** | **Not started** | — |
| **Path Sandbox** | **Not started** | — |
| **Capability discovery** | **Not started** | — |
| **Dotenv secrets fallback** | **Not started** | — |
| **Projection idempotency** | **Not started** | — |

---

## Architecture

```
Existing (working)                New (this plan)
──────────────────                ─────────────────
cn_runtime.ml                    cn_shell.ml (NEW)
  process_one                      parse_ops_manifest
  finalize                         validate_op
  run_cron                         execute_typed_op
  run_daemon                       write_receipt
                                   write_artifact
cn_context.ml                      path_sandbox_check
  pack                             exec_scrub_env

cn_config.ml                     cn_dotenv.ml (NEW)
  load                             parse_dotenv
                                   load_secrets

cn_runtime.ml (MODIFIED)
  finalize → finalize_v33
    adds: parse ops manifest
    adds: two-pass logic
    adds: receipt writing
    adds: projection markers
```

**One new module (`cn_shell.ml`), one small module (`cn_dotenv.ml`), and modifications to `cn_runtime.ml`, `cn_context.ml`, `cn_config.ml`.**

---

## Implementation Steps

### Step 1: Dotenv loader + secrets fallback (`cn_dotenv.ml`)

**Goal:** Implement the SETUP-INSTALLER §5.3 contract — `Cn_config.load` resolves secrets via env → `.cn/secrets.env` fallback.

New file: `src/cmd/cn_dotenv.ml` (~60 lines)

```ocaml
(** Parse .cn/secrets.env per SETUP-INSTALLER §5.4 spec.
    Returns (key * value) list. *)
val parse : string -> (string * string) list

(** Load a secret: env var first, then .cn/secrets.env fallback.
    Returns None if neither source provides a non-empty value.
    Refuses to load if file permissions > 0600 (ssh-style). *)
val resolve_secret : hub_path:string -> env_key:string -> string option
```

Parsing rules (per spec):
- Blank lines → skip
- `# comment` → skip
- `KEY=VALUE` — key must match `[A-Z0-9_]+`, value trimmed, one layer of quotes stripped
- No `export`, no interpolation, no multiline, no escape sequences
- File missing → treat as empty
- File unreadable → warn, treat as empty
- **Permissions > 0600 → error** (refuse to load, print `chmod 600 .cn/secrets.env`)

Modify `cn_config.ml:load`:
- Replace `non_empty_env "ANTHROPIC_KEY"` with `Cn_dotenv.resolve_secret ~hub_path ~env_key:"ANTHROPIC_KEY"`
- Same for `TELEGRAM_TOKEN`

**Tests:** dotenv parsing (blank, comments, quoted values, bad keys, missing file, permission check)

**Depends on:** nothing

---

### Step 2: CN Shell types + ops parser (`cn_shell.ml` — types and parsing)

**Goal:** Parse the `ops:` manifest from output.md frontmatter into typed ops.

New file: `src/cmd/cn_shell.ml` (~400 lines total, built incrementally across Steps 2–5)

```ocaml
(** Typed op kinds — closed vocabulary per v3.3.6 spec (complete set) *)
type observe_kind =
  | Fs_read    (* {path} *)
  | Fs_list    (* {path} *)
  | Fs_glob    (* {pattern} *)
  | Git_status (* no required fields *)
  | Git_diff   (* {rev} — rev range e.g. "HEAD~1..HEAD" *)
  | Git_log    (* {rev, max?} — max defaults to 20 *)
  | Git_grep   (* {query, path?} *)

type effect_kind =
  | Fs_write    (* {path, content} *)
  | Fs_patch    (* {path, unified_diff} *)
  | Git_branch  (* {name} *)
  | Git_commit  (* {message} *)
  | Exec        (* {argv, stdin?} *)

type op_kind = Observe of observe_kind | Effect of effect_kind

type typed_op = {
  kind : op_kind;
  op_id : string option;  (* required for effects; optional for observes *)
  fields : (string * Cn_json.t) list;  (* kind-specific fields *)
}

type receipt_status = Ok_status | Denied | Error_status | Skipped
type receipt = {
  pass : string;  (* "A" or "B" *)
  op_id : string option;  (* present when op declared one; runtime assigns for observes without *)
  kind : string;
  status : receipt_status;
  reason : string;
  start_time : string;
  end_time : string;
  artifacts : artifact list;
}
and artifact = {
  path : string;
  hash : string;  (* "sha256:..." *)
  size : int;
}

(** Parse ops: value from frontmatter. Returns typed ops or receipts for invalid ones. *)
val parse_ops_manifest : string -> (typed_op list * receipt list)
```

Parsing contract:
- `ops:` value MUST be single-line JSON array (reject newlines → receipt `denied`, `ops_not_single_line`)
- Each element is a JSON object with `kind` field (required) and `op_id` field
- Unknown `kind` → receipt `denied`, `unknown_op_kind`
- **`op_id` rules:**
  - Effect ops: `op_id` required — missing → receipt `denied`, `missing_op_id`
  - Observe ops: `op_id` optional — if absent, runtime assigns a deterministic id (e.g., `obs-01`, `obs-02` by manifest position) and records it in the receipt
  - `op_id` is the idempotence key for effects; observe ops don't need it but benefit from traceability when provided
- Duplicate `op_id` within a single manifest → receipt `denied`, `duplicate_op_id` (all ops sharing the id)
- **Cross-pass duplicates:** Pass B may reuse an `op_id` from Pass A. This is allowed —
  the idempotency key is `(trigger_id, pass, op_id)`, not `(trigger_id, op_id)` alone.
  This lets Pass B re-propose an effect after reviewing Pass A evidence without conflict.

**Tests:** parse valid manifests, reject unknown kinds, reject multi-line, missing op_id on effects, auto-assign observe op_ids, duplicate op_id detection

**Depends on:** `cn_json.ml` (already exists)

---

### Step 3: Path Sandbox enforcement (`cn_shell.ml` — sandbox)

**Goal:** Implement the 4-step path validation order from spec §Path Sandbox.

```ocaml
(** Validate a path for typed op access.
    Returns Ok canonical_relative_path or Error reason. *)
val sandbox_check : hub_path:string -> path:string -> write:bool
                    -> (string, string) result
```

4-step order (per spec):
1. **Reject absolute paths** — must be relative to hub root
2. **Collapse `..`** — deny if collapsed path escapes hub
3. **Resolve symlinks** — `Unix.realpath` or equivalent; deny if resolved path escapes hub
4. **Denylist on resolved path** — `.cn/`, `.git/`, `state/`, `logs/`

Protected files (`spec/SOUL.md`, `spec/USER.md`, `state/peers.md`) denied for write/delete regardless.

```ocaml
(** Scrub environment for exec: drop vars matching *_KEY, *_TOKEN, *_SECRET,
    plus configured secret keys. Returns a clean env array. *)
val scrub_env : extra_keys:string list -> (string * string) list
```

**Prerequisite:** `Cn_ffi.Process.exec_args` currently uses `Unix.create_process`, which
inherits the parent env wholesale. Add `Cn_ffi.Process.exec_args_env`:

```ocaml
(** Like exec_args but with explicit environment (Unix.create_process_env).
    Used by CN Shell exec to enforce env scrubbing structurally. *)
val exec_args_env : prog:string -> args:string list -> env:(string * string) list
                    -> ?stdin_data:string -> unit -> int * string
```

Without this primitive, env scrubbing is "policy" (trust the caller) rather than
"mechanism" (the kernel enforces it). CN Shell `exec` ops MUST use `exec_args_env`,
not `exec_args`.

**Tests:** normal paths, `..` escape, symlink bypass, denylist hits, protected files, env scrubbing, exec_args_env passes only scrubbed env

**Depends on:** Step 2 (types)

---

### Step 4: Typed op execution + receipts + artifacts (`cn_shell.ml` — execution)

**Goal:** Execute observe and effect ops, write receipts and artifacts.

```ocaml
(** Execute a single typed op under governance.
    Returns a receipt. Writes artifacts to state/artifacts/<trigger_id>/. *)
val execute_op : hub_path:string -> trigger_id:string -> config:shell_config
                 -> typed_op -> receipt

(** Write receipts to state/receipts/<trigger_id>.json.
    Container format: { "schema": "cn.receipts.v1", "trigger_id": "...", "receipts": [...] } *)
val write_receipts : hub_path:string -> trigger_id:string -> pass:string
                     -> receipt list -> unit

(** Read existing receipts (for Pass B append). *)
val read_receipts : hub_path:string -> trigger_id:string -> receipt list
```

Shell config (from `.cn/config.json` under `runtime`):

```ocaml
type shell_config = {
  apply_mode : [`Off | `Branch | `Working_tree];
  exec_enabled : bool;
  exec_allowlist : string list;
  max_observe_ops : int;          (* default: 10 *)
  max_artifact_bytes : int;       (* default: 65536 *)
  max_artifact_bytes_per_op : int; (* default: 16384 *)
}
```

Execution per kind:

**Observe ops:**
- `fs_read` → read file (sandbox check first), write content to artifact, cap at `max_artifact_bytes_per_op`
- `fs_list` → list directory entries (sandbox check), write listing to artifact
- `fs_glob` → glob pattern match, write file list to artifact
- `git_status` → `exec_args ~prog:"git" ~args:["status"; "--porcelain"]`, write to artifact
- `git_diff` → `exec_args ~prog:"git" ~args:["diff"; rev]`, write to artifact
- `git_log` → `exec_args ~prog:"git" ~args:["log"; "--oneline"; "-n"; max; rev]`, write to artifact
- `git_grep` → `exec_args ~prog:"git" ~args:["grep"; "-n"; query] @ (match path with Some p -> ["--"; p] | None -> [])`, write to artifact

**Effect ops:**
- `fs_write` → sandbox check, write content (respect `apply_mode`)
- `fs_patch` → sandbox check, apply unified diff
- `git_branch` → `exec_args ~prog:"git" ~args:["checkout"; "-b"; name]`
- `git_commit` → **two sequential argv calls** (no shell `&&`):
  1. `exec_args ~prog:"git" ~args:["add"; "-A"]` — if exit ≠ 0 → receipt `error`, stop
  2. `exec_args ~prog:"git" ~args:["commit"; "-m"; msg]` — if exit ≠ 0 → receipt `error`
  (Uses `cn/<trigger_id>` branch if `apply_mode: branch`)
- `exec` → check allowlist, scrub env, run via `exec_args_env` (NOT `exec_args`), cap output, hash artifact (SHA-256)

**Important:** All git/exec ops use argv-only primitives (`exec_args` / `exec_args_env`).
No shell pipelines or `&&` chaining — the runtime sequences calls explicitly and handles
errors between each step.

**Git observe path exclusion:** Git ops that accept paths or produce diffs apply the
same denylist as the filesystem sandbox. Enforcement is via git's `--` pathspec exclusion:
- `git_diff` → appends `-- . ':!.cn' ':!state' ':!logs'` to exclude denylisted prefixes
- `git_log` → same pathspec exclusion appended
- `git_grep` → if no `path` field specified, defaults to `-- . ':!.cn' ':!state' ':!logs'`;
  if `path` specified, sandbox-checks it first (same 4-step validation as fs ops)
- `git_status` → no exclusion needed (shows working tree status; no content leak)

This uses git's native pathspec negation (`':!prefix'`), not post-hoc output filtering.
The runtime constructs the argv with exclusions unconditionally — agents cannot opt out.

Receipt writing:
- Container: `{ "schema": "cn.receipts.v1", "trigger_id": "...", "receipts": [...] }`
- `pass` is per-receipt entry
- Artifacts referenced by relative path + `sha256:` hash + size
- Archive receipts to `logs/receipts/` after writing

**SHA-256 implementation:** The codebase is stdlib-only (zero external deps). Two options:
1. **(Preferred)** Implement SHA-256 in pure OCaml (~120 lines, well-known algorithm)
2. **(Fallback)** Shell out to `sha256sum` via `exec_args` — adds a runtime dep but is simpler

Decision: use option 1 (pure OCaml) to maintain the zero-deps invariant. Place in
`cn_shell.ml` as a private helper (not exposed in `.mli`).

**Tests:** each op kind (mock filesystem), receipt format, artifact hashing, budget enforcement

**Depends on:** Steps 2, 3

---

### Step 5: Two-pass execution (`cn_runtime.ml` modification)

**Goal:** Integrate CN Shell into the existing `finalize` pipeline with two-pass support.

Modify `cn_runtime.ml:finalize`:

```
finalize (current):
  1. archive_raw
  2. parse frontmatter → extract coordination ops
  3. execute coordination ops
  4. project to Telegram
  5. append conversation
  6. cleanup

finalize_v33 (new):
  1. archive_raw (unchanged)
  2. parse frontmatter → extract coordination ops + parse ops: manifest
  3. IF ops: manifest present AND contains observe ops:
     a. Execute observe ops only; skip effects with receipt (skipped, observe_pass_requires_followup)
     b. Apply coordination op phase rules (Pass-A-safe table)
     c. Write artifacts + receipts (pass: "A")
     d. Archive IO pair (Pass A)
     e. Repack context: receipts summary + artifact excerpts + same skills
     f. Call LLM again (Pass B) → write output.md
     g. Archive IO pair (Pass B)
     h. Parse Pass B output
     i. Validate all ops
     j. Execute effect ops in manifest order
     k. Gate coordination on effect success
     l. Append receipts (pass: "B")
  4. ELSE (no observe ops, or no ops: manifest):
     Execute normally (current behavior + typed effects if present)
  5. Project to Telegram (unchanged, but add projection markers)
  6. Append conversation (unchanged)
  7. Cleanup (unchanged)
```

Key invariants:
- `max_passes = 2` — hard limit, not configurable
- Pass B observe ops → denied with `max_passes_exceeded`
- Pass B repacking does NOT re-score skills (fixed at Pass A)
- Effect failure gates terminal coordination ops (`done`, `fail`, etc.)

**`ops_version` handling:**
- Parse `ops_version` from frontmatter (optional)
- If newer than runtime supports → warn receipt for unknown kinds
- If older or absent → proceed normally

**Tests:** single-pass with typed ops, two-pass flow, effect gating, max_passes enforcement

**Depends on:** Steps 2, 3, 4

---

### Step 6: Capability discovery block (`cn_context.ml` modification)

**Goal:** Add runtime-generated `## CN Shell Capabilities` block to packed context.

Modify `cn_context.ml:pack`:

```ocaml
(** Generate the CN Shell Capabilities block from config. *)
let capabilities_block (shell_cfg : Cn_shell.shell_config) : string
```

Placed after skills, before conversation history (in system block 2 / dynamic).

Rules:
- Kinds listed in fixed table order (observe first, then effect)
- Budget keys in lexical order
- If `exec` disabled → omit from effect list, omit allowlist
- If `apply_mode: off` → omit all effect kinds

Add shell_config to `cn_config.ml` config type (new fields under `runtime`):
- `apply_mode` (default: `"branch"`)
- `exec_enabled` (default: `false`)
- `exec_allowlist` (default: `[]`)
- `max_observe_ops`, `max_artifact_bytes`, `max_artifact_bytes_per_op` (defaults per spec)

**Tests:** capability block generation, deterministic ordering, omission rules

**Depends on:** Step 2 (types)

---

### Step 7: Projection idempotency markers

**Goal:** Implement the normative reply idempotency mechanism from spec.

Modify `cn_runtime.ml` Telegram projection section:

```ocaml
(** Check/create projection marker for idempotent send.
    Uses O_CREAT|O_EXCL for atomicity. *)
val mark_projected : hub_path:string -> projection:string -> trigger_id:string
                     -> [`New | `Already_sent]
```

- Marker path: `state/projected/{projection}/{trigger_id}.sent`
- Atomic create via `O_CREAT|O_EXCL` (same pattern as lock)
- If marker exists → skip Telegram send, emit receipt `skipped`, `already_projected`
- Marker writes under processor lock (crash-recovery envelope)

**Tests:** first send creates marker, second send is skipped, concurrent safety

**Depends on:** nothing (can be done in parallel with Steps 2–6)

---

## Examples

These show exact LLM output → runtime behavior → receipt output for
the key execution paths an implementer must handle.

---

### Example 1: Observe-only (single pass)

Agent reads a file. No effects, so no Pass B.

**LLM output (output.md):**

```markdown
---
id: 20260305-091200-abc
ack: trigger-42
ops: [{"kind":"fs_read","path":"src/lib/cn_json.ml"}]
---

Let me check the JSON parser first.
```

**Runtime behavior:**
1. Parse frontmatter → coordination op `Ack "trigger-42"` + typed op `Fs_read {path}`
2. Classify ops: 1 observe, 0 effects → single pass (no Pass B needed)
3. Execute `Ack "trigger-42"` (Pass-A-safe: yes)
4. Sandbox check `src/lib/cn_json.ml` → passes (not in denylist, no `..` escape)
5. Read file, write to `state/artifacts/20260305-091200-abc/obs-01.txt`
6. Hash artifact → `sha256:a1b2c3...`
7. Write receipt

**Receipt (`state/receipts/20260305-091200-abc.json`):**

```json
{
  "schema": "cn.receipts.v1",
  "trigger_id": "20260305-091200-abc",
  "receipts": [
    {
      "pass": "A",
      "op_id": "obs-01",
      "kind": "fs_read",
      "status": "ok",
      "reason": "",
      "start": "2026-03-05T09:12:01Z",
      "end": "2026-03-05T09:12:01Z",
      "artifacts": [
        {
          "path": "state/artifacts/20260305-091200-abc/obs-01.txt",
          "hash": "sha256:a1b2c3d4e5f6...",
          "size": 8432
        }
      ]
    }
  ]
}
```

**Key points:**
- `op_id` was not in the manifest → runtime assigned `obs-01` (first observe, position 0)
- No Pass B because there are no effect ops
- Body text ("Let me check...") is consumed by `resolve_payload` for coordination ops, not typed ops

---

### Example 2: Two-pass (observe + effect)

Agent wants to read a file, then patch it based on what it sees.

**Pass A — LLM output:**

```markdown
---
id: 20260305-091500-def
ops: [{"kind":"fs_read","path":"spec/SOUL.md"},{"kind":"fs_patch","op_id":"patch-soul","path":"spec/SOUL.md","unified_diff":"@@ -10,3 +10,4 @@\n context\n-old line\n+new line\n+added line"}]
---

I'll read the current SOUL spec, then patch it.
```

**Runtime behavior (Pass A):**
1. Parse manifest → 1 observe (`fs_read`), 1 effect (`fs_patch`)
2. Mixed observe+effect → two-pass mode triggered
3. Execute observe ops only:
   - `fs_read spec/SOUL.md` → artifact `obs-01.txt`, status `ok`
4. Skip effect ops with receipt:
   - `fs_patch` → status `skipped`, reason `observe_pass_requires_followup`
5. Write Pass A receipts
6. Archive IO pair (Pass A)
7. Repack context: original message + receipt summary + artifact content
8. Call LLM again (Pass B)

**Pass B — LLM output (after seeing the file content):**

```markdown
---
id: 20260305-091500-def
reply: trigger-99|Done, I've updated the SOUL spec.
ops: [{"kind":"fs_patch","op_id":"patch-soul","path":"spec/SOUL.md","unified_diff":"@@ -10,3 +10,4 @@\n context\n-old line\n+new line\n+added line"}]
---
```

**Runtime behavior (Pass B):**
1. Parse manifest → 0 observe, 1 effect (`fs_patch`)
2. No observe ops in Pass B → execute effects directly (no Pass C — `max_passes = 2`)
3. Sandbox check `spec/SOUL.md` → passes for write (not in protected list for patches)
4. Apply unified diff → success
5. Execute coordination ops: `Reply "trigger-99"` (gated on effect success)
6. Write Pass B receipts (appended to existing receipt file)

**Final receipt file (both passes):**

```json
{
  "schema": "cn.receipts.v1",
  "trigger_id": "20260305-091500-def",
  "receipts": [
    {
      "pass": "A",
      "op_id": "obs-01",
      "kind": "fs_read",
      "status": "ok",
      "reason": "",
      "start": "2026-03-05T09:15:01Z",
      "end": "2026-03-05T09:15:01Z",
      "artifacts": [{"path": "state/artifacts/20260305-091500-def/obs-01.txt", "hash": "sha256:...", "size": 2048}]
    },
    {
      "pass": "A",
      "op_id": "patch-soul",
      "kind": "fs_patch",
      "status": "skipped",
      "reason": "observe_pass_requires_followup",
      "start": "2026-03-05T09:15:01Z",
      "end": "2026-03-05T09:15:01Z",
      "artifacts": []
    },
    {
      "pass": "B",
      "op_id": "patch-soul",
      "kind": "fs_patch",
      "status": "ok",
      "reason": "",
      "start": "2026-03-05T09:15:03Z",
      "end": "2026-03-05T09:15:03Z",
      "artifacts": []
    }
  ]
}
```

**Key points:**
- Same `op_id` ("patch-soul") appears in both Pass A (skipped) and Pass B (ok) — cross-pass reuse is allowed
- `obs-01` auto-assigned for the observe op
- `Reply` coordination op only executes after effect succeeds (gating)
- If Pass B had proposed new observe ops → denied with `max_passes_exceeded`

---

### Example 3: Effect-only (single pass, no observe)

Agent commits directly without reading first.

**LLM output:**

```markdown
---
id: 20260305-100000-ghi
done: trigger-77
ops: [{"kind":"git_commit","op_id":"commit-1","message":"fix: correct typo in README"}]
---

Committed the fix.
```

**Runtime behavior:**
1. Parse manifest → 0 observe, 1 effect (`git_commit`)
2. No observe ops → single pass, execute effects directly
3. Execute `git_commit`:
   - `exec_args ~prog:"git" ~args:["add"; "-A"]` → exit 0
   - `exec_args ~prog:"git" ~args:["commit"; "-m"; "fix: correct typo in README"]` → exit 0
4. Execute coordination: `Done "trigger-77"` (gated on effect success)
5. Write receipt: status `ok`

---

### Example 4: Mixed coordination + typed ops with body resolution

Shows how `resolve_payload` interacts with typed ops.

**LLM output:**

```markdown
---
id: 20260305-103000-jkl
reply: trigger-55|Quick status update
send: bob|Hey Bob
ops: [{"kind":"git_status"},{"kind":"git_diff","rev":"HEAD~3..HEAD"}]
---

Here's the detailed status with recent changes.
I reviewed the last 3 commits and everything looks good.
```

**Runtime behavior:**
1. Parse coordination ops: `Reply("trigger-55", "Quick status update")`, `Send("bob", "Hey Bob", None)`
2. `resolve_payload`: body is present →
   - `Reply` payload becomes body text ("Here's the detailed status...")
   - `Send` has no explicit 3rd pipe → body is NOT consumed (Send only consumes explicit pipe or dedicated body)
3. Parse typed ops: `Git_status` (observe), `Git_diff` (observe)
4. All observe, no effects → single pass
5. Execute typed ops:
   - `git_status` → `exec_args ~prog:"git" ~args:["status"; "--porcelain"]` → artifact `obs-01.txt`
   - `git_diff` → `exec_args ~prog:"git" ~args:["diff"; "HEAD~3..HEAD"; "--"; "."; "':!.cn'"; "':!state'"; "':!logs'"]` → artifact `obs-02.txt`
6. Execute coordination ops (both Pass-A-safe for observe-only pass)

---

### Example 5: Denied ops (sandbox violation + missing op_id)

Shows error handling for invalid manifests.

**LLM output:**

```markdown
---
id: 20260305-110000-mno
ops: [{"kind":"fs_read","path":".cn/secrets.env"},{"kind":"fs_write","path":"src/main.ml","content":"let () = ()"},{"kind":"fs_read","path":"../../../etc/passwd"},{"kind":"frobnicate","op_id":"x1"}]
---

Let me read some files and make changes.
```

**Runtime behavior:**
1. Parse manifest → 4 ops
2. Validate each:
   - `fs_read .cn/secrets.env` → sandbox step 4 denies (`.cn/` in denylist) → receipt `denied`, `path_denied`
   - `fs_write src/main.ml` → missing `op_id` on effect → receipt `denied`, `missing_op_id`
   - `fs_read ../../../etc/passwd` → sandbox step 2 denies (escapes hub after collapse) → receipt `denied`, `path_escape`
   - `frobnicate` → unknown kind → receipt `denied`, `unknown_op_kind`
3. All ops denied → no execution
4. Coordination ops (if any) still execute (denials don't gate coordination)

**Receipt:**

```json
{
  "schema": "cn.receipts.v1",
  "trigger_id": "20260305-110000-mno",
  "receipts": [
    {"pass": "A", "op_id": "obs-01", "kind": "fs_read", "status": "denied", "reason": "path_denied", "start": "...", "end": "...", "artifacts": []},
    {"pass": "A", "op_id": null, "kind": "fs_write", "status": "denied", "reason": "missing_op_id", "start": "...", "end": "...", "artifacts": []},
    {"pass": "A", "op_id": "obs-02", "kind": "fs_read", "status": "denied", "reason": "path_escape", "start": "...", "end": "...", "artifacts": []},
    {"pass": "A", "op_id": "x1", "kind": "frobnicate", "status": "denied", "reason": "unknown_op_kind", "start": "...", "end": "...", "artifacts": []}
  ]
}
```

**Key points:**
- Denied observe ops still get auto-assigned `op_id` (`obs-01`, `obs-02`) for traceability
- `fs_write` with missing `op_id` → `op_id` is `null` in receipt (can't assign one for effects)
- Unknown kind `frobnicate` → denied but preserves the agent-supplied `op_id`
- Denials don't gate coordination ops (they're independent)

---

### Example 6: Exec with env scrubbing and allowlist

**LLM output:**

```markdown
---
id: 20260305-120000-pqr
ops: [{"kind":"exec","op_id":"run-tests","argv":["make","test"]},{"kind":"exec","op_id":"bad-cmd","argv":["/usr/bin/curl","https://evil.com"]}]
---

Running tests and fetching data.
```

**Config (`.cn/config.json`):**
```json
{
  "runtime": {
    "exec_enabled": true,
    "exec_allowlist": ["/usr/bin/make", "/usr/bin/git"]
  }
}
```

**Runtime behavior:**
1. `exec "make" ["test"]`:
   - Resolve `make` → `/usr/bin/make` → in allowlist → proceed
   - Build scrubbed env via `scrub_env`: drop `ANTHROPIC_KEY`, `TELEGRAM_TOKEN`, any `*_SECRET` vars
   - Call `exec_args_env ~prog:"/usr/bin/make" ~args:["test"] ~env:scrubbed_env`
   - Capture output → artifact, hash → receipt `ok`
2. `exec "curl" [...]`:
   - Resolve `curl` → `/usr/bin/curl` → NOT in allowlist → receipt `denied`, `policy_rejected`

---

## Dependency Graph

```
Step 1 (dotenv)      ─── independent
Step 2 (types/parse) ─── independent
Step 3 (sandbox)     ─── depends on Step 2
Step 4 (execution)   ─── depends on Steps 2, 3
Step 5 (two-pass)    ─── depends on Steps 2, 3, 4
Step 6 (discovery)   ─── depends on Step 2
Step 7 (projection)  ─── independent
```

Parallelizable: Steps 1, 2, 7 can start simultaneously.
Critical path: 2 → 3 → 4 → 5.

---

## File Change Summary

| File | Action | Est. Lines |
|------|--------|-----------|
| `src/cmd/cn_dotenv.ml` | **New** — dotenv parser + secret resolution | ~60 |
| `src/cmd/cn_shell.ml` | **New** — typed ops, sandbox, execution, receipts, SHA-256 | ~520 |
| `src/lib/cn_ffi.ml` | Edit — add `exec_args_env` (Unix.create_process_env) | ~30 |
| `src/cmd/cn_config.ml` | Edit — add shell_config fields, use dotenv fallback | ~40 |
| `src/cmd/cn_context.ml` | Edit — add capabilities block | ~30 |
| `src/cmd/cn_runtime.ml` | Edit — two-pass finalize, projection markers | ~150 |
| `src/cmd/dune` | Edit — add `cn_dotenv`, `cn_shell` | +2 |
| `test/cmd/cn_shell_test.ml` | **New** — typed ops + sandbox + receipt tests | ~200 |
| `test/cmd/cn_dotenv_test.ml` | **New** — dotenv parser tests | ~60 |
| **Total new/changed** | | **~1,090 lines** |

---

## Implementation Order

1. **Step 1** (dotenv) + **Step 2** (types/parse) + **Step 7** (projection) — in parallel
2. **Step 3** (sandbox) — after Step 2
3. **Step 4** (execution) — after Steps 2, 3
4. **Step 6** (discovery) — after Step 2 (can overlap with 3/4)
5. **Step 5** (two-pass) — after Steps 2, 3, 4 (the integration step)

---

## Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Path sandbox bypass via symlink | 4-step validation order: denylist on resolved path, not raw input |
| Git observe leaking secrets | `git_grep`/`git_diff`/`git_log` apply implicit path exclusion for denylisted prefixes (`.cn/`, `state/`, `logs/`) even if content is tracked |
| Secret leakage via exec | Suffix-based env scrubbing (`_KEY`, `_TOKEN`, `_SECRET`) + configurable list; enforced structurally via `exec_args_env` |
| Two-pass cost explosion | `max_passes = 2` hard cap; budgets on observe ops + artifact bytes |
| Receipt format instability | `cn.receipts.v1` schema version; `pass` per-entry; SHA-256 with prefix |
| Backwards compatibility | `ops:` is optional; absence means current behavior unchanged |
| Dotenv permission bypass | ssh-style refuse-to-load (not warn) when > 0600 |
