---
name: coding
description: Ship code where unintended behavior — by machine or maintainer — is unrepresentable. Use before implementing, during review, or pre-ship. Triggers on coding tasks, "check for bugs", "is this safe to ship".
---

# Coding

## Core Principle

**Coherent code: unintended behavior — by machine or maintainer — is unrepresentable.**

If the machine can do something unintended, it's incoherent. If a maintainer can misread the intent, it's incoherent. You're done when neither can go wrong.

## Coherence at Each Level

### 1. Types

Constrain what values can exist.

1.1. **Forbid invalid states**
  - ❌ `status: string`
  - ✅ `type status = Pending | Active | Closed`

1.2. **Use structure, not strings**
  - ❌ `exec (sprintf "cn %s" args_str)`
  - ✅ `Unix.execvp bin_path argv`

1.3. **Embed context in errors**
  - ❌ `"Parse error"`
  - ✅ `"Parse error: expected semver, got 'garbage'"`

1.4. **Name paths explicitly**
  - ❌ `execvp "cn"`
  - ✅ `execvp "/usr/local/bin/cn"`

### 2. Functions

Constrain what behavior can occur.

2.1. **Name for the output**
  - ❌ `process_version()`
  - ✅ `version_to_tuple()`

2.2. **Pass state, don't hide it**
  - ❌ `let latest_tag = ref ""`
  - ✅ Return `update_info`, pass to next function

2.3. **Isolate effects**
  - ❌ Function that parses AND writes AND logs
  - ✅ `parse` → `decide` → `execute`

2.4. **One abstraction level**
  - ❌ `Unix.putenv` next to `check_for_update`
  - ✅ High calls low, not mixed

2.5. **Bound iteration**
  - ❌ `while true`
  - ✅ `for i = 1 to max_attempts`

2.6. **Guard re-entry**
  - ❌ `re_exec()` can loop forever
  - ✅ Set `RUNNING=1`, check on entry

2.7. **Clean all exits**
  - ❌ Failure leaves `.new` file
  - ✅ Remove temp on every path

2.8. **Idempotent operations**
  - ❌ Append without checking
  - ✅ Check before mutate

2.9. **Validate before destroy**
  - ❌ `curl && mv new old`
  - ✅ `curl && ./new --version && mv`

### 3. Modules

Constrain what a maintainer can misunderstand.

3.1. **Group by domain**
  - ❌ Types at top, functions below
  - ✅ Type + impl + tests together

3.2. **Helpers near usage**
  - ❌ `show_tuple` 500 lines away
  - ✅ `show_tuple` before its tests

3.3. **Docstring states scope**
  - ❌ No header
  - ✅ `(** Pure functions only. I/O needs integration tests. *)`

3.4. **Comment the why**
  - ❌ `(* increment counter *)`
  - ✅ `(* last — no Unix.unsetenv *)`

3.5. **Document ordering**
  - ❌ Arbitrary order
  - ✅ "This test last — env persists"

### 4. Boundaries

Constrain what external interactions can occur.

4.1. **Cooldown external calls**
  - ❌ Check API every heartbeat
  - ✅ Skip if checked within 1 hour

4.2. **Test garbage inputs**
  - ❌ Only test "2.4.3"
  - ✅ Test garbage, empty, HTML blob

4.3. **Enumerate failure modes first**
  - ❌ Implement → "works"
  - ✅ "What if API returns HTML?"

## Reference

Case study: `references/auto-update-case.md`
