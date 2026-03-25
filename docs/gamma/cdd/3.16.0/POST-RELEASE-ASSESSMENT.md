# Post-Release Assessment — v3.16.0

**Issue closed:** #37 — cn update: end-to-end self-update (CI upload + binary naming + same-version patches)
**PR:** #104 (5 commits, +195/-44, 10 files)
**Assessor:** Claude (implementing agent — noted as limitation)
**Date:** 2026-03-25

---

## 1. Coherence Measurement

### Baseline

v3.15.2 — α A, β A, γ A

v3.15.2 shipped empty Telegram filter (#29), CDD canonical rewrite, review skill hardening. Full CDD pipeline restored after v3.15.0 regression.

### This release

v3.16.0 — α A, β A, γ A-

### Delta

- **α (PATTERN): Held at A.** `release_info` record type and `Update_patch` ADT variant extend the existing update machinery cleanly. `get_latest_release()` replaces grep/sed with `Cn_json` parsing — structural improvement. The `is_hex_sha` validation in `get_latest_release` is a correct structural guard against the GitHub API returning branch names instead of commit SHAs. No new modules or unnecessary abstractions.

- **β (RELATION): Held at A.** All 6 issue ACs met. Code, CI workflow, and binary naming agree. The one gap: AC6 (Pi end-to-end without manual scp) depends on tags being pushed — an operational precondition not enforced by code. Both `run_update` and `self_update_check` handle the new `Update_patch` variant. Version output includes commit hash.

- **γ (EXIT/PROCESS): Regressed from A to A-.** Three review rounds were needed before merge. Round 1 caught 5 findings including a syntax error in `cn_system.ml` and a non-exhaustive match — both D-severity blockers that should have been caught by author pre-flight or build verification. Round 2 caught false patch detection from `target_commitish = "main"` (the root cause was identified in the self-coherence report's known debt section but not fixed). Round 3 caught another cram test (`cli.t`) that wasn't updated alongside `version.t`. The pattern: known debt listed but not addressed before review, and incomplete test surface scan.

### Coherence contract closed?

**Closed.** The gap named in #37 (cn update fully broken — three independent failures) is eliminated:
1. `release.yml` now builds and uploads ARM binaries on tag push
2. Binary names match between `get_platform_binary()` and CI matrix
3. Same-version patches detected via commit hash comparison

What remains related but out of scope:
- Tags v3.14.5–v3.15.2 remain unpushed. `release.yml` triggers on tag push, so no binaries exist for those versions yet.
- #28 (daemon retry limit) — the broader safety net for other API failure modes.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #37 | cn update: end-to-end self-update | feature | converged | **shipped (v3.16.0)** | none |
| #28 | Daemon retry limit / dead-letter | bug | issue spec | not started | **growing** |
| #73 | Runtime Extensions — capability providers | feature | converged (issue spec) | not started | **stale** |
| #65 | Communication — surfaces, transport | feature | converged (issue spec) | not started | **stale** |
| #67 | Network access as CN Shell capability | feature | converged (subsumed by #73) | not started | **stale** |
| #68 | Agent self-diagnostics | feature | converged (issue spec) | not started | growing |
| #64 | P0: agent probes filesystem despite RC | process | bug report | not started | growing |
| #84 | CA mindset reflection requirements | feature | design (issue spec) | not started | growing |
| #79 | Projection surfaces | feature | design (issue spec) | not started | growing |
| #59 | cn doctor — deep validation | feature | partial design | partial impl | low |
| #94 | cn cdd: mechanize CDD invariants | feature | design (issue spec) | not started | growing |
| #100 | Memory as first-class capability | feature | design (issue spec) | not started | growing |
| #96 | Docs taxonomy alignment | process | design (issue spec) | not started | growing |
| #74 | Rethink logs structure (P0) | process | design (issue spec) | not started | growing |
| #101 | Normalize skill corpus | process | design (issue spec) | not started | growing |
| #20 | Eliminate silent failures in daemon | bug | issue spec | not started | growing |
| #43 | No interrupt mechanism | feature | issue spec | not started | growing |

**Changes since v3.15.2 assessment:**
- #37 moved from open to **none** (shipped)
- #73, #65, #67 remain **stale** — now carried across 5 assessment cycles
- All other entries unchanged

**MCI/MCA balance: Freeze MCI**

**Rationale:** 3 issues remain stale (#73, #65, #67) unchanged since v3.14.5 epoch. 12 issues at growing lag. The stale backlog has not been addressed. The freeze from v3.15.0 must hold. Per the v3.15.2 assessment, #28 is the most urgent operational item — a runtime bug that can wedge the daemon.

---

## 3. Process Learning

### What went wrong

1. **Known debt not fixed before review.** The self-coherence report explicitly listed `target_commitish` may be a branch name as known debt. This was the root cause of the Round 2 CI failure (false patch detection). Known debt that affects correctness should be fixed before requesting review, not documented and left.

2. **Three review rounds for a code PR.** Target is ≤2. Round 1 found a syntax error and non-exhaustive match — both would have been caught by `dune build`. Round 2 found the `target_commitish` root cause. Round 3 found `cli.t` not updated alongside `version.t`. Each round required a fix commit, rebase, and re-review.

3. **Incomplete test surface scan.** When `version.t` was updated from exact match to prefix match, `cli.t` (which has the same `--version` check) was not updated. Both cram tests exercise `--version` output but only one was found and fixed in the initial implementation.

4. **No build verification.** No OCaml toolchain available — the syntax error in `cn_system.ml` would have been caught by `dune build`. This is environmental, not a process failure, but it means CI is the first build check.

### What went right

1. **Root cause analysis in review.** Round 2 review didn't just identify the symptom (cram tests polluted) — it traced to the root cause (`target_commitish = "main"` → false patch detection) and proposed a correct fix (validate as hex SHA before comparison).

2. **Clean ADT extension.** `Update_patch` was added to the existing `update_info` type and handled in all three consumers (`check_for_update`, `run_update`, `self_update_check`) plus the daemon FSM. The pattern of extending an ADT and letting the compiler find all match sites worked correctly — except the compiler wasn't run before review.

3. **Assessment commitment honored.** v3.15.2 assessment committed #37 as next MCA via §3.2 (operational debt). This cycle honored that commitment.

### Skill patches needed

**One patch recommended:** The review skill or author pre-flight should include a step: "For every test file modified, search for other test files that exercise the same code path and verify they are also updated." This would have caught `cli.t` in Round 1 instead of Round 3.

**Status:** Not committed in this session — this is a judgment call on whether the review skill should grow another check or whether this is covered by existing §2.2 (cross-reference validation). Deferred to next cycle.

---

## 4. Review Quality

**PRs this cycle:** 1 (PR #104)
**Avg review rounds:** 3.0 (target: ≤2 for code PRs) — **exceeded**
**Superseded PRs:** 0 (target: 0) — **passed**
**Finding breakdown:** 5 mechanical / 3 judgment / 8 total
**Mechanical ratio:** 63% (threshold: 20%) — **exceeded, action required**
**Action:** The mechanical ratio is high. However, 3 of the 5 mechanical findings (syntax error, non-exhaustive match, missing `end`) would have been caught by a compiler. The remaining 2 (cli.t not updated, release.yml trigger pattern) are genuine process gaps. Filed as process learning above.

**Finding detail:**

| # | Finding | Round | Type | Severity |
|---|---------|-------|------|----------|
| 1 | Syntax error in `cn_system.ml` L429 — stale `end` | R1 | mechanical | D |
| 2 | Non-exhaustive match: `Update_patch` missing from daemon FSM | R1 | mechanical | D |
| 2b | Same gap in `cn_maintenance.ml` | R1 | mechanical | D |
| 3 | `release.yml` triggers on `v*` but project uses bare version tags | R1 | judgment | D |
| 4 | `target_commitish = "main"` causes false patch detection | R2 | judgment | D |
| 5 | Self-update triggers during cram tests (consequence of #4) | R2 | judgment | D |
| 6 | `cnos_commit` expect test hardcodes "unknown" | R2 | mechanical | D |
| 7 | `cli.t` version check uses exact match, not prefix match | R3 | mechanical | D |

**Assessment:** Review quality is below target. Three rounds instead of two. Mechanical ratio at 63% is well above the 20% threshold, driven primarily by the absence of a build step before review. The judgment findings (#4, #5) were substantive — the `target_commitish` root cause required real analysis. The improvement from v3.15.0 (0 reviews) holds, but this cycle regressed from v3.15.2 (2 rounds, 33% mechanical).

---

## 5. Next Move

**Next MCA:** #28 — Daemon retries failed triggers forever — no retry limit or dead-letter
**Owner:** to be assigned
**Branch:** pending creation (must follow CDD §1.4)
**First AC:** Failed API calls have a retry limit and stop after N attempts
**MCI frozen until shipped?** Yes — stale backlog still unaddressed.

**Rationale:** §0 selection function: §3.1 (P0 crash) — no active crash, skip. §3.2 (operational debt) — #28 is an operational bug that can wedge the daemon in an infinite retry loop. With #37 shipped, the system can now self-update, so #28's fix can be delivered automatically. The v3.15.2 assessment identified #28 as next after #37. §3.3 (assessment default) applies.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - Post-release assessment written (this document)
  - CHANGELOG TSC entry needed (deferred — no tag/release yet)
- Deferred outputs committed: yes
  - #28 as next MCA (owner/branch/AC above)
  - Skill patch consideration for test-surface scan (deferred to next cycle)
  - MCI freeze maintained

**Immediate fixes** (executed in this session):
- None beyond this assessment. The three review-round findings were all fixed during the PR cycle itself.
