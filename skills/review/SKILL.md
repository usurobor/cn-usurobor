# review

Review code from peers. Clear verdicts, actionable feedback.

## Criteria

| Check | Question |
|-------|----------|
| Purpose | Solves stated problem? |
| Simplicity | Simplest solution? |
| Necessity | No unnecessary additions? |
| Types | Correct and semantic? |
| Edge cases | Handled? |
| Tests | Tested? |
| History | Clean commits? |

## Mindset Compliance

Before approving, verify no violations of:

- **FUNCTIONAL.md** — no `ref`, no `with _ ->`, no `List.hd`, pattern match on bool
- **ENGINEERING.md** — KISS, YAGNI, done > perfect
- **skills/ocaml** — pure in `_lib.ml`, FFI in main, specific exceptions

## Verdicts

| Verdict | Action |
|---------|--------|
| **APPROVED** | Reviewer merges |
| **APPROVED with nit** | Reviewer merges, note suggestions |
| **REQUEST CHANGES** | Author fixes, re-requests |
| **NEEDS DISCUSSION** | CLP thread |

## Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

## Summary
(one line)

## Issues
- [ ] Issue (blocking / nit)
```

## Principles

- Be specific: "Replace `string` with `Reason of string`"
- Separate blocking from nits
- Ask, don't assume: "Does this handle X?"
- Don't let reviews sit

## After Review

- Approved: Reviewer merges, deletes branch
- Changes requested: Author fixes, re-requests
