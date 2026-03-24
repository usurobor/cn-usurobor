# Agent Runtime — Feature Bundle

The native cnos agent runtime: CN Shell, typed ops, N-pass orchestration, receipts, and the runtime contract.

---

## Canonical Spec

**[AGENT-RUNTIME.md](./AGENT-RUNTIME.md)** (v3.8.0) — the single source of truth for the agent runtime.

---

## Document Map

| Document | Class | Description |
|----------|-------|-------------|
| [AGENT-RUNTIME.md](./AGENT-RUNTIME.md) | Canonical spec | Full runtime spec — shell, ops, orchestration, receipts |
| [CAA.md](./CAA.md) | Canonical spec | Coherent agent architecture — structural definition, invariants, wake-up strata |
| [RUNTIME-CONTRACT-v2.md](./RUNTIME-CONTRACT-v2.md) | Canonical spec | Runtime contract v2 — vertical self-model (4 layers, 5 zone types) |
| [3.10.0/DESIGN.md](3.10.0/DESIGN.md) | Feature-scoped design | Wake-up self-model contract: self_model + workspace + capabilities |
| [3.8.0/N-PASS-BIND.md](3.8.0/N-PASS-BIND.md) | Feature-scoped design | Generalized N-pass bind loop replacing hardcoded two-pass |
| [3.8.0/SYSCALL-SURFACE.md](3.8.0/SYSCALL-SURFACE.md) | Feature-scoped design | Syscall surface redesign for v3.8.0 |
| [3.7.0/DESIGN.md](3.7.0/DESIGN.md) | Feature-scoped design | Scheduler design for v3.7.0 |

## Related Plans

| Plan | Scope |
|------|-------|
| [PLAN-v3.7.0-scheduler.md](../../gamma/plans/PLAN-v3.7.0-scheduler.md) | Scheduler unification implementation plan |
| [PLAN-v3.8.0-n-pass-bind.md](../../gamma/plans/PLAN-v3.8.0-n-pass-bind.md) | N-pass bind loop implementation plan |
| [PLAN-v3.8.0-syscall-surface.md](../../gamma/plans/PLAN-v3.8.0-syscall-surface.md) | Syscall surface coherence implementation plan |
| [PLAN-v3.10.0-runtime-contract.md](../../gamma/plans/PLAN-v3.10.0-runtime-contract.md) | Runtime contract implementation plan |

---

## Reading Order

1. **[AGENT-RUNTIME.md](./AGENT-RUNTIME.md)** — start here for the full runtime model
2. **[3.8.0/N-PASS-BIND.md](3.8.0/N-PASS-BIND.md)** — how the orchestration loop works
3. **[3.10.0/DESIGN.md](3.10.0/DESIGN.md)** — the wake-up contract design
4. **[3.8.0/SYSCALL-SURFACE.md](3.8.0/SYSCALL-SURFACE.md)** — the op surface

---

## Version History

The canonical spec (AGENT-RUNTIME.md) evolves in place. Feature-scoped design docs capture the design narrative for each major iteration. See patch notes in AGENT-RUNTIME.md header for the full changelog.

| Version | Directory | Highlights |
|---------|-----------|-----------|
| v3.14.0 | [3.14.0/](3.14.0/) | Runtime Contract v2: vertical self-model (4 layers, 5 zone types) |
| v3.10.0 | [3.10.0/](3.10.0/) | Runtime contract: self_model + workspace + capabilities at wake |
| v3.8.0 | [3.8.0/](3.8.0/) | N-pass bind loop, processing indicators, syscall surface redesign |
| v3.7.0 | [3.7.0/](3.7.0/) | Scheduler unification: one loop, two schedulers |
