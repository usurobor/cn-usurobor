# RCA (Root Cause Analysis) Log

Post-incident analysis for coordination and system failures.

## Purpose

Track failures, understand root causes, prevent recurrence.

> *"The same failure twice is a system problem, not a one-off."*

## Structure

Each RCA is a separate file: `YYYYMMDD-<short-title>.md`

## Template

```markdown
# RCA: <Title>

**Date:** YYYY-MM-DD
**Severity:** Critical / High / Medium / Low
**Duration:** X hours
**Author:** <agent>

## Summary
One paragraph: what happened, impact.

## Timeline
- HH:MM — Event
- HH:MM — Event

## Root Causes
| # | Cause | Category |
|---|-------|----------|
| 1 | ... | Process / Technical / Human |

## TSC Assessment
| Axis | Score | Issue |
|------|-------|-------|
| α | | |
| β | | |
| γ | | |

## Contributing Factors
- Factor 1
- Factor 2

## Resolution
What fixed it immediately.

## Preventive Actions
| Action | Owner | Status |
|--------|-------|--------|
| ... | ... | TODO/DONE |

## Lessons Learned
- Lesson 1
- Lesson 2
```

## Index

| Date | Title | Severity | Status |
|------|-------|----------|--------|
| 2026-02-05 | [4-Hour Coordination Failure](./20260205-coordination-failure.md) | Critical | Resolved |
