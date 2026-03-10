# Design

Create architectural design documents before significant changes.

## When

- New tool or system
- Architecture change
- Protocol change
- Takes >1 day to build

## Location

`docs/design/TITLE.md`

## Structure

```markdown
# [Title]

**Author:** [name]
**Date:** YYYY-MM-DD
**Status:** Draft / In Review / Approved

## Problem
What and why?

## Constraints
- ...

## Proposal

### Types
```ocaml
type foo = ...
```

### Interface
[API, commands]

### Workflow
[Steps]

## Alternatives Considered
| Option | Pros | Cons | Decision |
|--------|------|------|----------|

## Open Questions
- ?
```

## Principles

- Start with types
- Pure core, effectful shell
- KISS, YAGNI
- Make invalid states unrepresentable

## Checklist

- [ ] Problem stated
- [ ] Types defined
- [ ] Interface specified
- [ ] Alternatives considered
- [ ] CLP posted for review
