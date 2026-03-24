# PR: docs governance v3.13.0 — feature bundles, version directories, cnos-aligned versioning

**Branch:** `claude/75-docs-governance-v3.13.0`
**Base:** `main`
**Date:** 2026-03-23

---

## Summary

- CDD v3.13.0: §5 rewrite — branch rule (all dev on dedicated branch), per-step deliverable artifacts table (9 steps, each with explicit artifacts and locations), bootstrap-first rule (first diff = version dir with stubs)
- DOCUMENTATION-SYSTEM.md v3.13.0: §3 rewrite — single version lineage rule (all docs use cnos release versions, no independent per-document lineages), legacy version migration path
- docs/README.md v3.13.0: start-here paths by persona, two-dimensional reading model (triad × feature bundle), anchor doc index, directory map
- CDD feature bundle created: `docs/gamma/3.13.0-75-cdd/` with `v3.13.0/` frozen snapshot
- Two alpha feature bundles: `agent-runtime/` and `runtime-extensions/` with bundle READMEs
- `runtime-extensions/v1.0.6/` snapshot directory with frozen SPEC.md and manifest README
- Fix: AGENT-RUNTIME.md internal inconsistencies (packed_context, max_passes budgets table)
- Fix: packages/ sync drift from src/agent/ (#58)

## Coherence Contract

**Gap:** Three incoherences:
1. DOCUMENTATION-SYSTEM.md v1 said "canonical docs never versioned" but docs/alpha/ had version-stamped files. No bundle structure, no snapshot placement rules, no navigation.
2. CDD §5 listed pipeline steps as one-liners with no artifact expectations. No branch rule. No bootstrap requirement.
3. Documents carried independent version lineages (CDD 1.2.0, DOCUMENTATION-SYSTEM 2.0.0, THESIS 1.0.0, etc.) — impossible to answer "what does cnos vX.Y.Z look like?" with one version number.

**Mode:** MCA + MCI — fix the governance docs (MCI) and restructure the repo to match (MCA).

**Scope:** Documentation governance layer + development method.

**Expected triadic effect:**
- α: one version lineage, unambiguous artifact expectations per pipeline step, nine document classes with placement rules
- β: all navigation surfaces, bundle READMEs, and governance docs agree on structure and versioning
- γ: new features → bundles, new versions → `vX.Y.Z/` frozen snapshots, all versions are cnos versions

## Known Coherence Debt

| Item | Severity | Note |
|------|----------|------|
| Existing docs with legacy versions (THESIS 1.0.0, COHERENCE-SYSTEM 1.0, etc.) | B | Will be re-versioned when next updated per §3 legacy rule |
| `agent-runtime/` has no `vX.Y.Z/` snapshot yet | B | No frozen snapshot — not a violation |
| No CI enforcement of governance rules | C | DOCUMENTATION-SYSTEM.md §7 describes CI validation; not yet implemented |

## Test plan

- [x] Verify CDD §5 table enumerates deliverables for all 9 steps
- [x] Verify DOCUMENTATION-SYSTEM.md §3 establishes single version lineage
- [x] Verify all new/updated docs carry version 3.13.0 (frozen legacy snapshots retain historical versions per DOCUMENTATION-SYSTEM.md §3)
- [x] Verify version directory renamed from v1.3.0 to v3.13.0
- [x] Verify bundle READMEs and snapshot manifests are consistent

https://claude.ai/code/session_01UaEk6WhkDKvW2U6mfmiw59
