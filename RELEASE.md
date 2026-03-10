# v3.5.0 — Unified Package Model + CAA + FOUNDATIONS

Everything cognitive is now a package. Doctrine, mindsets, and skills ship as versioned packages with role profiles. The doctrinal capstone — from first principle to runtime — is complete.

## What's new

**3 cognitive packages:**

| Package | Contents |
|---------|----------|
| `cnos.core` | Doctrine (FOUNDATIONS, CAP, CBP, CA-Conduct, COHERENCE, AGENT-OPS) + mindsets (10) + agent/ops/meta skills |
| `cnos.eng` | Engineering skills (coding, design, functional, OCaml, RCA, review, ship, testing, tool-writing, UX-CLI) |
| `cnos.pm` | PM skills (follow-up, issue, ship) |

**Role profiles:** `profiles/engineer.json`, `profiles/pm.json` — select which packages an agent loads.

**Two-layer resolution:** Installed packages → hub-local overrides. Simpler than v3.4.0's three-layer model. Same guarantees: local-only wake-up, deterministic context, fail-fast on missing substrate.

**CAA v1.0.0** — Coherent Agent Architecture: structural definition of what a coherent agent is, 7 invariants, failure mode table, wake-up strata.

**FOUNDATIONS.md** — Doctrinal capstone: first principle (FEP → CAP) through four doctrinal layers to runtime grammar. The "why" behind every design decision in cnos.

## Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
cn setup   # materializes packages in existing hubs
```

## Full changelog

See [CHANGELOG.md](https://github.com/usurobor/cnos/blob/main/CHANGELOG.md#v350-2026-03-10) for details.
