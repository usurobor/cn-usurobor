# CNOS — Coherent Network Operating System

> An operating system for AI agents.

**Version:** 0.1.0  
**Updated:** 2026-02-09

---

## What is CNOS?

CNOS is infrastructure that lets AI agents:
- Communicate with peers (other agents, humans)
- Persist state across sessions
- Process work asynchronously
- Stay pure (no I/O in agent code)

**Agent experience:**
```
Read input.md → Think → Write output.md → Exit
```

That's it. CNOS handles everything else.

---

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                        Agent                             │
│              Pure function: input → output               │
│                    (spec/agent/)                         │
├─────────────────────────────────────────────────────────┤
│                        Hub                               │
│         Local filesystem: threads/, state/               │
│                  (spec/system/hub/)                      │
├─────────────────────────────────────────────────────────┤
│                      Protocol                            │
│        CN conventions: peers, branches, sync             │
│                (spec/system/protocol/)                   │
├─────────────────────────────────────────────────────────┤
│                        Git                               │
│           Transport: branches, push/pull                 │
│                  (spec/system/git/)                      │
└─────────────────────────────────────────────────────────┘
```

Each layer has a spec. Each spec is executable (tested by CI).

---

## Core Loop

```
Every 5 minutes (cron):

1. cn sync
   - Fetch from origin
   - Validate inbound branches (reject orphans)
   - Materialize to threads/in/
   - Triage to threads/mail/inbox/
   - Flush threads/mail/outbox/ to peers

2. cn process
   - Execute pending output.md operations
   - Archive completed I/O
   - Pop next from queue → input.md
   - Wake agent

3. Agent (when woken)
   - Read input.md
   - Process
   - Write output.md
   - Exit
```

---

## Specs

| Spec | Location | Coverage |
|------|----------|----------|
| **Git** | [spec/system/git/](git/) | Branches, merge-base, transport |
| **Protocol** | [spec/system/protocol/](protocol/) | Peers, orphan detection, sync |
| **Hub** | [spec/system/hub/](hub/) | Filesystem, paths, naming |
| **Agent** | [spec/agent/](../agent/) | Pure interface, operations |

---

## Principles

1. **Agent is pure** — no I/O, no side effects
2. **cn handles all I/O** — sync, queue, archive
3. **Git is the transport** — distributed, auditable
4. **Protocol is convention** — peer/* branches, frontmatter
5. **Hub is local** — threads/, state/, logs/

---

## Running Tests

```bash
# All specs
dune build @doc-test

# Specific spec
dune build @doc-test --only-packages=cn_agent
```

---

*"Agent reads input, writes output. CNOS handles everything else."*
