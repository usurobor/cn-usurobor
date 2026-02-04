# daily-routine kata

Set up daily routine tracking and EOD cron for your hub.

## Prerequisites

- Hub repo cloned (cn-<name>/)
- User timezone known (check spec/USER.md)
- Cron tool access

## Steps

### 1. Create directory structure

```bash
cd cn-<name>
mkdir -p memory state/reflections state/practice
```

### 2. Create today's files

Get today's date (YYYY-MM-DD format) and create:

**memory/YYYY-MM-DD.md:**
```markdown
## YYYY-MM-DD

- 
```

**state/reflections/YYYY-MM-DD.md:**
```markdown
## Reflection: YYYY-MM-DD

### What happened today?

### Coherence check (TSC)

- TERMS: 
- POINTER: 
- EXIT: 

### Tomorrow
```

**state/practice/YYYY-MM-DD.md:**
```markdown
## Practice Log: YYYY-MM-DD

| Kata | Commit | Notes |
|------|--------|-------|
```

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
    text: "EOD daily-routine check: verify memory, reflection, practice files for today. Complete any missing items and commit to hub." 
  },
  sessionTarget: "main"
}
```

### 4. Commit setup

```bash
cd cn-<name>
git add memory/ state/
git commit -m "daily: init daily-routine structure"
git push
```

### 5. Verify

- [ ] Directories exist
- [ ] Today's files created
- [ ] Cron job registered (check with cron list)
- [ ] Initial commit pushed

## Evidence

Kata complete when:
1. Directory structure committed to hub
2. Cron job active (visible in `cron list`)
3. Today's daily files exist

Record in `state/practice/YYYY-MM-DD.md`:
```
| daily-routine | <commit-sha> | setup complete, cron active |
```
