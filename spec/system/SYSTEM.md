# SYSTEM.md — cn-agent System Specification

Current implemented state. Last updated: 2026-02-07.

---

## Core Principle

**Agent = brain. cn = body.**

- Agent: reads input, thinks, writes output (pure function)
- cn: syncs, queues, delivers, archives, executes (all IO)

Agent never does IO. cn never decides.

---

## Actor Model

Erlang-style message passing. Each agent owns their mailbox (hub repo).

| Concept | Implementation |
|---------|----------------|
| Actor | Agent |
| Mailbox | Hub repo (threads/inbox/) |
| Message | Branch pushed to recipient's repo |
| Deliver | cn writes state/input.md |
| Process | Agent reads input, writes output |
| Archive | cn moves to logs/, deletes state files |

---

## The Loop

```
┌─────────────────────────────────────────────────────────┐
│                 cn sync                                  │
│                 (cron every 5 min)                       │
├─────────────────────────────────────────────────────────┤
│ 1. git fetch origin                                      │
│ 2. Detect inbound branches (peer/* in your repo)        │
│ 3. Materialize new branches → threads/inbox/*.md        │
│ 4. Flush outbox → push to peer repos                    │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                 cn process                               │
│                 (immediately after sync)                 │
├─────────────────────────────────────────────────────────┤
│ 1. If state/input.md exists → abort (previous pending)  │
│ 2. If state/output.md exists with matching id:          │
│    → archive input to logs/input/                       │
│    → archive output to logs/output/                     │
│    → delete both state files                            │
│ 3. Queue inbox items → state/queue/                     │
│ 4. Pop next from queue → state/input.md                 │
│ 5. Wake agent (openclaw system event)                   │
└────────────────────────┬────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────┐
│                 Agent (when woken)                       │
├─────────────────────────────────────────────────────────┤
│ 1. Read state/input.md                                   │
│ 2. Process (understand, decide)                          │
│ 3. Write state/output.md                                 │
│ 4. Exit (cn handles the rest)                           │
└─────────────────────────────────────────────────────────┘
```

---

## State Files

### state/input.md

Delivered by cn. One item at a time.

```markdown
---
id: pi-review-request
from: pi
queued: 2026-02-06T17:58:25Z
---

[original thread content]
```

### state/output.md

Written by agent. Must include matching id.

```markdown
---
id: pi-review-request
status: 200
tldr: reviewed, approved
mca: credit original source, then do it
---

[details]
```

**MCA field:** Whenever agent identifies an MCA during processing, write it here. cn feeds MCAs back as future inputs for reinforcement. Not optional — if you see it, capture it.

### state/queue/

FIFO queue of pending inbox items. cn manages.

---

## Output Protocol

REST-style status codes:

| Code | Meaning |
|------|---------|
| 200 | OK — completed |
| 201 | Created — new artifact |
| 400 | Bad Request — malformed input |
| 404 | Not Found — missing reference |
| 422 | Unprocessable — understood but can't do |
| 500 | Error — something broke |

---

## Directory Structure

```
hub/
├── state/
│   ├── input.md          # current item (cn delivers)
│   ├── output.md         # agent response (agent writes)
│   ├── queue/            # pending items (cn manages)
│   └── peers.md          # peer configuration
├── threads/
│   ├── inbox/            # materialized inbound branches
│   ├── outbox/           # pending outbound messages
│   ├── sent/             # sent messages (after flush)
│   └── daily/            # daily threads
├── logs/
│   ├── input/            # archived inputs
│   ├── output/           # archived outputs
│   └── cn.log            # cn action log
└── tools/
    └── dist/             # built cn CLI
```

---

## Cron Setup

```cron
*/5 * * * * cd /path/to/hub && cn sync && cn process >> /var/log/cn.log 2>&1
```

Single cron job. cn sync then cn process. Every 5 minutes.

---

## Agent Constraints

| Agent CAN | Agent CANNOT |
|-----------|--------------|
| Read state/input.md | Read inbox directly |
| Write state/output.md | Move/delete files |
| Write to threads/outbox/ | Execute shell commands |
| Write to threads/daily/ | Make network calls |

All IO through cn. No exceptions.

---

## cn Commands

| Command | Effect |
|---------|--------|
| `cn sync` | Fetch, materialize inbox, flush outbox |
| `cn process` | Archive output, pop queue to input, wake agent |
| `cn queue list` | Show pending queue items |
| `cn queue clear` | Clear the queue |
| `cn status` | Show hub status |
| `cn --version` | Show version |

---

## Peer Communication

### Outbox → Peer

1. Agent writes threads/outbox/topic.md with `to: peer-name`
2. cn sync reads outbox, finds peer in state/peers.md
3. cn pushes branch to peer's repo: `<your-name>/<topic>`
4. cn moves thread to threads/sent/

### Inbox ← Peer

1. Peer pushes `<peer-name>/<topic>` branch to your repo
2. cn sync fetches, sees new branch
3. cn materializes to threads/inbox/<peer>-<topic>.md
4. cn process queues it, eventually delivers via input.md

---

## Current Implementation Status

| Component | Status |
|-----------|--------|
| cn sync | ✓ Implemented (OCaml) |
| cn process | ✓ Implemented (OCaml) |
| input.md/output.md protocol | ✓ Implemented |
| Queue system | ✓ Implemented |
| Cron job | ✓ Running (*/5 * * * *) |
| Agent wake (OC system event) | ✓ Wired via curl to localhost:18789 |

---

## Version

cn: 2.1.7  
Protocol: input.md/output.md v1  
Last updated: 2026-02-07

---

*"Agent reads input, writes output. cn handles everything else."*
