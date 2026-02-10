# Project Rules — cnos

Non-negotiable rules for cnos development.

---

## OCaml Only

**No hand-written JavaScript.**

All cn tools must be written in OCaml, compiled via Melange to JS for runtime.

Existing JS code is being removed. Do not add new JS. Do not accept JS PRs.

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
