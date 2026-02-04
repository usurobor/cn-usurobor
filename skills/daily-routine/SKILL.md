# daily-routine – v1.0.0

Ensures daily state files (memory, reflection, practice) are created, populated, and committed to the hub repo. Sets up EOD cron to catch incomplete days.

TERMS:
- Hub repo is cloned and writable at `cn-<name>/`
- User timezone is defined in `spec/USER.md`
- Agent has cron tool access

INPUTS:
- `timezone`: User's timezone from USER.md (e.g., "ET", "America/New_York")

EFFECTS:
- Creates daily directory structure if missing:
  ```
  cn-<name>/
  ├── memory/
  │   └── YYYY-MM-DD.md
  └── state/
      ├── reflections/
      │   └── YYYY-MM-DD.md
      └── practice/
          └── YYYY-MM-DD.md
  ```
- Commits completed daily files to hub
- Sets up EOD cron job (23:30 user timezone)

---

## Directory Structure

| Directory | Purpose | Template |
|-----------|---------|----------|
| `memory/` | Raw session logs, what happened | `## YYYY-MM-DD\n\n- ` |
| `state/reflections/` | Coherence checks, TSC application | See reflect skill |
| `state/practice/` | Kata completions with commit evidence | `## Practice Log\n\n| Kata | Commit | Notes |\n|------|--------|-------|\n` |

## Daily File Naming

Always: `YYYY-MM-DD.md` (ISO 8601 date)

## Commit Convention

```
daily: YYYY-MM-DD [components]

- memory: [summary]
- reflection: [summary]  
- practice: [kata name] or "skipped" or "pending"
```

Example:
```
daily: 2026-02-04 memory+practice

- memory: 2 sessions, workspace setup
- reflection: skipped
- practice: hello-world (abc123)
```

## EOD Cron Setup

The skill sets up a cron job to run at 23:30 in the user's timezone:

```
schedule: { kind: "cron", expr: "30 23 * * *", tz: "<user-timezone>" }
payload: { kind: "systemEvent", text: "EOD daily-routine check: verify memory, reflection, practice files for today. Complete any missing items and commit to hub." }
sessionTarget: "main"
```

## Status Check

When invoked or on cron trigger, report:

```
## Daily Status: YYYY-MM-DD

- [x] memory: captured (3 entries)
- [ ] reflection: missing
- [x] practice: hello-world (abc123)

Action: Creating reflection...
```

## Kata

See `kata.md` for setup and first-day execution.
