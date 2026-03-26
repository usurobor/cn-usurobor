# v3.18.0 Self-Coherence — Package System Substrate (AC3 + AC4)

**Issue:** #113
**Active skills:** eng/ocaml, eng/testing, eng/coding
**Review round:** 2

## AC Status

| AC | Description | Status | Evidence |
|----|-------------|--------|----------|
| AC3 | Restore installs full package content | met | Remote restore uses `copy_tree` — same as local path. No hardcoded category list. |
| AC4 | Third-party handling explicit | met | `lockfile_for_manifest` returns `Result`, rejects non-`cnos.*` with error message. |

## Triad Scores

| Dimension | Score | Notes |
|-----------|-------|-------|
| α (structural) | B+ | Both restore paths now use `copy_tree`; Result type enforced at boundary. Manifest skill paths corrected. |
| β (alignment) | B | PR claims narrowed to AC3+AC4. Deferred ACs explicitly listed. Still partial on AC8. |
| γ (process) | B- | 2 review rounds needed. Round 1 had unused variable (build fail), tautological logic, overclaimed scope, stale manifest. All fixed in round 2. |

## Review Round 1 Findings — Resolution

| Finding | Reviewer | Severity | Resolution |
|---------|----------|----------|------------|
| F1: unused `config` in `effective_permissions` | Sigma | D | Fixed: `config.exec_enabled` now gates all permissions. Added test for exec_disabled → empty. |
| F2: stale skill paths in manifest | Sigma | D | Fixed: cnos.core updated to cdd/*, removed moved skills. cnos.eng added missing eng/* skills. |
| F3: indentation in reconcile_packages | Sigma | C | Fixed: Ok arm body aligned to 6-space indent. |
| F4: test references deleted cnos.pm | Sigma | C | Fixed: replaced with cnos.eng in subdir pattern test. |
| F6: tautological network logic | Sigma | B | Fixed: `exec_enabled=false` → empty permissions. Network checked against `v` not `ext_perms`. |
| F1: local/remote restore diverge | Claude | D | Fixed: remote path now uses `copy_tree src_root pkg_dir` — same as local. No hardcoded list. |
| F2: profiles in restore but not source_decl | Claude | D | Fixed: removed hardcoded list entirely. `copy_tree` copies whatever exists. |
| F3: test simulates restore_one | Claude | C | Fixed: tests now prove `copy_tree` (shared primitive) with honest claims. |
| F5: scope ambiguity | Claude | C | Fixed: README/SELF-COHERENCE narrowed to AC3+AC4. Deferred ACs listed. |

## Active Skill Compliance

### eng/ocaml
- **§3.1 type safety:** `lockfile_for_manifest` returns `(lockfile, string) result` — callers forced to handle both arms
- **§3.3 Result types:** Both cn_system.ml callers pattern-match on Ok/Error
- **§2.6 no partial functions:** No `List.hd`, `Option.get`, all matches exhaustive
- **§3.5 build-before-push:** No toolchain available in this environment. Audit: all type changes and call sites reviewed manually. **Known gap.**

### eng/testing
- **§3.1 invariant-first:** Each test names invariant (I1–I5) in comment and test name
- **§3.6 negative space:** Third-party rejection (2 tests), no-empty-source, exec_disabled → empty
- **§3.2 match proof to claim:** Tests prove `copy_tree` (shared primitive), not a simulated list
- **§2.12 derivation:** Content preservation test proves actual copy, not coincidental match

### eng/coding
- **Minimal complexity:** Removed 5-category hardcoded list, replaced with single `copy_tree` call
- **No premature abstraction:** Third-party rejection is filter + error, not a registry stub
- **Pattern match:** `lockfile_for_manifest` uses pattern match on Result at all call sites

## Changes

| File | Change |
|------|--------|
| `src/cmd/cn_deps.ml` | `restore_one` remote path uses `copy_tree` (was hardcoded 5-list); `lockfile_for_manifest` returns Result |
| `src/cmd/cn_system.ml` | Both callers handle Result; indentation fixed |
| `src/cmd/cn_extension.ml` | `effective_permissions` uses `config.exec_enabled` as gate; removed tautological network check |
| `packages/cnos.core/cn.package.json` | Skill paths updated for post-reorg tree; extensions preserved |
| `packages/cnos.eng/cn.package.json` | Added missing eng/* skills (documenting, follow-up, skill, architecture-evolution, etc.) |
| `test/cmd/cn_deps_test.ml` | 7 tests: copy_tree structure+content, third-party rejection, first-party valid, negative space |
| `test/cmd/cn_extension_test.ml` | Fixed tests for exec_enabled config; added exec_disabled test |
| `test/cmd/dune` | Added cn_deps_test library stanza |
