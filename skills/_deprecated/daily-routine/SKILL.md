# Daily Routine – v1.2.0

> **⚠️ DEPRECATED:** This skill is superseded by `reflect` + the unified threads model.
> 
> **Migration:**
> - `memory/` → `threads/daily/` (raw notes go in daily threads)
> - `state/practice/` → removed (track kata in daily threads or adhoc)
> - Reflections → `reflect` skill with α/β/γ framework
> 
> This file is kept for reference during transition.

---

Ensures daily state files (memory, reflection thread, practice) are created, populated, and committed to the hub repo. Sets up EOD cron to catch incomplete days.

---

## Ownership & Schema

**daily-routine orchestrates; it does not own reflection schema.**

| Directory | Owner | Schema |
|-----------|-------|--------|
| `memory/` | daily-routine | Freeform session logs |
| `threads/` | **reflect** | TSC α/β/γ for periodic threads (see reflect skill) |
| `state/practice/` | daily-routine | Kata completion table |

For reflections, daily-routine:
- Checks if today's reflection thread exists at `threads/YYYYMMDD-daily.md`
- If missing, prompts the agent to run the reflect skill
- MUST NOT write reflection threads directly (reflect owns the schema)

---

## Scope (Protocol vs Template)

`memory/` and `state/practice/` are **cn-agent template conventions**, not git-CN protocol requirements.

- The protocol minimum is: `cn.json`, `.gitattributes`, `threads/`, signatures.
- These directories are recommended practice patterns for Coherent Agent workflows.
- Other git-CN implementations MAY use different logging patterns or omit these entirely.

See whitepaper §4.1 and Appendix A.1 for the protocol-level requirements.

---

## TERMS

- Hub repo is cloned and writable at `cn-<name>/`
- User timezone is defined in `spec/USER.md`
- Agent has cron tool access (OpenClaw `cron` tool or equivalent)
- **reflect skill is available** (for reflection thread creation)

## INPUTS

- `timezone`: User's timezone from USER.md (e.g., "ET", "America/New_York")

## EFFECTS

- Creates daily directory structure if missing:
  ```
  cn-<name>/
  ├── memory/
  │   └── YYYY-MM-DD.md
  ├── threads/
  │   └── YYYYMMDD-daily.md   ← created by reflect skill
  └── state/
      └── practice/
          └── YYYY-MM-DD.md
  ```
- For memory/: creates file with freeform template
- For state/practice/: creates file with kata table template
- For threads/: checks if daily reflection exists, invokes reflect if missing
- Commits completed daily files to hub
- Sets up EOD cron job (23:30 user timezone)

---

## Directory Structure

| Directory | Owner | Purpose | Template |
|-----------|-------|---------|----------|
| `memory/` | daily-routine | Raw session logs | `## YYYY-MM-DD\n\n- ` |
| `threads/` | reflect | Threads including daily reflections | `YYYYMMDD-daily.md` (see reflect skill) |
| `state/practice/` | daily-routine | Kata completions | `## Practice Log\n\n\| Kata \| Commit \| Notes \|\n` |

## Daily File Naming

- Memory: `YYYY-MM-DD.md` (ISO 8601 date)
- Practice: `YYYY-MM-DD.md` (ISO 8601 date)
- Threads: `YYYYMMDD-<type>.md` (compact date prefix)

## Commit Convention

```
daily: YYYYMMDD [components]

- memory: [summary]
- thread: daily reflection
- practice: [kata name] or "skipped" or "pending"
```

Example:
```
daily: 20260204 memory+thread

- memory: 2 sessions, workspace setup
- thread: daily α=A β=A γ=B
- practice: skipped
```

## EOD Cron Setup

The skill sets up a cron job to run at 23:30 in the user's timezone:

```
schedule: { kind: "cron", expr: "30 23 * * *", tz: "<user-timezone>" }
payload: { kind: "systemEvent", text: "EOD daily-routine check: verify memory, daily thread, practice files for today. Complete any missing items and commit to hub." }
sessionTarget: "main"
```

### Runtime Note

The JSON format above is for OpenClaw's built-in `cron` tool. For other runtimes:

**Standard crontab** (user's timezone must be set on host):
```
30 23 * * * echo "EOD daily-routine check" | <agent-trigger-command>
```

**systemd timer:**
```ini
# ~/.config/systemd/user/daily-routine.timer
[Timer]
OnCalendar=*-*-* 23:30:00
Persistent=true
```

Adapt the trigger mechanism to your runtime. The intent is: fire once daily at 23:30 local time with a prompt to check/complete daily files.

## Status Check

When invoked or on cron trigger, report:

```
## Daily Status: YYYYMMDD

- [x] memory: captured (3 entries)
- [ ] thread: YYYYMMDD-daily.md missing
- [x] practice: hello-world (abc123)

Action: Running reflect skill...
```

## Kata

See `kata.md` for setup and first-day execution.
