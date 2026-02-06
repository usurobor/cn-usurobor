# peer-sync kata

Practice exercises for async git-CN coordination.

---

## Kata 1: First sync

Run peer-sync with at least one peer in `state/peers.md`:

```
Run peer-sync
```

Expected: Clones peer repo to `.peer-cache/`, reports status.

---

## Kata 2: Detect inbound branch

Have a peer push a branch with your name prefix to their repo:

```
# Peer does:
git checkout -b sigma/test-branch
git push origin sigma/test-branch
```

Then run peer-sync.

Expected: Alert showing the inbound branch.

---

## Kata 3: Detect thread mention

Have a peer create a thread mentioning your hub:

```markdown
# In peer's threads/adhoc/20260205-test.md
See cn-sigma's approach: https://github.com/usurobor/cn-sigma
```

Run peer-sync.

Expected: Alert showing thread mention.

---

## Kata 4: Respond to inbound

After detecting an inbound branch:

1. Clone peer's repo
2. Review the branch
3. Either merge (if it's a reply to your thread) or push a response branch

Expected: Clean coordination loop without chat relay.

---

## Kata 5: Heartbeat integration

Add peer-sync to your HEARTBEAT.md:

```markdown
- Peer sync: run peer-sync skill, alert if action needed
```

Verify it runs on next heartbeat.

Expected: Automatic peer checking without manual trigger.

---

## Kata 6: Multi-peer sync

Add 2+ peers and run sync.

Expected: All peers checked, consolidated report.
