## Post-Release Assessment — v3.17.0

### 1. Coherence Measurement

- **Baseline:** v3.16.2 — α A, β A, γ A-
- **This release:** v3.17.0 — α A, β B+, γ C+
- **Delta:**
  - α held (A) — clean module boundaries, backward compatible, registry as single source of truth. Extension types are well-separated after field rename.
  - β regressed (A → B+) — full type-level wiring complete, but 3 of 7 ACs only partially met. Subprocess host binary doesn't exist, policy intersection not enforced, build integration missing. The architecture is sound but the execution boundary stops at dispatch — nothing runs end-to-end outside tests.
  - γ regressed (A- → C+) — 5 review rounds (target: ≤2). 15 total findings. Same bug class (type disambiguation) persisted across 3 rounds before root-cause fix. Mechanical ratio 53% (8/15, threshold: 20%). Code violated loaded skill rules (List.hd, bare `with _ ->`, Hashtbl in List.map) that were then self-corrected — skills used as post-hoc linter, not generation constraints.
- **Coherence contract closed?** Partially. 4 of 7 ACs fully met (AC2/3/4/6), 3 partially met (AC1/5/7). The open op registry architecture is landed and wired. The execution path is type-complete but not runtime-complete — no host binary, no policy enforcement, no build integration.

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #73 | Runtime Extensions — capability providers | feature | converged | Phase 1 shipped | **low** |
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

**MCI/MCA balance:** Freeze MCI — 2 issues remain stale (#65, #67). #73 moved from stale to low (Phase 1 shipped, Phase 2 pending). Freeze holds until #73 Phase 2 ships or another stale issue moves.

**Rationale:** #73 Phase 1 reduces the stale count from 3 to 2 but doesn't clear the freeze. #65 and #67 have been stale since the v3.14.5 epoch (7+ cycles). New design work blocked until at least one more stale issue ships.

### 3. Process Learning

**What went wrong:**

1. **Same bug class across 3 review rounds.** `extension_op.kind` vs `backend.kind` field ambiguity caused compile errors in Round 1 (cn_extension.ml), Round 2 (cn_capabilities.ml), and Round 3 (cn_capabilities.ml again — missed file). The root-cause fix (rename fields at type definition) was available from Round 1 via OCaml skill §3.1 but not applied until the reviewer explicitly demanded it in Round 3. This is the single largest process failure of the cycle.

2. **Skills used as post-hoc linter, not generation constraints.** Wrote `List.hd`/`List.tl`, bare `with _ ->`, `Hashtbl` inside `List.map`, catch-all `| _ -> ()` — all violations of loaded skills. Then found and fixed them in self-review. The correct process is: load constraints before writing, generate code that satisfies them. The current process is: write code, review against skills, patch violations.

3. **Test files not updated when production signatures changed.** `gather` gained a `()` unit arg, `op_kind` gained an `Extension` variant, `Filename.temp_dir` doesn't exist in OCaml stdlib — all discovered by CI, not by the author. Every signature change should trigger a grep for all call sites including tests.

4. **Environment-dependent test expectations.** `Cn_json.parse` produces different error messages across OCaml environments. Hardcoding the exact error string caused a CI-only failure. Expect tests for error messages should test structure (prefix/class), not exact wording.

**What went right:**

1. **Architecture correct from start.** The extension module design (manifest parsing, discovery, registry, lifecycle states, op index) survived all 5 review rounds without structural changes. Only wiring and mechanical fixes were needed.
2. **Wiring completed in one round.** Round 1 identified 3 unwired call sites (orchestrator, context packer, output parser). All 3 were fixed in one commit, correctly.
3. **Self-coherence report was honest.** The SELF-COHERENCE.md correctly reported 4 PASS / 3 PARTIAL after reviewer correction. No overclaiming in the final version.
4. **Root-cause fix was structural.** Once applied, the field rename (`kind` → `op_kind`/`backend_kind`) eliminated the entire class of type disambiguation errors permanently. No file will hit this again.
5. **Refactoring improved functional purity.** fold_left, polymorphic variant dispatch, exhaustive match, trace events for silent failures — all genuine quality improvements.

**Skill patches:**

1. OCaml skill §3.1 already existed but was not applied at generation time. No new rule needed — the failure is application, not specification.
2. Review skill §2.1.3 updated with overlapping field name check (committed: `7e9ad2f`).
3. Two new L7 skills shipped: testing (invariant-first proof: `ea4dad7`), architecture-evolution (boundary-change: `ace55fc`).

### 4. Review Quality

**PRs this cycle:** 1 (PR #111)
**Review rounds:** 5 (target: ≤2) — **FAILED**
**Superseded PRs:** 0 (target: 0) — PASS
**Finding breakdown:** 8 mechanical / 7 judgment / 15 total
**Mechanical ratio:** 53% (threshold: 20%) — **FAILED**
**Action:** Same mechanical ratio as v3.16.2 (53%). Two consecutive cycles at 53% mechanical ratio is a pattern, not an accident. The pre-flight checks are insufficient — type compilation, test site updates, and environment-independent assertions should all be caught before review.

Findings by round:

| Round | Findings | Mechanical | Judgment |
|-------|----------|------------|----------|
| R1 | 8 | 2 (compile error, branch name) | 6 (wiring ×3, overclaim ×3) |
| R2 | 1 | 1 (type disambiguation) | 0 |
| R3 | 2 | 1 (missed file) | 1 (root cause design) |
| R4 | 3 | 3 (test compile errors) | 0 |
| R5 | 1 | 1 (expect-test string) | 0 |
| **Total** | **15** | **8** | **7** |

R1 had legitimate judgment findings (wiring gaps, self-coherence overclaims). R2-R5 were entirely mechanical — the kind of errors that a `dune build && dune test` before push would catch. 7 of 15 findings (47%) occurred after R1 and were all mechanical.

### 5. Next Move

**Next MCA:** #73 Phase 2 — subprocess host binary + policy intersection
**Owner:** sigma
**Branch:** pending branch creation
**First AC:** AC7 fully met — `cnos-ext-http` host binary exists and executes
**MCI frozen until shipped?** Yes — freeze holds from v3.16.2 assessment
**Rationale:** #73 Phase 1 landed the architecture. Phase 2 makes it executable: host binary, policy enforcement, build integration. This moves #73 from low to none and unblocks #67 (subsumed by #73).

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - OCaml skill §3.1 application awareness noted (`fabb11b`)
  - Review skill §2.1.3 overlapping fields check (`7e9ad2f`)
  - Testing skill shipped (`ea4dad7`)
  - Architecture-evolution skill shipped (`ace55fc`)
  - 4 code refactorings executed in-session (`aa82a11`)
- Deferred outputs committed: yes
  - #73 Phase 2: host binary + policy — next cycle MCA
  - Pre-flight automation for mechanical findings (compile + test before push) — process debt, not yet filed

**Immediate fixes** (executed in this session):
- Field rename root-cause fix: `15bc303`
- OCaml checklist violations (List.hd, bare catch-all, bare with): `da8c1fa`
- Functional purity refactoring (fold, variant dispatch, exhaustive match, trace event): `aa82a11`
- Test compile fixes (gather unit arg, Extension variant, temp_dir): `97fb93a`
- Environment-independent expect test: `756e53e`
