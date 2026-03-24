# PLAN-v3.8.0
## Generalized Bind Loop and Processing Indicators

**Status:** Draft
**Date:** 2026-03-21
**Implements:** [`N-PASS-BIND-v3.8.0.md`](../../alpha/N-PASS-BIND-v3.8.0.md)
**Scope:** Replace the hardcoded two-pass orchestration with a bounded N-pass bind loop and add sink-aware processing indicators (Telegram typing first).
**Issues:** #50, #48

---

## 0. Coherence Contract

### Gap

The runtime currently hardcodes a two-pass orchestration:
- observe
- then effect

This is coherent for a single observe → effect cycle, but it becomes incoherent when a task naturally requires:
- observe → effect → verify
- observe → effect → observe again
- multiple observe/effect rounds before a final response

It also gives poor operator/user feedback on long-running cycles.

### Mode

**MCA** — change the runtime/orchestrator.

### α / β / γ target

- **α PATTERN:** replace the special-case two-pass logic with one bounded general bind loop
- **β RELATION:** keep the new loop aligned with CAP, output-plane separation, traceability, and current FSM semantics
- **γ EXIT:** preserve `N=2` compatibility while enabling deeper bounded cycles

### Smallest coherent intervention

Do **not** change:
- the FSM
- the direct I/O boundary
- typed op authority
- output-plane separation
- receipts/artifacts model

Change only:
- pass orchestration
- processing-indicator behavior
- trace events / projections needed to explain it

---

## 1. Deliverables

### New / expanded runtime behavior

1. bounded `run_n_pass`
2. pass-level events (`pass.N.start`, `pass.N.complete`, `pass.N.stopped`)
3. final-pass-only user projection
4. sink-aware processing indicators
5. config for `max_passes` and typing refresh

### New / modified files

- `src/cmd/cn_orchestrator.ml`
- `src/cmd/cn_runtime.ml`
- `src/cmd/cn_telegram.ml`
- `src/cmd/cn_trace_state.ml`
- `src/cmd/cn_config.ml`
- `docs/alpha/agent-runtime/AGENT-RUNTIME.md` (already amended)
- tests under `test/cmd/`

No new top-level module is strictly required; this can be done inside `cn_orchestrator` + runtime integration.

---

## 2. Architectural decisions carried into implementation

### 2.1 The bind loop is below the FSM

Do not add FSM states for Pass A / Pass B / Pass N.
The FSM remains about outer runtime lifecycle.
The bind loop is an inner orchestration mechanism within one processing cycle.

### 2.2 One LLM call per pass

Keep the existing discipline:
- pack once per pass
- one LLM call
- parse once
- execute once
- repack
- next pass

This is **not** an in-call tool loop.

### 2.3 Only the final pass may be projected to the user

Intermediate passes are:
- archived
- receipted
- traced
- repacked

They are not projected to human surfaces.

### 2.4 Telegram typing is a processing indicator, not protocol semantics

Typing/reactions are best-effort UX signals.
They never change correctness or authority.

---

## 3. Step order

### Step 1 — Generalize the pass runner in `cn_orchestrator.ml`

**Goal:** Replace hardcoded two-pass logic with a generic bounded loop.

#### Add / refactor

Introduce a pass result type:

```ocaml
type pass_stop_reason =
  | No_ops
  | Max_passes_reached
  | Budget_exhausted
  | Processing_failed
  | Projection_failed
```

Introduce a driver:

```ocaml
val run_n_pass :
  config:Cn_shell.shell_config ->
  hub_path:string ->
  trigger_id:string ->
  llm_call:(string -> (string, string) result) ->
  indicator:indicator_handle option ->
  Cn_shell.typed_op list ->
  (n_pass_result, string) result
```

#### Responsibilities

Per pass:
1. emit `pass.N.start`
2. pack
3. call LLM
4. parse
5. classify typed ops
6. execute observe/effect according to current rules
7. collect receipts
8. emit `pass.N.complete`
9. decide: continue or stop

#### Stop conditions

- no ops
- max passes reached
- budget exhausted
- fatal runtime failure

#### Acceptance

- `max_passes = 2` reproduces current two-pass semantics
- no user projection from intermediate passes

---

### Step 2 — Add pass-indexed trace events

**Goal:** Traceability must explain each pass as its own bounded unit.

#### Required events

- `pass.N.start`
- `pass.N.complete`
- `pass.N.stopped`

#### Required fields

- `pass_index`
- `trigger_id`
- `reason_code`
- `typed_op_count`
- `receipt_count`
- refs to relevant output/receipt artifacts if available

#### Suggested reason codes

- `observe_detected`
- `effect_only`
- `no_ops`
- `max_passes_reached`
- `budget_exhausted`
- `processing_failed`
- `projection_failed`

#### Acceptance

Operator can reconstruct:
- how many passes ran
- why each pass continued or stopped

---

### Step 3 — Add N-pass config plumbing

**Goal:** Expose bounded loop settings in config.

#### In `cn_config.ml`

Extend shell/runtime config with:

```json
{
  "runtime": {
    "shell": {
      "max_passes": 5,
      "max_total_artifact_bytes": 131072,
      "max_total_ops": 32
    },
    "telegram": {
      "typing_indicator": true,
      "typing_refresh_sec": 4
    }
  }
}
```

#### Defaults

- `max_passes` = 5
- `max_total_artifact_bytes` = 131072
- `max_total_ops` = 32
- `typing_indicator` = true
- `typing_refresh_sec` = 4

#### Validation

Clamp:
- `max_passes` >= 1
- `typing_refresh_sec` >= 1
- budgets >= 1

#### Acceptance

Config loads cleanly and backward-compatible defaults preserve old behavior.

---

### Step 4 — Implement processing indicator abstraction

**Goal:** Abstract "processing is ongoing" into a sink-aware mechanism.

#### In `cn_runtime.ml` or a tiny helper module

Introduce conceptual helpers:

```ocaml
type indicator_handle = ...
type indicator_sink =
  | Telegram of { chat_id : int; token : string }
  | No_indicator

val start_indicator : indicator_sink -> indicator_handle option
val refresh_indicator : indicator_handle -> unit
val stop_indicator : indicator_handle -> unit
val fail_indicator : indicator_handle -> unit
```

#### Initial implementation

Only Telegram has a real implementation.
Other sinks return `None`.

#### Acceptance

No change to correctness if indicators fail.

---

### Step 5 — Telegram typing integration in `cn_telegram.ml`

**Goal:** Implement the sink-specific behavior required by issue #48.

#### Behavior

- when a Telegram-origin trigger is accepted/dequeued:
  - send typing
- before each LLM call after the first:
  - refresh typing
- optionally refresh after long execution gaps if needed
- stop naturally by final projection or by not refreshing on terminal failure

#### Important

Use the current best-effort / bounded synchronous helper (`request_once`) and keep:
- non-fatal behavior
- bounded timeouts
- no retries that meaningfully stall the cycle

#### Acceptance

Typing appears for long multi-pass Telegram cycles and does not appear for non-Telegram sinks.

---

### Step 6 — Integrate `run_n_pass` into `cn_runtime.process_one`

**Goal:** Runtime uses the new orchestrator instead of hardcoded two-pass flow.

#### Changes

- replace current two-pass call path with `run_n_pass`
- preserve:
  - archiving
  - receipts
  - final projection semantics
  - conversation append semantics
  - recovery and cleanup rules

#### Important

Only the final pass output should be sent through:
- `HumanSurface`
- `ConversationStore`

Intermediate pass outputs remain internal evidence.

#### Acceptance

Current two-pass cases still work.
A 3-pass case now works without additional user-visible turns.

---

### Step 7 — Projection and conversation rules

**Goal:** Ensure output-plane separation remains intact under N-pass orchestration.

#### Rule

For pass 1..N-1:
- no user projection
- no conversation append

For pass N (terminal pass):
- render for sink
- project to Telegram if applicable
- append final assistant text to conversation store

#### Acceptance

Intermediate control/prose never leaks to human surfaces.

---

### Step 8 — Projection indicator events

**Goal:** Make processing indicators visible in the trace.

#### Events

- `indicator.start`
- `indicator.refresh`
- `indicator.stop`
- `indicator.fail`

#### Fields

- `sink`
- `trigger_id`
- `pass_index` (when relevant)
- `reason_code` if failed/skipped

#### Acceptance

Operator can explain:
- why a user saw typing
- whether typing was refreshed between passes
- whether indicator attempts failed harmlessly

---

### Step 9 — Ready/runtime projection updates

**Goal:** Surface N-pass state to operators.

#### `state/runtime.json`

Add or update:
- `current_pass`
- `max_passes`
- `pass_reason`
- `pending_projection`
- `indicator_active` (optional)

#### `state/ready.json`

For daemon mode, if desired:
- include typing-indicator enabled/disabled in sensor posture

#### Acceptance

Operator can see whether the system is mid-cycle and which pass it is on.

---

### Step 10 — Tests

#### 10.1 Pure / orchestration tests

- `max_passes = 2` behaves like old two-pass
- no-op first pass terminates immediately
- observe pass defers effects
- pass beyond max denies observe with `max_passes_exceeded`
- budget exhaustion stops loop

#### 10.2 Runtime integration tests

- final pass only is projected
- final pass only is appended to conversation
- intermediate passes still archive outputs and receipts
- `pass.N.*` events appear in order

#### 10.3 Telegram indicator tests

- Telegram-origin cycle starts typing
- second pass refreshes typing
- non-Telegram cycle does not try typing
- indicator failure does not fail the cycle

#### 10.4 Output-plane regression tests

- N-pass does not reintroduce control-plane leaks to human sinks

---

## 4. Compile-safe sequence

1. Add config fields
2. Generalize orchestrator loop
3. Add pass events
4. Add indicator abstraction
5. Implement Telegram typing refresh
6. Integrate into runtime
7. Update projections
8. Add tests

Each step should compile independently.

---

## 5. Estimated change surface

### Modified modules

| Module | Impact |
|--------|--------|
| `cn_orchestrator.ml` | substantial |
| `cn_runtime.ml` | moderate |
| `cn_telegram.ml` | small to moderate |
| `cn_trace_state.ml` | small |
| `cn_config.ml` | small |
| `cn_shell.ml` | small |

### New code

Mostly orchestration and helper types, roughly +300 to +600 LOC depending on how much of the current two-pass logic is replaced vs generalized in place.

---

## 6. Explicit non-goals

- no FSM rewrite
- no new typed op kinds
- no sink/plugin framework
- no changes to capability authority
- no reintroduction of interactive tool loops
- no requirement for reactions as correctness condition

---

## 7. Success criteria

The implementation is done when:

1. A Telegram-origin session may perform more than two bounded passes within one runtime cycle.
2. Intermediate passes are not projected to the user.
3. The user sees typing during long multi-pass processing.
4. `max_passes = 2` reproduces existing behavior.
5. Operators can reconstruct each pass and why the loop stopped from traces alone.
6. Output-plane safety still holds.
