# daily-routine – v1.1.0

Ensures daily state files (memory, reflection, practice) are created, populated, and committed to the hub repo. Sets up EOD cron to catch incomplete days.

---

## Ownership & Schema

**daily-routine orchestrates; it does not own reflection schema.**

| Directory | Owner | Schema |
|-----------|-------|--------|
| `memory/` | daily-routine | Freeform session logs |
| `state/reflections/` | **reflect** | TSC α/β/γ (see reflect skill) |
| `state/practice/` | daily-routine | Kata completion table |

For reflections, daily-routine:
- Checks if today's reflection file exists at `state/reflections/daily/YYYY-MM-DD.md`
- If missing, prompts the agent to run the reflect skill
- MUST NOT write reflection files directly (reflect owns the schema)

---

## TERMS

- Hub repo is cloned and writable at `cn-<name>/`
- User timezone is defined in `spec/USER.md`
- Agent has cron tool access
- **reflect skill is available** (for reflection file creation)

## INPUTS

- `timezone`: User's timezone from USER.md (e.g., "ET", "America/New_York")

## EFFECTS

- Creates daily directory structure if missing:
  ```
  cn-<name>/
  ├── memory/
  │   └── YYYY-MM-DD.md
  └── state/
      ├── reflections/
      │   └── daily/
      │       └── YYYY-MM-DD.md   ← created by reflect skill
      └── practice/
          └── YYYY-MM-DD.md
  ```
- For memory/: creates file with freeform template
- For state/practice/: creates file with kata table template
- For state/reflections/: checks existence, invokes reflect if missing
- Commits completed daily files to hub
- Sets up EOD cron job (23:30 user timezone)

---

## Directory Structure

| Directory | Owner | Purpose | Template |
|-----------|-------|---------|----------|
| `memory/` | daily-routine | Raw session logs | `## YYYY-MM-DD\n\n- ` |
| `state/reflections/daily/` | reflect | TSC coherence checks | α/β/γ + Σ + → Next (see reflect skill) |
| `state/practice/` | daily-routine | Kata completions | `## Practice Log\n\n\| Kata \| Commit \| Notes \|\n` |

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
