## CDD Selection — Post v3.17.0

**Date:** 2026-03-25
**Inputs read:** CHANGELOG TSC, encoding lag table, CI status, v3.17.0 post-release assessment

---

### 1. Observation

| Signal | Value |
|--------|-------|
| Baseline | v3.16.2 — α A, β A, γ A- |
| This release | v3.17.0 — α A, β B+, γ C+ |
| Weakest axis | γ (C+) — process coherence |
| Mechanical ratio | 53% (two consecutive cycles) |
| Review rounds | 5 (target: ≤2) |
| MCI state | Frozen since v3.16.2 |
| Stale issues | 2 (#65 Communication, #67 Network) |
| Previous commitment | #73 Phase 2 (host binary + policy) |

### 2. Selection rules applied

| Priority | Rule | Result |
|----------|------|--------|
| 1 | P0 override | No. #64 is P0 but growing, not emergency. |
| 2 | Operational infrastructure debt | **Yes.** Two consecutive cycles at 53% mechanical ratio. γ regressed A- → C+. Same bug class persisted 3 review rounds. Skills used as post-hoc linter. |
| 3 | Last assessment's Next MCA | #73 Phase 2 — subprocess host binary + policy intersection. |
| 4 | Stale lag freezes new design | Yes. MCI frozen — #65, #67 stale since v3.14.5 epoch. |
| 5 | Weakest axis | γ (process). |
| 6 | Leverage | #73 Phase 2 — clears #73 lag, unblocks #67 (subsumed). |

### 3. Conflict resolution

Rules 2 and 3 conflict. Rule 2 (infrastructure debt) has higher priority than rule 3 (assessment commitment).

However, the infrastructure debt is a **process patch**, not a substantial MCA:

- Pre-push compile+test check (hook or script)
- Environment-independent test assertion patterns
- Call-site grep after signature changes

These are immediate outputs — executable in minutes, not a cycle-sized effort. CDD §2.0: "If no gap exists [that requires a substantial cycle], do not force a substantial cycle."

**Resolution:** Execute the process fix as an immediate output (same session or next session start). Honor the assessment commitment for the next substantial MCA.

### 4. Selected gap

**Next MCA:** #73 Phase 2 — Runtime Extensions: subprocess host binary + policy intersection

**Incoherence:** The extension architecture is type-complete but not runtime-complete. `cn_ext_host.ml` dispatches to a subprocess that doesn't exist. Three ACs remain partial (AC1, AC5, AC7) because no extension can actually execute.

**Why it matters:** #73 has been in the encoding lag table since v3.14.5. Phase 1 moved it from stale to low. Phase 2 moves it to none and unblocks #67 (Network, subsumed by #73).

**What fails if skipped:** Extensions remain a type-level abstraction. The open op registry works at the parsing and dispatch layer but produces `HostError "empty command"` at execution time. #67 stays stale. MCI freeze continues.

### 5. Mode

**MCA** — change the system. The design is converged. Implementation is the gap.

### 6. Immediate outputs (process debt)

Execute before or at the start of the next cycle:

1. **Pre-push check pattern:** `dune build && dune runtest` before every `git push` on substantial branches. Consider a git pre-push hook.
2. **Signature change protocol:** After changing any function signature, grep for all call sites (including test files) before committing.
3. **Environment-independent assertions:** Test error messages by prefix/class, not exact string. Apply to all new expect tests.

### 7. Deferred outputs

- #73 Phase 2 branch creation
- Bootstrap artifacts for Phase 2
- AC closure for AC1, AC5, AC7
