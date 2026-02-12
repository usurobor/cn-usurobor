---
name: adversarial-review
description: Self-review code with adversarial mindset before shipping. Use after implementing a feature and before requesting review. Catches failure modes that confirmation bias misses.
---

# Adversarial Review

Review your own code as an attacker, not a validator.

## The Problem

When you implement code, you think "does it work?"
When you self-review, you should think "how does it fail?"

**Confirmation bias kills:** You wrote it, so you assume it works. You look for evidence it's correct, not evidence it's broken.

## Process

After implementing, before shipping:

1. **Step away mentally** — Pretend you didn't write this code
2. **Ask the failure question** — "List 5 ways this can fail silently or catastrophically"
3. **Run the checklist** — See `references/failure-modes.md`
4. **Check for pattern recurrence** — If fixing bug X, does new code have same failure mode?

## The Failure Question

For every feature, ask:

> What are 5 ways this can fail silently or catastrophically?

Don't stop at 3. Push to 5. The 4th and 5th are usually the ones that ship.

## Pattern Recurrence

When implementing feature X that's similar to fixed bug Y:

1. Recall Y's root cause
2. Ask: "Can X fail the same way?"
3. Write explicit guard against Y's failure mode

**Example:** You just fixed an infinite loop timeout bug. Now you're writing auto-update with re-exec. Ask: "Can this infinite loop?"

## Severity Escalation

After finding a failure mode, rate it:

| Level | Definition | Action |
|-------|------------|--------|
| **Silent** | Fails without error | MUST FIX |
| **Catastrophic** | Breaks system/data | MUST FIX |
| **Noisy** | Fails with clear error | Fix if easy |
| **Recoverable** | System self-heals | Document |

Silent + Catastrophic = worst bugs. They ship undetected, then cause outages.

## Quick Reference

Before pushing:

```
□ "5 ways this can fail?"
□ Checked references/failure-modes.md
□ Pattern recurrence check (does it repeat a known bug?)
□ No silent failures
□ No catastrophic failures
```

## See Also

- `references/failure-modes.md` — Common failure mode checklist
- `references/auto-update-lessons.md` — Case study: 10 issues in one feature
