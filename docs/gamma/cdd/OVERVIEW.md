# CDD Overview

**Version:** 1.0.0
**Status:** Draft
**Date:** 2026-03-25
**Placement:** γ document (`docs/gamma/cdd/`)
**Audience:** Humans who need to understand the method before reading the full spec
**Scope:** Plain-language explanation of what CDD is, why cnos uses it, and how one development cycle works

---

## 0. What this document is for

This is the human-readable introduction to Coherence-Driven Development. It is not the law. It is not the workflow profile. It is not the full rationale.

It exists to answer simpler questions first:

- What is CDD trying to optimize for?
- Why is ordinary issue-driven process not enough here?
- What changes once agents can write code?
- What does one CDD cycle look like in normal language?
- What stays human or judgment-bearing?

If you want the exact method, read CDD.md. If you want the deeper design argument, read RATIONALE.md.

---

## 1. The short version

CDD is the development method cnos uses to change itself without losing coherence.

Most development processes ask:

- did we finish the task?
- did the tests pass?
- did the PR merge?
- did the release ship?

CDD asks a stricter question:

> Did this cycle reduce incoherence across the system?

That is a different target. It means a cycle is not judged only by code output. It is judged by whether doctrine, design, implementation, runtime behavior, operator understanding, release state, and process all moved into better alignment.

In CDD, shipping is necessary. It is not sufficient.

---

## 2. Why this matters more when agents can write code

When implementation is expensive, teams often optimize for throughput:

- keep the backlog moving
- reduce friction
- ship more

When agents can write code quickly, the bottleneck moves. The expensive parts become:

- selecting the right gap
- naming the incoherence precisely
- choosing whether to change the system or the model
- keeping design, code, docs, tests, and release aligned
- measuring whether the change actually helped
- preventing process errors from repeating

In other words, faster code generation makes process quality more important, not less. If code gets cheap but selection stays sloppy, the system just accumulates incoherence faster.

CDD exists because of that asymmetry.

---

## 3. What CDD changes

The most important change is where a cycle starts.

Ordinary process often starts from:

- an issue somebody wants to do
- a task someone already claimed
- a feature someone wants to show
- a local bug someone happens to see

CDD does not start there. CDD starts from observation.

Before selecting substantial work, it reads:

- the current coherence state
- the lag state
- the live system health
- the previous assessment

That means the next cycle is selected from evidence, not preference. This is the center of gravity of the method.

CDD is not "pick an issue and follow a checklist." CDD is "observe, select, execute, assess, and close the loop."

---

## 4. What one cycle looks like

In plain language, one substantial CDD cycle looks like this:

### 4.1 Observe

Read the system as it is. Where is it weak? What is stale? What is broken? What did the last cycle say should come next?

### 4.2 Select

Choose the next gap from that evidence. Urgent failures override preference. Operational debt overrides feature work. Stale lag freezes new design work. Otherwise choose by weakest axis, leverage, dependency order, and effort.

### 4.3 Branch and bootstrap

Open a dedicated branch. Create the frozen-snapshot skeleton for the work before improvising content.

### 4.4 Name the gap

State what is incoherent, why it matters, and what fails if nothing changes.

### 4.5 Choose mode

Decide whether the next move is:

- MCA — change the system
- MCI — change the model
- both, if needed

### 4.6 Build artifacts in order

Do not jump straight to code. The expected flow is:

- design
- coherence contract
- plan
- tests
- code
- docs
- self-coherence

### 4.7 Review

Use CLP. Ask whether the change is coherent, not just locally plausible.

### 4.8 Gate and release

Release only when the structural requirements are met.

### 4.9 Observe again

Now look at the released system, not just the branch.

### 4.10 Assess

Measure what changed. Update the coherence view. Record process learning. Name the next move.

### 4.11 Close

Execute immediate follow-ups now. Turn deferred follow-ups into explicit next-cycle commitments.

Then the method returns to observation. That is why CDD is a loop, not a line.

---

## 5. What CDD is not

CDD is not:

- a generic agile overlay
- a prettier issue tracker
- a release checklist
- a replacement for judgment
- an excuse to add process for its own sake

It does not claim that every project needs this much structure. It claims something narrower:

For cnos, where the system is self-hosting, agent-assisted, Git-native, and coherence-sensitive, development must be explicit enough to inspect, assess, and close. Without that, drift wins.

---

## 6. What stays mechanical and what stays human

CDD deliberately separates two things.

### Mechanical

These can be checked, enforced, or scaffolded:

- branch naming
- artifact presence
- frozen snapshot structure
- AC accounting
- cross-reference integrity
- gate requirements
- release artifact presence

### Judgment-bearing

These still require thinking:

- what the real incoherence is
- whether MCA or MCI is the right move
- whether the design is coherent enough
- whether a review has actually converged
- whether the cycle should stop

CDD is rigorous. It is not a machine that decides for you. That distinction matters.

---

## 7. Why release is not the end

A normal process often treats release as the finish line. CDD does not.

A release can still be:

- unmeasured
- mis-scored
- under-documented
- out of sync with runtime reality
- hiding process debt that will repeat next cycle

So CDD requires post-release assessment. That assessment does two jobs:

1. it measures what the cycle actually changed
2. it decides what must happen next

Without assessment, release is just output. With assessment, release becomes part of a learning loop.

---

## 8. Why CDD lives in gamma

CDD is not doctrine. It is not runtime behavior. It is not one feature.

It is the method by which the system evolves without losing itself.

That makes it γ. CDD is coherence applied to development.

---

## 9. How to read the rest of the bundle

Read in this order:

1. README.md — bundle navigation
2. OVERVIEW.md — this document
3. CDD.md — canonical algorithm
4. RATIONALE.md — why the method takes this shape
5. epoch assessments — evidence of how the method behaves over time

If you are implementing or reviewing work, the next document to read after this one is CDD.md.

---

## 10. One sentence version

CDD is the closed-loop method cnos uses to select work from observed incoherence, execute it through an explicit artifact pipeline, assess the result after release, and close the cycle before starting the next one.
