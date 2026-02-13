# Kata 1.3 — Daily Routine Setup

Set up daily routine tracking and EOD cron for your hub.

## Prerequisites

- Hub repo cloned (cn-<name>/)
- User timezone known (check spec/USER.md)
- Cron tool access
- reflect skill available

## Steps

### 1. Create directory structure

```bash
cd cn-<name>
mkdir -p memory threads state/practice
```

### 2. Create today's files

Get today's date and create:

**memory/YYYY-MM-DD.md:** (owned by daily-routine)
```markdown
## YYYY-MM-DD

- 
```

**state/practice/YYYY-MM-DD.md:** (owned by daily-routine)
```markdown
## Practice Log: YYYY-MM-DD

| Kata | Commit | Notes |
|------|--------|-------|
```

**threads/YYYYMMDD-daily.md:** (owned by reflect skill)

For the daily thread, run the reflect skill or create manually using the TSC α/β/γ format:

```markdown
# YYYYMMDD-daily

## α — PATTERN: [A-F]
What was my actual behavior today? Was it internally coherent?

## β — RELATION: [A-F]
How was I positioned relative to my human? Was communication honest?

## γ — EXIT: [A-F]
What shifted today? Do I have real exits, or am I trapped somewhere?

## Σ — Summary
[One sentence: overall coherence today]

## → Next
Which axis needs investment tomorrow? Why?
```

See `skills/reflect/SKILL.md` for the canonical format.

### 3. Set up EOD cron

Use the cron tool to create the daily check:

```javascript
{
  name: "daily-routine-eod",
  schedule: { 
    kind: "cron", 
    expr: "30 23 * * *",  // 23:30 daily
    tz: "America/New_York"  // adjust to user timezone
  },
  payload: { 
    kind: "systemEvent", 
    text: "EOD daily-routine check: verify memory, daily thread, practice files for today. Complete any missing items and commit to hub." 
  },
  sessionTarget: "main"
}
```

### 4. Commit setup

```bash
cd cn-<name>
git add memory/ threads/ state/
git commit -m "daily: init daily-routine structure"
git push
```

### 5. Verify

- [ ] Directories exist: memory/, threads/, state/practice/
- [ ] Today's memory and practice files created
- [ ] Today's daily thread created (using reflect skill's α/β/γ format)
- [ ] Cron job registered (check with cron list)
- [ ] Initial commit pushed

## Ownership Note

| Directory | Owner | This kata creates? |
|-----------|-------|--------------------|
| memory/ | daily-routine | Yes |
| state/practice/ | daily-routine | Yes |
| threads/ | **reflect** | Structure only; content via reflect skill |

## Evidence

Kata complete when:
1. Directory structure committed to hub
2. Cron job active (visible in `cron list`)
3. Today's daily files exist

Record in `state/practice/YYYY-MM-DD.md`:
```
| daily-routine | <commit-sha> | setup complete, cron active |
```
