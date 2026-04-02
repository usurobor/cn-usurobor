## Post-Release Assessment — v3.28.0

### 1. Coherence Measurement

- **Baseline:** v3.27.1 — α A, β A, γ A
- **This release:** v3.28.0 — α A, β A, γ A-
- **Delta:**
  - α held (A) — `rejection_filename` is a clean deterministic function. `is_already_rejected` checks two directories with short-circuit evaluation. Self-send guard follows the existing `outbox.skip` trace pattern. No type ambiguity. Dead code (`get_branch_author`) removed.
  - β held (A) — rejection frontmatter now carries `from:` field. Trace events use existing `outbox.skip` event with new `reason_code:"self_send"`. Protocol FSM unchanged (transitions were already correct; the code now uses them properly). Rejection message content updated to match current pull-only protocol (R1 fix).
  - γ regressed (A-) — mechanical ratio 33% (2/6 findings). Stale clone wording in the rejection message template was a mechanical finding that should have been caught by pre-review self-check. Both mechanical findings (#2 and #6) were about the same stale content — one root cause, surfaced as two findings.
- **Coherence contract closed?** Yes. All 5 ACs met:
  - AC1: `is_already_rejected` checks outbox+sent before creating rejection (dedup)
  - AC2: `peer_name` used exclusively; `get_branch_author` removed
  - AC3: `to_name = name` guard in `send_thread` with trace event
  - AC4: 9 ppx_expect tests across all three invariants
  - AC5: Deterministic filename = at most 1 rejection per (peer, branch)

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #135 | Per-pass logging in N-pass bind loop (#74 Phase 2) | feature | issue spec | not started | growing |
| #141 | Peer sync: empty-content branches cause permanent limbo | bug | issue spec | not started | new |
| #142 | Peer sync: FidoNet parity (receipts, relay, crash recovery) | feature | issue spec | not started | new |
| #144 | Orphan rejection loop | bug | issue spec | **shipped** | **none** |
| #20 | Eliminate silent failures in daemon | bug | issue spec | partially addressed | low |
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
| #132 | Rename skill categories | process | issue spec | not started | growing |

**MCI/MCA balance:** MCI remains resumed. #144 shipped — P1 bug closed. Two new peer-sync issues (#141, #142) filed. Backlog stable at ~14 growing issues. No stale threshold crossed.

### 3. Process Learning

**What went wrong:**

1. **Stale clone wording in rejection template (R1 #2, #6).** The rejection message content referenced "cn-{recipient}-clone" and "cn outbox (uses clone automatically)" — concepts from the old clone-based send model. The pull-only protocol has been in place since the inbox skill rewrite, but the rejection message template was never updated. This is a content currency problem: when protocol changes, all user-facing message templates must be audited.

**What went right:**

1. **Deterministic filename fix is clean and minimal.** The core fix (replacing `make_thread_filename` with `rejection_filename`) is 3 lines of code that eliminate the entire amplification class. The dedup check (`is_already_rejected`) is 5 lines. Small, targeted MCA.

2. **Self-send guard follows existing patterns.** The `outbox.skip` trace event with `reason_code:"self_send"` matches the existing `no_recipient` and `unknown_peer` patterns exactly. No new event types or severity levels needed.

3. **Review converged in 2 rounds.** R1 found 6 findings (1 D-level), R2 approved after fix. Within code target of ≤2.

**Skill patches:** None needed. The mechanical finding was about stale content in a message template, not about a skill gap. No loaded skill covers "audit user-facing message templates for protocol currency."

**Active skill re-evaluation:**

| Finding | Active skill | Would skill have prevented it? | Assessment |
|---------|-------------|-------------------------------|------------|
| F2 R1 (stale clone wording) | ocaml | No — content currency is not an OCaml concern | Not applicable |
| F6 R1 (same stale wording) | ocaml | No — same as F2 | Not applicable |
| F1 R1 (no tip hash in dedup) | performance-reliability | Partially — §2.4 "find amplification paths" was applied; tip hash was a scope decision | Application was correct — (peer, branch) dedup stops the loop |
| F3 R1 (partial envelope) | ocaml | No — full envelope is a design scope decision | Scope boundary, not skill gap |
| F5 R1 (shallow self-send test) | testing | Partially — §2.6 "model/state-machine tests for stateful systems" suggests deeper testing | Application gap — guard is a 1-line comparison; integration test cost disproportionate |

### 4. Review Quality

**PRs this cycle:** 1 (PR #145, squash merge eccae01)
**Review rounds:** 2 (R1 request changes, R2 approved) — target: ≤2 — **PASSED**
**Superseded PRs:** 0 — target: 0 — **PASSED**
**Finding breakdown:**

| # | Finding | Type |
|---|---------|------|
| F1 R1 | Dedup key missing tip hash | judgment |
| F2 R1 | Stale clone wording in rejection hint | mechanical |
| F3 R1 | Partial envelope (only from: added) | judgment |
| F4 R1 | derive_name untested inline | judgment |
| F5 R1 | Shallow self-send tests | judgment |
| F6 R1 | Clone terminology persistence | mechanical |

**Total findings:** 6 (2 mechanical, 4 judgment)
**Mechanical ratio:** 33% (2/6) — threshold: 20% — **EXCEEDED**
**Action:** Both mechanical findings stem from one root cause: stale message template content not updated when protocol changed. This is a one-off content currency issue, not a recurring mechanical failure class. No process issue filed — the inbox skill v3 rewrite (shipped in same release) now documents pull-only protocol explicitly, making future audits straightforward.

### 4a. CDD Self-Coherence

- **CDD α:** 4/4 — Bootstrap (README.md), SELF-COHERENCE.md, 9 tests, POST-RELEASE-ASSESSMENT.md all present. CHANGELOG TSC row present.
- **CDD β:** 3/4 — Surfaces mostly agree. SELF-COHERENCE.md claims "8 tests" but the merged diff contains 9 tests (the clone-reference regression test was added in the R1 fix commit). Minor stale count.
- **CDD γ:** 3/4 — 2 review rounds (within target). Mechanical ratio 33% (above threshold). Single-session cycle. Immediate outputs executed. But the mechanical finding was avoidable with a content audit before submission.
- **Weakest axis:** β (stale test count in SELF-COHERENCE.md)
- **Action:** No skill patch. The SELF-COHERENCE.md test count is frozen in the version directory (§5.6). Future cycles: verify SELF-COHERENCE.md counts match final diff before review submission.

### 5. Production Verification

**Scenario:** Two peers (sigma, pi) where pi has an orphan branch pushed to sigma's clone. On `cn sync`, sigma should reject the orphan once, create exactly one rejection file, and on subsequent syncs skip the re-rejection.

**Before this release:** Each `cn sync` cycle (every ~5 min) creates a new timestamped rejection file for the same orphan branch. Over 2.5 hours, 30+ rejection branches accumulate. Self-addressed rejection messages produce "Unknown peer" errors.

**After this release:** First `cn sync` creates one deterministic rejection file (`rejected-pi-{slug}.md`). Subsequent syncs print "Already rejected" and skip. Self-addressed messages are caught by the self-send guard with a trace event.

**How to verify:**
1. Deploy v3.28.0 binary to both peers
2. Create an orphan branch on pi's clone (push a branch with no merge base)
3. Run `cn sync` on sigma — should see "Rejected orphan" once
4. Run `cn sync` on sigma again — should see "Already rejected" (dim output, no new file)
5. Check `threads/mail/outbox/` — should contain exactly one `rejected-pi-*.md` file
6. Check `cn logs --errors` — should show `outbox.skip` with `self_send` reason if applicable

**Result:** Deferred — requires deployed two-peer environment. Committed to verify on next deployment cycle.

## Cycle Iteration

### Triggers fired
- [ ] review rounds > 2 (actual: 2)
- [x] mechanical ratio > 20% (actual: 33%)
- [ ] avoidable tooling/environmental failure
- [ ] loaded skill failed to prevent a finding

### Friction log
Rejection message template contained stale clone-based protocol references ("cn-{recipient}-clone", "uses clone automatically"). This content predated the pull-only protocol transition but was never audited. The reviewer caught it as a D-level finding in R1.

### Root cause
One-off. The rejection message template was written during the clone-based era and never updated when the protocol changed. Not a recurring pattern — the template is now updated, and the inbox skill v3 documents pull-only protocol explicitly.

### Skill impact
No loaded skill covers "audit user-facing message templates for protocol currency." This is not a skill gap — it's a one-time content debt discovered during the fix. The inbox skill (not loaded as active) now documents the current protocol model.

### MCA
The rejection message content was updated in the same cycle (commit 8f85c57). No separate MCA needed — the fix is already shipped.

### Cycle level
L6 (system-safe execution)
Justification: Code is locally correct (L5 met cleanly — no compilation errors, type errors, or broken tests reached review). Cross-surface coherence mostly held (L6) — the stale message content was a β miss (content/protocol mismatch) but was caught and fixed within the review cycle, not after merge. L7 not applicable — this is a targeted bugfix, not a boundary move.

### 6. CDD Closeout

| Step | Artifact | Skills loaded | Decision |
|------|----------|--------------|----------|
| 11 Observe | git pull, grep verification | post-release | All 3 fixes present on main; VERSION=3.28.0; CHANGELOG entry present |
| 12 Assess | POST-RELEASE-ASSESSMENT.md | post-release | Assessment completed; §9.1 triggered (mechanical ratio 33%); cycle level L6 |
| 13 Close | immediate fixes listed below | post-release | Cycle closed; deferred outputs committed |

### 7. Next Move

**Next MCA:** #141 — Peer sync: empty-content branches cause permanent limbo
**Owner:** pending selection
**Branch:** pending
**First AC:** Empty-content inbound branches are detected and handled (skip or reject) instead of creating empty inbox files
**MCI frozen until shipped?** No — no P0s remaining; backlog stable
**Rationale:** #141 is a peer-sync bug in the same transport subsystem as #144. Fixing it while the transport code is fresh reduces context-switch cost. #135 (#74 Phase 2) is a natural follow-on but lower priority (enhancement, not bug). #142 (FidoNet parity) is larger scope — design-first.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - #144 shipped (PR #145, squash merge eccae01)
  - CHANGELOG 3.28.0 TSC entry present
  - Rejection message content updated to current protocol (8f85c57)
  - POST-RELEASE-ASSESSMENT.md written (this artifact)
  - Cycle iteration §9.1 present (mechanical ratio trigger)
- Deferred outputs committed: yes
  - Production verification: next deployment cycle with two-peer environment
  - #141 committed as next MCA candidate
  - SELF-COHERENCE.md test count frozen (§5.6); noted as β debt

**Immediate fixes** (executed in this session):
- POST-RELEASE-ASSESSMENT.md (this artifact)
- CHANGELOG TSC row verified (provisional scores hold: α A, β A, γ A-)
