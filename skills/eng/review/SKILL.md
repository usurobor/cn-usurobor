# review

Review code from peers. Clear verdicts, actionable feedback.

## 1. Go through `checklist.md`

Stop at first P0 or P1 failure → request fix. Don't continue reviewing.

## Philosophy

- **Be specific.** "Replace `string` with `Reason of string`" not "fix types"
- **Separate blocking from nits.** Blocking stops merge. Nits are suggestions.
- **Ask, don't assume.** "Does this handle X?" not "This doesn't handle X"
- **Don't let reviews sit.** Review promptly or hand off.

## Verdicts

| Verdict | When |
|---------|------|
| **REQUEST REBASE** | Branch behind main |
| **APPROVED** | All checks pass |
| **APPROVED with nit** | Pass, minor suggestions |
| **REQUEST CHANGES** | Blocking issues |
| **NEEDS DISCUSSION** | Requires CLP thread |

## Format

**Rejection (P0/P1 failure):**
```markdown
**Verdict:** REQUEST CHANGES

**Violation:** <checklist item number>

**Details:** <how exactly it's violated>
```

**Approval:**
```markdown
**Verdict:** APPROVED

## Summary
(one line)

## Nits
- (optional suggestions)
```
