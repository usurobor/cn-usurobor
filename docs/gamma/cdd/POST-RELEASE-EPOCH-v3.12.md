# Post-Release Epoch Assessment — v3.12.0–v3.12.2

Epoch: **Runtime Contract v1 + Authority Hardening**
Releases covered: v3.12.0 (#56, #57), v3.12.1 (#61), v3.12.2 (#63)
Date range: 2026-03-23

This is a retroactive epoch assessment per CDD §11, created under issue #85.
Individual per-release assessments were not performed at release time.
Option B (epoch grouping) was chosen per the #85 recommendation.

---

## 1. Coherence Measurement

### Baseline

v3.11.0 — α A+, β A+, γ A

Coherence note: N-pass merge + misplaced ops correction (#51). Structured output reverted (needs rework). γ at A (not A+) due to the revert — evolution stability took a minor hit.

### This epoch

| Version | C_Σ | α | β | γ | What shipped |
|---------|-----|---|---|---|---|
| v3.12.0 | A+ | A+ | A+ | A+ | Wake-up self-model contract (#56). CDD/review skill hardening (#57). |
| v3.12.1 | A+ | A+ | A+ | A+ | Daemon boot log declares config sources (#61). |
| v3.12.2 | A+ | A+ | A+ | A+ | Runtime Contract authoritative over stale history (#63). |

### Delta

- **α (PATTERN):** Held at A+. Runtime Contract introduced a new structural primitive (self_model / workspace / capabilities) that is internally consistent and type-safe.
- **β (RELATION):** Held at A+. All three releases tightened the relationship between agent context and runtime truth — the contract now replaces guesswork with declared state.
- **γ (EXIT/PROCESS):** Improved from A to A+. The v3.11.0 revert instability was absorbed. Three releases shipped in one day with consistent process. CDD/review skill hardening (#57) made the release process more explicit.

### Coherence contract closed?

The arc across this epoch had a single coherent thesis: **the agent should know itself through a declared contract, not through probing**. v3.12.0 introduced the contract, v3.12.1 extended it to operator-visible boot diagnostics, v3.12.2 established contract authority over stale conversation history.

Contract closed: **yes**. The Runtime Contract v1 exists, renders at wake, and is authoritative.

Residual gap: the contract is v1 (flat structure). The vertical self-model (#62) was already designed but not yet shipped — this became epoch 2's primary MCA.

---

## 2. Encoding Lag (as of v3.12.2)

| Issue | Title | Design | Impl | Lag |
|-------|-------|--------|------|-----|
| #62 | Runtime Contract v2 — vertical self-model | converged (PLAN-runtime-contract-v2.md) | not started | growing |
| #65 | Communication as first-class runtime contract | converged (issue spec) | not started | growing |
| #73 | Runtime Extensions — capability providers | converged (issue spec) | not started | growing |
| #67 | Network access as CN Shell capability | converged (issue spec, subsumed by #73) | not started | growing |
| #59 | cn doctor — deep self-model validation | partial design | partial impl (basic doctor exists) | low |
| #64 | P0: agent probes filesystem despite RC | bug report | not started | growing |

**MCI/MCA balance: Freeze MCI**

**Rationale:** 5 issues at growing lag, including a P0 bug (#64) that directly contradicts the epoch's thesis (agent should use contract, not probe). Designs are outpacing implementation. The system has a clear Runtime Contract v1 but multiple converged designs waiting for runtime enforcement.

---

## 3. Process Learning

### What went wrong

1. **No post-release assessment existed.** The post-release skill was not yet created during this epoch. Three releases shipped in rapid succession without any structured reflection. This is the exact failure mode CDD §11 was designed to prevent.
2. **v3.12.2 has no CHANGELOG entry.** The tag exists (`v3.12.2`) but no detailed release notes were written in CHANGELOG.md — only a TSC row (which is also missing). The release is discoverable only through `git log`.
3. **Velocity over assessment.** Three releases in one day. Each built coherently on the last, but no pause to assess encoding lag meant the growing design backlog was invisible.

### What went right

1. **Tight thematic coherence.** All three releases advanced a single thesis (Runtime Contract). No scope drift.
2. **CDD/review skill hardening (#57)** shipped alongside the primary feature (#56), strengthening the process that governs future releases.
3. **Type-safe design.** `secret_source` in v3.12.1 made secret leakage structurally impossible — pattern-level safety, not just policy.

### Skill patches

- Post-release skill created later in #78 (v3.14.1) — partially addresses the gap
- This epoch assessment (#85) adds the remaining process gate (AC 6)

---

## 4. Next Move (as decided at epoch boundary)

**Next MCA:** #62 — Runtime Contract v2 (vertical self-model)
**Owner:** sigma
**First AC:** CAA.md updated with wake-time architecture
**MCI frozen until shipped?** Yes — 5 issues at growing lag, P0 open
**Rationale:** #62 is the foundation for #73 (extensions), #65 (communication), and #59 (doctor). Shipping v2 unblocks the entire design backlog. #64 (filesystem probe P0) is a direct consequence of v1's limitations.

**Immediate fixes** (executed retroactively via #85):
- Process gate added to CDD §9: assessment required before next release tag
