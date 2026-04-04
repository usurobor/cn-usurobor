---
name: issue
description: Write an issue so problem, impact, and acceptance criteria are specific enough to act on without clarification loops.
artifact_class: runbook
kata_surface: none
governing_question: How do we write an issue that is specific, actionable, and testable?
---

# Issue

## Core Principle

**Coherent issue: engineer can act without asking clarifying questions.**

An issue has parts: problem, impact, acceptance criteria. Coherence = each part is specific enough that an engineer who wasn't in the conversation can pick it up and ship.

Failure mode: issue requires back-and-forth to clarify scope, acceptance, or priority.

---

## 1. Define

1.1. **Identify the parts**
  - Problem (what's broken or missing — symptoms, not diagnosis)
  - Impact (who cares, how bad)
  - Acceptance criteria (what "fixed" looks like — testable)
  - ❌ Just a title: "cn sync broken"
  - ✅ All three parts present and specific

1.2. **Articulate how they fit**
  - Problem grounds in reality. Impact justifies priority. Acceptance defines done — engineer knows when to stop.
  - ❌ "Fix cn sync" (no acceptance)
  - ✅ "27 messages reach input.md within 5 minutes of send" (testable outcome)

1.3. **Name the failure mode**
  - Issue fails via **ambiguity** (requires clarification) or **duplication** (restates what companion artifacts already say)
  - ❌ "It doesn't work" (what doesn't? for whom?)
  - ✅ "Daily threads written to workspace/ not hub/ — not git-backed"

---

## 2. Unfold

### 2.1. Problem statement

2.1.1. **State the incoherence in 3-5 lines**
  - Name what exists, what's expected, and where they diverge
  - ❌ Multi-paragraph re-derivation of the design doc's gap analysis
  - ✅ "Package restore copies doctrine/mindsets/skills but not profiles/extensions. The package-system doc says packages may contain both."

2.1.2. **Link to evidence, don't inline it**
  - Code review, design doc, failing test — link to them
  - ❌ Paste the entire code review into the issue body
  - ✅ "See [code review comment](link) and [PACKAGE-SYSTEM.md §2](link)"

### 2.2. Acceptance criteria

2.2.1. **Each AC is independently testable**
  - An AC that requires interpretation is not an AC
  - ❌ "Package system works correctly"
  - ✅ "Restore installs full package content, not only cognitive subsets"

2.2.2. **ACs are numbered**
  - Reviewer and implementer can reference by number
  - ❌ Bullet list of vague goals
  - ✅ "AC1: ... AC2: ... AC3: ..."

2.2.3. **ACs don't duplicate the plan**
  - Issue ACs say what done looks like. Plan ACs say what each step's done looks like.
  - ❌ Issue lists per-step acceptance criteria from the plan
  - ✅ Issue lists outcome-level criteria; plan lists step-level criteria

### 2.3. Scope and non-goals

2.3.1. **Name what's out of scope**
  - Prevents scope creep and clarifies boundaries for the implementer
  - ❌ Omit non-goals (implementer guesses at boundaries)
  - ✅ "Non-goals: registry publication, marketplace UX, ambient runtime install"

### 2.4. Related artifacts

2.4.1. **Link to design doc and plan if they exist**
  - Issue is the entry point. Design and plan are the depth.
  - ❌ Issue restates the design to be "self-contained"
  - ✅ "Design: [PACKAGE-SYSTEM.md]. Plan: [PLAN-package-system.md]."

2.4.2. **Link to related issues**
  - Cross-reference overlapping or dependent issues
  - ❌ "This is related to some other issues"
  - ✅ "Related: #73 (runtime extensions), #59 (doctor hardening)"

### 2.5. Artifact boundaries

2.5.1. **Issue owns problem + ACs + priority. Nothing else.**
  - Design doc owns: gap analysis, constraints, proposal, impact graph
  - Plan owns: step order, per-step ACs, file changes
  - Issue owns: problem summary, outcome-level ACs, priority, scope boundaries
  - ❌ Issue contains the full gap analysis, implementation steps, and per-file changes
  - ✅ Issue is the concise entry point that links to deeper artifacts

---

## 3. Rules

3.1. **Engineer can act without asking**
  - If you removed the author from the conversation, could someone ship this?
  - ❌ "See Slack thread for context"
  - ✅ All context is in the issue or linked from it

3.2. **Problem in 3-5 lines, not 30**
  - Concise problem statement. Link to details.
  - ❌ Multi-section problem re-derivation
  - ✅ Short statement + link to design doc

3.3. **ACs are testable**
  - Each AC has a clear pass/fail
  - ❌ "System is more coherent"
  - ✅ "Doctor validates lock ↔ install parity"

3.4. **Reference, don't restate**
  - If a design doc or plan exists, link to it. Don't copy its content.
  - ❌ Issue body contains the full design rationale
  - ✅ "Design: [link]. Plan: [link]. This issue tracks the implementation."

3.5. **Non-goals are mandatory for substantial issues**
  - Any issue with 3+ ACs needs explicit non-goals
  - ❌ Leave scope implicit
  - ✅ "Non-goals: X, Y, Z"

3.6. **Priority is stated, not implied**
  - Label or explicit text
  - ❌ "This should probably be done soon"
  - ✅ "P0: blocks runtime extension install"
