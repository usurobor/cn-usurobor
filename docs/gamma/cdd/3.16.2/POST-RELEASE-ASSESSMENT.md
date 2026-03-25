# Post-Release Assessment — v3.16.2

**Issue closed:** #106 — Two-membrane fix: presentation leak + self-knowledge probe
**PR:** #109 (9 commits, +557/-20, 6 files)
**Superseded PR:** #107 (closed — branch name did not follow CDD §2.1)
**Assessor:** Claude (implementing agent — noted as limitation)
**Date:** 2026-03-25

---

## 1. Coherence Measurement

### Baseline

v3.16.1 — α A, β A, γ A

v3.16.1 shipped daemon retry limit (#28). Single review round, zero mechanical findings.

### This release

v3.16.2 — α A, β A, γ B+

### Delta

- **α (PATTERN): Held at A.** `xml_prefixes` lifted to module level, shared between `is_control_plane_like` and `strip_xml_pseudo_tools` — single source of truth for the XML blocklist. `strip_xml_pseudo_tools` follows the existing `strip_embedded_frontmatter` pattern (state machine over lines + inline scan). `sanitize` helper in `render_human_facing` applies uniform pipeline to all candidates (body, resolved reply, raw reply). `extract_tag_name` + `has_matching_close` provides correct matched-tag block removal. Anti-probe instruction is one sentence appended to existing Runtime Contract preamble. I5 follows I1-I4 structure in INVARIANTS.md. Clean pattern coherence throughout.

- **β (RELATION): Held at A.** All 7 issue ACs met. The two-membrane architecture matches the issue's design spec exactly: Cn_output is the single presentation membrane (body + reply candidates sanitized uniformly), Runtime Contract is the single self-knowledge source (anti-probe instruction + sandbox denylist). I5 documents both membranes. The inline same-line stripper closes the position-invariant claim in I5. 13 new expect tests cover block-level, mid-body, inline, reply, nested XML, and negative (harmless angle brackets) scenarios.

- **γ (EXIT/PROCESS): Regressed from A to B+.** This is the weakest axis by a significant margin:
  1. **5+ review rounds across 2 reviewers.** Target is ≤2 for code PRs. This cycle took at least 5 (Sigma R1-R4 + second reviewer R1). The v3.16.1 achievement of 1 round is completely reversed.
  2. **High mechanical finding ratio.** Of ~14 total findings, at least 8 were mechanical (unused variable, duplicate list entry, wrong test expectations, `has_close` bug, stale doc references). That's ~57% mechanical — well above the 20% threshold.
  3. **Bootstrap not first diff.** CDD §2.2 requires bootstrap as the first diff on the branch. The bootstrap was originally a separate commit but got squashed during `git reset --soft` + rebase cycles. The version directory exists but the commit ordering violates the spec.
  4. **Branch naming violation.** Started on `claude/review-agent-runtime-docs-LyUlu` (system-assigned), required correction to `claude/3.16.2-106-two-membrane-fix` per CDD §2.1. Created a superseded PR (#107 → #109).
  5. **Observation inputs read late.** CDD §2.0 requires reading CHANGELOG TSC, encoding lag, doctor/status, and last assessment before selection. These were read mid-cycle after a reviewer flagged the gap — not before implementation began.
  6. **No build verification (persistent).** Same environmental constraint. CI is the first build check. Multiple compile errors discovered only through CI (unused variable, etc.).
  7. **9 commits for a bugfix.** Each review round produced a fix commit rather than amending. While CDD doesn't mandate squashing, the commit count reflects iterative patching rather than coherent initial implementation.

### Coherence contract closed?

**Closed.** The gap named in #106 (internal markup on human surface + agent reads cn.json for version) is eliminated:
1. `<tool_calls>`, `<cn:ops>`, and 6 other XML variants added to shared `xml_prefixes` blocklist
2. `strip_xml_pseudo_tools` handles block-level (matched-tag walk), mid-body, and inline same-line XML
3. All candidates (body + reply) sanitized through shared `sanitize` helper
4. Anti-probe instruction in Runtime Contract authority preamble
5. `.cn/` reads remain denied by sandbox denylist (pre-existing)
6. I5 invariant documents both membranes

What remains related but out of scope:
- #64 (P0: agent probes filesystem despite RC) — broader self-probe pattern beyond version
- Trace event gap: stripping path produces `Renderable "(acknowledged)"` rather than `Fallback` with reason code

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #106 | Two-membrane fix: presentation leak + self-knowledge | bug | converged | **shipped (v3.16.2)** | none |
| #73 | Runtime Extensions — capability providers | feature | converged (issue spec) | not started | **stale** |
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

**Changes since v3.16.1 assessment:**
- #106 moved from new (P0) to **none** (shipped)
- #73, #65, #67 remain **stale** — now carried across 7 assessment cycles
- All others unchanged

**MCI/MCA balance: Freeze MCI**

**Rationale:** 3 issues remain stale (#73, #65, #67) unchanged since v3.14.5 epoch. 12 issues at growing lag. MCI freeze holds until at least one stale item ships.

---

## 3. Process Learning

### What went right

1. **Architecture correct from the start.** The two-membrane design (Cn_output as presentation membrane, Runtime Contract as self-knowledge membrane) was identified early and never changed. Reviewers confirmed the direction in every round. The `sanitize` helper applying uniform pipeline to body + reply is clean design that survived all reviews.

2. **Senior eng review incorporated.** The initial patch was narrow (add `<tool_calls>` to prefix list). The senior eng's two-membrane design review transformed it into an architectural fix. This is CDD working as intended — design review before implementation hardens the coherence contract.

3. **Root cause analysis was precise.** The prefix-match gap (`<tool_call>` vs `<tool_calls>` at position 10) was identified by byte-level analysis. Every subsequent fix (mid-body stripping, inline stripping, matched-tag close) addressed a real gap, not a symptom.

4. **Test coverage comprehensive.** 13 new expect tests cover: start-of-string blocking (I4 expanded), block-level stripping (single/multi-line), inline same-line (3 cases + negative), membrane integration (Telegram + ConversationStore), reply sanitization, and nested XML. The tests caught real bugs during development.

5. **Assessment commitment honored.** v3.16.1 assessment committed #106 as next MCA via §3.1 (P0). This cycle honored that commitment. Three consecutive cycles now follow the assessment→selection→delivery chain.

### What went wrong

1. **Too many mechanical findings.** 8+ mechanical findings across 5 rounds: unused variable, duplicate list entry, wrong test expectations (3×), `has_close` bug (finding `<` instead of `</`), stale doc counts, branch name. These are compiler-level errors and copy-paste mistakes that should have been caught before review. The no-build-verification constraint is the primary cause, but even without a compiler, more careful desk-checking would have caught the duplicate entry and stale doc references.

2. **`has_close` went through 3 iterations.** v1: `String.index` finds first `<` (wrong — finds opening tag). v2: scan for `</` at any position (wrong — matches inner `</path>` in nested XML). v3: matched-tag tracking with `extract_tag_name` + `has_matching_close` (correct). This function should have been designed correctly from the start. The matched-tag approach was suggested by the reviewer in round 1 (F7) but deferred as "theoretical" — it was not theoretical.

3. **Bootstrap ordering violated.** The bootstrap commit existed but was lost during `git reset --soft` and rebase cycles. The process of addressing review findings destructively rewrote early history. CDD §2.2 requires bootstrap as first diff — this is a structural discipline that was not maintained through the iterative fix cycle.

4. **Branch naming required correction.** Started on the system-assigned branch name instead of following CDD §2.1 format. Created a superseded PR (#107 → #109). This wasted reviewer time and added process noise.

5. **Observation inputs read late.** CDD §2.0 was not followed at the start. CHANGELOG, lag table, and last assessment were read only after a reviewer flagged the gap. The observation step was retrofitted rather than driving selection.

6. **Inline stripping deferred too long.** Round 1 reviewer flagged inline same-line XML as C-severity. It was acknowledged as debt. Round 3 second reviewer flagged it again as D-severity — it was blocking AC1/AC4. The initial "deferred as theoretical" judgment was wrong. When the invariant (I5) claims "regardless of position," the implementation must match.

### Process improvements needed

- **Desk-check before review.** Without a compiler, manually trace through new functions with at least 3 test inputs before committing. The `has_close` bug would have been caught by tracing `<tool_calls> [...] </tool_calls>` through `String.index`.

- **Don't defer C-findings that contradict your own invariant claims.** If I5 says "regardless of position" and the implementation is line-start-only, that's a β conflict, not a deferral.

- **Follow CDD §2.0-§2.2 mechanically.** Read inputs → select → branch (CDD name) → bootstrap (first commit). Do not start coding before these steps complete. The observation step is not optional.

- **Amend or squash fix commits.** 9 commits for a bugfix adds review noise. Consider squashing mechanical fixes into the parent commit rather than creating new commits per round.

---

## 4. Review Quality

**PRs this cycle:** 2 (PR #107 superseded, PR #109 active)
**Superseded PRs:** 1 (target: 0) — **failed**
**Review rounds:** 5+ (Sigma R1-R4, second reviewer R1) (target: ≤2) — **failed**

**Finding breakdown:**

| # | Finding | Round | Reviewer | Type | Severity |
|---|---------|-------|----------|------|----------|
| 1 | `<cn:ops>` not in blocklist | R1 | Sigma | judgment | D |
| 2 | Reply payloads bypass mid-body stripper | R1 | Sigma | judgment | D |
| 3 | Duplicate `<invoke>` entry | R1 | Sigma | mechanical | D |
| 4 | 3 CI expect-test mismatches | R1 | Sigma | mechanical | D |
| 5 | Branch name mismatch | R1 | Sigma | mechanical | D |
| 6 | Inline same-line XML not caught | R1 | Sigma | judgment | C |
| 7 | `has_close` over-strips (any `</`) | R1 | Sigma | judgment | C |
| 8 | `strip_xml_pseudo_tools` eats content after XML | R2 | Sigma | mechanical | D |
| 9 | SELF-COHERENCE "7 variants" stale count | R2 | Sigma | mechanical | B |
| 10 | Inline same-line XML still not stripped (AC1/AC4 partial) | R3 | Reviewer 2 | judgment | D |
| 11 | CI checks not green | R3 | Reviewer 2 | mechanical | D |
| 12 | I5 overclaims "regardless of position" | R3 | Reviewer 2 | judgment | C |
| 13 | Nested inner `</path>` exits block early | R3 | Sigma | judgment | D |
| 14 | Reply mid-body test expectation wrong | R3 | Sigma | mechanical | D |
| 15 | Unused variable `is_xml_open` | R4 | Sigma | mechanical | D |
| 16 | CI gate — checks not green | R4 | Reviewer 2 | mechanical | D |
| 17 | Stale self-coherence (claims inline is debt, but it's implemented) | R4 | Reviewer 2 | judgment | C |

**Totals:** 17 findings. 9 mechanical / 8 judgment.
**Mechanical ratio:** 53% (threshold: 20%) — **failed**

**Assessment:** Review quality is poor. The mechanical ratio (53%) is the worst since v3.16.0 (63%) and far above the 20% threshold. The round count (5+) is the worst in the project's history. Contributing factors: no build verification, insufficient desk-checking, deferred findings that should have been addressed immediately, and branch naming discipline not followed. The two genuine design improvements that came from review (reply candidate sanitization, matched-tag close) were valuable and would not have been found without review — but they were buried in a flood of preventable mechanical findings.

**Trend:** v3.15.2 (2 rounds, 33% mechanical) → v3.16.0 (3 rounds, 63%) → v3.16.1 (1 round, 0%) → v3.16.2 (5+ rounds, 53%). The v3.16.1 recovery is reversed. The regression is attributable to scope (new function with multiple edge cases) and process discipline (observation/bootstrap steps skipped initially).

---

## 5. Next Move

**Next MCA:** To be determined from observation inputs at next cycle start.

**Candidates (by selection function):**
- §3.1 P0: #64 (agent probes filesystem despite RC) — design-level, no clear fix path yet
- §3.1 P0: #74 (rethink logs structure) — labeled P0 but is a design issue
- §3.4 MCI freeze: #73, #65, #67 — stale across 7 cycles, freeze should be re-evaluated
- §3.5 Weakest axis: γ is weakest (B+) — process improvement work

**MCI frozen until shipped?** Yes — stale backlog still unaddressed. But 7 cycles of freeze without progress should trigger re-evaluation of whether these issues should be descoped, consolidated, or explicitly deferred.

**Rationale:** No P0 with a clear fix path remains. #64 is P0 but design-level. The weakest axis is γ (process), suggesting the next cycle should either (a) address the stale MCI freeze or (b) improve process tooling (#94 — mechanize CDD invariants) to prevent the mechanical finding regression seen in this cycle.

---

## 6. Closure

**Closure evidence (CDD §10):**

### Immediate outputs
- [x] Post-release assessment written (this document)
- [x] Encoding lag table updated (#106 closed)
- [x] Review quality metrics recorded
- [x] Self-coherence artifact synced with branch state

### Deferred outputs
- Next MCA to be selected from observation at next cycle start
- I1 CI failure triage (deferred — pre-existing, not blocking, carried from v3.16.0)
- MCI freeze re-evaluation: 7 cycles of stale backlog (#73, #65, #67) warrants explicit descope or consolidation decision
- Process improvement: desk-check discipline before review submission
- Process improvement: follow CDD §2.0-§2.2 mechanically at cycle start, not retrofitted
