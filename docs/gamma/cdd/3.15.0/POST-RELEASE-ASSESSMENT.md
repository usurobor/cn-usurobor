# Post-Release Assessment — v3.15.0

**Issue closed:** #22 — Version coherence: single source of truth from tag to agent self-awareness
**PR:** #99 (6 commits, +336/-54, 20 files)
**Assessor:** Claude (independent review, not the implementing agent)
**Date:** 2026-03-24

---

## 1. Coherence Measurement

### Baseline

v3.14.7 — α A, β A, γ A

v3.14.7 (#97) introduced branch pre-flight validation, scope enumeration, review quality metrics (§11.11), process debt integration (§11.12), and finding taxonomy. It tightened the development method.

### This release

v3.15.0 — α A, β A-, γ B+

### Delta

- **α (PATTERN): Held at A.** The VERSION → dune rule → `cn_version.ml` → `Cn_lib.version` chain is structurally clean. Single derivation path, CI-validated, no parallel version sources. Minor weakness: the `dir_name → split on '@' → extract version` parsing logic is duplicated in 4 places (`cn_runtime_contract.ml:gather`, `cn_system.ml:update_runtime`, `cn_system.ml:run_status`, `cn_system.ml:run_doctor`). This is a pattern smell, not a pattern failure.

- **β (RELATION): Regressed from A to A-.** The PR claims 10/10 ACs met. AC3 states "CI fails if derived files stale" and AC10 states "Release gate blocks on version disagreement." The new `check-version-consistency.sh` script does work. However, the pre-existing I1 CI check (Package/source drift) **failed** on the PR's head commit, and the PR was merged anyway. Merging a PR about version coherence with a failing version-adjacent CI check undermines the coherence contract. The relation between claim ("CI validates coherence") and reality ("a CI check was red at merge time") has a gap. Additionally, `third_party_rev` is computed via `git ls-remote` network call even when all dependencies are first-party — dead code on the happy path that adds latency and a failure surface.

- **γ (EXIT/PROCESS): Regressed from A to B+.** Three specific process regressions:
  1. **Zero review rounds.** PR #99 was self-merged in ~26 minutes with no peer review, no review comments, and no approval. v3.14.7 — the immediately preceding release — introduced §11.11 review quality metrics specifically to track review discipline. The first release after introducing those metrics bypassed review entirely.
  2. **Merged with failing CI.** The I1 check (Package/source drift) failed. The PR was merged despite the red check. This is not a flaky test — I1 validates exactly the domain (package/source coherence) that this PR addresses.
  3. **Three fix commits after implementation.** Commits `b5d16d5`, `f76341d`, `8de7d9e` are post-implementation fixes (cram test whitespace, self-coherence report accuracy, cram glob patterns). This pattern — implement then patch — suggests insufficient pre-merge validation. The pre-flight checks from v3.14.7 §1.5 were not applied.

### Coherence contract closed?

**Partially closed.**

The version-tax problem (#22 names) is genuinely eliminated: future bumps require editing one file, all consumers derive from `VERSION`, and the new CI gate (`check-version-consistency.sh`) validates the chain. This is a real structural improvement.

What remains open:
- I1 CI check was failing at merge time — the very class of problem this release claims to solve
- `cn build --check` does not call `check-version-consistency.sh` (acknowledged as follow-up for #94)
- No git tag for v3.15.0 exists locally (latest tag is v3.14.4); multiple releases between v3.14.4 and v3.15.0 remain untagged
- The CHANGELOG TSC entry (A/A/A/A) was self-scored before independent assessment, per the self-coherence report — this assessment disagrees on β and γ

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #22 | Version coherence | feature | converged | **shipped (v3.15.0)** | none |
| #97 | Reduce review round-trips | process | converged | **shipped (v3.14.7)** | none |
| #85 | Retroactive epoch assessments | process | converged | **shipped (v3.14.6)** | none |
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

**New since v3.14.5 epoch assessment:**
- #22, #97, #85 moved from growing/low to **none** (shipped)
- #94, #100, #96, #74 are **new entries** at growing lag
- #73, #65, #67 remain at **stale** — now carried across 3 assessment cycles with zero progress

**MCI/MCA balance: Freeze MCI**

**Rationale:** 3 issues remain stale (#73, #65, #67) — unchanged since the v3.14.5 epoch assessment. 8 issues at growing lag (up from 4). The stale backlog has not been addressed. New design issues (#94, #100, #96) were opened despite the MCI freeze, adding to the lag. The freeze must hold until at least one stale issue ships.

---

## 3. Process Learning

### What went wrong

1. **Review bypassed entirely.** PR #99 received zero reviews — not even a cursory scan. This is a 20-file, 336-line change touching build infrastructure, dependency resolution, runtime contracts, and CI gates. The risk surface warranted at least one review round. Issue #97 (the previous release) was specifically about reducing review round-trips through pre-flight checks — not about eliminating review.

2. **Merged with red CI.** The I1 check (Package/source drift) failed on the head commit. The PR was merged anyway. This directly contradicts the project's CI discipline and is particularly ironic for a PR about version/package coherence.

3. **Post-hoc fix pattern.** 3 of 6 commits are fixes to the implementation commit: cram test whitespace, self-coherence report inaccuracies, cram glob patterns. These are mechanical issues that pre-flight validation or a single review round would have caught.

4. **MCI freeze violated.** Issues #94, #100, #96 were opened during the freeze period. While opening issues is lighter than writing design docs, issues with detailed design sections (like #100's multi-phase architecture) constitute MCI activity. The freeze is not being honored in spirit.

5. **Untagged releases accumulate.** v3.14.5 through v3.14.7 have no git tags. v3.15.0 was reportedly tagged on GitHub but the tag is not in the local repository. Ghost releases (documented in CHANGELOG but not referenceable by tooling) were already called out in the v3.14.5 epoch assessment for v3.13.0. The same problem continues.

### What went right

1. **VERSION single-source-of-truth chain works.** The core technical design is sound. `VERSION` → dune rule → `cn_version.ml` → `Cn_lib.version` is a clean, CI-validated derivation chain. Future version bumps genuinely require editing one file.

2. **Comprehensive scope.** All 10 ACs from #22 have corresponding code. Build system, manifests, deps, runtime contract, system commands, tests, and CI gate were all updated together. No partial implementation.

3. **Tests made dynamic.** Both cram and ppx_expect tests now derive from `VERSION`/`Cn_lib.version` instead of hardcoding literals. The "5-file tax" is permanently eliminated.

4. **`reconcile_packages` closes the update loop.** `cn update` inside a hub now rewrites locks, restores packages, and updates runtime — the split-brain problem between binary and packages is addressed.

5. **Doctor gains version-coherence check.** `cn doctor` now validates binary/package alignment and surfaces drift clearly. This makes the problem visible even if CI is bypassed.

### Skill patches needed

**Yes — two patches required:**

1. **CI gate enforcement.** PR merge with a failing CI check should not be possible for MCA PRs. This is a GitHub branch protection issue, not a skill issue, but the CDD skill should document: "Do not merge with red CI checks. If a check fails on a domain your PR touches, that is a blocking finding." → File as process issue.

2. **Self-scoring timing.** The CHANGELOG TSC entry and self-coherence report scored the release before independent assessment. §11.2 says "Score α/β/γ for new release and compare." The self-coherence report is an author artifact; the post-release assessment is the independent score. The CHANGELOG should be updated after the assessment, not before. → Patch post-release skill to clarify sequence.

---

## 4. Review Quality

**PRs this cycle:** 1 (PR #99)
**Avg review rounds:** 0.0 (target: ≤2 for code PRs) — **FAILED**
**Superseded PRs:** 0 (target: 0) — passed
**Finding breakdown:** 0 mechanical / 0 judgment / 0 total (no review occurred)
**Mechanical ratio:** N/A (division by zero — no findings because no review)
**Action:** Cannot assess finding quality because review did not happen.

**Assessment:** Review quality is unmeasurable for this cycle because the review step was skipped entirely. This is worse than a high mechanical ratio — it's a process gap. The v3.14.7 release introduced §11.11 review quality metrics. The first release measured under those metrics has no data because the process wasn't followed.

**Findings that a review would have surfaced:**

| # | Finding | Type | Severity |
|---|---------|------|----------|
| 1 | I1 CI check failing — should not merge | mechanical | blocking |
| 2 | `@`-parsing duplicated in 4 places | judgment | advisory |
| 3 | `third_party_rev` computed unconditionally via network | judgment | advisory |
| 4 | `engines.cnos` exact pin — deliberate tightening needs explicit justification | judgment | advisory |
| 5 | `check-version-consistency.sh` depends on `python3` with no fallback | mechanical | advisory |
| 6 | `update_runtime` called twice on in-hub update path (idempotent but wasteful) | mechanical | advisory |
| 7 | 3 fix commits suggest insufficient pre-merge validation | mechanical | process |

Hypothetical ratio: 4 mechanical / 3 judgment / 7 total = 57% mechanical. This exceeds the 20% threshold. If review had happened, a process issue for pre-flight checks would be required.

---

## 5. Next Move

**Next MCA:** #73 — Runtime Extensions: capability providers, discovery, and isolation
**Owner:** to be assigned
**Branch:** pending creation (must follow CDD §1.4: `{agent}/{version}-73-runtime-extensions`)
**First AC:** Define the capability provider interface and registration mechanism
**MCI frozen until shipped?** Yes — 3 stale issues have been carried across 3 assessment cycles. #73 is the foundation that unblocks #65 and #67. The stale backlog is the highest-priority coherence debt.

**Rationale:** The stale trio (#73, #65, #67) has been flagged in every assessment since the v3.14.5 epoch. #73 is the root — #65 (communication) and #67 (network) depend on its transport/capability model. Shipping #73 would move 3 issues from stale to none/low in a single cycle. No other MCA has comparable leverage on the lag table.

**Alternative considered:** #94 (cn cdd mechanization) would automate the process gaps exposed in this assessment (CI enforcement, pre-flight validation). However, #73 has been stale longer and is a feature-level blocker. Process fixes (#94) can be addressed through immediate skill patches and branch protection rules without a full MCA.

**Immediate fixes** (to execute in this session):

1. **Update CHANGELOG TSC entry** — revise v3.15.0 from A/A/A/A to A/A-/B+/A- with updated coherence note reflecting the process findings
2. **Clarify post-release skill** — add note that CHANGELOG TSC score is provisional until post-release assessment; assessment may revise it

---

## Appendix: Tag Audit

| Version | In CHANGELOG | Git tag exists | GitHub release |
|---------|-------------|---------------|----------------|
| v3.14.4 | yes | yes | yes |
| v3.14.5 | yes | no | unclear |
| v3.14.6 | yes | no | unclear |
| v3.14.7 | yes | no | unclear |
| v3.15.0 | yes | no (locally) | yes (per operator) |

Multiple releases documented in CHANGELOG but not referenceable by `git tag`. This was flagged in the v3.14.5 epoch assessment for v3.13.0 and continues. Recommend: tag all untagged releases retroactively, or document the gap as accepted debt.
