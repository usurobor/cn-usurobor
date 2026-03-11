# v3.5.1 — TRACEABILITY: Structured Observability

Operators can now answer from files alone: Did the agent boot? What did it load? Why did it transition this way?

## What's new

**Append-only event stream** (`logs/events/YYYYMMDD.jsonl`) — every lifecycle event, state transition, and decision carries a `reason_code`. Five layers: sensor, body, mind, governance, world.

**State projections** — `state/ready.json` (mind/body/sensors snapshot), `state/runtime.json` (current cycle/lock/pass), `state/coherence.json` (structural checks).

**Boot telemetry** — 9 mandatory events from `boot.start` to `boot.ready`. If boot fails: `boot.blocked` with specific reason code + `state/ready.json` status `blocked`.

**Cycle telemetry** — Full trace from queue dequeue through LLM call, effects execution, projection, to finalize. Recovery paths are distinguishable from fresh paths.

**CDD v1.1.0** — Coherence-Driven Development design doc: the development method that applies CAP to the development process itself.

## Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
cn doctor   # verify readiness
```

After restarting the daemon, check `state/ready.json` and `logs/events/` for boot trace.

## Full changelog

See [CHANGELOG.md](https://github.com/usurobor/cnos/blob/main/CHANGELOG.md#v351-2026-03-11).
