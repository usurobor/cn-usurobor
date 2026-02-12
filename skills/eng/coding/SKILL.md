---
name: coding
description: Pre-ship self-review discipline. Use after implementing and before requesting external review. Catches failure modes that confirmation bias misses.
---

# Coding

Adversarial self-review before shipping.

## The Discipline

After implementing, before pushing:

1. Ask: **"5 ways this can fail silently or catastrophically?"**
2. Check: **Does this repeat a bug we already fixed?**
3. Run the checklist below

## Pattern Recurrence

When implementing X similar to fixed bug Y, explicitly verify X doesn't have Y's failure mode.

**Example:** We fixed infinite-loop timeout bug. Next feature had re-exec that could infinite loop. Same class of bug, different manifestation.

## Pre-Ship Checklist

```
□ "5 ways to fail?" answered
□ Pattern recurrence check done
□ Loops bounded (no infinite loop risk)
□ Re-exec has recursion guard (env var)
□ External APIs have cooldown
□ Downloads validated before use
□ Shell commands use execv, not string interpolation
□ Version compare uses tuples, not strings
□ Temp files cleaned up on all paths
```

## Failure Severity

| Type | Action |
|------|--------|
| Silent + Catastrophic | MUST FIX |
| Noisy + Recoverable | Document, fix later |

## Reference

See `references/auto-update-case.md` for detailed case study (10 issues in one feature).
