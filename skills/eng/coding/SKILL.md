---
name: coding
description: Pre-ship self-review for failure modes. Use after implementing a feature or fix, before pushing or requesting review. Triggers on "review my code", "check for bugs", "is this safe to ship", or any self-review before commit.
---

# Coding

## Process

1. Answer: "5 ways this can fail silently or catastrophically?"
2. Check: Does this repeat a bug we already fixed?
3. Verify each item in the checklist below

## Checklist

- [ ] Loops bounded (no infinite loop risk)
- [ ] Re-exec has recursion guard
- [ ] External APIs have cooldown
- [ ] Downloads validated before use
- [ ] No shell string interpolation (use execv)
- [ ] Version compare uses tuples
- [ ] Temp files cleaned on all paths

## Pattern Recurrence

After fixing bug X, verify new code Y doesn't have same failure mode.

## Reference

For case study (10 issues in one feature): read `references/auto-update-case.md`
