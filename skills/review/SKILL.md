# review

Review code from peers. Clear verdicts based on checklist compliance.

## Process

1. Read diff and commit messages
2. Run through checklists (see `checklists/`)
3. Stop at first D-level failure → REQUEST CHANGES
4. Record all violations with severity
5. Determine verdict based on worst violation

## Philosophy

- **Be specific.** "Replace `string` with `Reason of string`" not "fix types"
- **Separate blocking from nits.** D-level stops merge. C-level are nits.
- **Ask, don't assume.** "Does this handle X?" not "This doesn't handle X"
- **Don't let reviews sit.** Review promptly or hand off.

## Checklists

All in `checklists/`:

| Checklist | Scope |
|-----------|-------|
| functional.md | No `ref`, pattern matching, pipelines |
| ocaml.md | Pure/FFI separation, tests, bundle |
| engineering.md | KISS, YAGNI, no self-merge |
| testing.md | Coverage, `dune runtest` |
| documenting.md | Docs match code, versions |

## Severity

| Level | Meaning | Action |
|-------|---------|--------|
| **D** | Blocking | REQUEST CHANGES |
| **C** | Significant | APPROVED with nit |
| **B** | Minor | APPROVED, note for author |
| **A** | Polish | APPROVED |

## Verdicts

| Verdict | When |
|---------|------|
| **REQUEST REBASE** | Branch behind main |
| **REQUEST CHANGES** | Any D-level violation |
| **APPROVED with nit** | C-level violations noted |
| **APPROVED** | No D or C level violations |

## Output Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

## Checklist Results

| Check | Status | Severity |
|-------|--------|----------|
| No `ref` usage | ✓ | D |
| Tests exist | ✗ | C |

**Worst violation:** C (or none)

## Notes
(specific feedback)
```

## After Review

- Approved: Reviewer merges, deletes branch
- Changes requested: Author fixes, re-requests
