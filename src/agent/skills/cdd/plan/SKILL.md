---
name: plan
description: Turn a design into an ordered implementation plan with steps, acceptance criteria, and file changes. Use after design is converged, before implementation begins.
artifact_class: runbook
kata_surface: none
---

# Plan

## Core Principle

**Coherent plan: every step closes a named gap, every step has acceptance criteria, and the order minimizes rework.**

A plan has parts: coherence contract, steps, acceptance, test strategy, non-goals. Coherence = each step is independently verifiable and the sequence builds on prior steps without backtracking.

Failure mode: plan restates the design instead of operationalizing it. Or: steps have no acceptance criteria, so "done" is ambiguous.

---

## 1. Define

1.1. **Identify the parts**
  - Coherence contract (reference the design, don't restate it)
  - Ordered steps
  - Per-step acceptance criteria
  - Per-step file changes
  - Test strategy
  - CI/release gating
  - Non-goals
  - ❌ Copy the design doc's gap analysis into §0
  - ✅ "See [DESIGN.md] for gap analysis. This plan operationalizes it."

1.2. **Articulate how they fit**
  - Design names the gap and the shape of the fix. Plan names the order and the verification. Each step's acceptance criteria are independently checkable. Steps build on prior steps.
  - ❌ Plan that requires reading the design to know when a step is done
  - ✅ Each step has its own pass/fail criteria without external reference

1.3. **Name the failure mode**
  - Plan fails via **duplication** (restating the design) or **ambiguity** (steps without acceptance criteria). A plan that just reorganizes the design into numbered steps adds no information.
  - ❌ "Step 1: Fix restore. Step 2: Fix third-party." (no criteria, no files, no order rationale)
  - ✅ "Step 1: Full package restore. AC: profiles and extensions present in installed root. Files: cn_deps.ml. Depends on: nothing. Unblocks: Step 4 (doctor)."

---

## 2. Unfold

### 2.1. Coherence contract

2.1.1. **Reference the design, don't restate it**
  - One sentence + link to the design doc
  - Gap, mode, α/β/γ targets already live in the design
  - ❌ Copy the design's §0 into the plan's §0
  - ✅ "Implements [PACKAGE-SYSTEM.md]. Gap and targets defined there."

2.1.2. **State only what the plan adds**
  - The plan's unique contribution is: order, step boundaries, per-step ACs, file lists
  - ❌ Re-derive why the work matters
  - ✅ State the implementation strategy (e.g., "bottom-up: substrate before consumers")

### 2.2. Steps

2.2.1. **Each step closes one named gap**
  - A step that closes two gaps should be split
  - A step that closes half a gap should name what remains
  - ❌ "Step 3: Fix integrity and doctor" (two concerns)
  - ✅ "Step 3: Integrity generation + verification. Step 4: Doctor validation."

2.2.2. **Each step has acceptance criteria**
  - Specific, testable, no interpretation needed
  - ❌ "Restore works correctly"
  - ✅ "Installed root contains profiles/ and extensions/ when package declares them"

2.2.3. **Each step names files changed**
  - Reviewer can scope the diff before reading it
  - ❌ "Various files"
  - ✅ "src/cmd/cn_deps.ml, test/cmd/cn_deps_test.ml"

2.2.4. **Order minimizes rework**
  - Substrate before consumers. Data model before logic. Logic before presentation.
  - State dependencies explicitly: "Step 4 depends on Step 3 (integrity must exist before doctor can verify it)"
  - ❌ Random order that requires revisiting earlier steps
  - ✅ Topological order with explicit dependency edges

2.2.5. **Prioritize steps**
  - P0/P1/P2 or must-have/should-have/nice-to-have
  - A plan that treats all 10 steps as equal priority is not a plan
  - ❌ "All steps are required"
  - ✅ "Steps 1-2 are P0 (restore coherence). Steps 3-5 are P1 (harden). Steps 6-7 are P2 (complete)."

### 2.3. Test strategy

2.3.1. **One test section, not per-step test lists duplicated**
  - Per-step ACs define what to test. Test strategy section defines how.
  - ❌ Repeat the same test expectations in both step ACs and test section
  - ✅ Step ACs say what. Test section says how (unit, integration, expect-test, property).

### 2.4. Non-goals

2.4.1. **Name what this plan explicitly does not do**
  - Prevents scope creep during implementation
  - ❌ Omit non-goals (scope creeps silently)
  - ✅ "This plan does not include registry publication or marketplace UX."

### 2.5. Artifact boundaries

2.5.1. **A plan references companion artifacts, never restates them**
  - Design doc owns: gap, constraints, proposal, impact graph
  - Issue owns: problem summary, ACs, priority
  - Plan owns: step order, per-step ACs, file changes, test strategy
  - ❌ Plan restates the design's gap analysis and the issue's problem statement
  - ✅ Plan links to both and adds only implementation-specific content

---

## 3. Rules

3.1. **Reference, don't restate**
  - If another artifact already says it, link to it
  - ❌ Plan §0 re-derives the gap from the design doc
  - ✅ Plan §0: "Implements [design doc]. See §0 there for gap and targets."

3.2. **Every step has AC + files**
  - No step without acceptance criteria. No step without named files.
  - ❌ "Step 5: Clarify metadata source-of-truth"
  - ✅ "Step 5: Clarify metadata source-of-truth. AC: one explicit rule exists, build/check/doctor enforce it. Files: cn_build.ml, docs."

3.3. **Order is explicit, not implicit**
  - State why step N comes before step N+1
  - ❌ Steps numbered but order never justified
  - ✅ "Step 3 before Step 4 because doctor needs integrity to exist before it can verify it"

3.4. **Priority is explicit**
  - Not all steps are equal. Say which are P0.
  - ❌ Flat list of 10 equal steps
  - ✅ "P0: Steps 1-2. P1: Steps 3-5. P2: Steps 6-7."

3.5. **Plan earns its existence**
  - If the design is small enough that steps are obvious, skip the plan
  - A plan for a 1-file change is overhead, not coherence
  - ❌ Write a plan for every change regardless of size
  - ✅ Write a plan when the implementation has 3+ steps with ordering constraints
