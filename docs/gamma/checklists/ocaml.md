# OCaml Checklist

From `skills/ocaml/SKILL.md` + hardening rounds (2026-02-18)

## Structure

| Item | Severity |
|------|----------|
| Pure functions in `_lib.ml` | D |
| FFI only in main `.ml` | D |
| Types use semantic wrappers where needed | B |
| README in tool directory | A |

## Safety

| Item | Severity |
|------|----------|
| `Filename.quote` for shell interpolation (not hand-rolled) | C |
| Semantic version cmp (not string cmp) | C |
| No `with _ ->` (specific exceptions) | C |
| No partial functions (`List.hd`, `Option.get`) | C |
| Bounds-check before `String.sub` / `String.get` | C |
| `Fun.protect` on file handles (ensure cleanup on exception) | C |
| No `let _ =` on `Result.t` — handle errors explicitly | C |

## Style

| Item | Severity |
|------|----------|
| Prefer `fold_left` / `fold_right` over manual iteration | B |
| Prefer `let*` / `Result.bind` over `ref` for state threading | B |
| Prefer pattern match on bool over `if`/`else` | B |

## Testing

| Item | Severity |
|------|----------|
| ppx_expect tests exist | B |
