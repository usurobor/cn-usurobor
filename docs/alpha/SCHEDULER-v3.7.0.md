# SCHEDULER-v3.7.0
## Scheduler Unification: One Loop, Two Schedulers

**Status:** Draft
**Version:** 3.7.0
**Audience:** Runtime implementers, operators, reviewers
**Related:** `AGENT-RUNTIME.md`, `TRACEABILITY.md`, `CDD.md`

---

## 0. Purpose

This document defines scheduler unification for cnos.

Today the system has one processing engine but two incomplete operational stories:

- **daemon mode** is optimized for Telegram long-poll ingress
- **oneshot/timer mode** is optimized for git-native peer coordination (`cn sync` + inbox/outbox work)

This split is incoherent.

If the daemon is the actual deployment, but peer sync only happens under cron/timer, then a daemon-run agent can appear "alive" to humans while being dead to the git-native network.

The goal of v3.7.0 is:

> **one protocol loop, one processing engine, two schedulers**

The schedulers differ only in *how they wake the loop*:
- oneshot/timer (interoception — self-driven, periodic)
- service/daemon (exteroception — sensor-driven, plus interoception)

They do not differ in protocol responsibilities.

---

## 1. Core Principle

cnos is git-native first.

Telegram is a projection adapter for human interaction, not the center of the protocol.

Therefore:

- **all deployments** must support the full git-native coordination loop
- **daemon mode** must not be "Telegram-only"
- **oneshot mode** must remain a valid scheduler for environments that prefer periodic execution

The architectural distinction is:

### Not two modes of behavior
- cron mode
- daemon mode

### But two trigger sources for one behavior
- **Interoception** (internal triggers) — timer-driven maintenance, self-checks, periodic sync.
  This is the maintenance engine. Both schedulers have it.
- **Exteroception** (external triggers) — Telegram messages, future transports (webhooks, etc.).
  These are sensor/ingress adapters. Only present when configured.

### Two schedulers
- **oneshot scheduler** — one interoceptive tick, then exit
- **daemon scheduler** — continuous interoceptive ticks + exteroceptive sensors

---

## 2. The Unified Loop

The unified loop has three components:

### 2.1 Ingress adapters (exteroception)
Sources of work from external sensors:
- Telegram updates (external human interaction)
- stdio/manual injection (external operator interaction)

Ingress adapters only create or reveal work.
They do not execute the processing engine directly.

### 2.2 Maintenance engine (interoception)
Self-driven protocol duties (in order):
- inbox check: fetch inbound peer branches, triage to inbox
- git sync: stage local changes, heartbeat commit, push to origin
- materialize inbox items into processing queue
- flush outbox: send pending messages to peer repos
- update checks (when idle)
- MCA/review tick (time-gated by `review_interval_sec`)
- stale state cleanup

Note: git sync includes a heartbeat commit (`git commit --allow-empty`) to advance
HEAD even when idle, keeping peers informed of liveness via git log.

Primitive boundaries (each does exactly one thing):
- `inbox_check_once`: fetch inbound branches, triage to inbox (protocol-level)
- `sync_once`: git fetch, add, heartbeat commit, push (transport-level)
- `materialize_inbox_once`: queue inbox items for processing
- `flush_outbox_once`: send pending outbox to peer repos
- `update_check_once`: binary update check
- `review_tick_once`: time-gated MCA review
- `cleanup_once`: GC stale finalized markers

Maintenance changes what work is available and what state the runtime is in.

### 2.3 Processing engine
The existing `process_one` pipeline:
- recover or dequeue
- pack context
- call LLM
- archive
- execute coordination + CN Shell effects
- project
- update conversation
- cleanup

This remains the canonical engine.

---

## 3. Scheduler Modes

## 3.1 Oneshot / timer mode (`cn agent`)
Runs one full maintenance/processing cycle, then exits.

### Behavior
1. Run one maintenance tick
2. Drain queued work up to a bounded limit
3. Exit

### Intended use
- systemd timer
- cron
- peer-only agents
- low-resource or simple hosts
- CI/manual repair workflows

### Invariant
Oneshot mode is **not** a reduced protocol mode.
It is a different scheduler for the same protocol loop.

---

## 3.2 Daemon / service mode (`cn agent --daemon`)
Runs the same unified loop continuously.

### Behavior
The daemon has two activity sources:

#### Exteroception (sensor-driven)
External triggers that create work:
- Telegram long-poll (when configured)
- immediate queue drain after ingress
- future: webhooks, other transports

#### Interoception (self-driven)
Internal maintenance on a periodic timer:
- inbox check + git sync
- materialize inbox + outbox flush
- update checks
- review/MCA tick
- stale state cleanup

Telegram is optional. A peer-only daemon runs interoception only.

### Invariant
A daemon that reports `ready` is not just listening to Telegram.
It is also participating in the git-native network on schedule.

---

## 3.3 Stdio mode (`cn agent --stdio`)
A local/manual scheduler:
- accepts injected input
- can run the same maintenance cycle or a reduced local cycle
- primarily for testing and development

No unique protocol semantics.

---

## 4. Protocol Responsibilities by Layer

### 4.1 Scheduler responsibilities
Schedulers are responsible for:
- deciding when to wake
- invoking maintenance
- invoking queue draining
- respecting locking and runtime state
- exposing operator-visible readiness

### 4.2 Runtime responsibilities
The runtime is responsible for:
- correctness of processing
- recovery
- capability execution
- receipts / artifacts
- projection
- conversation persistence

### 4.3 Transport responsibilities
Telegram and git sync are both transports:
- Telegram = human ingress/projection
- git sync = peer ingress/egress

Neither transport changes the core authority model.

---

## 5. Operational Invariants

### 5.1 One engine
There is only one processing engine (`process_one` + supporting runtime/orchestrator logic).

### 5.2 One lock
All state mutation still happens under the same lock discipline.

### 5.3 One readiness story
Ready means:
- doctrine and packages loaded
- capabilities rendered
- processing engine healthy
- required transports initialized
- maintenance clocks active (for daemon) or available (for oneshot)

### 5.4 No "daemon-only human, cron-only peers" split
That split is explicitly forbidden by this design.

---

## 6. Maintenance Tick

Define a canonical `maintain_once` routine.

### Responsibilities
- peer sync
- inbox materialization
- outbox flush
- update check
- optional review/MCA tick
- runtime hygiene (stale markers, etc.)

### Output
Maintenance emits:
- events
- projection updates
- newly queued work

It does not directly mutate the agent's cognition.

---

## 7. Queue Draining

Define a canonical `drain_queue` routine.

### Responsibilities
- repeatedly call `process_one`
- stop on:
  - empty queue
  - lock contention
  - error
  - configured drain limit

### Why
This avoids duplicating "process one item or several?" logic between cron and daemon.

### Scheduler-specific defaults
- oneshot: conservative limit (e.g. 1 by default for backward compatibility)
- daemon: bounded burst limit (e.g. >1, configurable)

---

## 8. Traceability Requirements

Scheduler unification must integrate with `TRACEABILITY.md`.

### Required events

#### Boot / readiness
- `boot.start`
- `boot.ready`
- `boot.blocked`

#### Maintenance
- `maintenance.start`
- `inbox.checked`
- `sync.start`
- `sync.ok`
- `sync.error`
- `inbox.materialized`
- `outbox.flushed`
- `review.tick.start`
- `review.tick.complete`
- `maintenance.complete`

#### Queue draining
- `drain.start`
- `drain.complete`
- `drain.stopped`

#### Scheduler
- `scheduler.tick`
- `scheduler.idle` (status=Ok_ when clean, status=Degraded + severity=Warn when degraded)

### Required reason codes
Examples:
- `timer_invocation`
- `telegram_ingress`
- `sync_due`
- `review_due`
- `queue_empty`
- `drain_limit_reached`
- `lock_busy`
- `processing_failed`

---

## 9. Readiness Semantics

### 9.1 Oneshot readiness
Oneshot does not remain "ready" forever.
Its readiness is:
- booted
- maintenance-capable
- able to process work now

### 9.2 Daemon readiness
Daemon readiness includes:
- boot readiness
- sensor readiness (if Telegram enabled)
- maintenance clock health
- last sync status / recency

If sync is overdue or repeatedly failing, daemon state should become:
- `degraded`, not silently `ready`

---

## 10. Configuration

Add scheduler-related runtime config under `.cn/config.json`:

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

### Notes
- `sync_interval_sec` controls daemon interoception cadence (maintenance timer interval)
- `review_interval_sec` controls MCA review tick (wall-clock gated via `state/.last-review-at`)
- `oneshot_drain_limit` preserves backward-compatible conservative behavior
- `daemon_drain_limit` prevents unbounded burst starvation
- All values clamped to minimum 1

---

## 11. Relationship to Existing Commands

### cn sync

May remain as a standalone command, but should reuse the same internal maintenance primitives.

### cn agent

Becomes the canonical oneshot scheduler.

### cn agent --daemon

Becomes the canonical full-loop service scheduler.

No mode is "less protocol-correct" than the other.

---

## 12. Migration from Current Behavior

### Old world
- cron/timer for git-native loop
- daemon for Telegram
- conceptual split between peer and human scheduling

### New world
- same unified protocol loop everywhere
- scheduler determines cadence, not responsibilities

Migration should preserve:
- existing cron setups still work
- daemon gains sync duties instead of losing Telegram duties
- no behavior regression in process_one

---

## 13. Success Criteria

The design is implemented when:
1. `cn agent` performs one full maintenance + drain cycle
2. `cn agent --daemon` performs Telegram ingress and periodic maintenance ticks
3. peer sync works in daemon mode without cron assistance
4. readiness/projections distinguish:
   - ready
   - degraded
   - blocked
5. operators can explain from logs:
   - why a maintenance tick ran
   - why a queue drain stopped
   - why sync did or did not happen

---

## 14. Summary

v3.7.0 replaces the cron-vs-daemon behavioral split with:
- one protocol loop
- one processing engine
- one maintenance engine
- two schedulers

This preserves the git-native identity of cnos while allowing daemon mode to be the real deployment without losing peer coordination.
