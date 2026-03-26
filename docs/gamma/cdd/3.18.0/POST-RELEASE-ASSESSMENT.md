## Post-Release Assessment — v3.18.0

### 1. Coherence Measurement

- **Baseline:** v3.17.0 — α A, β B+, γ C+
- **This release:** v3.18.0 — α A-, β B+, γ B-
- **Delta:**
  - α regressed slightly (A → A-) — `copy_tree` simplification is clean, but the manifest update scope expanded well beyond AC3+AC4 into skill-reorg package rebuild. The package rebuild was mechanically correct but not part of the original gap statement. The `lockfile_for_manifest` Result type change is structurally sound.
  - β held (B+) — AC3 and AC4 met. Scope honestly narrowed in docs. But #113 is still mostly open (AC5-AC8 deferred). The PR that shipped is a partial implementation, not the package system substrate. Honest about what shipped vs what remains.
  - γ improved (C+ → B-) — 3 review rounds (target: ≤2) is better than v3.17.0's 5. Mechanical ratio 57% (8/14) still above 20% threshold but improving. One superseded PR (#112 → #114) — not ideal but the pivot was justified (scope absorption into #113). Skills declared upfront (eng/ocaml, eng/testing, eng/coding) and actively applied during generation, not just post-hoc.
- **Coherence contract closed?** Partially. AC3+AC4 of #113 closed. AC5-AC8 remain open. The PR was explicitly scoped as partial — no overclaim in the final version (after review correction).

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #113 | Package System Substrate | feature | converged (#113 spec) | AC3+AC4 shipped | **low** |
| #73 | Runtime Extensions | feature | converged | Phase 1+2 partial shipped | **low** |
| #65 | Communication — surfaces, transport | feature | converged (issue spec) | not started | **stale** |
| #67 | Network access as CN Shell capability | feature | converged (subsumed by #73) | not started | **stale** |
| #64 | P0: agent probes filesystem despite RC | process | bug report | not started | growing |
| #68 | Agent self-diagnostics | feature | converged (issue spec) | not started | growing |
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

**MCI/MCA balance:** Freeze MCI — 2 stale issues remain (#65, #67). Freeze holds.

**Rationale:** #113 AC3+AC4 shipped but doesn't move any stale issue. #73 Phase 2 partially landed via cherry-pick (policy, host binary, build integration) but not released as a standalone cycle. #65 and #67 remain stale since v3.14.5 epoch.

### 3. Process Learning

**What went wrong:**

1. **Manifest scope creep.** The gap was "restore copies full content + honest third-party." The fix required updating skill paths in package manifests (post-reorg), rebuilding packages, fixing version scripts, cleaning stale cnos.pm references. Each was individually correct but the total footprint was much larger than the stated gap. A tighter scope statement at bootstrap would have separated "fix restore semantics" from "sync manifests post-reorg."

2. **No OCaml toolchain.** Build-before-push (eng/ocaml §3.5) impossible in this environment. Round 1's D-level finding (unused variable → build failure) would have been caught by `dune build`. Round 2's G1 (host path) would have been caught by `dune runtest`. Two rounds of review were pure compile/test errors. This is the same failure as v3.17.0.

3. **Superseded PR.** PR #112 was opened, reviewed, then closed and replaced by #114 when the scope was absorbed into #113. The cherry-pick approach worked mechanically but the PR lifecycle was messy. Should have opened #114 directly against #113 from the start.

**What went right:**

1. **Active skill application improved.** eng/ocaml, eng/testing, eng/coding declared at bootstrap and applied during generation. The `lockfile_for_manifest` Result type, invariant-first test naming (I1-I5), and `copy_tree` simplification were all skill-driven, not post-hoc corrections.

2. **Scope narrowed honestly after review.** Round 1b (Claude reviewer) correctly identified overclaim. Scope narrowed to AC3+AC4 with deferred ACs explicitly listed. No pushback — the correction was accepted and executed.

3. **Path-consistent restore is genuinely simpler.** Replacing the 5-category hardcoded list with `copy_tree` eliminated an entire class of "restore doesn't match build" bugs. The fix was 1 line replacing 12.

4. **Two-reviewer convergence pattern.** Sigma caught mechanical issues (build fail, stale paths). Claude caught semantic issues (overclaim, path divergence, test evidence depth). Complementary — neither alone would have caught everything.

**Skill patches:** None needed. The loaded skills (eng/ocaml, eng/testing, eng/coding) were correct — the failures were environmental (no toolchain) and scope (manifest creep), not skill gaps.

### 4. Review Quality

**PRs this cycle:** 2 (PR #112 superseded, PR #114 merged)
**Review rounds:** 3 (target: ≤2) — **FAILED** (but improved from v3.17.0's 5)
**Superseded PRs:** 1 (target: 0) — **FAILED**
**Finding breakdown:** 8 mechanical / 6 judgment / 14 total
**Mechanical ratio:** 57% (threshold: 20%) — **FAILED**
**Action:** Third consecutive cycle above 50% mechanical ratio. Root cause is identical: no local build/test before push. Environment constraint (no OCaml toolchain) is the blocker. Filed as known debt — not actionable until environment provides build tooling.

Findings by round:

| Round | Findings | Mechanical | Judgment |
|-------|----------|------------|----------|
| R1 (Sigma) | 6 | 5 (unused var, stale paths, indent, stale ref, CI cascade) | 1 (tautological logic) |
| R1b (Claude) | 5 | 2 (source_decl mismatch, CI red) | 3 (overclaim, shallow test, scope ambiguity) |
| R2 (Sigma) | 1 | 1 (host binary path) | 0 |
| R3 (Sigma) | 2 | 0 | 2 (CI gate, stale cnos.pm — pre-existing) |
| **Total** | **14** | **8** | **6** |

### 5. Next Move

**Next MCA:** #113 AC5-AC7 — integrity, doctor depth, Runtime Contract truth
**Owner:** sigma
**Branch:** pending branch creation
**First AC:** AC5 — integrity generated and verified
**MCI frozen until shipped?** Yes — freeze holds from v3.16.2 assessment
**Rationale:** #113 is the active package-system issue. AC3+AC4 shipped. AC5 (integrity) is the natural next step — it's self-contained, testable, and unblocks AC6 (doctor validates integrity).

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - Stale cnos.pm references cleaned from code paths (committed in PR #114)
  - Package manifests synced with skill reorg (committed in PR #114)
  - CHANGELOG TSC correction for v3.17.0 — **not yet executed** (see below)
- Deferred outputs committed: yes
  - #113 AC5-AC7: next cycle MCA
  - Build toolchain in CI/dev environment: ongoing infrastructure debt

**Immediate fixes** (to execute now):
- CHANGELOG v3.17.0 TSC entry disagrees with its post-release assessment (CHANGELOG says A/A/A-, assessment says A/B+/C+). Per CDD §Step 2, assessment governs. Will correct.
