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

If no response after 2 pings (2+ hours):
1. Note in daily thread
2. Flag to human on next interaction

## Anti-Patterns

| Smell | Fix |
|-------|-----|
| Pinging every 10 minutes | 1 hour minimum |
| Pinging when no active work | Only ping if work is assigned |
| Assuming blocked without asking | Ask first |
