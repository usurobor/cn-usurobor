# PR: docs governance v2.0.0 — feature bundles, version directories, navigation

**Branch:** `claude/cdd-executable-skill-PfdYZ`
**Base:** `main`
**Date:** 2026-03-23

---

## Summary

- DOCUMENTATION-SYSTEM.md v2.0.0: nine document classes, feature bundle structure, bundle-local `vX.Y.Z/` version directories with freeze semantics (MUST NOT modify), required snapshot README manifests, CI validation rules, legacy filename migration path
- docs/README.md v2.0.0: start-here paths by persona, two-dimensional reading model (triad × feature bundle), anchor doc index, directory map
- Two feature bundles created: `agent-runtime/` and `runtime-extensions/` with bundle READMEs naming canonical specs
- `runtime-extensions/v1.0.6/` snapshot directory with frozen SPEC.md and manifest README
- Fix: AGENT-RUNTIME.md internal inconsistencies (packed_context, max_passes budgets table)
- Fix: packages/ sync drift from src/agent/ (#58)

## Coherence Contract

**Gap:** DOCUMENTATION-SYSTEM.md v1 said "canonical docs never versioned" but docs/alpha/ had version-stamped files. No feature bundle structure, no snapshot placement rules, no navigation in docs/README.md.

**Mode:** MCI — repo structure is correct, governance docs must catch up.

**Scope:** Documentation governance layer.

**Expected triadic effect:**
- α: document taxonomy stabilized — nine classes with unambiguous placement rules
- β: navigation surfaces (README, bundle README, directory map) aligned with governance law
- γ: clear evolution path — new features get bundles, new versions get `vX.Y.Z/` frozen snapshots

## AC Coverage (Issue #75)

| # | AC | Status | Evidence |
|---|-----|--------|----------|
| 1 | DOCUMENTATION-SYSTEM.md v2.0.0 with bundles, snapshots, classes, placement, migration | **Met** | `3570593` + `a602434` + `51f5adf` + `c57fe10` + `5186778` |
| 2 | docs/README.md v2.0.0 with reading paths, bundle explanation, anchor index | **Met** | `3570593` + `f7111dc` |
| 3 | docs/alpha/agent-runtime/ exists as feature bundle with README.md | **Met** | `3570593` |
| 4 | docs/alpha/runtime-extensions/ has README.md | **Met** | `3570593` + `f7111dc` |
| 5 | No contradictions between meta-doc and repo structure | **Met** | All 5 governance files verified |
| 6 | Legacy versioned filenames documented with migration path | **Met** | `3570593` — §6 migration path table |

## Triadic Score

| Axis | Score | Note |
|------|-------|------|
| α Pattern | A | Governance spec internally consistent. Nine classes, RFC 2119 freeze semantics, unambiguous placement. |
| β Relation | A | All navigation surfaces agree with law. Bundle README, directory map, snapshot manifest enumerate same files. |
| γ Exit | A | New features → bundles, new versions → `vX.Y.Z/` frozen snapshots, corrections → new version dir or superseding note. |
| **C_Σ** | **A** | |

## Known Coherence Debt

| Item | Severity | Note |
|------|----------|------|
| `agent-runtime/` has no `vX.Y.Z/` snapshot yet | B | No frozen snapshot taken — not a violation, governance only requires dirs when snapshots exist |
| `v1.0.6/SPEC.md` status says "Draft — converged" | B | Minor wording tension with freeze semantics; "converged" qualifier is accurate |
| No CI enforcement of governance rules | C | DOCUMENTATION-SYSTEM.md §7 describes CI validation; no implementation yet. Design-ahead, tracked. |

## Test plan

- [x] Verify all 5 governance files are internally consistent
- [x] Verify bundle README document maps enumerate all files including snapshot manifests
- [x] Verify top-level directory map matches actual tree structure
- [x] Verify freeze semantics stated in DOCUMENTATION-SYSTEM.md, restated in v1.0.6/README.md

https://claude.ai/code/session_01UaEk6WhkDKvW2U6mfmiw59
