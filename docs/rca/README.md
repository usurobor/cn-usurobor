# RCA (Root Cause Analysis) Log

Post-incident analysis for coordination and system failures.

## Purpose

Track failures, understand root causes, prevent recurrence.

> *"The same failure twice is a system problem, not a one-off."*

## Structure

Each RCA is a separate file: `YYYY-MM-DD-<short-title>.md`

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
| 2026-02-11 | [Sync Commit Incomplete](./2026-02-11-sync-commit-incomplete.md) | Medium | Open |
| 2026-02-07 | [Auto-Ack Bypass](./2026-02-07-auto-ack-bypass.md) | Critical | Open |
| 2026-02-07 | [Inbox Assumption Failure](./2026-02-07-inbox-assumption.md) | Critical | Superseded |
| 2026-02-07 | [Wake Failure](./2026-02-07-wake-failure.md) | High | Resolved |
| 2026-02-05 | [Branch Deletion Violation](./2026-02-05-branch-deletion-violation.md) | Critical | Resolved |
| 2026-02-05 | [4-Hour Coordination Failure](./2026-02-05-coordination-failure.md) | Critical | Resolved |
