---
name: coding
description: Ship code where intent is obvious and behavior matches. Use before implementing, during review, or pre-ship. Triggers on coding tasks, "check for bugs", "is this safe to ship".
---

# Coding

## Core Principle

**Coherent code: intent is obvious, behavior matches — in structure, communication, and under stress.**

## Failure Mode

Incoherent code: works in testing, breaks in production. Or works, but no one can predict what it does. Intent and behavior drift apart.

## Process

1. **Before:** "5 ways this fails silently or catastrophically?"
2. **During:** Structure for clarity; guard for failure
3. **After:** Test garbage inputs, not just valid ones

---

## A. Failure Handling

Behavior matches intent when things go wrong.

### A.1. Enumerate failure modes before implementing
Prevents shipping blind spots.
- ❌ Implement → "it works"
- ✅ "What if the API returns HTML? What if this re-execs itself?"

### A.2. Validate before destructive operations
Corrupt downloads bricked auto-update.
- ❌ `curl ... && mv new old`
- ✅ `curl ... && ./new --version && mv new old`

### A.3. Guard recursive paths
Re-exec without guard caused infinite loop.
- ❌ `re_exec()` with no loop check
- ✅ Set `ALREADY_RUNNING=1` before exec, check on entry

### A.4. Clean up on all failure paths
Leftover temp files cause next run to fail.
- ❌ Download fails, `.new` file left behind
- ✅ `if exists new_path then remove new_path` on every exit

### A.5. Add cooldowns for external APIs
Heartbeat every 5 min × GitHub API = rate limited.
- ❌ Check releases on every heartbeat
- ✅ Skip if checked within 1 hour (mtime of state file)

### A.6. Test garbage inputs
GitHub returns HTML on rate limit, not JSON.
- ❌ "2.4.3 parses correctly"
- ✅ "garbage, empty, HTML blob → None/false safely"

### A.7. Document ordering constraints
OCaml has no Unix.unsetenv — env persists in process.
- ❌ Tests in arbitrary order
- ✅ "CN_UPDATE_RUNNING test last — env mutation persists"

---

## B. Structure

Organization matches intent.

### B.1. Pass state explicitly
Mutable refs hide data flow, cause coupling.
- ❌ `let latest_tag = ref ""`
- ✅ Return `update_info` from check, pass to update

### B.2. Use exec arrays, not shell strings
String interpolation risks injection, loses argv structure.
- ❌ `exec (sprintf "cn %s" args_str)`
- ✅ `Unix.execvp bin_path argv`

### B.3. Use types to forbid invalid states
Stringly-typed code accepts garbage silently.
- ❌ `status: string`
- ✅ `type status = Pending | Active | Closed`

### B.4. Separate pure from effectful
Mixed functions are hard to test and reason about.
- ❌ Function that parses AND writes AND logs
- ✅ `parse` (pure) → `decide` (pure) → `execute` (effectful)

### B.5. Bound all iteration
Implicit breaks hide termination conditions.
- ❌ `while true` with break inside
- ✅ `for i = 1 to max_attempts`

### B.6. Make operations idempotent
Crash-and-retry must not corrupt state.
- ❌ Append without checking if already done
- ✅ Check state before mutating

### B.7. Use absolute paths for exec
PATH lookup might find wrong binary after update.
- ❌ `execvp "cn"`
- ✅ `execvp "/usr/local/bin/cn"`

---

## C. Clarity

Communication matches intent.

### C.1. Name functions for what they return
Reader predicts behavior from name alone.
- ❌ `process_version()`
- ✅ `version_to_tuple()`

### C.2. Comment the why, not the what
Code shows what; comments explain non-obvious constraints.
- ❌ `(* increment counter *)`
- ✅ `(* test last — no Unix.unsetenv in OCaml stdlib *)`

### C.3. Include context in error messages
"Parse error" doesn't help debugging.
- ❌ `"Parse error"`
- ✅ `"Parse error: expected semver, got 'garbage'"`

### C.4. Place helpers near usage
500 lines away = context lost.
- ❌ `show_tuple` at top, tests at bottom
- ✅ `show_tuple` immediately before its test group

### C.5. Keep one abstraction level per function
Mixing levels hides the flow.
- ❌ `Unix.putenv` next to `check_for_update` call
- ✅ High-level orchestrates low-level, not mixed

### C.6. State scope in module docstring
Reader knows what's covered and what's not.
- ❌ No header
- ✅ `(** Tests pure functions. I/O needs integration tests. *)`

### C.7. Group by domain, not by kind
Types-then-functions splits related code.
- ❌ All types at top, all functions below
- ✅ `version_to_tuple` type + impl + tests together

---

## Reference

Case study (10 issues across all sections): `references/auto-update-case.md`
