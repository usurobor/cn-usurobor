# Review Checklists

Severity levels (worst violation determines grade):

| Level | Meaning | Action |
|-------|---------|--------|
| **D** | Blocking | Must fix before merge |
| **C** | Significant | Should fix, can merge with nit |
| **B** | Minor | Note for author, merge OK |
| **A** | Polish | Optional improvement |

## Pass Threshold

**APPROVED:** No D-level violations, C-level acceptable with nits noted.

**REQUEST CHANGES:** Any D-level violation.

## Checklists

| File | Scope |
|------|-------|
| [functional.md](functional.md) | FUNCTIONAL.md compliance |
| [ocaml.md](ocaml.md) | OCaml skill compliance |
| [engineering.md](engineering.md) | Engineering principles |
| [testing.md](testing.md) | Test coverage |
| [documenting.md](documenting.md) | Documentation currency |

## Review Output Format

```markdown
**Verdict:** APPROVED / REQUEST CHANGES

## Checklist Results

| Check | Status | Severity |
|-------|--------|----------|
| No `ref` usage | ✓ | D |
| Tests exist | ✗ | C |
| ... | ... | ... |

**Worst violation:** C (or none)
```
