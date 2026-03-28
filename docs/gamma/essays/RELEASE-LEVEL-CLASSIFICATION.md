# Release-Level Classification

**Scope**: All 39 releases in the coherence grade table (v3.3.0–3.23.0)
**Rubric**: `docs/gamma/ENGINEERING-LEVELS.md` §8 (diff-level) + `docs/gamma/cdd/CDD.md` §9.1 (cycle-level caps)
**Date**: 2026-03-28

Related:
- docs/gamma/ENGINEERING-LEVELS.md
- docs/gamma/essays/ENGINEERING-LEVEL-ASSESSMENT.md
- docs/gamma/cdd/CDD.md §9.1

---

## Methodology

Each release is classified by **executed engineering level** — the minimum of its architectural scope and its execution quality ceiling.

- **Architectural scope** is assessed per ENGINEERING-LEVELS.md §8: L5 (local correctness), L6 (cross-surface coherence), L7 (boundary change / new primitive).
- **Execution quality ceiling** is assessed per CDD §9.1: if mechanical errors reached review (>20% ratio), cycle caps at L5. If cross-surface drift reached review, cycle caps at L6. The cycle level is the lowest miss.

Where mechanical ratio data is available in the coherence note, it is applied as a cap. Where absent, the architectural classification stands.

---

## Pass 1: Classification

| Version | C_Σ | Executed Level | Evidence |
|---------|-----|---------------|----------|
| v3.3.0  | A+  | **L7** | CN Shell creates new execution primitive: typed ops, two-pass execution, path sandbox, crash recovery |
| v3.3.1  | A+  | **L6** | Cross-surface alignment: canonical ops examples + stale path fixes + output discipline across agent instructions |
| v3.4.0  | A+  | **L7** | CAR introduces three-layer cognitive asset resolver + package system as new architectural layer |
| v3.5.0  | A+  | **L7** | "Everything cognitive is a package" — unifies the cognitive model under a single primitive |
| v3.5.1  | A+  | **L7** | Structured event stream + state projections create a new observability layer (traceability infrastructure) |
| v3.6.0  | A+  | **L7** | Output Plane Separation: new rendering layer with sink-safe typing, two-pass execution, CDD skill |
| v3.7.0  | A   | **L7** | Scheduler unification: one loop, two schedulers, 7-primitive maintenance engine (new scheduling boundary) |
| v3.7.2  | A   | **L6** | Trace gap closure + boot drain fix — hardening existing observability surface, no new boundary |
| v3.7.3  | A   | **L6** | Agent output discipline: detection + peer awareness + coordination across output surfaces |
| v3.8.0  | A+  | **L6** | Syscall surface coherence + CLI injection hardening — cross-surface safety within existing boundary |
| v3.9.0  | A+  | **L7** | COGNITIVE-SUBSTRATE spec + DUR skill contract + two-pass wiring — new specification layer |
| v3.9.1  | A+  | **L5** | Bug fix (execute never called) + sync — local correctness, no boundary change |
| v3.9.2  | A+  | **L6** | Block Pass A projection when Pass B fails — explicit failure-mode handling across pass boundary |
| v3.9.3  | A+  | **L6** | Anti-confabulation: makes op result signals and denial reasons explicit within existing op framework |
| v3.10.0 | A+  | **L7** | N-pass bind loop generalizes 2-pass → N-pass — removes the pass-count ceiling for all future work |
| v3.11.0 | A+  | **L6** | N-pass merge + misplaced ops correction — extends N-pass with safety mechanism; structured output reverted |
| v3.12.0 | A+  | **L7** | Runtime Contract replaces overloaded capabilities block — new self-model primitive |
| v3.12.1 | A+  | **L6** | Boot log declares config sources with type-safe secret_source — observability within existing contract |
| v3.13.0 | A-  | **L7** | CDD pipeline: per-step artifacts, self-coherence reports, frozen snapshots, bootstrap-first rule — new process primitive |
| v3.14.0 | A   | **L7** | Runtime Contract v2: vertical self-model (identity/cognition/body/medium) + zone classification — architecture evolution |
| v3.14.1 | A   | **L6** | CDD tightening: mandatory encoding lag, MCI freeze triggers — hardening existing process, no new boundary |
| v3.14.2 | A   | **L5** | Alpha bundle migration: moves docs into existing CDD bundle structure — organizational, follows pattern |
| v3.14.3 | A   | **L5** | Organize alpha docs: 18 specs → 8 bundles — applies established bundle pattern, no new primitive |
| v3.14.4 | A   | **L5** | Organize beta docs: 7 files → 4 bundles — same organizational pattern |
| v3.14.5 | A   | **L5** | Organize gamma docs: completes trilogy — same organizational pattern |
| v3.14.6 | A   | **L6** | Retroactive epoch assessments + §9.11 release gate — new gate mechanism ensures assessment coverage |
| v3.14.7 | A   | **L7** | Review skill: pre-flight validation, scope enumeration, quality metrics, finding taxonomy — changes how review works for all future cycles |
| v3.15.0 | A-  | **L5** | Version coherence chain sound but: 0 review rounds, self-merged with red CI, 3 post-fix commits — process failures cap execution |
| v3.15.1 | A   | **L6** | Cross-surface fix: re-exec after update + stamp-versions.sh + build/release gates — coherence across version surfaces |
| v3.15.2 | A   | **L6** | CDD canonical rewrite + review skill hardening — cross-surface process coherence |
| v3.16.0 | A   | **L5** | Self-update e2e is L6-scope but 63% mechanical ratio (no build step before review) caps cycle at L5 |
| v3.16.1 | A   | **L6** | Daemon retry + dead-letter: 4xx fail-fast, exponential backoff, offset advancement — systematic failure handling |
| v3.16.2 | A   | **L6** | Two-membrane projection hardened + configuration mode spec — cross-surface coherence across 5 review rounds |
| v3.17.0 | B+  | **L5** | Runtime Extensions Phase 1 is L7-scope but 53% mechanical ratio + 5 review rounds caps cycle at L5 |
| v3.18.0 | B+  | **L5** | Package Substrate AC3+AC4 is L6-scope but 57% mechanical ratio + superseded PR caps cycle at L5 |
| v3.19.0 | A-  | **L5** | Package Substrate AC5-AC7 has 33% mechanical ratio (>20% threshold) — caps at L5 despite clean 1-round delivery |
| v3.20.0 | B+  | **L6** | Runtime Extensions e2e: 0% mechanical, host command resolution with validation — system-safe completion of extension pipeline |
| v3.22.0 | A-  | **L6** | Version-drift detection as 8th maintenance primitive with drain guard — extends existing maintenance architecture |
| 3.23.0  | A-  | **L7** | Pre-push gate + CDD §9.1 cycle iteration framework + ENGINEERING-LEVELS.md — meta-level tooling that changes how all future cycles execute |

---

## Pass 2: Analysis

### 1. Level Distribution

| Level | Count | Percentage |
|-------|-------|------------|
| L5    | 10    | 26%        |
| L6    | 16    | 41%        |
| L7    | 13    | 33%        |

#### Shift over time

Split at v3.11.0 (release 16 of 39), roughly the boundary between the architecture-building phase and the hardening/process phase:

| Period | Releases | L5 | L6 | L7 |
|--------|----------|----|----|----|
| Early (v3.3.0–v3.10.0)  | 15 | 1 (7%)   | 6 (40%)  | 8 (53%)  |
| Late (v3.11.0–3.23.0)   | 24 | 9 (38%)  | 10 (42%) | 5 (21%)  |

The L7 rate dropped from 53% to 21%. The L5 rate rose from 7% to 38%. The L6 rate held steady (~40%). The system transitioned from boundary-creation to hardening, with mechanical-ratio caps suppressing the late-period level.

### 2. Grade–Level Correlation

| Grade | L5 | L6 | L7 |
|-------|----|----|-----|
| A+    | 1 (v3.9.1) | 5 | 8 |
| A     | 4 (v3.14.2–5, v3.16.0) | 7 | 2 |
| A-    | 3 (v3.15.0, v3.19.0) | 0 | 3 (v3.13.0, 3.23.0) |
| B+    | 2 (v3.17.0, v3.18.0) | 1 (v3.20.0) | 0 |

**Key findings:**

- **A+ at L5 exists** (v3.9.1): a perfectly executed bug fix is A+ in coherence but L5 in scope. Grade measures execution quality, not architectural ambition.
- **A- at L7 exists** (v3.13.0, 3.23.0): a boundary-changing release can have minor coherence gaps. Level measures what moved; grade measures how cleanly.
- **B+ never reaches L7**: when mechanical ratios are high enough to depress the grade, they also cap the cycle level. B+ is a leading indicator of L5-capped execution.
- **Grades and levels are orthogonal axes**: grade = coherence quality (how well), level = architectural scope (what moved). A release should be assessed on both.

### 3. Level Transitions

| Transition | Releases | Trigger |
|------------|----------|---------|
| **L7 plateau** | v3.3.0–v3.10.0 | Rapid architecture-building: CN Shell → CAR → packages → traceability → output plane → scheduler → cognitive substrate → N-pass. 8 of 15 releases are L7. |
| **L7 → L6 shift** | v3.11.0 | N-pass merge extends rather than creates. First non-L7 release after 3 consecutive L7s. |
| **L7 clusters** | v3.12.0, v3.13.0, v3.14.0 | Runtime Contract → CDD pipeline → RC v2. Three L7s in 5 releases during the process formalization phase. |
| **L5 plateau** | v3.14.2–v3.14.5 | Four consecutive L5 releases (doc reorganization). Organizationally necessary but architecturally flat. |
| **Mechanical cap era** | v3.15.0–v3.19.0 | Five of six releases capped at L5 by process failures (red CI, high mechanical ratios). The architecture attempted was L6–L7 but execution quality forced the cap. |
| **L7 recovery** | 3.23.0 | Pre-push gate + cycle iteration framework. Meta-level L7: the tooling created by this release directly addresses the mechanical caps that suppressed prior releases. |

The transitions tell a clear story: **build → harden → cap → recover**. The pre-push gate in 3.23.0 is the MCA for the entire mechanical-cap era.

### 4. Leverage Density

#### Highest leverage per scope

| Version | What moved | Why it's high-leverage |
|---------|-----------|----------------------|
| v3.10.0 | 2-pass → N-pass | Removes a hard ceiling; every future cognitive pass is free |
| v3.12.0 | Runtime Contract | Replaces an overloaded block with a typed self-model; every future self-reference resolves against it |
| v3.6.0  | Output Plane Separation | Typed rendering for all output; eliminates a class of sink-confusion bugs |
| 3.23.0  | Pre-push gate + §9.1 | Meta-leverage: prevents the mechanical-ratio caps that suppressed 5 prior releases |
| v3.14.7 | Review pre-flight + taxonomy | Changes review economics for every future cycle |

#### Over-weighted L7 attempts

| Version | Cost | Issue |
|---------|------|-------|
| v3.17.0 | 5 rounds, 53% mechanical, L7 architecture → L5 executed | The extension system required Phase 2 (v3.20.0) to deliver value. High design cost, discounted execution. |
| v3.13.0 | CDD pipeline (A- grade) | The process primitive is real but the docs-to-code concern from the assessment applies — process machinery without proportionate runtime leverage. |

### 5. Process Economics

| Mechanical Ratio | Review Rounds | Releases | Median Level |
|-----------------|---------------|----------|-------------|
| 0%              | 1             | v3.22.0  | L6          |
| 0%              | 3             | v3.20.0  | L6          |
| 12%             | 5             | v3.16.2  | L6          |
| 33%             | 1             | v3.19.0  | L5 (capped) |
| 53%             | 5             | v3.17.0  | L5 (capped) |
| 57%             | 3             | v3.18.0  | L5 (capped) |
| 63%             | 3             | v3.16.0  | L5 (capped) |

**Findings:**

- **Mechanical ratio is the dominant cap**. Every release with >20% mechanical ratio is L5 regardless of review rounds or architectural scope.
- **More review rounds do not produce higher levels**. v3.17.0 (5 rounds) is L5. v3.22.0 (1 round) is L6. Rounds compensate for errors; they don't create leverage.
- **Clean first submission is the strongest predictor of L6+**. Releases with 0% mechanical ratio consistently achieve L6 or above.
- **Review produces safer L6, not L7**. No release reached L7 through review iteration alone. L7 requires architectural intent before the cycle starts.

---

## Pass 3: Recommendations

### 3 Recommendations for Increasing L7 Density

1. **Enforce the pre-push gate universally.** The 3.23.0 pre-push gate (`dune build`, `dune runtest`, `cn build --check`, VERSION parity) directly prevents mechanical-ratio caps. Five releases (v3.15.0–v3.19.0) were capped at L5 by errors that this gate catches. Eliminating those caps alone would have raised 2–3 releases to their architectural level (L6/L7).

2. **Scope L7 releases smaller.** The early L7 streak (v3.3.0–v3.10.0) achieved 53% L7 density because each release shipped one boundary change with tight scope. Later L7 attempts (v3.17.0: extensions Phase 1) bundled too many ACs, drowning in mechanical errors. Target one boundary change per release; split multi-AC features into separate cycles with explicit phase gates.

3. **Add a pre-cycle leverage check.** Before starting a cycle, ask: "Does this change a boundary?" If yes, design for L7 with a clean scope. If no, execute clean L6 and move on. The current pattern shows releases accidentally mixing L7 architectural ambition with L5 execution discipline. Making the level target explicit at cycle start aligns scope to capability.

### 3 Anti-Patterns

1. **"L7 architecture, L5 execution."** v3.17.0 (53% mechanical), v3.18.0 (57%), v3.16.0 (63%). Ambitious boundary changes shipped with mechanical errors that cap the cycle level. This is the most wasteful pattern: high design cost, L5-discounted outcome. The architecture is real but the level credit is not earned.

2. **"Doc org as filler."** v3.14.2 through v3.14.5 — four consecutive L5 releases doing organizational work within an established bundle pattern. Individually clean (all A-graded), but as a sequence they create an L5 plateau that delays architectural progress. Batch organizational work into fewer releases or interleave with L6/L7 cycles.

3. **"Review as correction, not prevention."** Releases with 5 review rounds (v3.16.2, v3.17.0) use review to discover and fix errors rather than preventing them before submission. This is expensive (process cost) and ineffective (doesn't raise level — only prevents regression). The pre-push gate is the structural fix. Complement it with: build before every `git push`, not just before merge.

### Prediction: Next 10 Releases

Given the trajectory — L7-dominant early → L5-capped late → 3.23.0 showing meta-level L7 recovery with the pre-push gate — the next 10 releases should target:

| Level | Target Count | Rationale |
|-------|-------------|-----------|
| L7    | 2           | The pre-push gate and cycle iteration framework are now in place. One L7 per 5 releases is sustainable without over-abstraction. |
| L6    | 6           | With mechanical caps eliminated by the gate, L6 becomes the natural baseline for well-executed feature and hardening work. |
| L5    | 2           | Maintenance, organizational, and bug-fix releases. Acceptable when scope is genuinely local. |

**Distribution shift**: L5 should drop from 38% → 20%, L6 should hold at ~40% → 60%, L7 should recover from 21% → 20%. The key change is not more L7 — it's fewer involuntary L5s caused by mechanical caps. The pre-push gate is the mechanism that makes this shift possible.

If the gate holds and scope discipline improves, the realistic floor is **0 involuntary L5 caps in 10 releases** — every L5 should be a deliberate choice (maintenance/org), not an execution failure.

---

## Summary

The release history shows three distinct eras:

1. **Architecture era** (v3.3.0–v3.10.0): 53% L7. Rapid boundary creation. High leverage.
2. **Mechanical cap era** (v3.11.0–v3.19.0): 38% L5, most capped by execution quality. Architecture ambition exceeded execution discipline.
3. **Recovery** (v3.20.0–3.23.0): Meta-level tooling (pre-push gate, cycle iteration) addresses the root cause. 3.23.0 is L7 precisely because it eliminates the cap mechanism.

The single highest-leverage finding: **mechanical ratio is the binding constraint on level, not architectural ambition.** Fix the gate, and the levels take care of themselves.
