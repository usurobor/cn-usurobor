---
name: cdd
description: Apply Coherence-Driven Development to substantial changes. Use when work spans design, code, tests, docs, runtime behavior, process, or release.
---

# CDD

## Core Principle

A release is not the end of the method. Assessment and closure are part of the method.

## Algorithm

1. Define — observe the system, select the gap, name the incoherence, choose MCA or MCI.
2. Unfold — produce artifacts in order: design → contract → plan → tests → code → docs → self-coherence → review → gate → release → observe → assess.
3. Rules — enforce the mechanical invariants and leave semantic judgment explicit.

---

## 1. Define

### 1.1 Identify the parts

- observation inputs
- selected gap
- mode (MCA / MCI / both)
- artifact pipeline
- review
- gate
- assessment
- closure

  - ❌ "Pick an issue and start coding."
  - ✅ "Read CHANGELOG TSC, lag table, doctor/status, and the last assessment first."

### 1.2 Articulate how they fit

Observation chooses the next gap. The gap determines mode. Mode drives the artifact pipeline. The pipeline produces something reviewable. Release is measured by assessment. Assessment creates immediate fixes and next commitments. Closure feeds the next cycle.

  - ❌ Treat release as the finish line.
  - ✅ Treat release as the handoff into observation and assessment.

### 1.3 Name the failure mode

CDD fails through pipeline without selection or release without closure. Typical failures:

- work chosen by preference, not observation
- missing bootstrap or missing self-coherence
- review without an explicit contract
- release without assessment
- assessment that names debt but does not materialize it

---

## 2. Unfold

### 2.0 Observe and select

Read, in order:

1. CHANGELOG TSC table
2. encoding lag table
3. doctor / status
4. last post-release assessment

Selection rules:

- P0 override first — but only if the P0 is new since the last assessment or has escalated. Known P0s that were weighed and deferred are not overrides.
- operational infrastructure debt second — but size it first: if the fix is minutes of work, execute as immediate output and continue to §3.3. Only select as cycle gap when it requires design/tests/review.
- last assessment's Next MCA is the default unless overridden
- stale lag set freezes new design work
- then weakest axis
- then leverage
- then dependency order
- then effort-adjusted tie-break

If no gap exists, do not force a substantial cycle. Remain in observation or use the small-change path.

### 2.1 Branch

Create a dedicated branch before artifacts.

Format:

```text
{agent}/{version}-{issue}-{scope}
```

or, if version is not known:

```text
{agent}/{issue}-{scope}
```

Pre-flight:

- version valid
- no duplicate branch
- no duplicate open PR
- branch format valid
- CI/main state known
- scope declared

### 2.2 Bootstrap

First diff on a substantial branch:

```text
docs/{tier}/{bundle}/{X.Y.Z}/
```

with:

- README.md
- one stub per declared deliverable

Version directories freeze after release except for path-reference repair.

### 2.3 Name the gap

State:

- what incoherence exists
- why it matters
- what fails if skipped

### 2.4 Choose mode and active skills

- MCA → change the system
- MCI → change the model
- both when required
- MCA first when coherent action is possible
- when in doubt, apply CAP: if the answer is already in the system, cite it (MCA) — don't reinvent it (MCI). If two paths close the same gap, take the lighter one unless the heavier one buys durability the lighter one cannot.

State why MCI is required if action is blocked.

Name 2–3 skills as hard generation constraints for this change. **Read each SKILL.md file before beginning any work step.** Naming a skill without reading it is not loading it. All others are reference only. Fewer constraints deeply applied > many constraints lightly checked. (CDD §4.4)

### 2.5 Build artifacts in order

For substantial changes:

1. design
2. coherence contract
3. plan
4. tests
5. code
6. docs
7. self-coherence

Do not invert the order casually. Each step should reduce uncertainty for the next.

### 2.6 Review

Use CLP. Ask for:

- α / β / γ separately
- weakest-axis diagnosis
- concrete patches
- iterate or converge

### 2.7 Gate

Before release verify:

- required artifacts exist
- ACs accounted for
- docs and code agree
- snapshot ready
- previous release assessed
- known debt explicit

### 2.8 Release

Delegate release mechanics to release/SKILL.md. CDD owns:

- when release is allowed
- what must already be true

### 2.9 Observe, assess, close

After release:

- observe runtime/design alignment
- write the post-release assessment
- if a §9.1 trigger fired (review rounds > 2, mechanical ratio > 20%, avoidable tooling failure, loaded skill failed to prevent a finding): write a `## Cycle Iteration` section in the assessment with friction log, root cause classification, skill impact, MCA, and **cycle level** (L5/L6/L7 per ENGINEERING-LEVELS.md §6 — level = lowest miss). Patch any skill that failed to prevent a finding it covers as an immediate output. Cycle cannot close without this section if triggered. (CDD §9.1, §10.3)
- execute immediate outputs (including skill patches from cycle iteration)
- commit deferred outputs concretely

Skill/spec patches produced as immediate outputs must pass CLP β: does this change create a mismatch with any canonical or derived surface? If the skill has a canonical spec (§5), both must be updated together.

A cycle is not closed until both classes of output are handled.

---

## 3. Rules

### 3.1 Mechanize invariants, not judgment

Mechanical:

- branch naming
- duplicate-branch check
- bootstrap presence
- AC accounting
- stale cross-ref check
- snapshot freeze
- gate checks

Judgment:

- real gap
- MCA vs MCI correctness
- triadic score substance
- review convergence
- stop/continue decision

  - ❌ Ask tooling to decide what the right design is.
  - ✅ Ask tooling to prove that the required artifacts and checks exist.

### 3.2 One canonical source per development fact

Do not duplicate:

- version facts
- capability lists
- contract fields
- AC state
- release metadata

Derive secondary surfaces from the canonical one.

### 3.3 Build-sync source assets

If you edit anything under `src/agent/`, run `cn build` before commit so packaged copies stay in sync.

### 3.3a Authority-sync on skill/spec changes

If you edit an executable skill that declares a canonical source (§5), verify the canonical source is updated in the same commit. If you edit a canonical spec, verify derived skills are updated. One-directional edits to paired surfaces create β drift — the review caught this in `20add78` (skill updated, spec not).

### 3.4 No review without a contract

A reviewer should never have to infer:

- what the gap is
- what the mode is
- what ACs were promised

### 3.5 No release without assessment

A release without assessment is incomplete CDD.

### 3.6 No closure without execution or commitment

Immediate outputs must be executed now. Deferred outputs must be recorded concretely as next-cycle commitments.

---

## 4. Delegation

CDD owns the lifecycle. Sub-skills own execution details:

- design → `eng/design/SKILL.md`
- review → `eng/review/SKILL.md`
- release → `release/SKILL.md`
- post-release assessment → `ops/post-release/SKILL.md`

CDD defines what must happen and in what order. Sub-skills define how.

---

## 5. Authority

This skill is the executable summary. The canonical algorithm spec is:

```
docs/gamma/cdd/CDD.md
```

If this skill and the canonical doc disagree, the canonical doc governs.

---

## 6. Reference

- canonical spec: `docs/gamma/cdd/CDD.md`
- rationale: `docs/gamma/cdd/RATIONALE.md`
- post-release assessment: `ops/post-release/SKILL.md`
- review protocol: `eng/review/SKILL.md`
- design protocol: `eng/design/SKILL.md`
- release procedure: `release/SKILL.md`
- coherence history: `CHANGELOG.md`
