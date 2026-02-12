---
name: coding
description: Ship code where intent is obvious and behavior matches. Use before implementing, during review, or pre-ship. Triggers on coding tasks, "check for bugs", "is this safe to ship".
---

# Coding

## Core Principle

**Coherent code: intent is obvious, behavior matches — at every level of scope.**

Incoherent code works in testing, breaks in production. Or works, but no one can predict what it does.

---

### 1. Types

Make invalid states unrepresentable.

1.1. **Use types to forbid invalid states**
  - ❌ `status: string`
  - ✅ `type status = Pending | Active | Closed`

1.2. **Use structured data, not strings**
  - ❌ `exec (sprintf "cn %s" args_str)` — injection, loses structure
  - ✅ `Unix.execvp bin_path argv`

1.3. **Include context in error values**
  - ❌ `"Parse error"`
  - ✅ `"Parse error: expected semver, got 'garbage'"`

1.4. **Use explicit paths**
  - ❌ `execvp "cn"` — PATH lookup finds wrong binary
  - ✅ `execvp "/usr/local/bin/cn"`

---

### 2. Functions

Single units of behavior.

2.1. **Name for what they return**
  - ❌ `process_version()`
  - ✅ `version_to_tuple()`

2.2. **Pass state explicitly**
  - ❌ `let latest_tag = ref ""`
  - ✅ Return `update_info` from check, pass to update

2.3. **Separate pure from effectful**
  - ❌ Function that parses AND writes AND logs
  - ✅ `parse` (pure) → `decide` (pure) → `execute` (effectful)

2.4. **Keep one abstraction level**
  - ❌ `Unix.putenv` next to `check_for_update` call
  - ✅ High-level orchestrates low-level, not mixed

2.5. **Bound all iteration**
  - ❌ `while true` with break inside
  - ✅ `for i = 1 to max_attempts`

2.6. **Guard recursive paths**
  - ❌ `re_exec()` with no loop check
  - ✅ Set `ALREADY_RUNNING=1` before exec, check on entry

2.7. **Clean up on all exit paths**
  - ❌ Download fails, `.new` file left behind
  - ✅ `if exists new_path then remove new_path` on every exit

2.8. **Make operations idempotent**
  - ❌ Append without checking if already done
  - ✅ Check state before mutating — safe to run twice

2.9. **Validate before destructive operations**
  - ❌ `curl ... && mv new old`
  - ✅ `curl ... && ./new --version && mv new old`

---

### 3. Modules

Organization and communication.

3.1. **Group by domain, not by kind**
  - ❌ All types at top, all functions below
  - ✅ `version_to_tuple` type + impl + tests together

3.2. **Place helpers near usage**
  - ❌ `show_tuple` at top, tests at bottom
  - ✅ `show_tuple` immediately before its test group

3.3. **State scope in docstring**
  - ❌ No header — reader guesses
  - ✅ `(** Tests pure functions. I/O needs integration tests. *)`

3.4. **Comment the why, not the what**
  - ❌ `(* increment counter *)`
  - ✅ `(* test last — no Unix.unsetenv in OCaml stdlib *)`

3.5. **Document ordering constraints**
  - ❌ Tests in arbitrary order
  - ✅ "CN_UPDATE_RUNNING test last — env mutation persists"

---

### 4. Boundaries

External systems and failure modes.

4.1. **Add cooldowns for external APIs**
  - ❌ Check GitHub releases on every heartbeat
  - ✅ Skip if checked within 1 hour (mtime of state file)

4.2. **Test garbage inputs**
  - ❌ "2.4.3 parses correctly"
  - ✅ "garbage, empty, HTML blob → None/false safely"

4.3. **Enumerate failure modes before implementing**
  - ❌ Implement → "it works"
  - ✅ "What if the API returns HTML? What if this re-execs itself?"

---

## Reference

Case study (10 issues across all levels): `references/auto-update-case.md`
