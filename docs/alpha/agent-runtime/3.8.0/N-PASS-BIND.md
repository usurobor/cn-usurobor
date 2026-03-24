# N-PASS-BIND-v3.8.0
## Generalized Bind Loop and Processing Indicators

**Status:** Draft
**Version:** 3.8.0
**Date:** 2026-03-21
**Authors:** usurobor
**Scope:** Replace the hardcoded two-pass orchestrator with a bounded N-pass bind loop; add sink-aware processing indicators for human-facing surfaces, with Telegram typing as the first implementation.
**Issues:** #50 (N-pass bind loop), #48 (Telegram typing indicators)

---

## 0. Coherence Contract

### Gap

The current runtime hardcodes two passes (`run_two_pass` in `cn_orchestrator.ml`).

This is coherent for a single observe → effect cycle, but incoherent for longer reasoning/action chains such as:

- observe → think → effect → verify
- observe → effect → observe again → effect again
- inspect multiple artifacts before a final decision

As a result, one logical agent cycle may require multiple user-visible turns.

This weakens:
- capability composability
- parity with tool-loop runtimes
- user trust on long waits

### Mode

**MCA** — change the runtime/orchestrator, not the prompting model.

### α / β / γ target

- **α PATTERN:** replace hardcoded two-pass logic with one bounded, general bind loop
- **β RELATION:** keep the loop aligned with CAP, output-plane separation, receipts, and traceability
- **γ EXIT:** preserve current two-pass behavior as the `N=2` special case while enabling deeper bounded loops

### Smallest coherent intervention

Keep:
- one LLM call per pass
- post-call governed capability execution
- output-plane separation
- receipts/artifacts
- current FSM semantics

Change only:
- pass orchestration (generalize `run_two_pass` → `run_n_pass`)
- processing indication behavior (new abstraction)

---

## 1. Core Decision

The runtime SHALL replace `run_two_pass`-style orchestration with a bounded **N-pass bind loop**.

### 1.1 Conceptual form

```ocaml
let rec bind ~context ~pass_index =
  let packed = pack context in
  let response = call packed in
  let parsed = parse response in
  let rendered = render parsed in

  if no_ops parsed then
    project_final rendered
  else if stop_condition reached then
    stop_with_receipts
  else
    let receipts = execute_pass parsed pass_index in
    let context' = repack context receipts response in
    bind ~context:context' ~pass_index:(pass_index + 1)
```

### 1.2 Invariant

Each pass remains:
- one packed context
- one LLM call
- one parsed response
- one bounded execution step
- one repack

The loop is still pure-pass composition, not a live in-call tool loop.

---

## 2. Relation to CAP

This design is the runtime expression of:
- **CMP** — build the most coherent picture available now
- **CAP** — choose MCA or MCI
- **CLP** — review the resulting delta

At runtime scale:
- observe ops support CMP
- effect ops support MCA
- receipts/artifacts support CLP and next-pass CMP

The loop therefore becomes:

> CMP → effect or learn → receipts → CMP again

within one bounded agent cycle.

---

## 3. Relation to the FSM

This is **not** an FSM change.

The FSM continues to own:
- actor lifecycle
- queue/process/recover states
- terminal thread transitions via coordination ops

The N-pass loop is a sub-cycle orchestration mechanism inside one processing cycle.

### 3.1 Rule

Typed pass orchestration MUST NOT be encoded as new actor states.

### 3.2 Why

The FSM models:
- outer runtime state

The bind loop models:
- inner coherent action/observation within one processing attempt

Those are different levels.

---

## 4. Pass Semantics

### 4.1 Pass classes

Every pass is classified by the typed ops it contains.

**Observe-class pass**

If the pass output contains any observe-class ops:
- execute observe ops
- defer effect ops in that same pass
- write receipts with:
  - status: `skipped`
  - reason: `observe_pass_requires_followup`

**Effect-class pass**

If the pass contains only effect-class ops:
- execute them under the existing policy/sandbox/governance rules

**No-op pass**

If the pass contains no typed ops:
- this is a terminal pass candidate
- final projection rendering rules apply

### 4.2 Existing two-pass behavior

The current two-pass model is preserved as the special case:
- `max_passes = 2`

v3.8.0 generalizes this to:
- `max_passes = N`, configurable, bounded

---

## 5. Stop Conditions

The bind loop MUST terminate on any of the following:

### 5.1 No ops

The parsed output contains no typed ops.

### 5.2 Max passes reached

`pass_index >= max_passes`

### 5.3 Budget exhausted

A configured budget is exceeded, for example:
- max passes
- max cumulative artifact bytes
- max cumulative typed ops
- max wall-clock processing duration

### 5.4 Hard runtime failure

Examples:
- LLM call error
- projection failure requiring cycle failure
- fatal policy/sandbox inconsistency

### 5.5 Pass-N observe overflow

If a pass at the boundary still asks to observe:
- deny with receipt/event:
  - status: `denied`
  - reason: `max_passes_exceeded`

### 5.6 Misplaced ops (Issue #51)

If `typed_ops = []` but the body contains ops-like syntax (`ops: [`, `send: `, etc.):
- classify the pass as `misplaced_ops`
- do **not** project the raw body to human sinks
- run a bounded correction pass: call LLM with explicit formatting instructions
- if correction produces valid frontmatter ops: execute normally
- if correction fails: terminate safely with `misplaced_ops` reason code
- body scanning is for **anomaly detection**, never for execution authority
- the correction pass counts against normal `max_passes` / budget limits

---

## 6. Final Projection Rule

Only the **final pass** may be projected to the user.

Intermediate pass outputs are:
- archived
- receipted
- traced
- repacked

They are **not** sent to human-facing sinks.

### Why

Intermediate outputs belong to the control/reasoning process, not to the presentation plane.

This preserves the existing output-plane separation:
- control plane → internal
- final safe presentation → external

---

## 7. Processing Indicators

The runtime SHALL introduce a generic processing indicator abstraction for human-facing sinks.

### 7.1 Rationale

The bind loop increases the chance of multiple LLM calls within one user-visible cycle.
Without a processing indicator, human users see dead air and cannot tell:
- still processing
- blocked
- dead

Issue #48 already defines the Telegram requirement for typing indicators.
This amendment generalizes it into a sink-level concept.

### 7.2 Interface

Conceptual interface:

```ocaml
type indicator_sink =
  | Telegram of { chat_id : int; token : string }
  | None

type indicator_handle

val start_indicator : indicator_sink -> indicator_handle option
val refresh_indicator : indicator_handle -> unit
val stop_indicator : indicator_handle -> unit
```

### 7.3 Rules

- best-effort only
- never changes protocol correctness
- never blocks the processing pipeline catastrophically
- may be sink-specific
- `request_once` semantics (no retries, bounded timeout) per existing `cn_telegram.ml` pattern

---

## 8. Telegram Processing Indications

Telegram is the first concrete sink.

### 8.1 Required behavior

For Telegram-origin triggers:

1. **Start**: When the message is accepted/dequeued, send:
   - `sendChatAction: typing`
2. **Refresh**: Refresh typing:
   - before each LLM call after the first
   - and after long execution phases if needed
3. **Stop**: Stop naturally by:
   - final projection success
   - or no further refresh after terminal failure

### 8.2 Optional reaction semantics

If Telegram reactions are available and supported:
- a lightweight "thinking" reaction MAY be used while the cycle is active
- it MAY be cleared on success
- it MAY remain or switch on failure

But this is optional and not part of correctness.

### 8.3 Sink guarding

No typing indicator must be emitted for:
- non-Telegram surfaces
- peer outboxes
- conversation store
- audit sinks

---

## 9. Telemetry and Traceability

The N-pass loop MUST emit pass-level events.

### 9.1 Required events

- `pass.N.start`
- `pass.N.complete`
- `pass.N.stopped`

Each with:
- `pass_index`
- `trigger_id`
- `reason_code`
- optional refs to IO pairs / receipts

### 9.2 Suggested reason codes

- `observe_detected`
- `effect_only`
- `no_ops`
- `max_passes_reached`
- `budget_exhausted`
- `processing_failed`
- `projection_failed`

### 9.3 Processing indicator events

- `indicator.start`
- `indicator.refresh`
- `indicator.stop`
- `indicator.fail`

For Telegram:
- sink = `telegram`
- include `chat_id`
- no secret-bearing data

---

## 10. Configuration

Extend the `runtime` config block for the bind loop:

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

### 10.1 Defaults

- `max_passes` = 5
- `max_total_artifact_bytes` = 131072
- `max_total_ops` = 32
- `typing_indicator` = true
- `typing_refresh_sec` = 4

### 10.2 Notes

- 5 is high enough for observe → effect → verify → adapt patterns
- still bounded enough to avoid runaway loops
- `max_passes` replaces the hardcoded `2` in `cn_orchestrator.ml`
- `max_total_artifact_bytes` caps cumulative artifact size across all passes
- existing per-op `max_artifact_bytes` and `max_artifact_bytes_per_op` budgets remain unchanged
- new fields live under `runtime.shell`, consistent with `two_pass`, `apply_mode`, `max_observe_ops`

---

## 11. Backward Compatibility

### 11.1 Existing two-pass behavior

If `max_passes = 2`, behavior MUST remain equivalent to current two-pass semantics.

### 11.2 Existing issue #48 behavior

Typing-on-processing is subsumed by the processing indicator abstraction.
Telegram-specific acceptance remains satisfied through the generalized mechanism.

### 11.3 Receipt pass field

Currently receipts use `pass = "A"` or `pass = "B"`. Under N-pass, the pass label generalizes to an N-indexed scheme. The `cn.receipts.v1` schema already accepts any string for the pass field, so no schema migration is required.

---

## 12. Acceptance Criteria

The design is correctly implemented when:

1. `run_n_pass` replaces the hardcoded two-pass path.
2. The loop terminates on:
   - no ops
   - max passes
   - budget exhaustion
   - fatal runtime failure.
3. Each pass emits:
   - `pass.N.start`
   - `pass.N.complete`
   with receipts and telemetry.
4. Telegram typing is:
   - sent when the Telegram message is dequeued
   - refreshed between passes / before subsequent LLM calls
   - absent on non-Telegram surfaces.
5. Only the final pass output is projected to the user; intermediate outputs are archived.
6. Existing two-pass behavior is preserved when `max_passes=2`.

---

## 13. Non-goals

This amendment does not:
- change the FSM model
- introduce an in-call tool loop
- change the output-plane separation
- change capability authority
- add new typed op kinds
- require reactions for correctness

---

## 14. Module Impact

### 14.1 Modified modules

| Module | Change |
|--------|--------|
| `cn_orchestrator.ml` | Replace `run_two_pass` with `run_n_pass`; generalize pass A/B into pass N; add stop condition logic |
| `cn_runtime.ml` | Wire `run_n_pass`; add indicator lifecycle around LLM calls; pass `max_passes` from config |
| `cn_shell.ml` | Add `max_passes`, `max_total_artifact_bytes`, `max_total_ops` to `shell_config`; generalize `needs_two_pass` |
| `cn_config.ml` | Parse `max_passes`, `max_total_artifact_bytes`, `max_total_ops`, `telegram.typing_indicator`, `telegram.typing_refresh_sec` |
| `cn_telegram.ml` | Already has `send_typing`, `request_once` — no changes needed |
| `cn_trace.ml` | No changes needed — `pass` field already accepts any string |

### 14.2 New code

No new top-level module is strictly required. The processing indicator abstraction can live inside `cn_orchestrator.ml` or `cn_runtime.ml`, or optionally in a tiny `cn_indicator.ml` helper if the surface area warrants it.

### 14.3 Test impact

| Test file | Change |
|-----------|--------|
| `cn_orchestrator_test.ml` | Add N-pass tests; verify N=2 backward compat; test stop conditions |
| `cn_runtime_integration_test.ml` | Update mocked orchestration for N-pass; add indicator lifecycle tests |

---

## 15. Summary

v3.8.0 generalizes:
- **two-pass → bounded N-pass bind loop**

and introduces:
- **Telegram typing quirk → processing indicator abstraction**

The result is:
- more coherent observe/effect chaining
- better parity with real agent workflows
- better user trust on long cycles
- no loss of the current governed, post-call, auditable architecture
