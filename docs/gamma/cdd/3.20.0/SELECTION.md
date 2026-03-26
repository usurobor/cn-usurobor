## CDD Selection — Post v3.19.0

**Date:** 2026-03-26
**Inputs read:** CHANGELOG TSC, encoding lag table, v3.19.0 post-release assessment

---

### 1. Observation

| Signal | Value |
|--------|-------|
| Baseline | v3.18.0 — α A-, β B+, γ B- |
| This release | v3.19.0 — α A, β A-, γ B+ |
| Weakest axis | γ (B+) — process coherence |
| Mechanical ratio | 33% (improved from 57%, first cycle below 50% in 3 cycles) |
| Review rounds | 1 (target met for first time since v3.16.1) |
| MCI state | Frozen since v3.16.2 |
| Stale issues | 2 (#65 Communication, #67 Network) |
| Growing issues | 11 (#64, #68, #84, #79, #94, #100, #96, #74, #101, #20, #43) |
| Previous commitment | #113 AC8 (or close #113 if AC8 already met) |
| #67 state on GitHub | Closed as "not_planned" — design absorbed into #73 |

### 2. AC8 evaluation

The v3.19.0 assessment noted: "If AC8 is already met by existing extension architecture, close #113 and move to MCI freeze resolution."

**AC8:** "Extensions and future bundles/apps can sit above the package system without requiring package substrate redesign."

**Evidence:**
- Extensions sit inside packages: `packages/cnos.core/extensions/cnos.net.http/` exists
- cn_build handles extensions as a first-class source category (source_decl, copy_source, check)
- copy_tree (restore) copies all content including extensions — no category-specific logic needed
- Runtime Contract discovers extensions from packages, tracks originating package, surfaces in cognition + body

**Verdict:** AC8 is already met. The substrate supports extensions without redesign. #113 can be closed.

### 3. Selection rules applied

| Priority | Rule | Result |
|----------|------|--------|
| 1 | P0 override | No. #64 is P0 but known, mitigated since v3.12.0. |
| 2 | Operational infrastructure debt | No cycle-sized debt. Mechanical ratio improved to 33%. |
| 3 | Assessment commitment default | #113 AC8 was committed, but AC8 is already met. Assessment alternative fires: "close #113 and move to MCI freeze resolution." |
| 4 | MCI freeze check | **Yes.** #65 and #67 stale since v3.14.5. Freeze has held for 5 releases. With #113 closing, the substrate beneath the stale set is complete. MCI freeze rule requires next MCA from stale set. |
| 5 | Weakest axis | γ (B+). Process coherence. |
| 6 | Leverage | #67 (Network) was closed as not_planned — its design was absorbed into #73 (Runtime Extensions). #73 is open, Phase 1 shipped. Completing #73's remaining ACs (end-to-end extension execution, cnos.net.http proving the model) resolves the stale #67 gap through the superseding issue. Higher leverage than #65 (Communication) which has no partial implementation. |
| 7 | Dependency order | #73 remaining work depends on package substrate (now complete via #113) + extension architecture (shipped in #73 Phase 1). No remaining blockers. |

### 4. Selected gap

**Next MCA:** #73 — Runtime Extensions: end-to-end extension execution (cnos.net.http as proof)

**Note on #67:** #67 (Network access) is closed as "not_planned" on GitHub — its design was absorbed into #73. The MCI freeze references #67 as stale, but the work lives in #73. Completing #73 resolves the #67 gap. After #73 ships, #67 can be formally noted as superseded in the encoding lag table.

**Incoherence:** The extension architecture is type-complete and discovery-complete, but cnos.net.http has never executed end-to-end. The host binary exists but has not been validated through the full dispatch pipeline in a real agent session. #73's final AC ("cnos.net.http proves the model by shipping http_get as first extension") remains open.

**What fails if skipped:** Extensions remain a design-level abstraction. The open op registry dispatches to a subprocess that hasn't been validated end-to-end. The stale #67 gap persists through #73. MCI freeze continues indefinitely.

### 5. Mode

**MCA** — prove the extension model works end-to-end with network access as the reference implementation.

### 6. Immediate outputs

1. **Close #113** — all 8 ACs now met (AC3-AC7 shipped in v3.18.0+v3.19.0, AC1-AC2 pre-existing, AC8 already met).
2. **Add v3.19.0 CHANGELOG TSC entry** — already done (committed with assessment).

### 7. Deferred outputs

- #73 branch creation and bootstrap for remaining ACs
- End-to-end validation of cnos.net.http through full dispatch pipeline
- MCI freeze re-evaluation after #73 ships (#67 superseded, #65 re-evaluated)
