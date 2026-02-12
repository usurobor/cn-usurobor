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
id: pi-review-request
type: inbox
from: pi
subject: Review request
date: 2026-02-06
path: threads/inbox/pi-review-request.md
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

```
Pi → Sigma:
1. Pi pushes sigma/topic to cn-sigma
2. cn sync detects it
3. cn process materializes to state/input.md
4. Sigma handles ONE item

Sigma → Pi:
1. Sigma writes state/output.md
2. cn sync sends to cn-pi
```

## Automation

```bash
# cron: every 5 min
cd cn-sigma && cn sync && cn process
```

cn wakes agent when there's work.
