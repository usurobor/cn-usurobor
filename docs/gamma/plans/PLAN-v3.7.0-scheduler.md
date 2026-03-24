# PLAN-v3.7.0
## Scheduler Unification — Implementation Plan

**Status:** Draft
**Implements:** `SCHEDULER-v3.7.0`
**Method:** CDD / SDD
**Primary goal:** make daemon and oneshot two schedulers for one full protocol loop

---

## 0. Coherence Contract

### Gap
The current runtime splits protocol responsibilities:
- daemon handles Telegram ingress
- oneshot/timer handles peer sync and inbox processing

This makes a daemon-run agent appear live to humans while being dead to the git-native network.

### Mode
**MCA** — change runtime scheduling so the full protocol loop is available in both schedulers.

### α / β / γ target
- **α PATTERN:** remove the daemon-vs-cron behavioral split
- **β RELATION:** make runtime behavior match the protocol's git-native identity
- **γ EXIT:** create one maintenance engine reusable across schedulers and future transports

### Smallest coherent intervention
Do not rewrite `process_one`. Add a shared maintenance engine and a shared drain helper, then route both schedulers through them.

---

## 1. New / Changed Modules

### New module
- `src/cmd/cn_maintenance.ml`

### Modified modules
- `src/cmd/cn_runtime.ml`
- `src/cmd/cn_config.ml`
- `src/cmd/cn_system.ml` (sync command reuse)
- `src/cmd/cn_trace_state.ml` (scheduler projection fields)
- `src/cmd/dune` (add new module)
- tests for runtime/scheduler behavior

---

## 2. Step 1 — Extract maintenance primitives into `cn_maintenance.ml`

### Purpose
Factor the git-native protocol duties out of ad hoc mode-specific code.

### Responsibilities
Implement pure-ish / well-bounded helpers:

- `sync_once`
- `materialize_inbox_once`
- `flush_outbox_once`
- `update_check_once`
- `review_tick_once` (if current design keeps this)
- `cleanup_once` (stale marker cleanup etc.)

### Eventing
Each helper should emit trace events through the shared trace session:
- `sync.start` / `sync.ok` / `sync.error`
- `inbox.materialized`
- `outbox.flushed`
- `update.check.start` / `update.check.ok` / `update.check.error`
- `review.tick.start` / `review.tick.complete`

### Acceptance
- no scheduler logic inside this module
- no Telegram logic inside this module
- reusable from both daemon and oneshot

---

## 3. Step 2 — Add `maintain_once`

### Function
Add to `cn_maintenance.ml`:

- `maintain_once ~config ~hub_path ~name ~trace_session : (unit, string) result`

### Behavior
In one bounded call:
1. emit `maintenance.start`
2. run sync
3. materialize inbox
4. flush outbox
5. update check
6. optional review tick
7. cleanup
8. emit `maintenance.complete`

### Policy
A failed sub-step should be logged with events and surfaced according to severity.
Decide explicitly:
- hard failure vs degraded completion

Recommended v1:
- sync/update failures degrade but do not crash the scheduler
- use `maintenance.complete` with `status = degraded` when substeps failed

---

## 4. Step 3 — Add `drain_queue`

### Function
Add to `cn_runtime.ml` (or a small helper module if preferred):

- `drain_queue ~config ~hub_path ~name ~limit : (int * string option) result`

### Behavior
Repeatedly:
- call `process_one`
- stop on:
  - queue empty
  - lock busy
  - error
  - limit reached

### Events
Emit:
- `drain.start`
- `drain.complete`
- `drain.stopped`

Reason codes:
- `queue_empty`
- `lock_busy`
- `processing_failed`
- `drain_limit_reached`

### Acceptance
- no duplicated process logic
- `process_one` semantics unchanged

---

## 5. Step 4 — Rework oneshot scheduler (`cn agent`)

### Current intent
Oneshot should become:
- one maintenance tick
- one bounded queue drain
- exit

### Implementation
In `run_cron` / `run_agent` oneshot path:

1. shared boot/readiness sequence
2. `maintain_once`
3. `drain_queue ~limit:config.runtime.scheduler.oneshot_drain_limit`
4. write projections / emit final scheduler event
5. exit

### Acceptance
- no Telegram dependency
- still works for peer-only nodes
- still safe for cron/systemd timer

---

## 6. Step 5 — Rework daemon scheduler (`cn agent --daemon`)

### Purpose
Daemon owns the full loop, not just Telegram.

### Structure
Inside daemon loop:
- **fast clock**:
  - Telegram poll / ingress
  - immediate `drain_queue` after new work
- **slow clock**:
  - if `now - last_sync >= sync_interval_sec` → `maintain_once`
  - then `drain_queue ~limit:daemon_drain_limit`

### Required state
Track:
- `last_sync_at`
- `last_review_at`
- `last_maintenance_status`

### Events
Emit:
- `scheduler.tick`
- `scheduler.idle`
- `scheduler.degraded`

### Acceptance
- daemon can operate with Telegram enabled or disabled
- daemon performs peer sync periodically without cron assistance

---

## 7. Step 6 — Scheduler config plumbing

### Add scheduler block to config load
Parse:

```json
{
  "runtime": {
    "scheduler": {
      "sync_interval_sec": 300,
      "review_interval_sec": 300,
      "oneshot_drain_limit": 1,
      "daemon_drain_limit": 8
    }
  }
}
```

### Defaults

Recommended defaults:
- `sync_interval_sec` = 300
- `review_interval_sec` = 300
- `oneshot_drain_limit` = 1
- `daemon_drain_limit` = 8

### Validation

Clamp:
- intervals >= 1
- drain limits >= 1

---

## 8. Step 7 — Traceability integration

### Projections

Update:
- `state/ready.json`
- `state/runtime.json`

Add scheduler/maintenance fields:
- `last_sync_at`
- `last_sync_status`
- `last_review_at`
- `last_maintenance_status`
- `scheduler_mode`

### Readiness semantics

For daemon:
- if sync overdue or repeatedly failing → status = degraded

For oneshot:
- ready means "able to run now," not long-lived service readiness

### Acceptance

Operators can tell:
- whether sync is active
- whether the daemon is only polling Telegram or actually participating in the protocol
- why maintenance did or didn't run

---

## 9. Step 8 — Reuse cn sync command through shared maintenance primitives

### Goal

Avoid divergence between:
- standalone `cn sync`
- scheduler-maintenance sync

### Implementation

Refactor existing sync command to call the same `sync_once` / maintenance primitives where possible.

### Acceptance

No duplicated protocol logic between sync command and scheduler.

---

## 10. Step 9 — Tests

### 10.1 Unit tests
- config parsing for scheduler block
- maintenance status shaping
- drain-stop reason mapping

### 10.2 Integration tests

A. Oneshot
- boot
- maintenance runs
- queue drains up to limit
- exits cleanly

B. Daemon
- Telegram ingress enqueues work
- slow tick runs maintenance on interval
- queue drains after poll and after maintenance

C. Peer-only daemon
- no Telegram token
- daemon still runs maintenance ticks and drains queue

D. Degraded sync
- maintenance emits degraded
- ready.json reflects degraded state

E. Traceability
- maintenance events present
- drain events present
- reason codes visible
- projections updated

---

## 11. Compile-safe order
1. `cn_maintenance.ml`
2. scheduler config parsing
3. `drain_queue`
4. oneshot integration
5. daemon integration
6. projections / readiness semantics
7. tests
8. sync-command reuse

Each step should compile and be reviewable independently.

---

## 12. Estimated change surface

### New code
- `cn_maintenance.ml`: ~180–280 LOC

### Modified code
- `cn_runtime.ml`: ~120–220 LOC
- config parsing: small
- tests: ~150–250 LOC

### Total

Roughly +350 to +700 LOC, depending on how much existing sync logic is already factored.

---

## 13. Explicit non-goals
- changing process_one semantics
- changing CN Shell execution semantics
- changing projection logic
- new transport adapters
- removing oneshot mode
- adding distributed scheduling or leader election

---

## 14. Success criteria

The implementation is done when:
1. daemon mode performs periodic peer sync without cron
2. oneshot mode performs one full maintenance cycle before processing
3. both schedulers use the same maintenance engine
4. operators can answer from logs/projections:
   - when sync ran
   - why it stopped
   - why the queue did or didn't drain
   - whether the daemon is protocol-ready or only transport-alive

---

## 15. Final note

This is a scheduler unification, not a runtime rewrite.

The processing engine stays the same.
The protocol responsibilities become the same.
Only the scheduler cadence differs.
