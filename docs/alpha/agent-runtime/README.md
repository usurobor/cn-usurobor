# Agent Runtime — Feature Bundle

The native cnos agent runtime: CN Shell, typed ops, N-pass orchestration, receipts, and the runtime contract.

---

## Canonical Spec

**[AGENT-RUNTIME.md](../AGENT-RUNTIME.md)** (v3.8.0) — the single source of truth for the agent runtime.

---

## Document Map

| Document | Class | Description |
|----------|-------|-------------|
| [AGENT-RUNTIME.md](../AGENT-RUNTIME.md) | Canonical spec | Full runtime spec — shell, ops, orchestration, receipts |
| [RUNTIME-CONTRACT-v3.10.0.md](../RUNTIME-CONTRACT-v3.10.0.md) | Feature-scoped design | Wake-up self-model contract: self_model + workspace + capabilities |
| [N-PASS-BIND-v3.8.0.md](../N-PASS-BIND-v3.8.0.md) | Feature-scoped design | Generalized N-pass bind loop replacing hardcoded two-pass |
| [SYSCALL-SURFACE-v3.8.0.md](../SYSCALL-SURFACE-v3.8.0.md) | Feature-scoped design | Syscall surface redesign for v3.8.0 |
| [SCHEDULER-v3.7.0.md](../SCHEDULER-v3.7.0.md) | Feature-scoped design | Scheduler design for v3.7.0 |

### Migration target

When the legacy design docs move into this bundle, the structure becomes:

```
agent-runtime/
├── README.md
├── v3.7.0/
│   └── DESIGN.md            ← SCHEDULER-v3.7.0.md
├── v3.8.0/
│   ├── DESIGN.md            ← N-PASS-BIND-v3.8.0.md
│   └── SYSCALL-SURFACE.md   ← SYSCALL-SURFACE-v3.8.0.md
└── v3.10.0/
    └── DESIGN.md            ← RUNTIME-CONTRACT-v3.10.0.md
```

## Related Plans

| Plan | Scope |
|------|-------|
| [PLAN-v3.8.0-n-pass-bind.md](../../gamma/plans/PLAN-v3.8.0-n-pass-bind.md) | N-pass bind loop implementation plan |
| [PLAN-v3.10.0-runtime-contract.md](../../gamma/plans/PLAN-v3.10.0-runtime-contract.md) | Runtime contract implementation plan |

---

## Reading Order

1. **[AGENT-RUNTIME.md](../AGENT-RUNTIME.md)** — start here for the full runtime model
2. **[N-PASS-BIND-v3.8.0.md](../N-PASS-BIND-v3.8.0.md)** — how the orchestration loop works
3. **[RUNTIME-CONTRACT-v3.10.0.md](../RUNTIME-CONTRACT-v3.10.0.md)** — the wake-up contract design
4. **[SYSCALL-SURFACE-v3.8.0.md](../SYSCALL-SURFACE-v3.8.0.md)** — the op surface

---

## Version History

The canonical spec (AGENT-RUNTIME.md) evolves in place. Feature-scoped design docs capture the design narrative for each major iteration. See patch notes in AGENT-RUNTIME.md header for the full changelog.

| Version | Highlights |
|---------|-----------|
| v3.10.0 | Runtime contract: self_model + workspace + capabilities at wake |
| v3.8.0 | N-pass bind loop, processing indicators, syscall surface redesign |
| v3.7.0 | Scheduler, agent scheduler integration |
