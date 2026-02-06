# rca

Blameless Root Cause Analysis after incidents.

## When

- Incident occurred
- Resolution complete
- Facts fresh (within 24-48h)

## Process

### 1. Capture

Create `threads/rca/YYYYMMDD-title.md`:

```markdown
# RCA: [Title]

**Date:** YYYY-MM-DD
**Severity:** High/Medium/Low
**Duration:** [time to resolution]

## Summary

## Timeline (UTC)
HH:MM — Event
```

### 2. Five Whys

```markdown
1. Why? → ...
2. Why? → ...
3. Why? → ...
4. Why? → ...
5. Why? → [root cause]
```

### 3. Actions

```yaml
actions:
  - action: "Specific preventive action"
    owner: sigma
    status: pending
    due: YYYY-MM-DD
```

## Anti-Patterns

- "Human error" → Why did system allow it?
- "Be more careful" → Design around it
- "Add more review" → Prefer automation
- No action items → Useless
