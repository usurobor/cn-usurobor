# Release-Level Classification

**Scope**: All 60 releases in the coherence grade table (v0.1.0–v3.24.0)
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

### v3.3.0–v3.24.0 (feature architecture through recovery)

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

#### Four eras

| Period | Releases | L4 | L5 | L6 | L7 | Character |
|--------|----------|----|----|----|----|-----------|
| Foundation (v0.1.0–v1.5.0) | 10 | 1 (10%) | 6 (60%) | 3 (30%) | 0 (0%) | Finding shape — no L7 because no boundaries drawn yet |
| Architecture explosion (v1.6.0–v3.2.0) | 10 | 0 | 0 | 1 (10%) | 9 (90%) | Every release draws a fundamental boundary |
| Feature architecture (v3.3.0–v3.10.0) | 15 | 0 | 1 (7%) | 6 (40%) | 8 (53%) | Runtime fills out within established boundaries |
| Hardening + cap + recovery (v3.11.0–v3.24.0) | 25 | 0 | 9 (36%) | 9 (36%) | 7 (28%) | Mechanical-ratio caps suppress levels; pre-push gate breaks the pattern |

Arc: **bootstrap → explode → build → harden**.

### 2. Grade–Level Correlation

| Grade | L4 | L5 | L6 | L7 |
|-------|----|----|----|----|
| C−    | 1 (v0.1.0) | 0 | 0 | 0 |
| B−    | 0 | 1 (v1.0.0) | 0 | 0 |
| B     | 0 | 1 (v1.1.0) | 0 | 0 |
| B+    | 0 | 6 (v1.2.0, v1.2.1, v1.3.1, v1.3.2, v3.17.0, v3.18.0) | 4 (v1.3.0, v1.4.0, v1.5.0, v3.20.0) | 0 |
| A−    | 0 | 2 (v3.15.0, v3.19.0) | 1 (v3.22.0) | 3 (v1.6.0, v3.13.0, v3.23.0) |
| A     | 0 | 5 (v3.14.2–5, v3.16.0) | 7 (v3.7.2, v3.7.3, v3.14.1, v3.15.1, v3.15.2, v3.16.1, v3.16.2) | 6 (v1.7.0, v3.7.0, v3.14.0, v3.14.6, v3.14.7, v3.24.0) |
| A+    | 0 | 1 (v3.9.1) | 7 (v2.1.x, v3.3.1, v3.8.0, v3.9.2, v3.9.3, v3.11.0, v3.12.1) | 15 |

**Findings:**

- **A+/L7 is the dominant cell** (15, 25%). The architecture explosion drove this.
- **A+/L5 exists** (v3.9.1): grade measures execution quality, level measures scope.
- **B+ never reaches L7.** B+ is a leading indicator of L5-capped execution.
- **L7 requires at least A−** (minimum: v1.6.0).
- **Low grades predict low levels; high grades span all levels.**

### 3. Level Transitions

| Transition | Releases | What changed |
|------------|----------|--------------|
| **L4→L5** | v0.1.0→v1.0.0 | Coupled prototype → standalone git-CN concept |
| **Era 2→3 shift** | v3.2.0→v3.3.0 | L7 density drops from 90% to 53% — L6 hardening begins interleaving with L7 creation |
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

**Findings:** >20% mechanical → L5, regardless of rounds or scope. Rounds compensate for errors; they don't create leverage. L7 requires architectural intent before the cycle starts — no release reached L7 through review iteration alone.

---

## Pass 3: Recommendations

### 3 Recommendations for Increasing L7 Density

1. **Enforce the pre-push gate universally.** The v3.23.0 gate (`dune build`, `dune runtest`, `cn build --check`, VERSION parity) prevents mechanical-ratio caps. Five releases (v3.15.0–v3.19.0) were capped by errors this gate catches.

2. **Scope L7 releases smaller.** One boundary change per release. The early L7 streak (v3.3.0–v3.10.0) shipped one boundary each at 53% L7 density. v3.17.0 bundled too many ACs and drowned in mechanical errors.

3. **Add a pre-cycle leverage check.** "Does this change a boundary?" If yes, design for L7 with clean scope. If no, execute clean L6.

### 3 Anti-Patterns

1. **"L7 architecture, L5 execution."** v3.17.0 (53%), v3.18.0 (57%), v3.16.0 (63%). High design cost, L5-discounted outcome.

2. **"Doc org as filler."** v3.14.2–v3.14.5: four consecutive L5s. Batch organizational work or interleave with L6/L7.

3. **"Review as correction, not prevention."** v3.16.2 and v3.17.0 used 5 rounds to discover errors. Rounds don't raise level — only prevent regression. Build before every `git push`, not just before merge.

### Prediction: Next 10 Releases

Target for next 10 releases:

| Level | Count | Why |
|-------|-------|-----|
| L7    | 2     | One per 5 releases — sustainable with gate + scope discipline |
| L6    | 6     | Natural baseline once mechanical caps are eliminated |
| L5    | 2     | Deliberate (maintenance/org), not involuntary |

Shift: L5 36%→20%, L6 36%→60%, L7 ~20%. The change is fewer involuntary L5s, not more L7. Floor: **0 involuntary L5 caps.**

---

## Pass 4: TSC-Grounded Reading

TSC's formal structure (tsc-core, c-equiv, tsc-oper) adds warrant to the classifications without changing any.

### The formal structure

TSC is grounded in C≡, a term algebra where wholeness articulates as one-as-two in `tri(·,·,·)`. C≡ v3.1.0 §3.4 proves the three evaluators pairwise non-isomorphic via distinct idempotent profiles:

| Evaluator | Algebra | Idempotents | Measures |
|-----------|---------|-------------|----------|
| α (Pattern) | (ℕ, +, 0) | {0, M} | Stability under perturbation |
| β (Relation) | [0, M] min/max | All elements | Pairwise coherence |
| γ (Process) | (ℕ×ℕ, ·, (1,1)) | {(0,0)} only | Temporal stability |

Independence theorem, not taxonomy. C_Σ = (s_α · s_β · s_γ)^(1/3) — S₃ symmetric, any zero annihilates.

### γ as generative depth

γ is the multiplicative evaluator: nesting depth, how processes compose into higher-order processes. This reframes:

- **v3.14.6 (L7):** §9.11 release gate is a γ-primitive — a process constraining all future processes.
- **v3.23.0 (L7):** Self-application (tsc-oper §10) — the system measuring its own release process. Verdict, not score.
- **v0.1.0–v1.5.0 (no L7):** γ near-zero. No generative primitives to nest.

### Four eras under TSC

| Era | TSC reading |
|-----|-------------|
| Foundation | α/β developing; γ ≈ 0 → no L7 |
| Architecture explosion | γ crystallizing — each release nests inside the previous |
| Feature architecture | `tri(·,·,·)` established; extensions within, not deeper |
| Hardening + recovery | Contraction operator T (§7.1) toward fixed point; L5↔L7 oscillation = convergence under κ < 1 |

### Relationship to methodology

No reclassifications. Level = min(scope, cap). TSC grades are witnesses, not determinants. What TSC adds: the four-era pattern is a consequence of bootstrapping `tri(·,·,·)` — building α, then β, then γ depth, then converging.

---

## Summary

| Era | Releases | Level | TSC |
|-----|----------|-------|-----|
| Foundation | v0.1.0–v1.5.0 | 60% L5 | α/β developing, γ ≈ 0 |
| Architecture explosion | v1.6.0–v3.2.0 | 90% L7 | γ crystallizing |
| Feature architecture | v3.3.0–v3.10.0 | 53% L7 | `tri(·,·,·)` established |
| Hardening + recovery | v3.11.0–v3.24.0 | 28% L7, 36% L5 | Contraction toward fixed point |

**Mechanical ratio is the binding constraint on level, not architectural ambition.** The pre-push gate (v3.23.0) eliminates the cap mechanism. v3.24.0 confirms.

**L7 density is a natural function of system maturity.** The pathology isn't low L7 — it's involuntary L5 caps. Under TSC, the trajectory is `tri(·,·,·)` bootstrapping: α, then β, then γ, then convergence.
