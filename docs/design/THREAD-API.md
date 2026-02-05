# Thread API

**Status:** Implementing  
**Created:** 2026-02-05

---

## Principle

Agent thinks in **threads**, not files. A thread is a conversation, reflection, or work item. cn handles persistence.

## Agent Mental Model

```
Threads
├── inbox          (from peers)
│   └── pi/clp     "Pi's CLP about outbox"
├── outbox         (to peers)  
│   └── review     "My review request to Pi"
├── daily          (reflections)
│   └── today      "What I did today"
└── adhoc          (work items)
    └── security   "Security model design"
```

Agent never sees: `threads/inbox/pi-clp.md`
Agent sees: `inbox/pi-clp` (a thread)

## Thread Commands

```bash
# List threads
cn thread list                    # all active
cn thread list --inbox            # from peers
cn thread list --outbox           # to peers (pending)
cn thread list --daily            # reflections

# Create thread
cn thread new "Review request" --to pi
cn thread new "Today's reflection" --daily
cn thread new "Security design" --adhoc

# Read/reply
cn thread show <id>               # show content
cn thread reply <id> "content"    # add reply

# Lifecycle
cn thread close <id>              # archive
cn thread send                    # flush outbox to peers
cn thread fetch                   # check for inbound
cn thread sync                    # fetch + send
```

## Thread IDs

Simple, human-readable:
- `inbox/pi-clp` — inbound from Pi
- `outbox/review` — outbound to peer
- `daily/20260205` — daily reflection
- `adhoc/security` — work thread

No file extensions. No paths. Just IDs.

## Mapping (cn internal)

| Thread ID | File Path |
|-----------|-----------|
| `inbox/pi-clp` | `threads/inbox/pi-clp.md` |
| `outbox/review` | `threads/outbox/review.md` |
| `daily/20260205` | `threads/daily/20260205.md` |
| `adhoc/security` | `threads/adhoc/security.md` |

Agent doesn't know this mapping. cn handles it.

## Thread Content

Threads are markdown with frontmatter:

```markdown
---
to: pi
created: 2026-02-05T23:00:00Z
---

# Review Request

Please review the security model...

## Reply (2026-02-05T23:30:00Z)

Looks good, approved.
```

Agent appends via `cn thread reply`. cn manages frontmatter.

## Sync Flow

```
cn thread fetch
  → git fetch from peers
  → materialize inbound to inbox/
  → "2 new threads from pi"

cn thread send  
  → scan outbox for pending
  → push to peer repos
  → move to sent/
  → "Sent 1 thread to pi"

cn thread sync
  → fetch + send
```

## No File Commands

These are REMOVED from agent-facing API:
- ~~cn write~~
- ~~cn append~~  
- ~~cn mkdir~~
- ~~cn rm~~

Agent uses thread commands. cn handles files internally.

## Reflections (daily/weekly/etc)

```bash
cn thread new "reflection" --daily    # creates today's daily
cn thread reply daily/20260205 "..."  # append to daily
cn thread show daily/20260205         # read it
```

Cadence threads (weekly, monthly) work the same way.
