## Post-Release Assessment — v3.25.0

### 1. Coherence Measurement

- **Baseline:** v3.24.0 — α A, β A, γ A-
- **This release:** v3.25.0 — α A, β A, γ A-
- **Delta:**
  - α held (A) — `Contract_redirect` is a first-class variant, not overloaded. `check_self_knowledge_path` is pure, one-place, exhaustive. Pattern matches in orchestrator are complete (3 sites). `is_self_knowledge_path` predicate derived from `check_self_knowledge_path` (no duplication).
  - β held (A) — all 5 observe surfaces closed: fs_read (interceptor), fs_list (child filter), fs_glob (result filter), git_grep (pathspec exclusion), git_status/diff/log (shared exclusions). RC authority declaration references structural enforcement. Orchestrator handles `Contract_redirect` correctly in both `effects_all_ok` (failure — blocks coordination) and `has_failures` (non-failure — no anti-confabulation warning). 10 tests verify positive, negative, and membrane-hole cases.
  - γ held (A-) — 2 review rounds (target: ≤2). R1 found 3 D-level membrane holes (fs_list children, fs_glob, git_grep). All closed in R2. Review divergence between Sigma (approved R1) and independent reviewer (request changes R1) — CLP'd, review skill §2.2.1a gate shipped as MCA. 1 superseded PR (#128 from prior cycle, not this one).
- **Coherence contract closed?** Yes. All 6 ACs met:
  - AC1: `fs_read cn.json` → `contract_redirect` (interceptor L165)
  - AC2: `fs_read *.package.json` → `contract_redirect` (suffix match L138)
  - AC3: `fs_list` self-knowledge dirs → `contract_redirect` (interceptor L222)
  - AC4: Legitimate reads unaffected (tests: `src/main.ml`, `docs/README.md`, `src/`)
  - AC5: Redirect reason includes RC pointer ("Runtime Contract (Identity/Cognition section)")
  - AC6: RC authority declaration references structural interception (L277-281)

### 2. Encoding Lag

| Issue | Title | Type | Design | Impl | Lag |
|-------|-------|------|--------|------|-----|
| #64 | P0: agent probes filesystem despite RC | bug | converged | **shipped** | **none** |
| #74 | Rethink logs structure (P0) | process | issue spec | not started | **growing** |
| #59 | cn doctor — deep validation | feature | partial design | partially addressed | **low** |
| #68 | Agent self-diagnostics | feature | issue spec | not started | **growing** |
| #84 | CA mindset reflection requirements | feature | issue spec | not started | **growing** |
| #79 | Projection surfaces | feature | issue spec | not started | **growing** |
| #94 | cn cdd: mechanize CDD invariants | feature | issue spec | not started | **growing** |
| #100 | Memory as first-class capability | feature | issue spec | not started | **growing** |
| #96 | Docs taxonomy alignment | process | issue spec | not started | **growing** |
| #101 | Normalize skill corpus | process | issue spec | not started | **growing** |
| #20 | Eliminate silent failures in daemon | bug | issue spec | not started | **growing** |
| #43 | No interrupt mechanism | feature | issue spec | not started | **growing** |
| #124 | Agent asks permission despite autonomy defaults | bug | issue spec | not started | **growing** |

**MCI/MCA balance:** MCI remains resumed. #64 shipped — last P0 closed. Zero P0s remaining. Backlog stable at ~12 issues, all growing. No new stale.

### 3. Process Learning

**What went wrong:**

1. **Sigma approved R1 with incomplete membrane.** Caught `fs_glob` as C ("defense-in-depth works") but missed `fs_list` child entries and `git_grep` entirely. Independent reviewer correctly found all three D-level holes. Root cause: §2.2.1a (input-source enumeration) wasn't applied at full rigor because the PLAN.md labeled the boundary "coherence, not security." CLP'd — gate shipped (review skill §2.2.1a now mandates security-level rigor for any structural closure claim).

2. **PR #128 superseded by #130.** Branch naming non-compliance from Claude Code. Same pattern as v3.24.0 (#128→#129). Not a recurring systemic issue — Claude Code doesn't always comply with CDD branch format, but the format is already documented.

**What went right:**

1. **Independent review caught what Sigma missed.** The multi-reviewer model worked exactly as designed — divergence surfaced real findings, not noise. The CLP analysis led to a concrete gate (§2.2.1a structural closure clause).

2. **R2 fixes were clean.** All 3 membrane holes closed with 3 new tests. The `is_self_knowledge_path` predicate derived from `check_self_knowledge_path` avoids duplication. Child entry filtering and glob result filtering are narrow — only self-knowledge paths are filtered, not entire categories.

3. **Post-release skill gained production verification step (§5.7).** Each release now earns a concrete kata demonstrating the boundary move. Shipped in this session as immediate output.

**Skill patches shipped this session:**
- Review skill §2.2.1a: structural closure claims trigger security-level input-source enumeration (ce07f82)
- Review skill §2.3.7: divergence analysis captured in durable adhoc thread (be5060d)
- Post-release skill §5.7: production verification step (984ad3c)
- SOUL §2.4: adhoc write triggers for divergences, errors, skill gaps, decisions (d18091794)

**Active skill re-evaluation:**

| Finding | Active skill | Would skill have prevented it? | Assessment |
|---------|-------------|-------------------------------|------------|
| F1-F3 R1 (membrane holes) | review §2.2.1a | Yes, if applied at full rigor | Application gap → patched to gate (structural closure = security rigor) |

### 4. Review Quality

**PRs this cycle:** 2 (PR #128 superseded, PR #130 merged)
**Review rounds:** 2 (R1 request changes from independent reviewer + Sigma amendment, R2 approved) — target: ≤2 — **PASSED**
**Superseded PRs:** 1 (PR #128, branch naming) — target: 0 — **MISSED**
**Finding breakdown:** 3 judgment (membrane holes) + 1 mechanical (CI state) + 1 mechanical (Unicode warnings) / 5 total
**Mechanical ratio:** 40% (2/5) — threshold: 20% — **EXCEEDED**
**Action:** Mechanical findings were CI-state timing (checks re-running after force push) and GitHub Unicode display warnings (verified not real bidi chars). Neither is automatable as a pre-submit check. No process issue filed — these are environmental artifacts, not author errors.

### 4a. CDD Self-Coherence

- **CDD α:** 4/4 — All required artifacts: SELECTION.md, README.md, PLAN.md, SELF-COHERENCE.md, POST-RELEASE-ASSESSMENT.md. CHANGELOG TSC entry added.
- **CDD β:** 4/4 — Surfaces agree. Self-coherence scores match assessment. R2 self-coherence updated to reflect all 5 surfaces.
- **CDD γ:** 3/4 — 2 review rounds (within target). 1 superseded PR. Review divergence found and resolved with MCA (§2.2.1a gate). Production verification step added to skill.
- **Weakest axis:** γ
- **Action:** Superseded PR pattern (branch naming from Claude Code) is the same as v3.24.0. Not yet systemic — 2 occurrences across 2 releases. Watch for 3rd occurrence before filing a process issue.

### 5. Production Verification

**Scenario:** Agent attempts to probe filesystem for self-knowledge (version, config) on a deployed cnos v3.25.0 instance.

**Before this release:** Agent issues `fs_read cn.json` → executor reads the file → returns content (or `file_not_found`) → agent gets version info from filesystem instead of Runtime Contract. Token waste, contract violation.

**After this release:** Agent issues `fs_read cn.json` → executor intercepts before I/O → returns `contract_redirect` with pointer to Runtime Contract. Agent also cannot discover `cn.json` via `fs_list "."`, `fs_glob "*.json"`, or `git_grep` — all surfaces filtered.

**How to verify:**
1. Deploy v3.25.0 binary to Pi (`cn update` or manual)
2. Trigger an agent wake with a prompt that would historically cause filesystem probing (e.g., "what version of cnos are you running?" without the RC in context)
3. Check receipts: `state/receipts/` should show `status=contract_redirect` for any `cn.json` probe
4. Check pass output: should contain `[REDIRECTED: this information is in your Runtime Contract]`
5. Negative check: `fs_read src/main.ml` should still return `status=ok`

**Result:** Deferred — requires Pi deployment. Committed to verify on next Pi update cycle.

### 6. Next Move

**Next MCA:** #74 — Rethink logs structure (P0)
**Owner:** pending selection
**Branch:** pending
**First AC:** TBD by selection
**MCI frozen until shipped?** No — freeze remains lifted. Zero P0s after #64 closure (if #74 is confirmed as P0).
**Rationale:** #74 is the only remaining issue tagged P0 in the encoding lag table. If confirmed, P0 override fires. If downgraded, selection falls to standard priority.

**Closure evidence (CDD §10):**
- Immediate outputs executed: yes
  - #64 closed (all 6 ACs met)
  - CHANGELOG 3.25.0 TSC entry (e8b6b86)
  - GH release created (https://github.com/usurobor/cnos/releases/tag/3.25.0)
  - Review skill §2.2.1a gate shipped (ce07f82)
  - Review skill §2.3.7 adhoc thread gate shipped (be5060d)
  - Post-release skill §5.7 production verification shipped (984ad3c)
  - SOUL §2.4 adhoc write triggers shipped (d18091794)
  - Review divergence adhoc thread captured (20260328-review-divergence-pr130.md)
- Deferred outputs committed: yes
  - Production verification on Pi: next Pi update cycle
  - Superseded PR monitoring: watch for 3rd occurrence
