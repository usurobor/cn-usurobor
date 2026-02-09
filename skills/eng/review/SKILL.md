# review

Review code from peers. Clear verdicts based on checklist compliance.

## Process

1. Read diff and commit messages
2. Run through checklists (see `checklists/`)
3. Record violations with severity
4. Determine verdict based on worst violation

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

- **APPROVED:** No D-level, C-level noted as nits
- **REQUEST CHANGES:** Any D-level violation

## Output Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

## Checklist Results

| Check | Status | Severity |
|-------|--------|----------|
| No `ref` usage | ✓ | D |
| Tests exist | ✗ | C |

**Worst violation:** C

## Notes
(specific feedback)
```

## After Review

- Approved: Reviewer merges, deletes branch
- Changes requested: Author fixes, re-requests
