# CN Logging Architecture

**Status:** Superseded by [`TRACEABILITY.md`](TRACEABILITY.md)
**Date:** 2026-02-11
**Author:** usurobor (aka Axiom)
**Contributors:** Sigma

---

## Status

This document is historical.

The current observability architecture is defined in:

- [`TRACEABILITY.md`](TRACEABILITY.md) — append-only event stream, readiness/runtime/coherence projections, transition reason codes, and operator-facing traceability
- [`AGENT-RUNTIME.md`](AGENT-RUNTIME.md) — runtime lifecycle and execution model

---

## What remains true from this document

The following are still valid:

1. **IO pairs remain authoritative for deliberation**
   - `logs/input/{trigger}.md`
   - `logs/output/{trigger}.md`

2. **Receipts/artifacts remain authoritative for typed capability execution**
   - `state/receipts/{trigger}.json`
   - `state/artifacts/{trigger}/...`

3. **System stdout may still be used as a human-readable mirror**
   - but it is not the primary operational trace

---

## What changed

This document previously described an ad hoc split between:
- IO-pair archives
- optional run directories
- system stdout
- a removed hub JSONL log

That model is now replaced by the structured observability system in `TRACEABILITY.md`:

- **events** — append-only lifecycle log
- **state projections** — `state/ready.json`, `state/runtime.json`, `state/coherence.json`
- **evidence artifacts** — IO pairs, receipts, artifacts

`Cn_hub.log_action` is no longer a conceptual no-op; runtime trace emission now belongs to the explicit event/projection architecture.

---

## Historical Notes

The old model's core insight still holds:

> The agent's work must remain auditable without reading git history.

What changed is the mechanism:
- previous model: mostly IO pairs + cron stdout
- current model: IO pairs + receipts + structured lifecycle events + readiness projections

---

## Related

- [`TRACEABILITY.md`](TRACEABILITY.md) — current observability architecture
- [`AGENT-RUNTIME.md`](AGENT-RUNTIME.md) — runtime execution model
- [`SECURITY-MODEL.md`](SECURITY-MODEL.md) — auditability as part of the security boundary
