# v3.18.0 — Package System Substrate (AC3 + AC4)

**Issue:** #113 — Implement the Git-native package system substrate
**Branch:** `claude/3.18.0-113-package-system`
**Mode:** MCA
**Base:** v3.17.0
**Design:** `docs/beta/architecture/PACKAGE-SYSTEM.md`

## Gap

cnos has the right package-system spine but not a complete substrate. `restore_one` copies only doctrine/mindsets/skills via a hardcoded list, diverging from the local first-party path which copies the full package tree. Third-party lock entries silently produce empty source/subdir with wrong-repo rev.

## Active skills (CDD §4.4)

Hard generation constraints:

1. **eng/ocaml** — §3.1 type safety, §3.3 Result types, §2.6 no partial functions, §3.5 build-before-push
2. **eng/testing** — §3.1 start from invariants, §3.6 negative space mandatory, §3.2 match proof to claim
3. **eng/coding** — prefer pattern match, no premature abstraction, minimal complexity

All other skills are reference only.

## Scope

This PR narrows to **AC3 + AC4 only** (Steps 1-2 of #113). The remaining ACs (integrity, doctor depth, Runtime Contract truth) are deferred to future PRs.

| Step | Description | Status |
|------|-------------|--------|
| 1 | Path-consistent restore — remote path uses copy_tree like local path | done |
| 2 | Honest third-party handling — explicitly reject non-first-party lock entries | done |
| 7 | Build/check/clean for extensions (cherry-picked from #112) | done |
| — | Fix stale skill paths in package manifests (from skill reorg on main) | done |
| — | Fix effective_permissions to actually intersect with runtime config | done |

## Deliverables

| Artifact | Status |
|----------|--------|
| README.md (this file) | done |
| SELF-COHERENCE.md | done |
| Code: cn_deps.ml restore_one — path-consistent copy_tree | done |
| Code: cn_deps.ml lockfile_for_manifest — Result type, third-party rejection | done |
| Code: cn_extension.ml effective_permissions — exec_enabled gate | done |
| Code: cn_system.ml — callers handle Result | done |
| Fix: cnos.core manifest — skill paths match post-reorg tree | done |
| Fix: cnos.eng manifest — add missing eng/* skills | done |
| Tests: cn_deps_test.ml (7 tests, invariant-first) | done |
| Tests: cn_extension_test.ml exec_disabled test added | done |

## ACs addressed (from #113)

| AC | Description | Status |
|----|-------------|--------|
| AC3 | Restore installs full package content | met |
| AC4 | Third-party handling explicit | met |
| AC1 | Git-native publication/retrieval | unchanged (pre-existing) |
| AC5 | Integrity generated/verified | deferred |
| AC6 | Doctor validates package truth | deferred |
| AC7 | Runtime Contract reflects truth | deferred |
| AC8 | Extensions/bundles sit above | partial (cherry-pick) |
