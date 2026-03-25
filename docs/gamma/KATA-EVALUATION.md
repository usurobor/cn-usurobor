# Kata Evaluation Framework

## Measuring Skill, Selection, and Coherence Gain in cnos

**Version:** 1.0.0
**Status:** Draft

**Purpose:** Define a repeatable method for measuring whether skills improve agent performance, whether skill selection is correct, and whether the gain is worth the added context/process cost.

---

## 0. Core Question

The question is not merely:

> "Did the score go up?"

The real question is:

> Did the agent stop failing in the same way?

A skill is real if it changes the shape of failure:

- from incoherent to coherent
- from shallow to structured
- from local correctness only to reusable transfer
- from guesswork to constraint-following

This framework measures:

1. **Repair** — can the skill fix the immediate failure?
2. **Transfer** — does the skill help on a different but same-family task?
3. **Cost** — is the gain worth the extra context, time, and complexity?

---

## 1. Design Principles

### 1.1. Fresh session per arm

The agent is stateless across sessions. Therefore every arm must run in a fresh session.

### 1.2. Same task family, not just same task

A skill that only improves the exact same kata may be prompt-local rather than reusable.

### 1.3. Selection is part of the experiment

We are not only evaluating skills. We are evaluating whether we can choose the right 2–3 governing skills before work begins.

### 1.4. Cost matters

Constraint-first prompting is not free. Skill loading consumes:

- tokens
- latency
- operator/reviewer time
- artifact overhead

A skill that improves correctness while doubling cost may still be the wrong operational choice.

### 1.5. Hidden oracle

The kata packet should contain hidden checks/rubric so the evaluation is not contaminated by the test criteria.

---

## 2. What the Framework Measures

### 2.1 Repair

Cold run fails. Skill-loaded run on the same kata improves.

This measures:

- immediate recoverability
- usefulness of the selected skill(s) on the exact failure

### 2.2 Transfer

Skill-loaded run on a different but same-family kata also improves.

This measures:

- whether the skill teaches a reusable pattern
- whether the skill is overfit to the original prompt

### 2.3 Cost

The skill-loaded run should be measured for:

- added prompt tokens
- added latency
- added number of rounds
- added artifact/process burden

This measures:

- whether the gain is economically coherent

---

## 3. Experimental Arms

Run each kata family through these arms.

### Arm A — Cold

No special skills loaded beyond baseline doctrine/runtime context.

Purpose:

- establish raw baseline

### Arm B — All plausible skills

Load every skill that might help.

Purpose:

- establish the "skill soup" control
- test whether broad loading beats or harms selected loading

### Arm C — Selected governing skills

Before the run, explicitly name the 2–3 governing skills.

Purpose:

- test the skill-selection hypothesis
- measure whether fewer, deeper constraints beat broad loading

### Optional Arm D — Negative control

Load a deliberately irrelevant skill set.

Purpose:

- detect false positives from generic verbosity or placebo effects

---

## 4. Standard Run Sequence

For one kata family:

1. Cold run on Task A
2. Selected-skills run on Task A
3. All-skills run on Task A
4. Selected-skills run on Task B (same family, unseen)
5. Optional negative-control run on Task B
6. Optional selected-skills run on Task C (different family)

Interpretation:

- A → A = repair
- A → B = transfer
- B → C = overfitting / misgeneralization check

---

## 5. Scoring Dimensions

Use vector scoring first. Avoid collapsing too early into one scalar.

### 5.1 α — Pattern

Does the output have internal coherence?

- correctness
- structural consistency
- absence of contradiction
- valid format / valid artifacts

### 5.2 β — Relation

Does it cohere with the surrounding system?

- respects issue contract / docs / runtime contract
- preserves parity across surfaces
- aligns with authority hierarchy
- updates all relevant artifacts consistently

### 5.3 γ — Exit

Does it create a viable next state?

- chooses the right next move
- leaves behind usable artifacts
- acknowledges debt honestly
- preserves future evolution path

### 5.4 Efficiency

How expensive was the improvement?

- tokens
- latency
- number of rounds
- artifact/process overhead
- operator/reviewer burden

---

## 6. Score Bands

Use a 0–4 scale for each dimension.

| Score | Meaning |
|-------|---------|
| 0 | failed / incoherent |
| 1 | weak / mostly wrong |
| 2 | partial / mixed |
| 3 | good / coherent enough |
| 4 | strong / clearly reusable |

### Example interpretation

- α=4, β=1, γ=2 means technically good local work that breaks cross-surface/system relation
- α=2, β=3, γ=4 means imperfect local execution but good architectural/process direction

---

## 7. Optional Weighted Aggregate

Use only after vector scoring.

Suggested default:

- α = 40%
- β = 30%
- γ = 20%
- Efficiency = 10%

For architecture kata, consider:

- α = 25%
- β = 35%
- γ = 30%
- Efficiency = 10%

For review/parity kata, consider:

- α = 25%
- β = 45%
- γ = 20%
- Efficiency = 10%

---

## 8. Skill Selection Hypothesis

Before the selected-skills arm, record:

- the 2–3 governing skills
- why each is relevant
- what failure class each should prevent

### Example

```md
## Governing Skills Hypothesis

1. review — should prevent missing AC coverage and authority-surface conflict
2. documenting — should prevent stale doc/runtime examples and parity drift
3. testing — should force stronger evidence depth than shallow example tests
```

This is mandatory. If selection is wrong, that itself is a result.

---

## 9. Result Classification

After scoring, classify the failure mode.

### 9.1 Skill-effective

Selected skills improve both repair and transfer with acceptable cost.

### 9.2 Knowledge-limited

Failure persists because the system lacks domain knowledge, not because process/skill is missing.

Example:

- OCaml-specific type resolution behavior is unknown
- no loaded skill can replace missing compiler/language knowledge

### 9.3 Selection-limited

The selected skills were the wrong ones.

Signal:

- all-skills arm outperforms selected-skills arm
- or selected arm improves little while postmortem shows wrong governing skills were chosen

### 9.4 Context-limited

The selected skills help, but context cost overwhelms the benefit.

Signal:

- correctness rises, but tokens/latency/rounds become operationally unacceptable

### 9.5 Architecture-limited

The task shape itself is wrong for the current substrate/runtime/process.

Signal:

- repeated similar failure despite correct skill loading and enough domain knowledge

---

## 10. First Three Canonical Kata Families

### Family A — Local implementation + invariant proof

**Purpose:** Measure coding skill, testing skill, language/domain knowledge, whether skills turn "make it pass" into "make it correct and provable."

**Typical kata shape:**

- parser/compiler bug
- retry/dead-letter logic
- runtime contract field drift
- dispatch conflict handling
- state machine edge case

**Expected governing skills:** coding, testing, optional language/domain skill (e.g. OCaml-specific)

**Typical hidden checks:** correctness tests, invariant/property tests, regression tests, negative-case coverage

---

### Family B — Cross-surface coherence / review kata

**Purpose:** Measure review skill, documenting skill, authority/conflict detection, parity reasoning across multiple artifacts.

**Typical kata shape:**

- issue ACs partially met but PR summary overclaims
- markdown vs JSON mismatch
- canonical doc vs executable skill mismatch
- stale examples after architecture change
- frozen snapshot drift

**Expected governing skills:** review, documenting, optional testing if evidence-depth is central

**Typical hidden checks:** AC coverage table correctness, named-doc coverage, multi-format parity, authority-surface conflict, evidence depth, exact blocker vs non-blocker judgment

---

### Family C — Architecture / leverage / process-economics kata

**Purpose:** Measure design skill, architecture-evolution skill, process-economics skill, whether the agent can choose a higher-leverage move instead of a local patch.

**Typical kata shape:**

- repeated core accretion suggests extensions/packages/registry
- communication modeled at wrong layer
- self-model too flat; needs vertical contract
- governance/process overhead added without pricing cost
- platform vs product boundary confusion

**Expected governing skills:** design, architecture-evolution, process-economics

**Typical hidden checks:** challenged assumption named, leverage vs negative leverage, migration path, process cost justified, lighter alternatives considered, right layer separation

---

## 11. Kata Packet Structure

Each kata should exist as a packet with:

1. Public task statement
2. Context bundle
3. Hidden evaluator rubric
4. Hidden checks/tests
5. Expected governing skills
6. Failure-family label

The public packet should not expose the full hidden rubric.

---

## 12. Run Record Requirements

Every run must record:

- kata family
- task ID
- model
- temperature / relevant settings
- session freshness confirmed
- skill set loaded
- selected-skills hypothesis
- token count
- latency
- number of rounds
- output artifacts
- α / β / γ / efficiency scores
- failure classification
- notes

---

## 13. Interpretation Rules

### 13.1 Same-task improvement alone is not enough

That proves repair, not transfer.

### 13.2 Transfer without cost discipline is incomplete

A skill that "works" but is too expensive may still not be viable.

### 13.3 All-skills beating selected-skills is not necessarily good

That may indicate:

- bad skill selection discipline
- or over-reliance on brute-force context loading

### 13.4 Knowledge-limited results are still valuable

They show where skill cannot substitute for missing domain understanding.

---

## 14. Stop Conditions

A kata family is "good enough" when:

- cold vs selected difference is stable across several packets
- transfer behavior is measurable
- costs are measurable
- failure classification is repeatable

Do not overbuild before you can distinguish these clearly.

---

## 15. Non-goals

This framework does not attempt to:

- solve statelessness at the agent level
- replace real production metrics
- prove general intelligence
- collapse all skill quality into one scalar score

It is a tool for:

- measuring skill usefulness
- improving skill selection
- and understanding failure shape

---

## 16. Summary

The kata program should answer three questions:

1. Can the right skill repair the immediate failure?
2. Does that improvement transfer to the same family of task?
3. Is the gain worth the added context and process cost?

That is the right way to test whether a skill is real.
