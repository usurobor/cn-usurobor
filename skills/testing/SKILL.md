# Testing

Write and maintain tests for cn-agent.

## Structure

```
tools/test/<tool>/
├── <tool>_test.ml   # ppx_expect tests
└── dune
```

## Approach

- Pure functions in `_lib.ml` → unit tests
- FFI/main modules → integration tests (when possible)
- Test parsing roundtrips: `parse → serialize → parse`
- Test edge cases: empty input, missing fields, invalid data

## ppx_expect Pattern

```ocaml
let%expect_test "parse valid input" =
  parse "input" |> print_endline;
  [%expect {| expected output |}]
```

## What to Test

| Layer | Test |
|-------|------|
| Pure functions | All parsing, formatting, transforms |
| Type conversions | Roundtrips (parse ↔ serialize) |
| Edge cases | Empty, missing, malformed |
| FFI wrappers | Integration with real fs/git when feasible |

## Coverage Goals

- `_lib.ml` files: 100% of public functions
- Main modules: critical paths
- Commands: happy path + error cases

## Running

```bash
eval $(opam env)
dune runtest
```

## Checklist

See `checklists/testing.md` for review checklist with severities.
