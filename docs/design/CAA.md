# Coherent Agent Architecture (CAA) v1.0.0

What a coherent agent is, structurally.

**Status:** v1.0.0
**Date:** 2026-03-10
**Relationship:** FOUNDATIONS.md = doctrine/why. This doc = architecture/what.
AGENT-RUNTIME = execution/how. CAR = package distribution/how cognition arrives.

---

## 1. Definition

A coherent agent is a system that minimizes the gap between model and reality
through MCA or MCI, MCA first, using doctrine as always-on substrate, skills
as bounded amplifiers, and a governed runtime for action.

---

## 2. First Principle

From Friston's Free Energy Principle, reframed for agents:

- **model** — what the agent believes
- **reality** — what the world is
- **gap** — the distance between them = incoherence

Operational law (CAP):

> Gap → MCA or MCI → MCA first

This is the irreducible dynamic. Everything below exists to make this
choice well and keep it coherent over time.

---

## 3. Doctrinal Layers

Four layers, each with a distinct role. Defined in FOUNDATIONS.md,
referenced here as architectural constraints:

| Layer | Doctrine file | Architectural role |
|-------|--------------|-------------------|
| Dynamic atom | CAP | When and how to act or learn |
| Review geometry | COHERENCE | Whether the result remained whole (α/β/γ) |
| Relational boundary | CBP + CA-Conduct | Whether the action preserved trust |
| Runtime grammar | AGENT-OPS | How the agent emits output |

These are not optional enrichments. They are structural requirements.
An agent missing any layer is architecturally incomplete.

---

## 4. Cognitive Strata at Wake-Up

The agent reconstitutes from local files in this order:

| # | Stratum | Source | Loaded |
|---|---------|--------|--------|
| 1 | Identity | `spec/SOUL.md`, `spec/USER.md` | Always |
| 2 | Core Doctrine | Installed `cnos.core` package | Always, not scored |
| 3 | Mindsets | All installed packages | Always, not scored |
| 4 | Reflections | `threads/reflections/` | Always (recent N) |
| 5 | Task Skills | All installed packages | Scored, bounded (top N) |
| 6 | Capabilities | Runtime-generated | Always |
| 7 | Conversation | `state/conversation.json` | Recent N turns |
| 8 | Inbound message | Queue / stdin | Current demand |

Strata 1-3 are stable and cacheable. Strata 4-8 are dynamic.

Doctrine and mindsets never compete for skill slots. If they do,
the architecture is broken.

---

## 5. The Agent Loop

Every processing cycle:

```
Sense → Compare → Choose (MCA/MCI) → Review (α/β/γ) → Emit → Repeat
```

### 5.1 Sense
Gather evidence. Read files, check state, observe the world.
The runtime enforces this: observe ops run before effect ops.

### 5.2 Compare
Where is the gap? What did the model predict vs what the evidence shows?

### 5.3 Choose
- Can I change reality? → MCA (act)
- Must I update my model? → MCI (learn)
- Both needed? → MCA first, then MCI from the result

### 5.4 Review
Before emitting, check:
- α — is this internally consistent?
- β — does it align across views?
- γ — is the next step clear?

### 5.5 Emit
Output via the governed channel: prose + coordination ops + typed capability ops.
The runtime validates, executes, records receipts.

---

## 6. Runtime Embodiment

The agent is not a process with a shell. It is a reasoning system with
a governed I/O boundary.

### 6.1 Direct I/O
- Input: `state/input.md`
- Output: `state/output.md`

Reasoning and execution are separated. The agent proposes; the runtime disposes.

### 6.2 Governed capabilities
The agent does not execute commands. It emits typed ops:
- **Observe ops** — read files, check state, search
- **Effect ops** — write files, patch, branch, commit

The runtime:
1. Validates ops against policy
2. Executes within budget
3. Records receipts
4. Feeds evidence back for a bounded second pass if needed

### 6.3 Two-pass structure
- Pass A: agent requests observe ops → runtime gathers evidence
- Pass B: agent proposes effect ops → runtime executes governed effects

This is CAP made runtime-real: sensing is first-class, action is governed,
learning is built into the loop.

### 6.4 No ambient authority
The agent has no direct filesystem, git, exec, or network authority.
All mutation goes through the capability runtime. All effects produce receipts.

---

## 7. Invariants

Non-negotiable architectural properties:

1. **Doctrine is always-on.** Loaded every wake-up. Never competes for
   task-skill slots. Never dropped for context budget.

2. **Wake-up is local-only.** No network fetch during `cn agent`. All
   cognitive assets are pre-installed packages.

3. **No ambient authority.** The agent emits requests. The runtime
   validates, executes, and records.

4. **Observe before effect.** Evidence before action. Always.

5. **Receipts for all effects.** Every mutation is logged. Recovery is
   possible from any crash point.

6. **Deterministic resolution.** Same lockfile + same hub state →
   same packed context. No ordering surprises.

7. **Fail-fast on missing substrate.** If doctrine or required mindsets
   are absent, the agent does not wake. Silent degradation is the
   failure mode this architecture exists to prevent.

---

## 8. Failure Modes

| Failure | Violated invariant | Symptom |
|---------|-------------------|---------|
| No doctrine at wake-up | #1, #7 | Agent operates without principles |
| Network fetch during wake-up | #2 | Flaky, non-deterministic starts |
| Direct exec/shell access | #3 | Ungoverned side effects |
| Effect before observe | #4 | Action based on hallucinated state |
| Missing receipts | #5 | No recovery path after crash |
| Non-deterministic context | #6 | Same input, different behavior |
| Silent zero-skills wake-up | #7 | Agent functions but is cognitively empty |
| Doctrine in skill slots | #1 | Principles dropped when skills are full |

Each failure mode maps to a specific invariant. If the invariant holds,
the failure cannot occur.

---

## 9. Relationship to Other Documents

| Document | Scope | Question it answers |
|----------|-------|-------------------|
| FOUNDATIONS.md | Doctrine | Why — first principles and doctrinal layers |
| **CAA.md** | **Architecture** | **What — structural definition of a coherent agent** |
| AGENT-RUNTIME | Runtime spec | How — process lifecycle, queue, execution |
| CAR.md | Distribution | How — package model, install, restore |

FOUNDATIONS defines the principles. CAA defines the structure that
implements them. The runtime and distribution docs define the mechanics.
