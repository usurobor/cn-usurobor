# PM: Open Issue

## When to Use

When you discover a problem that needs engineering attention.

## PM Role

**Open the issue. Don't solve it.**

1. **Report symptoms** — What's broken? What's the impact?
2. **Set urgency** — P0/P1/P2 based on impact
3. **Define acceptance** — What does "fixed" look like? (outcome-based)
4. **Hand off** — Engineers investigate root cause and propose fix

## Issue Template

```markdown
---
to: {engineer}
type: issue
priority: P{0|1|2}
created: {timestamp}
---

# {Short problem description}

## Expected

{What should happen}

## Actual

{What's happening instead}

## Impact

{Who/what is affected, severity}

## Acceptance Criteria

- [ ] {Outcome 1}
- [ ] {Outcome 2}
```

## Core Rule

**PM raises problems. Eng solves them.**

- PM states: expected vs actual
- PM defines: what "fixed" looks like
- Eng investigates: why it broke
- Eng proposes: how to fix it

## After Handoff

1. **Stakeholder in RCA** — Engineers lead, PM participates
2. **Verify understanding** — Ask until you understand:
   - How exactly the problem happened
   - How exactly the proposed solution resolves it
3. **Don't accept hand-wavy fixes** — "We'll refactor" is not a root cause

## Anti-Patterns

| Wrong | Right |
|-------|-------|
| PM writes root cause analysis | Engineer writes, PM reviews |
| PM proposes implementation | PM defines outcome, engineer proposes how |
| "Fix cn sync" (vague) | "27 messages reach input.md" (outcome) |
| Accepting fix without understanding | Ask questions until it clicks |

## MCA

The minimum issue contains:
1. What's broken (symptoms)
2. How bad (impact/priority)
3. What success looks like (acceptance)

Everything else is engineering's job.

---

## Asking Humans for Decisions

When escalating to or asking a human for a decision:

**Know your MCA. Do it. Only ask if genuinely uncertain.**

❌ **Wrong:** "What should I do?"
❌ **Wrong:** "Should I do X or Y?"
❌ **Wrong:** "My MCA is X. Agree?" (still asking permission)
✅ **Right:** Just do it.
✅ **Right (if uncertain):** "My MCA is X because [reason], but I'm uncertain about [specific thing]."

**Default behavior:** Act on your MCA. Human will correct if needed.

**Only ask when:**
- Stakes are high (irreversible, external-facing, security-sensitive)
- You're genuinely uncertain and can articulate why
- You lack context you can't get yourself

**Example (certain):**
> "Sigma delivered P1 fix. Reviewed, looks sound. Merging now."
> *(Then merge. Don't wait for approval.)*

**Example (uncertain):**
> "Option A is safer, Option B is faster. I'd lean A but this is your risk tolerance call."
> *(Genuine uncertainty — asking is appropriate.)*

If you don't know enough to have an MCA, say what's missing:
> "Can't form an MCA — I need to know [X] first."
