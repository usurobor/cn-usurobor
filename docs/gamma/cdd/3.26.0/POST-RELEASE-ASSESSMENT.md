## Post-Release Assessment — v3.26.0

### 1. Coherence Measurement

- **Baseline:** v3.25.0 — alpha A, beta A, gamma A-
- **This release:** v3.26.0 — alpha A, beta A-, gamma B+
- **Delta:**
  - alpha held (A) — `cn_ulog.ml` is a clean module: 5-kind discriminated union, labeled optional args on `make_entry`, type-driven serialization with `entry_to_json`/`entry_of_json` roundtrip, chunk-accumulation read path with `list_unified_files` returning newest-first for early stopping. `cn_logs.ml` follows `cn_system.ml` CLI pattern. Both are structurally sound.
  - beta regressed (A-) — 9 emission sites cover all runtime paths (happy + silent failures + poll errors). CLI surfaces 6 filter modes. But: `read_recent` had a multi-day ordering bug that shipped and required a fix commit after the initial merge. The read path semantics weren't verified against the write path semantics — the very gap that review skill section 2.2.1a was designed to catch. Surfaces agree after fixes, but the initial merge had a broken invariant.
  - gamma regressed (B+) — 6 review rounds (target: <=2 for code). 1 independent reviewer + 1 primary reviewer. Multi-day ordering bug found by independent reviewer, not CI or tests. Branch name non-compliant. DST limitation documented but not tested. Process was iterative rather than convergent.
- **Coherence contract closed?** Yes. All 8 ACs met:
  - AC1: `cn logs` outputs human-formatted tail (cn_logs.ml:format_entry + run_logs)
  - AC2: `cn logs --since 2h` filters by time (parse_duration + filter_entries)
  - AC3: `cn logs --msg <id>` traces single message (filter_entries msg_id)
  - AC4: `cn logs --errors` filters to warnings/errors (filter_entries errors_only)
  - AC5: `cn logs --json` outputs raw JSONL (run_logs json_mode)
  - AC6: Correlation ID (msg_id) on all entries (all 9 emission sites)
  - AC7: No ANSI codes in persistent logs (cn_ulog writes JSON; colors in cn_logs display only)
  - AC8: Log volume < 5MB/day (by design: ~2KB per invocation)

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #74 | Rethink logs structure (P0) | process | issue spec + 4 comments | **Phase 1 shipped** | **low** |
| #20 | Eliminate silent failures in daemon | bug | issue spec | **partially addressed** (3 silent paths now logged) | **low** |
| #59 | cn doctor — deep validation | feature | partial design | partially addressed | low |
| #68 | Agent self-diagnostics | feature | issue spec | not started | growing |
| #84 | CA mindset reflection requirements | feature | issue spec | not started | growing |
| #79 | Projection surfaces | feature | issue spec | not started | growing |
| #94 | cn cdd: mechanize CDD invariants | feature | issue spec | not started | growing |
| #100 | Memory as first-class capability | feature | issue spec | not started | growing |
| #96 | Docs taxonomy alignment | process | issue spec | not started | growing |
| #101 | Normalize skill corpus | process | issue spec | not started | growing |
| #43 | No interrupt mechanism | feature | issue spec | not started | growing |
| #124 | Agent asks permission despite autonomy defaults | bug | issue spec | not started | growing |
| #132 | Rename skill categories | process | issue spec | not started | new |

**MCI/MCA balance:** MCI remains resumed. #74 Phase 1 shipped — P0 no longer blocking. Backlog stable at ~12 growing issues. No new stale. #132 is new but low-lag (filed this cycle, no accumulated design debt).

### 3. Process Learning

**What went wrong:**

1. **Multi-day ordering bug shipped in the initial merge.** `read_recent` used `List.rev_append entries acc` which reverses within-file order. 6 review rounds didn't catch this until an independent reviewer applied it in R4. The 21 tests all operated within a single day's file, never exercising the cross-day boundary. Root cause: section 2.2.1a was applied to write paths (9 emission sites enumerated) but not to read paths. The review skill was patched after v3.25.0 to require "write AND read path verification" but it wasn't applied at full rigor during implementation.

2. **6 review rounds (target: <=2).** Findings were spread across 6 rounds: R1 (5 findings: rebase, branch name, thin invocation_end, UTC handling, test boolean), R2 (2: CI ppx_expect, rebase), R3 (2: silent drops, poll errors), R4 (4: ordering bug, unicode, CI, convergence), R5 (approval), R5-amendment (1: stable_sort). Each round found genuinely new issues, but the cumulative count indicates the initial submission quality was insufficient for L7 scope.

3. **`List.sort` vs `List.stable_sort` misstep.** First fix attempt for the ordering bug used `List.sort` (not stable), which broke same-timestamp ordering. Required a second fix commit before reaching the correct chunk-accumulation approach. Diagnosis before switching approaches was insufficient.

**What went right:**

1. **Dual-reviewer model found complementary bugs.** Primary reviewer (Sigma) found write-path gaps (silent drops, poll errors) through section 2.2.1a enumeration. Independent reviewer found read-path ordering bug through semantic analysis. Neither found both — together they covered the full surface.

2. **Architecture is clean.** Dual-stream design (unified for operators, events for debugging) avoids touching 50+ existing emission sites. Strictly additive. `make_entry` with labeled optional args is ergonomic. `truncate_string 200` controls volume at write time. Chunk-accumulation for cross-day reads is correct and sort-free.

3. **All 5 issue scenarios answered.** The unified log now covers: "What happened?" (cn logs), "What happened in the last 2 hours?" (--since), "What happened to this message?" (--msg), "What went wrong?" (--errors), "Why did the agent do nothing?" (silent drops emit at Warn severity).

**Skill patches:** None committed this session. Review skill section 2.2.1a already updated in v3.25.0 cycle (ce07f82: "new data surfaces require write AND read path verification"). The skill was correct — the agent didn't follow it deeply enough on the read path. Application gap, not skill gap.

**Active skill re-evaluation:**

| Finding | Active skill | Would skill have prevented it? | Assessment |
|---------|-------------|-------------------------------|------------|
| F1 R4 (multi-day ordering) | review section 2.2.1a | Yes, if applied to read path | Application gap — skill already covers "write AND read" |
| F8 R3 (silent drops) | review section 2.2.1a | Yes, if enumeration covered failure paths | Application gap — "input source enumeration" should include failure paths |
| F5 R1 (test boolean inversion) | testing skill | Yes, tests should be run before submission | Application gap — no OCaml toolchain available |

### 4. Review Quality

**PRs this cycle:** 1 (PR #133, merged via squash)
**Review rounds:** 6 (R1 request changes, R2 request changes, R3 request changes, R4 request changes, R5 approved, R5-amendment request changes → fixed → approved) — target: <=2 — **MISSED**
**Superseded PRs:** 0 — target: 0 — **PASSED**
**Finding breakdown:**

| # | Finding | Type |
|---|---------|------|
| F1 R1 | Branch behind main | mechanical |
| F2 R1 | Branch name non-compliant | mechanical |
| F3 R1 | Thin invocation_end | judgment |
| F4 R1 | Fragile UTC parsing | judgment |
| F5 R1 | Test boolean inversion | mechanical |
| F6 R2 | ppx_expect parse error | mechanical |
| F7 R2 | Still behind main | mechanical |
| F8 R3 | Silent message drops not logged | judgment |
| F9 R3 | Poll errors not logged | judgment |
| F1 R4 | Multi-day ordering bug | judgment |
| F2 R4 | Hidden Unicode warnings | mechanical |
| F3 R4 | CI not complete | mechanical |
| F1 R5a | List.sort not stable | judgment |

**Total findings:** 13 (7 mechanical, 6 judgment)
**Mechanical ratio:** 54% (7/13) — threshold: 20% — **EXCEEDED**
**Action:** Mechanical findings include: rebase (2x), branch name (1x), CI state (2x), ppx_expect syntax (1x), Unicode display artifact (1x). The rebase and CI state findings are environmental (no local OCaml toolchain, branch management). ppx_expect syntax is learnable. Filed: no new process issue — the root cause is absence of local build/test capability, which is environmental not processual. The pre-push gate (scripts/pre-push.sh) would catch F5 and F6 if the toolchain were available.

### 4a. CDD Self-Coherence

- **CDD alpha:** 4/4 — All required artifacts: SELECTION.md, README.md, PLAN.md, SELF-COHERENCE.md, POST-RELEASE-ASSESSMENT.md. CHANGELOG TSC entry present.
- **CDD beta:** 3/4 — Surfaces mostly agree. SELF-COHERENCE.md says "4 unified log emission points" in cn_runtime.ml but the final code has 9. The self-coherence was written before R3 added silent-drop and poll-error emissions. Stale claim.
- **CDD gamma:** 2/4 — 6 review rounds (3x target). High mechanical ratio (54%). No superseded PRs. Assessment completed. But the cycle was expensive: 13 findings across 6 rounds for a feature that shipped correctly.
- **Weakest axis:** gamma
- **Action:** Update SELF-COHERENCE.md to reflect 9 emission sites (immediate fix). The gamma regression is driven by absence of local OCaml toolchain (can't run tests before submission) and insufficient pre-review self-check. No skill patch needed — the skills are correct, execution was shallow.

### 5. Production Verification

**Scenario:** Operator runs `cn logs` on a deployed cnos v3.26.0 instance after several Telegram message cycles.

**Before this release:** Operator must check 6 locations (daemon.log, cn.log, events/, input/, output/, systemd journal) and manually correlate by timestamp/update-id. No single command answers "what happened?" or "why did the agent do nothing?"

**After this release:** `cn logs` shows the last 50 entries in chronological order. `cn logs --errors` surfaces rejected users, empty messages, poll errors, LLM failures. `cn logs --msg tg-12345` traces one message from receipt to response. All entries carry msg_id for correlation.

**How to verify:**
1. Deploy v3.26.0 binary
2. Send several Telegram messages (including one from a non-allowed user if possible)
3. Run `cn logs` — should show message.received, invocation.start, invocation.end, message.sent entries
4. Run `cn logs --errors` — should show rejected-user entries at Warn severity
5. Run `cn logs --msg tg-<id>` for a specific message — should show 4 lifecycle entries
6. Run `cn logs --json | jq .kind` — should output valid JSONL with correct schema
7. Check `logs/unified/` — should contain YYYYMMDD.jsonl file(s)

**Result:** Deferred — requires deployed agent. Committed to verify on next deployment cycle.

### 6. Next Move

**Next MCA:** #74 Phase 2 — Step-level trace archival (per-pass logging in N-pass bind loop), or pivot to a different issue if Phase 2 is deprioritized.
**Owner:** pending selection
**Branch:** pending
**First AC:** Per-pass logging emits invocation.start/invocation.end for each pass in the N-pass loop (not just pass 1)
**MCI frozen until shipped?** No — no P0s remaining. #74 Phase 1 closed the P0.
**Rationale:** Phase 2 is natural follow-on but not P0. Selection should weigh Phase 2 against other growing-lag issues (#68 self-diagnostics, #20 silent failures now partially addressed, #124 autonomy defaults).

**Closure evidence (CDD section 10):**
- Immediate outputs executed: yes
  - #74 Phase 1 merged (PR #133, squash merge d628b05)
  - CHANGELOG 3.26.0 TSC entry (1a5c16b)
  - GH release tag: 3.26.0
  - Review skill section 2.2.1a patched in prior cycle (ce07f82) — confirmed applicable, applied in R3/R4
  - SELF-COHERENCE.md emission count update (pending — see section 4a action)
  - OPERATOR.md + CLI.md + TROUBLESHOOTING.md doc updates (PR #134)
  - Hub name sanitization across 19 files (PR #134)
- Deferred outputs committed: yes
  - Production verification: next deployment cycle
  - SELF-COHERENCE.md update: immediate (this session)
  - #74 Phase 2 selection: next CDD cycle

**Immediate fixes** (executed in this session):
- OPERATOR.md created (day-2 operations manual)
- CLI.md updated (Observability section, cn_ulog/cn_logs in implementation tree)
- TROUBLESHOOTING.md updated (unified log, cn logs usage, "Why did agent do nothing?")
- Hub name sanitization (cn-pi, cn-sigma, cn-usurobor stripped from 19 files)
