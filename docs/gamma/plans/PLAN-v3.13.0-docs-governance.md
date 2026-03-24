# PLAN — docs governance v3.13.0

**Branch:** `claude/75-docs-governance-v3.13.0`
**Issue:** #75
**Date:** 2026-03-23 (retroactive — plan created after implementation per self-coherence debt)

---

## Goal

Make cnos documentation governance self-consistent: explicit artifact expectations, single version lineage, feature bundles, frozen snapshots, and a self-coherence review artifact.

## Ordered steps

### Phase 1: Foundation (commits 588495e–a513e64)

1. **Feature bundles + snapshot rules** — create `docs/alpha/3.14.0-62-agent-runtime/`, `docs/alpha/3.12.0-73-runtime-extensions/` with bundle READMEs; move `runtime-extensions/v1.0.6/` into proper directory structure
2. **Version-as-directory** — replace `versions/spec/` flat layout with `v<X.Y.Z>/` directories; each version dir gets a frozen `README.md` manifest
3. **Bundle contract** — tighten bundle README requirements: name canonical, scope snapshots, clarify migration

### Phase 2: CDD pipeline formalization (commits 1e37e98–728d89f)

4. **Bootstrap CDD v1.3.0** — create version directory `docs/gamma/3.13.0-75-cdd/3.13.0/` with stub files (later renamed from v1.3.0 to v3.13.0)
5. **CDD §5 rewrite** — pipeline table with 9 steps (0–8), each with explicit deliverable artifacts and locations; bootstrap-first rule
6. **cnos-aligned versioning** — single version lineage rule in DOCUMENTATION-SYSTEM.md §3; no per-document versions
7. **Branch naming** — CDD §5.0 naming convention: `{agent}/{issue}-{scope}-{version}`; tooling suffix rule

### Phase 3: Self-coherence review (commit dc69e11)

8. **Fix stale §7 references** — RULES.md, RELEASE.md, PLAN.md → actual current locations
9. **Add §7.8** — self-coherence report format and placement rules
10. **Clarify bootstrap scope** — per-bundle, not per-branch
11. **Frozen legacy snapshot rule** — DOCUMENTATION-SYSTEM.md §3: frozen dirs keep historical versions
12. **Create SELF-COHERENCE.md** — first instance of the new artifact format
13. **Fix PR body** — correct branch name, fix test plan wording

### Phase 4: Final convergence (this commit)

14. **Create this plan** (retroactive) — close the plan-artifact gap
15. **Update self-coherence report** — reflect final branch state after all fixes
16. **Re-freeze snapshot** — CDD.md + README match canonical

## Dependencies

- Steps 1–3 must precede 4–7 (bundles and snapshot rules before CDD formalizes them)
- Step 4 must be the first diff that touches `v3.13.0/` (bootstrap-first rule)
- Steps 8–13 address review feedback on 4–7
- Steps 14–16 close remaining self-coherence debt

## Risk boundaries

- **Scope creep:** this branch is governance-only. No code, no runtime changes. All risk is in docs consistency.
- **Frozen snapshot staleness:** every time the canonical CDD.md is updated, the frozen copy must be refreshed. Final freeze happens at step 16.
- **Retroactive plan:** this plan was created after most implementation was done. This is a debt acknowledged in the self-coherence report. Future governance branches of this scope should have a plan before step 4.
