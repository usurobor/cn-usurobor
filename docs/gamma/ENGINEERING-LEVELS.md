# Engineering Levels

## What L5, L6, and L7 Mean in cnos

Version: 1.0.0
Status: Draft

Purpose: Define the shared meaning of engineering levels used in cnos so references to "L5", "L6", or "L7" are stable, local, and actionable.

Related:
- docs/gamma/essays/ENGINEERING-LEVEL-ASSESSMENT.md
- src/agent/skills/eng/README.md

---

## 0. Why this doc exists

cnos already uses level language such as:
- L4
- L5
- L6
- L7

But without a local reference, those labels can become fuzzy or overloaded.

This document defines what they mean inside cnos. It does not try to reproduce every outside career framework. It defines the levels only to the extent that they matter for:

- system design
- code quality
- proof discipline
- operational reliability
- process economics
- architectural leverage

---

## 1. Core Principle

The levels in cnos describe the shape of engineering impact, not title or tenure.

The shortest stable interpretation is:

- L5 — local correctness
- L6 — system-safe execution
- L7 — system-shaping leverage

These are cumulative:
- L6 includes L5
- L7 includes L6

---

## 2. L5 — Local Correctness

### Definition

An L5 engineer can implement a coherent local solution inside the existing architecture.

### Typical behaviors

- follows established patterns
- makes the local code work
- writes reasonable example tests
- handles obvious edge cases
- improves code quality without changing the system boundary

### Typical strengths

- local implementation quality
- understandable code
- reasonable decomposition
- happy-path correctness
- useful but mostly local review comments

### Typical limits

- may not model deeper failure modes
- may not catch cross-surface drift
- may assume the current architecture is fixed
- may use shallow proof where stronger proof is needed

### Typical signal

> "This change works and is reasonably sound."

---

## 3. L6 — System-Safe Execution

### Definition

An L6 engineer can make a change coherent across the surrounding system, not just inside the touched file.

### Typical behaviors

- keeps code, tests, docs, artifacts, and runtime surfaces aligned
- models failure modes and bounded recovery
- makes invariants explicit
- uses stronger review discipline
- maintains quality under maintenance and follow-up work

### Typical strengths

- cross-module correctness
- failure handling
- review quality
- traceability/operator truth
- consistent execution across multiple PR rounds

### Typical limits

- may still operate mostly inside the chosen architecture
- may harden the system without challenging its direction
- may add process without fully pricing its cost
- may still underuse property-based testing, model testing, or performance modeling

### Typical signal

> "This system change is coherent, testable, and safe to operate."

---

## 4. L7 — System-Shaping Leverage

### Definition

An L7 engineer changes the boundary of the system so repeated future work becomes simpler, safer, cheaper, or unnecessary.

### Typical behaviors

- challenges architecture assumptions explicitly
- chooses higher-leverage primitives
- moves recurring work out of the core path
- introduces stronger proof forms where the system needs them
- prices negative leverage and process overhead
- leaves behind a platform that changes future work, not just today's fix

### Typical strengths

- architecture evolution
- leverage-based design
- process economics
- performance/reliability modeling
- platformization of repeated work
- explicit tradeoff analysis and migration design

### Typical limits

- L7 work can still fail if it over-abstracts or adds unjustified system weight
- not every change should be an L7 change

### Typical signal

> "This changes the system boundary so a whole class of future work gets easier or disappears."

---

## 5. What the levels are not

These levels are not:

- job titles
- seniority labels from another company copied blindly
- "who is smarter"
- "who writes more code"
- "who writes more docs"

They are about:

- the scale of coherent engineering impact

---

## 6. Practical interpretation inside cnos

### L5 questions

- Is the local fix correct?
- Does it follow current patterns?
- Are the immediate tests good enough?

### L6 questions

- Does the change stay coherent across docs, runtime, artifacts, tests, and operator truth?
- Are the failure modes bounded and visible?
- Did review actually close the search space?

### L7 questions

- Are we changing the right boundary?
- Is there a higher-leverage move than this local fix?
- What future work becomes easier?
- What future work becomes harder?
- What process or operational cost are we adding?
- Could this become a package, extension, bundle, config rule, or primitive instead?

---

## 7. Mapping to the engineering skills

The skills in src/agent/skills/eng/ support the levels like this:

### Mostly L5-supporting

- coding
- functional
- ocaml

These help with local correctness and implementation quality.

### Mostly L6-supporting

- review
- testing
- ship
- tool-writing
- ux-cli

These help make system changes safer, more verifiable, and more operationally coherent.

### Mostly L7-supporting

- architecture-evolution
- performance-reliability
- process-economics
- design (when used for leverage and tradeoffs, not just local subsystem planning)

These help decide whether the system boundary itself should move.

### Important note

The levels are not hard partitions. A single skill may support multiple levels depending on how it is used.

---

## 8. How to tell what level a diff is operating at

### L5 diff

- improves local correctness
- stays within the existing architecture
- examples and local tests dominate
- no major system boundary changes

### L6 diff

- closes the loop across code/tests/docs/runtime/operator surfaces
- handles failure modes explicitly
- leaves the system safer and more coherent
- still mostly works inside the chosen architecture

### L7 diff

- changes the architecture boundary
- creates a new primitive or layer
- turns repeated future work into a simpler or more governed path
- explicitly trades off leverage, cost, and migration

---

## 9. How to use this doc

Use this doc when:

- writing engineering assessment essays
- describing the level of a diff or change set
- deciding which engineering skill bundle to load
- deciding whether a branch is merely correct, system-safe, or system-shaping

### Rule

Do not use "L7" loosely to mean:

- "very good"
- "fancy"
- "large"

Use it only when the change genuinely alters the system boundary in a leverage-rich way.

---

## 10. Relationship to the assessment essay

ENGINEERING-LEVEL-ASSESSMENT.md is a historical assessment of observed work.

This doc is the shared rubric that makes such assessments consistent in future.

If the essay and this doc disagree:

- the essay should be updated,
- or this doc should be deliberately revised.

This doc is the stable reference.

---

## 11. Summary

The cnos engineering levels mean:

- L5 — local correctness
- L6 — system-safe execution
- L7 — system-shaping leverage

Use the labels only when you can point to:

- what changed,
- what boundary moved,
- what invariants got stronger,
- and what future work became easier.
