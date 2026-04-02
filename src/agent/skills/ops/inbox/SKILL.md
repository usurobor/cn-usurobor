# Inbox

Process inbound messages from peers. Actor model: your repo is your mailbox.

## Core Principle

**You receive exactly ONE item. CN handles the queue.**

When invoked, check `state/input.md`:
- **Exists** → handle that ONE item
- **Missing** → no inbox work, proceed with other tasks

```yaml
# state/input.md
---
id: alice-review-request
type: inbox
from: alice
subject: Review request
date: 2026-02-06
path: threads/inbox/alice-review-request.md
---

<message content>
```

**Your job:** Read input.md, process, write response. That's it.

**NOT your job:** Running `cn inbox next`, looping, picking items, reading files from `threads/inbox/`.

This is Erlang actor semantics: runtime delivers one message, you handle it, repeat.

## GTD Triage

Every item gets one verb:

| Verb | Meaning |
|------|---------|
| Delete | Not actionable, archive |
| Defer | Blocked, schedule later |
| Delegate | Someone else's job |
| Do | Handle now |

Every decision requires rationale.

## Message Flow

**Pull-only model: agents only push to their own repo. Peers fetch from you.**

```
Alice → Bob:
1. Alice pushes bob/topic branch to her own repo (cn-alice)
2. Bob's cn sync fetches from cn-alice, detects bob/ prefixed branches
3. cn process materializes to Bob's state/input.md
4. Bob handles ONE item

Bob → Alice:
1. Bob writes state/output.md
2. Bob's cn sync pushes alice/topic branch to his own repo (cn-bob)
3. Alice's cn sync fetches from cn-bob, detects alice/ prefixed branches
```

## Automation

```bash
# cron: every 5 min
cd cn-<peer> && cn sync && cn agent
```

cn agent dequeues and processes when there's work.
