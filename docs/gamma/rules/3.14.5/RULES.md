# Project Rules — cnos

Non-negotiable rules for cnos development.

---

## OCaml Only

**No JavaScript. Native OCaml only.**

All cn tools are written in OCaml, compiled to native binaries via dune.

No Node.js, no Melange, no npm. Do not add JS. Do not accept JS PRs.

---

## Merge Governance

- **No self-merge**: Engineer writes → PM merges. PM writes → Engineer/owner merges.
- **Only creator deletes branch**: Reviewer returns branches, never deletes.
- **Always rebase before review**: Reviewer's time > your time.

---

## Agent Purity

- **Agent = brain**: Makes decisions, writes plans.
- **cn = body**: Executes effects (git, network, file I/O).
- Agent never executes actions directly — always through cn.

---

## Applies To

- **Sigma** (Engineer)
- **Pi** (PM)

---

*Last updated: 2026-02-06*
