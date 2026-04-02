# v3.29.0 — Remove Hardcoded Paths

Issue: #146
Branch: claude/execute-issue-146-cdd-O6Rl3
Mode: MCA
Active skills: ocaml, coding, testing

## Snapshot Manifest

- README.md — this file
- SELF-COHERENCE.md — triadic self-check

## Deliverables

- Derive `bin_path` from runtime self-location with `$CN_BIN` override
- Derive `repo` from `cn.json` metadata with `$CN_REPO` override
- Remove all `/usr/local/bin/cn` literals from src/
- Remove hardcoded `"usurobor/cnos"` from cn_agent.ml
- Tests for resolution chain

## CDD Trace

| Step | Status | Evidence |
|------|--------|----------|
| 0 Observe | ✅ | CHANGELOG TSC, v3.28.0 assessment |
| 1 Select | ✅ | #146 |
| 2 Branch | ✅ | `claude/execute-issue-146-cdd-O6Rl3` |
| 3 Bootstrap | ✅ | `docs/gamma/cdd/3.29.0/README.md` |
| 4 Gap | ✅ | Skills: ocaml, coding, testing |
| 5 Mode | ✅ | MCA, L6 |
| 6 Artifacts | ✅ | Code + 7 tests + SELF-COHERENCE.md |
| 7 Self-coherence | ✅ | α 4/4, β 4/4, γ 4/4 |
| 8 Review | ✅ | 2 rounds, 5 findings R1 (1B/4C), all addressed R2. Approved. |
| 9 Gate | ✅ | PR #147 merged, 412414e on main |
| 10 Release | ✅ | 3.29.0 tagged (c96cc1b), CI 4/4 green, binaries published |
| 11 Deploy | ✅ | Pi: 3.28.0 → 3.29.0, `cn deps restore` (2 pkgs, 32 skills), daemon active |
| 12 Validate | ✅ | Version consistency confirmed (binary, runtime.md, tag). Symlink resolves. No rejection loop. Issue #148 filed for pre-existing version drift bug found during validation. |
| 13 Close | ✅ | CDD trace complete |

## Validation Results

| Check | Result |
|-------|--------|
| Binary version | 3.29.0 (c96cc1b) ✓ |
| runtime.md cn_version | 3.29.0 ✓ |
| Tag | 3.29.0 ✓ |
| Symlink resolves | `/usr/local/bin/cn` → `/home/cn/bin/cn` ✓ |
| Self-update | "Already up to date" ✓ |
| Rejection loop (#144) | Outbox empty ✓ |
| Deps restored | 2 packages, 32 skills ✓ |
| Daemon | Active, PID running ✓ |

## Issues Found During Validation

- **#148**: `check_binary_version_drift` parses GNU coreutils output instead of `cn --version`, causing spurious re-exec and daemon crashes. Pre-existing, not introduced by this release.
