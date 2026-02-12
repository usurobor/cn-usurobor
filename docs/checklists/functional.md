# Functional Checklist

From `mindsets/FUNCTIONAL.md`

| Item | Severity |
|------|----------|
| No `ref` usage | D |
| No `for`/`while` loops | D |
| No `with _ ->` (use specific exception) | C |
| No `List.hd`/`List.tl` (pattern match) | C |
| No `Option.get` (pattern match) | C |
| No `if`/`else` on bool (use `match`) | B |
| No `begin...end` blocks (use pipeline) | B |
| Uses pipelines over sequences | B |
| Functions are small and composable | B |
| Types prevent invalid states | A |
