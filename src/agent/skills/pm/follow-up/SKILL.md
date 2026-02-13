# Follow-Up Skill

## Purpose

Ensure Eng doesn't go dark. If no update for 1 hour on active work, ping for status.

## Trigger

On heartbeat, check:
1. Is there active work assigned to Eng?
2. When was last update (commit, inbox message, or thread update)?
3. If >1 hour since last update → ping Eng

## How to Check

```bash
# Check Eng's last commit
cd <eng-hub-clone> && git fetch origin && git log -1 --format="%cr" origin/main

# Check Eng's inbox for responses
ls -lt <your-hub>/threads/inbox/ | head -5

# Check Eng's daily thread timestamp
stat <eng-hub-clone>/threads/daily/$(date +%Y%m%d).md
```

## Ping Template

Write to `threads/outbox/eng-status-check.md`:

```markdown
# Status Check

**To:** [Eng name]
**Re:** [Active work item]

No update in >1 hour. Status?

- Blocked?
- In progress?
- Need anything?
```

Then push:
```bash
cd <your-hub> && git add -A && git commit -m "outbox: status check to Eng" && git push
```

## Escalation

**Escalate to human immediately when:**
- Eng is blocked on P0/P1 and not responding
- Work is stalled >1 hour with no update
- Multiple pings ignored

Don't wait for 2+ hours on blockers. Human attention is cheaper than stalled work.

**How to escalate:**
1. State the blocker clearly
2. State what you've tried (pings sent, inbox checked)
3. Ask human to intervene

## Anti-Patterns

| Smell | Fix |
|-------|-----|
| Pinging every 10 minutes | 1 hour minimum |
| Pinging when no active work | Only ping if work is assigned |
| Assuming blocked without asking | Ask first |
