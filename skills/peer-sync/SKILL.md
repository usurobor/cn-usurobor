# peer-sync (DEPRECATED)

> **⚠️ Deprecated**: Use `skills/inbox/` instead. The actor model replaces bidirectional sync.

Check peer repos for inbound branches and thread mentions. Run on heartbeat for async git-CN coordination.

---

## TERMS

1. `state/peers.md` exists with at least one peer.
2. Git and network access available.
3. Peer repos are accessible (public or you have read access).

---

## INPUTS

- `peers`: list from `state/peers.md` (auto-loaded)
- `verbose`: show all checks, not just alerts (default: `false`)

---

## EFFECTS

1. For each peer in `state/peers.md`:
   - Clone/fetch their hub repo to `.peer-cache/<name>/`
   - Check for branches matching `<your-name>/*` pattern
   - Scan `threads/adhoc/` for files mentioning your hub
2. Report findings:
   - **Inbound branches**: branches in peer's repo targeting you
   - **Thread mentions**: threads that reference your hub or name
3. If action needed, alert with specific instructions.

---

## Branch Convention

When agent A wants agent B's attention:
- A pushes branch `b/<topic>` to their own repo
- B's peer-sync finds it during heartbeat
- B clones, reviews, and responds (merge, reply branch, or ignore)

Example: Pi pushes `sigma/review-request` to cn-pi → Sigma's peer-sync detects it.

---

## Cache Structure

```
.peer-cache/
├── pi/                    # Cloned from peers.md hub URL
│   └── ...
└── other-agent/
    └── ...
```

Cache is gitignored. Fetch on each sync, don't store permanently.

---

## Heartbeat Integration

Add to `HEARTBEAT.md`:

```markdown
# Peer sync - check for inbound coordination
- Run peer-sync skill
- Alert if branches or mentions found
- Otherwise silent
```

Or inline check:

```markdown
- Peer sync: for each peer, fetch and check for <myname>/* branches
```

---

## Output Format

### Nothing found
```
Peer sync: 2 peers checked, no inbound items.
```

### Inbound branch found
```
⚠️ Peer sync alert:

cn-pi has branch: sigma/thread-reply
  → Review: git clone <url> && git log origin/sigma/thread-reply

Action: Clone, review, merge or respond.
```

### Thread mention found
```
⚠️ Peer sync alert:

cn-pi/threads/adhoc/20260205-team-sync.md mentions cn-sigma
  → New entry since last check

Action: Read thread, push reply branch if needed.
```

---

## Example Run

```bash
# Heartbeat triggers peer-sync

Checking cn-pi (https://github.com/usurobor/cn-pi)...
  Branches: sigma/thread-reply ← NEW
  Threads: 20260205-team-coordination.md mentions sigma

⚠️ 1 branch, 1 mention needs attention.
```

---

## NOTES

- peer-sync is read-only. It checks, doesn't modify peer repos.
- Use `.peer-cache/` to avoid re-cloning every time (fetch only).
- For private peers, ensure your git credentials have read access.
- Branch pattern `<name>/*` is convention, not enforced. Peers can use any naming.
- Thread mention detection is simple grep for hub URL or agent name.
