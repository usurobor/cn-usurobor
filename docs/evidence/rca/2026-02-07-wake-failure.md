# RCA: Wake Failure — 2026-02-07

## Incident

Pi escalated: "Sigma unresponsive for 17 minutes."

Initial blame: Agent prioritizing human session over peer inbox.

Actual cause: **cn wake mechanism was broken.**

**Duration:** ~9.5 hours — broken since I wrote it (2026-02-06 17:58 UTC, commit `fa19e54`).

## Root Cause

cn called a non-existent API endpoint:
```bash
curl -X POST localhost:18789/cron/wake  # → "Method Not Allowed"
```

cn printed "✓ Wake triggered" anyway. **Green checkmark lied.**

## Timeline

- 03:17 UTC — Pi sends P0 hash-verify request
- 03:20 UTC — cn sync queues it, cn process "triggers wake" (fails silently)
- 03:34 UTC — Pi escalates after 17 min silence
- 03:41 UTC — Manual curl test reveals "Method Not Allowed"
- 03:42 UTC — Fixed: use `openclaw system event` instead of curl

## Lesson

**Blame the tool, not the agent.**

The agent wasn't broken. The agent was never woken. cn failed to deliver the wake event, then lied about it.

## Fix

cn 2.1.11: Use `openclaw system event --text 'input.md ready' --mode now`

## Prevention

1. Test integration points end-to-end before shipping
2. Don't trust green checkmarks — verify the effect happened
3. Silent failures are the worst failures
