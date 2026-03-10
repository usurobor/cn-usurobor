---
name: testing
description: Write effective tests — strategy, coverage, property-based, cram tests. Use for test design, reviewing test quality, or adding tests to existing code.
---

# Testing

## Core Principle

**Tests prove behavior, not implementation.**

A test should fail when behavior breaks, not when internals change.

## 1. Strategy

### 1.1 Test Pyramid

```
         ╱╲
        ╱ E2E ╲        Few — slow, brittle
       ╱────────╲
      ╱Integration╲    Some — real I/O, boundaries
     ╱──────────────╲
    ╱   Unit Tests    ╲  Many — fast, pure, isolated
   ╱────────────────────╲
```

### 1.2 What to Test

- ✅ Public API behavior
- ✅ Edge cases and error paths
- ✅ Regression for every bug fix (see ship skill)
- ❌ Private helpers (test through public API)
- ❌ Implementation details (coupled tests)

### 1.3 Test-First for Bugs

```
1. Write test that reproduces the bug — MUST FAIL
2. Fix the code
3. Test passes — proves fix works
```

If test passes before fix, it doesn't catch the bug. Rewrite.

## 2. Cram Tests (CLI)

### 2.1 Structure

```bash
Description:

  $ command arg1 arg2
  expected output line 1
  expected output line 2
```

### 2.2 Patterns

- Filter noisy output: `$ cmd 2>&1 | grep -E "(pattern)"`
- Setup with temp dirs: `$ mkdir -p test-hub/.cn`
- Use `$CN` wrapper for consistent env
- Test both success and failure paths

### 2.3 When to Use

- CLI behavior verification
- Protocol round-trip tests
- Integration tests with real git

## 3. Unit Tests (ppx_expect)

### 3.1 Structure

```ocaml
let%expect_test "description" =
  let result = function_under_test input in
  print_s [%sexp_of: type] result;
  [%expect {| expected_output |}]
```

### 3.2 Patterns

- Inline expected output — no assertion boilerplate
- Test pure functions directly
- Use `[%expect.unreachable]` for paths that should never execute

## 4. Coverage

### 4.1 What Matters

- ✅ Branch coverage (both sides of every if)
- ✅ Error path coverage
- ✅ Boundary values (empty, zero, max, nil)
- ❌ Line coverage % as a target (Goodhart's law)

### 4.2 Missing Test Smell

If you can change behavior without a test failing, you're missing a test.

## 5. Property-Based

### 5.1 When

- Parsers (roundtrip: parse(serialize(x)) = x)
- Data transformations (invariants hold for all inputs)
- Protocol state machines (no invalid transitions)

### 5.2 Pattern

```
For all valid input X:
  property(transform(X)) = true
```

## 6. Anti-Patterns

- ❌ Tests that test mocks, not implementation
- ❌ Tests coupled to internal structure
- ❌ Tests that pass when the feature is broken
- ❌ Flaky tests left in suite (fix or delete)
- ❌ "Test later" — test now or accept the risk explicitly
