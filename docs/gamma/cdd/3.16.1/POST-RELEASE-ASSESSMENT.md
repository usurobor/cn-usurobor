# Post-Release Assessment — v3.16.1

**Issue closed:** #28 — Daemon retries failed triggers forever — no retry limit or dead-letter
**PR:** #105 (4 commits, +233/-9, 4 files)
**Assessor:** Claude (implementing agent — noted as limitation)
**Date:** 2026-03-25

---

## 1. Coherence Measurement

### Baseline

v3.16.0 — α A, β A, γ A-

v3.16.0 shipped end-to-end self-update (#37). γ regressed to A- due to 3 review rounds and 63% mechanical finding ratio (no build verification).

### This release

v3.16.1 — α A, β A, γ A

### Delta

- **α (PATTERN): Held at A.** `retry_decision` ADT with three variants (`Retry`, `Dead_letter_non_retryable`, `Dead_letter_exhausted`) follows the existing `drain_stop_reason` pattern. `classify_retry_decision` is a pure function extracted for testability — no coupling to daemon state. `Hashtbl` retry counter scoped to `run_daemon` — no global state, entries cleaned on success and dead-letter. Exponential backoff formula (`1s * 2^(attempts-1)`, capped 30s) is inline and tested.

- **β (RELATION): Held at A.** All 5 issue ACs met. The two-layer retry architecture is sound: LLM-level retries with backoff in `cn_llm.ml` handle transient HTTP failures; daemon-level retries with dead-letter in `cn_runtime.ml` handle persistent failures. A single bad trigger gets at most 9 LLM calls (3 daemon attempts × 3 LLM retries) before dead-lettering — bounded and reasonable. Dead-letter advances offset, cleans state files, emits trace event, and continues processing remaining messages. The infinite retry loop from #28 is eliminated.

- **γ (EXIT/PROCESS): Recovered from A- to A.** One review round. Zero mechanical findings. The AC4 finding (daemon-level backoff missing) was a genuine judgment finding — the reviewer identified that poll-interval-as-backoff was insufficient and the author added real exponential backoff. No syntax errors, no missing match arms, no forgotten test files. The v3.16.0 regression (3 rounds, 63% mechanical) is corrected. The improvement is attributable to: (1) the change was smaller and more focused than v3.16.0, and (2) the pure-function extraction made the core logic independently testable.

### Coherence contract closed?

**Closed.** The gap named in #28 (daemon retries failed triggers forever, no escape without manual intervention) is eliminated:
1. Per-trigger retry counter with max 3 attempts
2. 4xx errors dead-letter immediately (no retry)
3. 5xx/network errors dead-letter after 3 attempts with exponential backoff
4. Dead-letter advances offset, cleans state, continues processing
5. Trace event `daemon.trigger.dead_lettered` provides operator visibility

What remains related but out of scope:
- #20 (eliminate silent failures in daemon) — broader error handling beyond retry/dead-letter
- #106 (agent leaks markup to human surface) — new P0 filed during this session

---

## 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #28 | Daemon retry limit / dead-letter | bug | converged | **shipped (v3.16.1)** | none |
| #106 | Agent leaks markup to human surface + reads version from cn.json | bug | issue spec | not started | **new (P0)** |
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

**Changes since v3.16.0 assessment:**
- #28 moved from growing to **none** (shipped)
- #106 added as **new (P0)** — agent leaks internal markup to human surface
- #73, #65, #67 remain **stale** — now carried across 6 assessment cycles

**MCI/MCA balance: Freeze MCI**

**Rationale:** 3 issues remain stale (#73, #65, #67) unchanged since v3.14.5 epoch. 13 issues at growing lag (+1 from #106). New P0 (#106) takes priority. MCI freeze holds.

---

## 3. Process Learning

### What went right

1. **Single review round.** Target is ≤2 for code PRs. This cycle achieved 1. The v3.16.0 regression (3 rounds) is corrected. Contributing factors: smaller scope (bugfix vs feature), pure function extraction made review trivial, and author pre-flight was thorough.

2. **Zero mechanical findings.** The sole finding (AC4 backoff) was a genuine judgment call about whether poll-interval constitutes "backoff." This is the review quality CDD targets — reviewers doing judgment work, not catching compiler-level errors.

3. **Assessment commitment honored.** v3.16.0 assessment committed #28 as next MCA via §3.2 (operational debt). This cycle honored that commitment. Two consecutive cycles now follow the assessment→selection→delivery chain correctly.

4. **Clean ADT design.** `retry_decision` follows the `drain_stop_reason` pattern already in the codebase. The reviewer did not flag any structural issues. The pure function + exhaustive match pattern made the logic self-documenting.

5. **Test-first for core logic.** 8 ppx_expect tests cover all classification paths including edge cases (4xx variants, exhaustion boundary, backoff formula). The backoff test validates the actual formula used in production code.

### What went wrong

1. **AC4 initial implementation was weak.** The first version claimed "poll interval as natural backoff" satisfied the backoff AC. The reviewer correctly identified this as insufficient — poll interval is fixed, not exponential. The fix (real `Unix.sleepf` with `1s * 2^(attempts-1)`) was straightforward but should have been in the initial implementation. The issue body explicitly says "retry with backoff."

2. **No build verification (persistent).** Same environmental constraint as v3.16.0 — no OCaml toolchain available. CI remains the first build check. This cycle got lucky: no syntax errors. The risk remains.

3. **I1 (package/source drift) still failing.** This is a pre-existing CI failure carried across multiple cycles. It is not caused by this PR but it means CI is never fully green. The failure should be triaged and either fixed or the check recalibrated.

### Process improvements observed

- **Smaller scope → fewer rounds.** v3.16.0 was a 6-AC feature touching 10 files. v3.16.1 was a 5-AC bugfix touching 4 files. The correlation between scope and review rounds holds. CDD §3.8 (effort-adjusted tie-break: choose the smaller one) is validated.

- **Pure function extraction → testable + reviewable.** Moving the classification logic out of the daemon loop into `classify_retry_decision` enabled both thorough unit testing and focused review. The reviewer could evaluate the decision logic independently from the daemon integration.

---

## 4. Review Quality

**PRs this cycle:** 1 (PR #105)
**Avg review rounds:** 1.0 (target: ≤2 for code PRs) — **passed**
**Superseded PRs:** 0 (target: 0) — **passed**
**Finding breakdown:** 0 mechanical / 1 judgment / 1 total
**Mechanical ratio:** 0% (threshold: 20%) — **passed**

**Finding detail:**

| # | Finding | Round | Type | Severity |
|---|---------|-------|------|----------|
| 1 | AC4 backoff: poll interval is not exponential backoff — needs real `sleepf` with doubling delay | R1 | judgment | C |

**Assessment:** Review quality is at target. Single round, zero mechanical findings, one substantive judgment finding that improved the implementation. This is a significant recovery from v3.16.0 (3 rounds, 63% mechanical). The improvement validates that smaller, focused changes with pure-function extraction produce cleaner review cycles.

**Trend:** v3.15.2 (2 rounds, 33% mechanical) → v3.16.0 (3 rounds, 63% mechanical) → v3.16.1 (1 round, 0% mechanical). The v3.16.0 regression was scope-driven, not process-driven.

---

## 5. Next Move

**Next MCA:** #106 — Agent leaks internal markup to human surface + reads version from cn.json
**Owner:** to be assigned
**Branch:** pending creation (must follow CDD §4.2)
**First AC:** `<tool_calls>` markup is stripped before any message reaches a human surface
**MCI frozen until shipped?** Yes — stale backlog still unaddressed.

**Rationale:** §3 selection function: §3.1 (P0) — #106 is a P0: internal agent-runtime markup (`<tool_calls>`) is visible to humans on Telegram. This is a user-facing coherence failure. P0 override fires; no further selection logic applies. #64 is also labeled P0 but is a design-level issue (agent probes filesystem); #106 is a concrete user-visible defect with a clear fix path.

**Alternative considered:** #73/#65/#67 (stale backlog). These remain frozen per MCI freeze. A P0 override (§3.1) takes precedence over MCI freeze resolution (§3.4).

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - Post-release assessment written (this document)
  - Encoding lag table updated (#28 closed, #106 added)
  - Review quality metrics recorded
- Deferred outputs committed: yes
  - #106 as next MCA (owner/branch/AC above)
  - I1 CI failure triage (deferred — pre-existing, not blocking)
  - MCI freeze maintained
  - Skill patch for test-surface scan (carried from v3.16.0 — still deferred)
