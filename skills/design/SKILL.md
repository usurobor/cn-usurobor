# design

Create architectural design documents before significant changes.

---

## TERMS

1. Change is significant (new feature, architecture shift, protocol change)
2. Multiple agents/humans affected
3. Decision needs to be documented

---

## When to Write a Design Doc

- New tool or system
- Architecture change
- Protocol or interface change
- Anything that affects multiple components
- Anything you'll need to explain twice

**Rule of thumb:** If it takes more than a day to build, write a design doc first.

---

## Design Doc Structure

Location: `docs/design/TITLE.md`

```markdown
# [Title]

**Author:** [name]
**Date:** YYYY-MM-DD
**Status:** Draft / In Review / Approved / Implemented

---

## Problem

What problem are we solving? Why now?

## Constraints

- Constraint 1
- Constraint 2

## Proposal

### Overview
[High-level summary]

### Design
[Detailed design with diagrams if needed]

### Types (if applicable)
```ocaml
type foo = ...
```

### Interface
[API, commands, file formats]

### Workflow
[How it works step by step]

## Alternatives Considered

### Alternative 1
- Pros
- Cons
- Why rejected

## Open Questions

- Question 1?
- Question 2?

## References

- Related docs, prior art
```

---

## Design Principles

### Start with Types

Define the data structures first:
```ocaml
type triage =
  | Delete of reason
  | Defer of reason
  | Delegate of actor
  | Do of action
```

Types clarify thinking. "Show me your data structures and I'll tell you what your code does."

### Separation of Concerns

- Pure core, effectful shell
- Agent = brain (decisions), cn = body (execution)
- Types = vocabulary, functions = grammar

### KISS

Simplest design that solves the problem. No premature abstraction.

### YAGNI

Design for today's requirements. Don't build for hypothetical futures.

### Make Invalid States Unrepresentable

Use types to prevent bugs:
```ocaml
(* Bad: can forget reason *)
type triage = Delete | Defer | ...

(* Good: reason required *)
type triage = Delete of reason | Defer of reason | ...
```

---

## CLP for Design Review

Before implementing, CLP the design:

```markdown
# CLP: [Design Title]

## TERMS
[What we're proposing, constraints]

## POINTER
[Key questions, what would change your mind]

## EXIT
- Agree: proceed to implementation
- Concerns: iterate on design
- Blocking: resolve before proceeding
```

---

## Design Review Checklist

- [ ] Problem clearly stated
- [ ] Constraints identified
- [ ] Types defined
- [ ] Interface specified
- [ ] Alternatives considered
- [ ] Open questions listed
- [ ] CLP posted for review

---

## Examples

- `docs/design/INBOX-ARCHITECTURE.md` — brain/body separation
- `docs/design/ACTOR-MODEL-DESIGN.md` — git-native coordination
- `docs/design/AGILE-PROCESS.md` — backlog workflow

---

## NOTES

- Design docs are living documents — update as design evolves
- Approval doesn't mean frozen — iterate during implementation
- "Plans are worthless, but planning is everything" — Eisenhower
- See `mindsets/ENGINEERING.md` for design philosophy
