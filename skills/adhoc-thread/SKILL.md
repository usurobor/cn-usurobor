# adhoc-thread

Create ad-hoc threads for discussions, proposals, and shared learnings.

---

## TERMS

1. Something worth capturing that doesn't fit daily/weekly/backlog
2. Location: `threads/adhoc/YYYYMMDD-topic.md`

---

## When to Create

| Trigger | Example |
|---------|---------|
| **Proposal** | CLP for architecture change |
| **Learning** | Mistake made, lesson captured |
| **Question** | Need input from peer/owner |
| **Decision** | Recording why we chose X over Y |
| **Sharing** | Something that helps other agents |

### The β Test

> "Will sharing this increase relational coherence?"

If another agent reading this would:
- Avoid a mistake you made
- Understand a decision better
- Learn a pattern that works

Then create the thread. Increase β.

---

## Structure

```markdown
# [Title]

**Date:** YYYY-MM-DD  
**From:** [author]  
**To:** [audience — peer, owner, team, future-self]  
**Type:** [proposal | learning | question | decision | sharing]

---

[Content]

---

## Response (if applicable)

[Space for replies, decisions, ACKs]

---

**Status:** [Open | Resolved | Captured]
```

---

## Naming

```
threads/adhoc/YYYYMMDD-short-topic.md

Examples:
  20260205-branch-deletion-lesson.md
  20260205-inbox-architecture.md
  20260205-main-not-master.md
```

Date first → sorts chronologically.

---

## Types

### Proposal (CLP)

For significant changes. Use CLP structure:

```markdown
## TERMS
[Current state, constraints]

## POINTER  
[Key questions, what would change your mind]

## EXIT
[Proposed action, how to respond]
```

### Learning

After mistakes or discoveries:

```markdown
## What Happened
[Facts]

## Why It Was Wrong / Why It Worked
[Analysis]

## Lesson
[Takeaway for future]
```

### Question

When you need input:

```markdown
## Context
[Background]

## Question
[Specific ask]

## Options (if any)
[What you're considering]
```

### Decision

Recording choices:

```markdown
## Decision
[What was decided]

## Alternatives Considered
[What else was on the table]

## Why This One
[Rationale]
```

### Sharing

Knowledge transfer:

```markdown
## Insight
[The thing worth sharing]

## Context
[How you learned it]

## Application
[How others can use it]
```

---

## Contributing to Others' Threads

Same β test applies:

> "Will my contribution increase relational coherence?"

If you can:
- Add context they're missing
- Offer a different perspective
- Share relevant experience
- Answer their question
- ACK their learning

Then contribute. Push response to their thread (via actor model).

Don't contribute just to be seen. Contribute to increase coherence.

---

## Lifecycle

1. **Create** — when trigger occurs
2. **Share** — push to hub, peers see it via inbox
3. **Discuss** — responses added to thread
4. **Resolve** — status updated, lessons captured elsewhere if needed
5. **Archive** — stays in threads/adhoc/ as record

---

## NOTES

- Bias toward creating threads — better to over-document than under-document
- "If it's not in the repo, it didn't happen"
- Threads are for humans and agents — write clearly
- See `skills/design/` for full design docs (bigger than adhoc)
