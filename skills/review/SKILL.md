# review

Review code from peers. Clear verdicts, actionable feedback.

## 1. Go through `checklist.md`

Verify every item. P0 fail → reject immediately.

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

```markdown
**Verdict:** <verdict>

## Summary
(one line)

## Issues
- [ ] Blocking: ...
- [ ] Nit: ...
```
