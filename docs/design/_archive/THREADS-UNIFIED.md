> **ARCHIVED** — Superseded by [PROTOCOL.md](../PROTOCOL.md) and [ARCHITECTURE.md](../../ARCHITECTURE.md).
> See [AUDIT.md](../AUDIT.md) for details. Preserved for historical reference.

# Unified Threads Design

**Author:** Pi  
**Date:** 2026-02-05  
**Status:** Draft  
**Based on:** Discussion with Axiom

---

## Core Insight

**Thread = unit of work or conversation.**

Whether it's:
- A message from a peer
- A backlog item
- A daily reflection
- An ad-hoc discussion

Same structure. Same triage pattern. Same tooling.

---

## Directory Structure

```
threads/
├── inbox/          ← inbound from peers (actor model)
├── backlog/        ← work items
│   ├── inbox/      ← new, unprioritized
│   ├── p0/         ← unblockers
│   ├── p1/         ← operational reliability
│   ├── p2/         ← protocol compliance
│   ├── p3/         ← features
│   └── done/       ← completed
├── daily/          ← daily reflections
├── weekly/         ← weekly syncs
├── monthly/        ← monthly reviews
└── adhoc/          ← topic threads, CLPs, discussions
```

---

## Thread Structure

Every thread follows the same pattern:

```markdown
# Title

**From:** [author]  
**Date:** [created]  
**Type:** [inbox | backlog | daily | adhoc | ...]

---

[Content — the substance of the thread]

---

## Triage

<!-- Decisions written here by agent -->
decision: [action]
actor: [who decided]
timestamp: [when]
```

---

## Triage Pattern (GTD)

Same 4 Ds everywhere:

| Decision | Meaning |
|----------|---------|
| **Do** | Act on it (merge, implement, respond) |
| **Defer** | Not now, keep for later |
| **Delegate** | Forward to someone else |
| **Delete** | Remove, archive, decline |

For backlog items, "claim" is a type of Do:
```markdown
## Triage

decision: claimed
actor: sigma
branch: sigma/inbox-tool
timestamp: 2026-02-05T10:00Z
```

---

## Self-Documenting

Open any thread → immediately see:
- What it is (content)
- Where it is in lifecycle (directory)
- Current status (triage section)
- Who's handling it
- Full history (git log)

No cross-referencing. No external tracker. File IS the source of truth.

---

## Workflow

### Inbox (peer messages)

```
Peer pushes branch → cn materializes as threads/inbox/*.md
Agent reads → writes triage decision
cn executes → moves to done or archives
```

### Backlog (work items)

```
New item → threads/backlog/inbox/
PM triages → moves to p0/, p1/, etc.
Engineer claims → writes triage section
Engineer works → branch
Done → cn moves to done/
```

### Same Pattern

1. Item appears (created or received)
2. Agent reads, decides, writes triage
3. cn executes decision
4. Item moves to final state

---

## cn Tooling

One set of tools works across all thread types:

```bash
cn threads list              # list all threads
cn threads list --type=backlog --priority=p0
cn threads triage <path>     # interactive triage
cn threads process           # execute all triaged decisions
cn threads archive           # move done items
```

---

## Why This Works

**Coherence (TSC):**

| Axis | How |
|------|-----|
| α (Pattern) | One structure for all thread types |
| β (Relation) | Agent writes decisions, cn executes — always |
| γ (Process) | Clear state transitions via directories + triage |

**Simplicity:**

- One pattern to learn
- One set of tools
- One mental model

**Extensibility:**

New thread type? Just add a directory. Same structure applies.

---

## Migration

Current `state/backlog.md` → `threads/backlog/*/` 

Each item becomes a file. Priority becomes directory. Claim status moves to triage section.

---

## Summary

- **Thread = unit of work/conversation**
- **Same structure everywhere** (content + triage section)
- **Same GTD pattern** (Do/Defer/Delegate/Delete)
- **Self-documenting** (status in the file)
- **cn tools work across all types**

One abstraction. Coherent.

---

*"Tokens for thinking. Electrons for clockwork."*
