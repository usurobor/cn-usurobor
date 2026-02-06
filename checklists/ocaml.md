# OCaml Checklist

From `skills/ocaml/SKILL.md`

| Item | Severity |
|------|----------|
| Pure functions in `_lib.ml` | D |
| FFI only in main `.ml` | D |
| No `with _ ->` (specific exceptions) | C |
| No partial functions (`List.hd`, `Option.get`) | C |
| Types use semantic wrappers where needed | B |
| ppx_expect tests exist | B |
| Bundled `.js` committed | C |
| README in tool directory | A |
