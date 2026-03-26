## CDD Selection — Post v3.18.0

**Date:** 2026-03-26
**Inputs read:** CHANGELOG TSC, encoding lag table, doctor/status, v3.18.0 post-release assessment

---

### 1. Observation

| Signal | Value |
|--------|-------|
| Baseline | v3.17.0 — α A, β B+, γ C+ |
| This release | v3.18.0 — α A-, β B+, γ B- |
| Weakest axis | γ (B-) — process coherence |
| Mechanical ratio | 57% (third consecutive cycle above 50%) |
| Review rounds | 3 (target: ≤2) |
| MCI state | Frozen since v3.16.2 |
| Stale issues | 2 (#65 Communication, #67 Network) |
| Growing issues | 11 (#64, #68, #84, #79, #94, #100, #96, #74, #101, #20, #43) |
| Previous commitment | #113 AC5-AC7 (integrity, doctor depth, Runtime Contract truth) |

### 2. Selection rules applied

| Priority | Rule | Result |
|----------|------|--------|
| 1 | P0 override | No. #64 is P0 but known and mitigated (root causes 1-2 fixed/mitigated in v3.12.0). Was visible at prior assessments; assessment committed different MCA. Per new-vs-known rule: assessment governs. |
| 2 | Operational infrastructure debt | No cycle-sized debt. 57% mechanical ratio persists but root cause is environmental (no OCaml toolchain). Not actionable as a cycle — same finding as v3.17.0 selection. |
| 3 | Assessment commitment default | **Yes.** v3.18.0 assessment committed #113 AC5-AC7 as next MCA. No stronger override fired. |
| 4 | MCI freeze check | Tension. #65, #67 remain stale since v3.14.5. #113 is not itself in the stale set. However, #73 Phase 2 was absorbed into #113 (per #113 body), and #67 is subsumed by #73. Completing #113 strengthens the package substrate that #67's implementation requires. Freeze holds — no new design work outside #113. |
| 5 | Weakest axis | γ (B-). Process coherence. #113 AC5 (integrity) and AC6 (doctor depth) are testable, verifiable deliverables — they improve γ by producing measurable verification artifacts. |
| 6 | Leverage | #113 AC5-AC7 moves #113 from low to near-closed. AC6 (doctor) partially addresses #59 (cn doctor hardening). AC7 (Runtime Contract truth) connects to #73 Phase 2 closure. |

### 3. Conflict resolution

No conflict. Rules 1-2 do not fire. Rule 3 (assessment commitment) selects #113 AC5-AC7 uncontested.

MCI freeze tension is acknowledged: #113 is not itself stale, but it is the substrate beneath the stale issues. The freeze permits this — the alternative (selecting #65 or #67 directly) would require building on an incomplete package substrate. Dependency order (§3.8) supports completing the substrate first.

### 4. Selected gap

**Next MCA:** #113 AC5-AC7 — Package System Substrate: integrity, doctor depth, Runtime Contract truth

**Incoherence:** The package system has honest lockfiles and path-consistent restore (AC3+AC4 shipped in v3.18.0), but integrity is modeled without enforcement, doctor checks presence without consistency, and Runtime Contract package truth is incomplete.

**ACs in scope:**
- **AC5** — Integrity is generated and verified. Lock entries carry integrity hashes; restore verifies them.
- **AC6** — Doctor validates package-system truth, not just file presence. desired vs resolved, installed vs lockfile, metadata validity, integrity.
- **AC7** — Runtime wake-time package truth comes from local installed state, surfaced through Runtime Contract.

**What fails if skipped:** Packages install without verification. Doctor reports "healthy" when lockfile disagrees with installed state. Runtime Contract doesn't surface package truth. The substrate remains half-coherent — everything above it (extensions, future bundles) inherits the ambiguity.

### 5. Mode

**MCA** — change the system. Design is converged (#113 spec + PACKAGE-SYSTEM.md). Implementation is the gap.

### 6. Immediate outputs (process debt)

Execute before or at the start of the next cycle:

1. **CHANGELOG v3.18.0 TSC entry** — already executed (committed with post-release assessment).
2. **CHANGELOG v3.17.0 TSC correction** — already executed (assessment governs per CDD §Step 2).

No new process patches needed. The mechanical ratio root cause (no OCaml toolchain) remains environmental debt — not actionable as an immediate output.

### 7. Deferred outputs

- #113 AC5-AC7 branch creation and bootstrap
- AC closure for integrity, doctor depth, Runtime Contract truth
- MCI freeze re-evaluation after #113 ships (does completing the substrate unblock #67?)
