# TRACEABILITY Implementation Plan

## Status: Implementing (Steps 1-9 complete)

This plan implements the observability system defined in
[TRACEABILITY.md](../../alpha/TRACEABILITY.md). It replaces ad hoc lifecycle logging
with structured events, state projections, and operator-facing readiness.

**Spec:** [TRACEABILITY.md](../../alpha/TRACEABILITY.md)
**Runtime contract:** [AGENT-RUNTIME.md](../../alpha/AGENT-RUNTIME.md) v3.3.7

---

## Goal

Let an operator answer, from files alone:
- Did the agent boot and become ready?
- Which packages/doctrine/mindsets/capabilities did it load?
- Why did it transition this way and not another?
- What is the current state of mind, body, and sensors?
- Why did an op execute, fail, get denied, or get deferred?
- Why did offset advance or not?

---

## Architectural stance

Three outputs, one source-of-truth hierarchy:

1. **Events** — append-only operational truth (`logs/events/YYYYMMDD.jsonl`)
2. **State projections** — current truth snapshots (`state/ready.json`, `state/runtime.json`, `state/coherence.json`)
3. **Evidence** — IO pairs, receipts, artifacts (unchanged)

Event stream becomes the primary lifecycle/transition trace.
IO pairs remain the primary deliberation audit.
Receipts remain the primary capability execution audit.

---

## New modules

| Module | Purpose |
|--------|---------|
| `src/cmd/cn_trace.ml` | Event schema, boot session state, append-only JSONL writer |
| `src/cmd/cn_trace_state.ml` | Writes `state/ready.json`, `state/runtime.json`, `state/coherence.json` |
| `test/cmd/cn_trace_test.ml` | Pure serialization + integration tests |
| `test/cmd/cn_trace_state_test.ml` | State projection tests |

## Existing modules to modify

| Module | Instrumentation |
|--------|----------------|
| `src/cmd/cn_hub.ml` | `log_action` becomes compatibility shim to `Cn_trace.emit` |
| `src/cmd/cn_runtime.ml` | Boot/cycle/body events + projection updates |
| `src/cmd/cn_orchestrator.ml` | Pass selection / gating events |
| `src/cmd/cn_projection.ml` | Projection marker and send events |
| `src/cmd/cn_telegram.ml` | Sensor-layer poll / offset / UX events |
| `src/cmd/cn_assets.ml` | Expose counts/hash inputs for readiness/coherence |
| `src/cmd/cn_capabilities.ml` | Expose rendered-hash / metadata for readiness |
| `src/cmd/cn_deps.ml` | Deps/lock load + asset validation events |
| `src/cmd/cn_system.ml` | Doctor/setup events where relevant |

---

## Steps

### Step 1: cn_trace.ml — event schema + append-only writer

Implement the event schema from TRACEABILITY.md §5.

**Required fields:** `schema`, `ts`, `boot_id`, `component`, `layer`, `event`, `severity`, `status`

**Optional fields:** `seq`, `cycle_id`, `trigger_id`, `pass`, `prev_state`, `next_state`, `reason_code`, `reason`, `refs`, `details`

Design:
- `schema = "cn.events.v1"`
- `boot_id` generated once per process start
- `seq` monotonic per boot session
- Append path: `logs/events/YYYYMMDD.jsonl`
- JSON serialization via `Cn_json.to_string`
- One event per line, no pretty-printing

API:
- `Cn_trace.start_session : hub_path -> session`
- `Cn_trace.emit : session -> event -> unit`
- `Cn_trace.emit_simple : session -> ... -> unit` (helper for common cases)
- `Cn_trace.event_path_for_day : hub_path -> string`

Acceptance criteria:
- Pure tests for serialization shape
- Two emitted events append as two JSONL lines
- All timestamps UTC ISO8601
- No multiline payloads

This step is the keystone. No instrumentation before this.

---

### Step 2: cn_trace_state.ml — readiness/runtime/coherence projections

Implement the three state projections from TRACEABILITY.md §9.

API:
- `write_ready : hub_path -> ready_projection -> unit`
- `write_runtime : hub_path -> runtime_projection -> unit`
- `write_coherence : hub_path -> coherence_projection -> unit`

**ready** — status, boot_id, updated_at, mind (profile, packages, doctrine counts/hash, mindset counts/hash, skills indexed, capability posture), body (fsm_state, lock_held, current_cycle, queue_depth), sensors (telegram enabled/offset/poll status)

**runtime** — current cycle id, current pass, active trigger, queue depth, lock owner/boot_id, pending projection status

**coherence** — structural checks: config loaded, lockfile loaded, doctrine loaded, mindsets loaded, packages resolved, capabilities rendered, transport ready, wake-up local-only

Acceptance criteria:
- JSON schema matches spec examples
- Projections are overwrite-in-place
- Missing optional sections degrade cleanly

For v1, projections are written directly by runtime code. Full event-sourced reconstruction can come later.

---

### Step 3: Boot instrumentation (mind layer + readiness)

Emit the mandatory boot sequence from TRACEABILITY.md §7:

1. `boot.start`
2. `config.loaded`
3. `deps.lock.loaded`
4. `assets.validated`
5. `doctrine.loaded`
6. `mindsets.loaded`
7. `skills.indexed`
8. `capabilities.rendered`
9. `boot.ready`

Optional (daemon mode):

10. `telegram.offset.loaded`
11. `daemon.poll.start`

Where to instrument:
- Config load path in CLI/runtime entry
- CAR/deps load in `cn_deps` / `cn_assets`
- Doctrine/mindset/skill counts in `Cn_assets`
- Capabilities render in `Cn_capabilities`
- Daemon startup in `cn_runtime.run_daemon`

Required details: profile, package list, doctrine required/loaded counts, mindset required/loaded counts, skills indexed count, capabilities hash/settings, transport enabled/disabled.

State projections:
- `state/ready.json` set to `ready` only after `boot.ready`
- On failure: emit `boot.blocked`, write `status: "blocked"` with specific `reason_code`

Acceptance criteria:
- One successful daemon start produces the exact boot sequence in order
- Failure to validate assets produces `boot.blocked` with specific `reason_code`

---

### Step 4: Runtime cycle instrumentation (body layer)

Instrument `cn_runtime.process_one` and recovery paths.

Required events:
- `cycle.start`
- `queue.dequeue` or `cycle.recover`
- `pack.start`
- `pack.complete`
- `llm.call.start`
- `llm.call.ok` or `llm.call.error`
- `effects.execute.start`
- `effects.execute.complete`
- `finalize.complete`

Transition fields required on any state change: `prev_state`, `next_state`, `reason_code`.

Recovery-specific reason codes: `recovery_output_present`, `recovery_input_present`, `fresh_dequeue`, `lock_busy`, `queue_empty`.

State projections: update `state/runtime.json` at cycle start, pass changes, finalize complete, error exit.

Acceptance criteria:
- Recovery path and fresh path are distinguishable from events alone
- Lock-busy and queue-empty are visible without stderr scraping

---

### Step 5: Pass orchestration + governance events

Instrument `cn_orchestrator.ml`.

Required events: `pass.selected`, `ops.classified`, `coordination.skipped`, `policy.denied`, `budget.denied`, `effects.execute.start`, `effects.execute.complete`.

Required reason codes: `observe_detected`, `n_pass_off`, `max_passes_exceeded`, `pass_a_unsafe`, `effects_failed`, `budget_exceeded`, `unknown_op_kind`, `phase_mismatch`, `path_denied`.

Receipts remain the primary audit for typed ops. These events are operator summaries.

Acceptance criteria:
- Given a mixed observe/effect manifest, the event stream explains why effects were deferred
- Given a denied op, the operator sees a policy event without opening the receipt file

---

### Step 6: Sensor layer instrumentation (Telegram / projection)

Instrument `cn_telegram.ml`, daemon poll loop, and `cn_projection.ml`.

Transport events:
- `telegram.offset.loaded`
- `daemon.poll.start` / `daemon.poll.ok` / `daemon.poll.error`
- `daemon.pending`
- `daemon.offset.advanced`
- `daemon.offset.blocked` (reason codes: `processing_failed`, `still_queued`, `still_in_flight`, `rejected_user`, `already_projected`)

Projection events:
- `projection.start` / `projection.ok` / `projection.skipped` / `projection.error`
- `projection.marker.created` / `projection.marker.exists` / `projection.marker.removed`

UX signal events (debug-level, optional):
- `sensor.typing.start` / `sensor.reaction.set` / `sensor.reaction.clear`

Acceptance criteria:
- From logs alone, operator can answer: why offset did or did not advance, whether projection was deduped, whether a send failed and was retried

---

### Step 7: Mind layer details (assets, skills, capabilities)

Instrument cognition loading with enough detail for operators to know what mind woke up.

Events: `doctrine.loaded`, `mindsets.loaded`, `skills.indexed`, `skills.selected`, `capabilities.rendered`.

Required details: doctrine file count/names, mindset file count/names, package list + versions, selected skills list, whether hub-local overrides present, capability block hash + posture (n_pass, apply_mode, exec_enabled).

Data source: `Cn_assets.asset_summary` and `Cn_capabilities.render` metadata.

Acceptance criteria:
- Operator can answer "which doctrine/mindsets/packages did the agent load on this boot?" from `logs/events` and `state/ready.json` alone

---

### Step 8: Wire Cn_hub.log_action into the new system

`Cn_hub.log_action` is currently a no-op.

Do not reintroduce the old generic hub log. Instead:
- Keep `Cn_trace.emit` as the real API
- Make `Cn_hub.log_action` a compatibility shim that forwards to `Cn_trace.emit_simple`

Acceptance criteria:
- No remaining operationally meaningful callsite silently drops lifecycle information

---

### Step 9: State projection update policy

**state/ready.json** — update on: boot start, boot blocked, boot ready, major configuration/asset changes.

**state/runtime.json** — update on: lock acquire/release, cycle start, pass change, finalize complete, runtime error.

**state/coherence.json** — update on: boot complete, deps/asset changes, capability render changes, transport enable/disable.

Acceptance criteria:
- Projections never claim `ready` before the mandatory boot sequence completes
- Projections remain useful after crashes/restarts

---

### Step 10: Tests

**Pure tests:**
- Event JSON serialization
- Severity/status enum rendering
- Seq increment
- Reason_code propagation
- Projection JSON shape

**Integration tests:**
- Successful boot emits required sequence
- Blocked boot writes `state/ready.json` with `status=blocked`
- Successful cycle emits start → pack → llm → effects → projection → finalize
- Two-pass cycle emits A/B selection and correct reasons
- Projection dedup emits marker events and blocks offset advancement
- Daemon failure emits `daemon.offset.blocked`
- No secret-bearing env var values appear in event JSON

**Negative tests:**
- Malformed event details rejected or sanitized
- Error messages with possible secrets get redacted
- Debug UX events do not change readiness/runtime state

---

### Step 11: File layout / retention

Implement:
- `logs/events/YYYYMMDD.jsonl`
- `state/ready.json`
- `state/runtime.json`
- `state/coherence.json`

Do not change:
- `logs/input/`
- `logs/output/`
- `state/receipts/`
- `state/artifacts/`

For v1: daily event file rotation by date, no complex pruning, state projections are last-write-wins.

---

### Step 12: Docs / command integration

After implementation:
- Update AGENT-RUNTIME.md if any event names or projection shapes changed
- Keep LOGGING.md as shim only
- Optionally add `cn trace doctor` or `cn doctor` extension to inspect readiness projections

---

## Critical path

1. Step 1 — `cn_trace.ml` (keystone)
2. Step 2 — `cn_trace_state.ml`
3. Step 3 — boot instrumentation
4. Step 4 — cycle instrumentation
5. Step 6 — sensor/projection instrumentation
6. Step 9 — projection update policy
7. Step 10 — tests

## Parallelizable work

Can run in parallel after Step 1:
- Step 5 (orchestrator/governance summaries)
- Step 7 (mind layer enrichment)
- Step 8 (log_action shim)
- Step 12 (docs update)

---

## Success criteria

The implementation is done when an operator can answer, from files alone:
- Did the agent boot and become ready?
- Which packages/doctrine/mindsets did it load?
- Which capabilities were active?
- Why did it choose Pass A vs Pass B?
- Why did a typed op get denied/skipped/error?
- Why did Telegram offset advance or not?
- Whether the system is currently ready, degraded, or blocked

Without reading source code or tailing stderr.
