> **ARCHIVED** — Superseded by [PROTOCOL.md](../PROTOCOL.md) and [ARCHITECTURE.md](../../ARCHITECTURE.md).
> See [AUDIT.md](../AUDIT.md) for details. Preserved for historical reference.

# Threads Model

**Status:** Implemented  
**Created:** 2026-02-05

---

## Principle

Agent writes prose (action plans). cn interprets and executes.

Agent never runs git commands. cn does all effects.

## Directory Structure

```
threads/
├── inbox/      ← cn materializes inbound here
├── outbox/     ← agent writes new outbound here
├── sent/       ← cn moves sent threads here
├── archived/   ← cn moves replied inbox threads here
└── adhoc/      ← regular threads (not scanned)
```

## Inbound Flow (inbox)

```
Peer pushes branch to MY repo (pi/some-message)
    ↓
cn inbox check — lists inbound branches
    ↓
cn inbox process — materializes to threads/inbox/pi-some-message.md
    ↓
Agent reads thread, writes reply (adds ## Reply section)
    ↓
cn inbox flush — detects reply, pushes back to peer, archives thread
```

## Outbound Flow (outbox)

```
Agent writes threads/outbox/some-request.md
    with frontmatter: to: pi
    ↓
cn outbox check — lists pending sends
    ↓
cn outbox flush — pushes to peer's clone, moves to threads/sent/
```

## Frontmatter

### Inbox threads (cn adds)
```yaml
---
from: pi
branch: pi/some-message
file: threads/adhoc/20260205-some-message.md
received: 2026-02-05T22:00:00Z
---
```

### Outbox threads (agent writes)
```yaml
---
to: pi
subject: Review request
---
```

### Sent threads (cn updates)
```yaml
---
to: pi
subject: Review request
sent: 2026-02-05T22:05:00Z
---
```

## Reply Detection

cn scans inbox threads for agent replies. A reply is detected when:
- Frontmatter has `reply: true`, or
- Content contains `## Reply` or `## Response` section

## Commands

```bash
cn inbox check     # list inbound branches (from peers)
cn inbox process   # materialize to threads/inbox/
cn inbox flush     # detect replies, send back to peers

cn outbox check    # list pending sends (threads/outbox/)
cn outbox flush    # push to peers, move to threads/sent/

cn sync            # full sync: inbox check/process/flush + outbox flush
```

## Logging

All operations logged to `logs/cn.log`:

```jsonl
{"ts":"...","action":"inbox.fetch","from":"pi","branches":["pi/xyz"],"count":1}
{"ts":"...","action":"inbox.materialize","from":"pi","branch":"pi/xyz","inboxFile":"pi-xyz.md"}
{"ts":"...","action":"inbox.reply","to":"pi","thread":"pi-xyz.md","branch":"sigma/xyz-reply","result":"ok"}
{"ts":"...","action":"outbox.send","to":"pi","thread":"request.md","branch":"sigma/request","result":"ok"}
```

## Actor Model

- **Inbound**: Check MY repo for peer/* branches
- **Outbound**: Push to PEER's clone (their repo)
- Peer clones configured in `state/peers.md` with `clone:` path
