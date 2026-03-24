# Design

Create architectural design documents before significant changes. Design is the gap between "what's wrong" and "what to build." It is judgment work — CDD mechanizes the artifacts around it, not the reasoning itself.

## When

- New subsystem or runtime capability
- Architecture change
- Protocol change
- Takes >1 day to build
- Any work where the wrong design wastes more than the design costs

## Location

Design docs live in version directories under the appropriate docs tier:
- `docs/alpha/{bundle}/{version}/SPEC.md` — runtime/protocol designs
- `docs/beta/{bundle}/{version}/SPEC.md` — governance/architecture designs
- `docs/gamma/{bundle}/{version}/SPEC.md` — method/process designs

For issue-scoped work, the design may live in the issue body itself if it's concrete enough.

## Structure

```markdown
# [Title]

**Issue:** #NN
**Version:** X.Y.Z
**Mode:** MCA / MCI
**Status:** Draft / In Review / Approved

## Problem
What incoherence does this address? Name it precisely.

## Constraints
- What can't change?
- What must be preserved?
- What existing contracts govern?

## Design Principles
Numbered principles that govern trade-off decisions in this design.
Each principle should be testable — you can look at the implementation
and say whether it was followed.

## Proposal

### Types
```ocaml
type foo = ...
```

### Interface
[Commands, ops, API surface]

### Workflow
[Step-by-step with material changes, deliverables, done-when for each step]

## Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|

## Impact Analysis
What existing artifacts consume, embed, or depend on what this changes?
(See §4 below.)

## Open Questions
- ?

## Acceptance Criteria
- [ ] Concrete, verifiable, mapped to specific files
```

## Principles

### 1. Start from the problem, not the solution

Name the incoherence. If you can't name what's wrong, you don't have a design problem — you have an exploration problem. Explore first (adhoc thread), then design.

### 2. Mechanize invariants, not judgment

Design should clearly separate what can be mechanically enforced (naming, artifact presence, structural checks) from what requires judgment (is the gap real, is the mode right, is the design good). CDD mechanizes the former. The latter stays human/agent.

### 3. Derive state from artifacts, not parallel bookkeeping

Prefer designs where the system's state can be derived from what exists (files, branches, tags, test results) rather than from a separate state store. Parallel state stores drift.

### 4. Trace the impact graph

When a design changes rules, contracts, or interfaces:
- Enumerate all artifacts that **consume** the changed thing (downstream)
- Enumerate all artifacts that **produce** inputs to the changed thing (upstream)
- Enumerate all artifacts that **embed or template** the changed thing (copies)

This is not optional. PR #98 review showed that 4 of 5 gaps came from editing the node without following the edges. "Who reads this?" is as important as "what do I write?"

### 5. One source of truth, N derived artifacts

If the same information appears in multiple places, one must be authoritative and the others must be derived or validated. Name the source explicitly. If two artifacts claim authority, that's a design bug.

### 6. Start with types

Define the data model before the interface. Types make invalid states unrepresentable. Pure core, effectful shell.

### 7. KISS / YAGNI

Simplest thing that works. Don't build for future requirements you can't justify today. But don't confuse "simple" with "incomplete" — if the problem has 5 failure modes, the design needs to address all 5.

### 8. Design the acceptance criteria as carefully as the design

Vague ACs produce vague implementations. Each AC should name a specific file, a specific check, and a specific pass/fail condition. "The system handles X correctly" is not an AC. "File Y contains Z, validated by check W" is.

### 9. Acknowledge what you're not doing

Every design has non-goals. State them. Every design has known debt. State it. The reader (and future you) needs to know what was deliberately excluded vs what was forgotten.

## Design Review Checklist

Before submitting for review:

- [ ] Problem stated as a named incoherence
- [ ] Constraints from existing contracts identified
- [ ] Design principles numbered and testable
- [ ] Types defined (where applicable)
- [ ] Interface specified
- [ ] Alternatives considered with explicit trade-offs
- [ ] Impact analysis: all consumers, producers, and copies of changed artifacts enumerated
- [ ] Acceptance criteria are concrete, file-specific, and verifiable
- [ ] Non-goals and known debt stated
- [ ] Authority relationships explicit (which artifact governs on disagreement)

## Anti-patterns

- ❌ Design that only updates one artifact when the change affects three
- ❌ ACs that can be "charitably interpreted" as met — they should be mechanically checkable
- ❌ Authority claims that contradict themselves ("skill is executable summary" + "canonical doc governs" + canonical doc not updated)
- ❌ Confusing "schema exists" with "schema is populated truthfully" (#22 lockfile lesson)
- ❌ Designing the solution before naming the problem
- ❌ "No changes needed" when the design adds new rules to a skill that declares an external authority
