# Post-Release Assessment — v3.15.2

**Issue closed:** #29 — Empty Telegram messages cause Claude API 400 — no content validation
**PR:** #103 (2 commits, +57/-2, 5 files)
**Assessor:** Claude (same agent that implemented — noted as limitation)
**Date:** 2026-03-25

---

## 1. Coherence Measurement

### Baseline

v3.15.1 — α A, β A, γ A-

v3.15.1 fixed #22 review blockers: re-exec after binary update, stamp-versions.sh, cn build --check, unified truth read. Process: reviewed before merge.

### This release

v3.15.2 — α A, β A, γ A

### Delta

- **α (PATTERN): Held at A.** The empty-content filter in `drain_tg` is structurally symmetric with the existing `rejected_user` skip pattern: trace event → advance offset → persist → continue drain. No new abstraction, no new type, no structural churn. The CDD rewrite and review skill additions are doc-only and don't change runtime structure.

- **β (RELATION): Held at A.** Both issue ACs met. The fix is at the correct layer (runtime, not parser). Two independent reviews confirmed: AC table, named doc coverage, diff findings all aligned. The one weakness: test evidence stops at the predicate level, not the integration level. Both reviewers accepted this as known debt given the daemon loop isn't unit-testable.

- **γ (EXIT/PROCESS): Improved from A- to A.** Full CDD pipeline followed for the first time since v3.14.7: §0 observation → branch pre-flight → bootstrap → gap → mode → artifacts → self-coherence → two independent reviews → convergence → merge. Author pre-flight (§8.5) was initially skipped but caught and corrected before merge. Two review rounds (one caught the rebase need, the second verified correctness). This is the process discipline that v3.15.0 lacked.

### Coherence contract closed?

**Closed.** The gap named in #29 (empty Telegram messages → Claude API 400 → infinite retry) is eliminated. The offset advances past filtered messages. The trace event makes the filtering visible to operators.

What remains related but out of scope:
- #28 (daemon retry limit) — the broader safety net. This fix removes one trigger class but doesn't add retry limits for other 400 causes.

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #29 | Empty Telegram filter | feature | converged | **shipped (v3.15.2)** | none |
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

**Changes since v3.15.0 assessment:**
- #29 moved from open to **none** (shipped)
- #101 is a **new entry** at growing lag
- #73, #65, #67 remain **stale** — now carried across 4 assessment cycles
- #28 elevated to **growing** — directly related to #29, identified as next operational debt

**MCI/MCA balance: Freeze MCI**

**Rationale:** 3 issues remain stale (#73, #65, #67) unchanged since the v3.14.5 epoch. 10 issues at growing lag. The stale backlog has not been addressed. The freeze from v3.15.0 must hold. However, #28 is the most urgent operational item — a runtime bug that can still wedge the daemon. Per §0.6, operational infrastructure debt overrides the normal MCI freeze priority.

---

## 3. Process Learning

### What went wrong

1. **Author pre-flight skipped on first pass.** §8.5 was not executed before the initial PR creation. The reviewer caught this. The pre-flight was performed retroactively and the PR updated. The fix was procedural, not structural, but it means the first review round was partially wasted on process compliance rather than code quality.

2. **Rebase complexity.** Main had diverged significantly (history rewrite, 1400+ commits). The initial `git rebase` hit conflicts across dozens of unrelated files. Required aborting and using cherry-pick onto fresh main. This is a consequence of the repo's force-push history — not a process failure per se, but the rebase took 3 attempts before landing cleanly.

3. **Self-review.** The implementing agent wrote the post-release assessment. CDD doesn't require a different assessor, but the v3.15.0 assessment noted "independent review, not the implementing agent" as better practice. This assessment may be less critical than an independent one would be.

### What went right

1. **Two independent reviews.** Both converged on approve. The first caught the rebase requirement (D-level mechanical finding). The second verified AC coverage, named doc coverage, and scored α A / β A- / γ A-. No design iteration needed — the fix was right on the first pass.

2. **Correct filter placement.** The design decision to filter in `drain_tg` (not `parse_update`) was well-reasoned and caught a real trap: filtering in the parser would have created an infinite poll loop because the offset would never advance past filtered messages. Both reviewers confirmed this rationale.

3. **Pattern reuse.** The fix mirrors the existing `rejected_user` skip exactly — same structure, same trace convention, same offset logic. No new patterns invented for a one-off case.

4. **CDD pipeline fully exercised.** This is the first release since v3.14.7 where the full pipeline ran end-to-end: observe → select → branch → bootstrap → gap → mode → artifacts → self-coherence → review → gate → release. γ discipline restored after the v3.15.0 regression.

### Skill patches needed

**No patches required.** The author pre-flight skip was a procedural miss, not a skill gap — §8.5 already exists and is clear. The reviewer caught it, which means the review step worked as designed.

---

## 4. Review Quality

**PRs this cycle:** 1 (PR #103)
**Avg review rounds:** 2.0 (target: ≤2 for code PRs) — **passed**
**Superseded PRs:** 0 (target: 0) — **passed**
**Finding breakdown:** 1 mechanical / 2 judgment / 3 total
**Mechanical ratio:** 33% (threshold: 20%)
**Action:** The mechanical finding (rebase/duplicate SHA) is a consequence of repo history divergence, not a repeatable process failure. No process issue filed — this is environmental, not systematic.

**Finding detail:**

| # | Finding | Reviewer | Type | Severity |
|---|---------|----------|------|----------|
| 1 | Branch needs rebase onto current main (duplicate SHA) | R1 | mechanical | D (required) |
| 2 | v3.15.1 post-release assessment missing (§9.11) | R1 | judgment | C |
| 3 | Tests are predicate-only, not integration | R2 | judgment | B |

**Assessment:** Review quality is healthy. Two independent reviews converged without contradictions. The mechanical finding was resolved in-cycle. The judgment findings were accepted as known debt with clear rationale. This is a significant improvement over v3.15.0 (0 reviews, 0 findings).

---

## 5. Next Move

**Next MCA:** #28 — Daemon retries failed triggers forever — no retry limit or dead-letter
**Owner:** to be assigned
**Branch:** pending creation (must follow CDD §1.4)
**First AC:** Non-retryable errors (4xx) fail immediately without retry
**MCI frozen until shipped?** Yes — stale backlog still unaddressed, and #28 is the operational safety net that #29's fix highlighted as missing.

**Rationale:** #29 removed one trigger for the infinite retry loop, but #28 is the structural fix. Any other non-retryable Claude API error (malformed prompt, token overflow, API contract change) will still wedge the daemon. This is the highest-leverage operational fix and was identified as next by both the issue body and both reviewers.

**Alternative considered:** #73 (Runtime Extensions) has been stale longest and was the v3.15.0 assessment's recommended next move. However, #28 is a runtime bug with direct operational impact — per §0.6, operational infrastructure debt overrides. #73 remains the next feature MCA after #28 ships.

**Immediate fixes** (executed in this session):
- None required. No skill patches, no CHANGELOG corrections, no process issues to file.
