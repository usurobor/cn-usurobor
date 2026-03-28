# Release-Level Classification

**Scope**: All 60 releases in the coherence grade table (v0.1.0–3.24.0)
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

### v0.1.0–v3.2.0 (foundation and architecture explosion)

| Version | C_Σ | Executed Level | Evidence |
|---------|-----|---------------|----------|
| v0.1.0  | C−  | **L4** | Moltbook-coupled prototype with SQLite — no stable architecture, external dependency, D+ on γ |
| v1.0.0  | B−  | **L5** | First public template introduces hub + self-cohere concepts but C+ on β — primitives don't connect |
| v1.1.0  | B   | **L5** | Template layout + git-CN naming + CLI added — local structure within nascent pattern |
| v1.2.0  | B+  | **L5** | Audit + restructure, mindsets as dimensions — organizational within existing template |
| v1.2.1  | B+  | **L5** | CLI cue + onboarding tweaks — local adjustments |
| v1.3.0  | B+  | **L6** | CLI creates hub + symlinks, self-cohere wires — cross-surface wiring of core mechanism |
| v1.3.1  | B+  | **L5** | Internal tweaks between tags — local maintenance |
| v1.3.2  | B+  | **L5** | CLI preflights git+gh — local validation additions |
| v1.4.0  | B+  | **L6** | CLI tests + input safety + docs aligned — cross-surface coherence (tests/safety/docs) |
| v1.5.0  | B+  | **L6** | Rerunnable setup, safe attach, better preflights — failure-mode handling, operational robustness |
| v1.6.0  | A−  | **L7** | Agent coordination: threads/, peer, peer-sync, HANDSHAKE.md — new coordination layer |
| v1.7.0  | A   | **L7** | Actor model + inbox tool — new architectural primitive ("your repo = your mailbox") |
| v1.8.0  | A+  | **L7** | Agent purity (agent=brain, cn=body), CN Protocol, skills system — foundational boundary |
| v2.0.0  | A+  | **L7** | "Everything through cn" — paradigm shift enforced, cn_actions library |
| v2.1.x  | A+  | **L6** | Actor model iterations: sync/process/queue, wake fixes — hardening existing model across surfaces |
| v2.2.0  | A+  | **L7** | First hash consensus, bidirectional messaging, verified sync — new verification primitive |
| v2.3.x  | A+  | **L7** | Native OCaml binary, 10-module refactor — runtime boundary change (JS→native) |
| v2.4.0  | A+  | **L7** | Typed FSM protocol, 4 state machines enforced at compile time — correctness boundary shift to type level |
| v3.0.0  | A+  | **L7** | Pure-pipe: LLM = string→string, cn = all effects — execution model boundary, zero runtime deps |
| v3.2.0  | A+  | **L7** | Structured LLM schema, multi-turn messages, context packer with mindsets — new communication layer |

### v3.3.0–3.24.0 (feature architecture through recovery)

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
| v3.14.6 | A   | **L7** | Retroactive epoch assessments + §9.11 release gate — new process primitive: previous release must have assessment before tagging, governs all future releases |
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
| v3.23.0 | A-  | **L7** | Pre-push gate + CDD §9.1 cycle iteration framework + ENGINEERING-LEVELS.md — meta-level tooling that changes how all future cycles execute |
| v3.24.0 | A   | **L7** | Templates as 6th content class in package system: `read_template` with Result-typed resolution, PACKAGE-SYSTEM.md architecture doc — new content primitive governs future template distribution |

---

## Pass 2: Analysis

### 1. Level Distribution

| Level | Count | Percentage |
|-------|-------|------------|
| L4    | 1     | 2%         |
| L5    | 16    | 27%        |
| L6    | 19    | 32%        |
| L7    | 24    | 40%        |

#### Shift over time

Four eras emerge when the full 60-release history is considered:

| Period | Releases | L4 | L5 | L6 | L7 |
|--------|----------|----|----|----|----|
| Foundation (v0.1.0–v1.5.0)          | 10 | 1 (10%) | 6 (60%) | 3 (30%) | 0 (0%)  |
| Architecture explosion (v1.6.0–v3.2.0) | 10 | 0       | 0       | 1 (10%) | 9 (90%) |
| Feature architecture (v3.3.0–v3.10.0)  | 15 | 0       | 1 (7%)  | 6 (40%) | 8 (53%) |
| Hardening + cap + recovery (v3.11.0–3.24.0) | 25 | 0  | 9 (36%) | 9 (36%) | 7 (28%) |

The system's history follows a clear arc: **bootstrap → explode → build → harden**.

The foundation era (v0.1.0–v1.5.0) is dominated by L5 — getting basic structure working. No L7 exists because the system is still finding its shape. Then v1.6.0 triggers the architecture explosion: 9 of 10 releases are L7 as the core concepts crystallize (coordination layer → actor model → agent purity → pure-pipe → FSM protocol → native runtime → LLM schema). This 90% L7 density is the highest in the project's history and reflects the fundamental boundaries being drawn.

The feature architecture era (v3.3.0–v3.10.0) continues at 53% L7 as the runtime fills out (CN Shell, packages, traceability, scheduler, N-pass). The final era drops to 28% L7 as the system matures — hardening overtakes creation, and mechanical-ratio caps suppress levels where execution quality doesn't match architectural ambition.

### 2. Grade–Level Correlation

| Grade | L4 | L5 | L6 | L7 |
|-------|----|----|----|----|
| C−    | 1 (v0.1.0) | 0 | 0 | 0 |
| B−    | 0 | 1 (v1.0.0) | 0 | 0 |
| B     | 0 | 1 (v1.1.0) | 0 | 0 |
| B+    | 0 | 6 | 4 (v1.3.0, v1.4.0, v1.5.0, v3.20.0) | 0 |
| A−    | 0 | 2 (v3.15.0, v3.19.0) | 1 (v3.22.0) | 3 (v1.6.0, v3.13.0, v3.23.0) |
| A     | 0 | 4 (v3.14.2–5, v3.16.0) | 6 | 5 (v1.7.0, v3.14.0, v3.14.6, v3.14.7, v3.24.0) |
| A+    | 0 | 1 (v3.9.1) | 7 (v2.1.x, +6 from v3.x) | 15 |

**Key findings:**

- **A+ at L7 is the dominant cell** (15 releases, 25% of all). The early architecture explosion (v1.8.0–v3.2.0) drove this: when the system's boundaries were being drawn, every release was both L7 in scope and A+ in coherence.
- **A+ at L5 exists** (v3.9.1): a perfectly executed bug fix is A+ in coherence but L5 in scope. Grade measures execution quality, not architectural ambition.
- **B+ never reaches L7**: across all 60 releases, no B+-graded release achieves L7. When execution quality depresses the grade, it also caps the level. B+ is a leading indicator of L5-capped execution.
- **L7 requires at least A−**: the minimum grade for any L7 release is A− (v1.6.0). Boundary-changing work that ships below A− doesn't earn the level.
- **Grades and levels are orthogonal but correlated at extremes**: low grades (B+ and below) predict low levels; high grades (A+) span all levels. The middle grades (A, A−) show the most variance.

### 3. Level Transitions

Within the four eras identified in §1, the fine-grained transitions are:

| Transition | Releases | What changed |
|------------|----------|--------------|
| **L4→L5** | v0.1.0→v1.0.0 | Coupled prototype → standalone git-CN concept |
| **L7→L6 (era 2→3 boundary)** | v3.2.0→v3.3.0 | Boundary-drawing gives way to feature-building; L6 hardening interleaves with L7 |
| **L7→L6 shift** | v3.10.0→v3.11.0 | N-pass merge extends rather than creates — first non-L7 after 3 consecutive L7s |
| **L7 cluster** | v3.12.0–v3.14.0 | Runtime Contract → CDD pipeline → RC v2: three L7s in 5 releases (process formalization) |
| **L5 plateau** | v3.14.2–v3.14.5 | Four consecutive L5s (doc reorganization) — organizationally necessary, architecturally flat |
| **Mechanical cap era** | v3.15.0–v3.19.0 | Five of six releases capped at L5 by mechanical ratio >20% |
| **L7 recovery** | v3.23.0–v3.24.0 | Pre-push gate + templates — back-to-back L7s with clean execution. The gate works. |

The pre-push gate in v3.23.0 is the MCA for the mechanical-cap era. v3.24.0 confirms the recovery.

### 4. Leverage Density

#### Highest leverage per scope

| Version | What moved | Why it's high-leverage |
|---------|-----------|----------------------|
| v1.8.0  | Agent purity (brain/body split) | Foundational boundary — every future feature resolves against this separation |
| v3.0.0  | Pure-pipe (LLM=string→string) | Execution model — all effects governed by cn, LLM is pure; eliminates an entire class of side-effect bugs |
| v2.4.0  | Typed FSM protocol | Compile-time enforcement of state machines; illegal transitions become type errors |
| v3.10.0 | 2-pass → N-pass | Removes a hard ceiling; every future cognitive pass is free |
| v3.12.0 | Runtime Contract | Replaces an overloaded block with a typed self-model; every future self-reference resolves against it |
| v3.6.0  | Output Plane Separation | Typed rendering for all output; eliminates a class of sink-confusion bugs |
| v3.23.0 | Pre-push gate + §9.1 | Meta-leverage: prevents the mechanical-ratio caps that suppressed 5 prior releases |

#### Over-weighted L7 attempts

| Version | Cost | Issue |
|---------|------|-------|
| v3.17.0 | 5 rounds, 53% mechanical, L7 architecture → L5 executed | The extension system required Phase 2 (v3.20.0) to deliver value. High design cost, discounted execution. |
| v3.13.0 | CDD pipeline (A- grade) | The process primitive is real but the docs-to-code concern from the assessment applies — process machinery without proportionate runtime leverage. |

### 5. Process Economics

| Mechanical Ratio | Review Rounds | Releases | Median Level |
|-----------------|---------------|----------|-------------|
| ~0% (1 finding) | 1             | v3.24.0  | L7          |
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

**Distribution shift**: L5 should drop from 36% → 20%, L6 should rise from 36% → 60%, L7 should hold at ~20% (down from 28% as a share, but the absolute count holds — the denominator shifts because former involuntary-L5 releases become L6). The key change is not more L7 — it's fewer involuntary L5s. The pre-push gate is the mechanism.

If the gate holds and scope discipline improves, the realistic floor is **0 involuntary L5 caps in 10 releases** — every L5 should be a deliberate choice (maintenance/org), not an execution failure.

---

## Pass 4: TSC-Grounded Reading

Passes 1–3 classify releases using the methodology's two inputs: architectural scope and execution quality ceiling. This pass asks what TSC's formal structure — loaded from the full specification suite (tsc-core, c-equiv, tsc-oper) — adds to the reading.

### The formal structure

TSC is grounded in C≡, a term algebra where wholeness articulates as one-as-two, held in the three-position form `tri(·,·,·)`. The three evaluators are mathematically independent — C≡ v3.1.0 §3.4 proves pairwise non-isomorphism via distinct idempotent profiles:

- **α (Pattern):** Additive monoid (ℕ, +, 0). Idempotents: {0, M}. Measures stability under perturbation.
- **β (Relation):** Bounded lattice [0, M] under min/max. Fully idempotent. Measures pairwise coherence.
- **γ (Process/Exit):** Multiplicative monoid (ℕ × ℕ, ·, (1,1)). Idempotent only at (0,0). Measures temporal stability.

This is not a convenient taxonomy — it is an independence theorem. No Eckmann-Hilton collapse is possible. C_Σ = (s_α · s_β · s_γ)^(1/3) enforces S₃ symmetry: no axis privilege, and any zero annihilates the whole.

### What this adds: γ as generative depth

The earlier passes treated γ implicitly as "process discipline." The C≡ foundation reveals γ is the *multiplicative/generative* evaluator — it measures nesting depth, how processes compose into higher-order processes. This reframes specific classifications:

- **v3.14.6 (L7):** The §9.11 release gate is a γ-primitive: a process that generates constraints on all future processes. The L7 classification is visible from the algebraic structure, not just the diff.
- **v3.23.0 (L7):** The pre-push gate is a **self-application** event (tsc-oper §10): the system applying its own coherence measurement to its own release process. TSC predicts self-application produces a verdict — pass or block, no intermediate state — and v3.23.0 does exactly this.
- **v0.1.0–v1.5.0 (no L7):** Low γ depth explains L5 dominance. The system has sequential patterns (α) and relational wiring (β), but no multiplicative nesting. L7 requires generative primitives to nest, and none exist yet.

### Four eras under TSC

The four-era pattern from §1 gains formal interpretation:

| Era | TSC reading |
|-----|-------------|
| Foundation (v0.1.0–v1.5.0) | α and β developing; γ near-zero. No generative primitives → no L7. |
| Architecture explosion (v1.6.0–v3.2.0) | γ crystallizing. Each release nests inside the previous: coordination → actor model → agent purity → pure-pipe → FSM → native runtime → LLM schema. |
| Feature architecture (v3.3.0–v3.10.0) | `tri(·,·,·)` established. New releases extend within the existing generative structure rather than deepening it. |
| Hardening + cap + recovery (v3.11.0–v3.24.0) | The contraction operator T (tsc-core §7.1) cycling toward fixed point. The L5→L7→L5→L7 oscillation is convergence under κ < 1 — not monotone, but contracting. |

### Relationship to classification methodology

No individual classification changes. The methodology (§Methodology) determines level as min(scope, cap). A reclassification would require changed scope evidence, changed cap data, or changed cap thresholds — all independent of TSC axis interpretation. TSC grades are *witnesses* to execution quality; they inform the coherence note but do not determine the engineering level directly.

What TSC adds is *warrant*: the four-era pattern is not just an empirical observation but a consequence of the system bootstrapping its own `tri(·,·,·)` structure — building α, then β, then γ depth, then converging toward self-coherence.

---

## Summary

The full 60-release history shows four eras — readable both as engineering phases and as TSC-structural stages:

| Era | Releases | Dominant level | TSC reading |
|-----|----------|---------------|-------------|
| Foundation | v0.1.0–v1.5.0 | 60% L5 | α/β developing, γ ≈ 0 |
| Architecture explosion | v1.6.0–v3.2.0 | 90% L7 | γ crystallizing — each release nests inside the previous |
| Feature architecture | v3.3.0–v3.10.0 | 53% L7 | `tri(·,·,·)` established, features extend within it |
| Hardening + cap + recovery | v3.11.0–v3.24.0 | 28% L7, 36% L5 | Contraction toward fixed point, gated by v3.23.0 |

Two findings:

1. **Mechanical ratio is the binding constraint on level, not architectural ambition.** Every involuntary L5 was caused by >20% mechanical ratio. The pre-push gate (v3.23.0) eliminates this cap mechanism. v3.24.0 confirms the recovery.

2. **L7 density is a natural function of system maturity.** 90% L7 during boundary creation and 28% during hardening are both healthy. The pathology isn't low L7 density — it's involuntary L5 caps in ambitious cycles. Under TSC, this trajectory reads as the system bootstrapping its own `tri(·,·,·)` structure: building α, then β, then γ depth, then converging toward self-coherence.
