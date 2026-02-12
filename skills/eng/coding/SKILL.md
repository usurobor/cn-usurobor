---
name: coding
description: Ship code that handles failure and is well-structured. Use before implementing features, during review, or when asked "is this safe to ship". Triggers on coding tasks, implementation, pre-ship review, or "check for bugs".
---

# Coding

**Coherent code: well-structured and handles how it fails.**

Incoherent code works in testing, breaks in production — or works but is fragile, coupled, hard to change.

## Process

1. **Before implementing:** "5 ways this fails silently or catastrophically?"
2. **During implementing:** Structure for clarity; guard for failure
3. **Before shipping:** Test garbage inputs, not just valid ones

---

## A. Failure Handling

### A.1. Enumerate failure modes before implementing

- ❌ Implement → "it works"
- ✅ "What if the API returns HTML? What if this re-execs itself?"

### A.2. Validate before destructive operations

- ❌ `curl ... && mv new old`
- ✅ `curl ... && ./new --version && mv new old`

### A.3. Guard recursive/re-entrant paths

- ❌ `re_exec()` with no loop guard
- ✅ Set `ALREADY_RUNNING=1` before exec, check on entry

### A.4. Clean up on all failure paths

- ❌ Download fails, `.new` file left behind
- ✅ `if exists new_path then remove new_path` on every exit

### A.5. Add cooldowns for external APIs

- ❌ Check GitHub releases on every heartbeat
- ✅ Skip if checked within 1 hour (use mtime of state file)

### A.6. Test garbage inputs

- ❌ "2.4.3 parses correctly" (happy path)
- ✅ "garbage, empty string, HTML blob all return None/false safely"

### A.7. Explain ordering when it matters

- ❌ Tests in arbitrary order
- ✅ "CN_UPDATE_RUNNING test last — no Unix.unsetenv in OCaml"

---

## B. Structure

### B.1. Pass state explicitly, not via mutable refs

- ❌ `let latest_tag = ref ""`
- ✅ `type update_info = Skip | Git of string | Binary of string` — return from check, pass to update

### B.2. Use exec arrays, not shell strings

- ❌ `exec (sprintf "cn %s" args_str)` — injection risk, loses argv
- ✅ `Unix.execvp bin_path argv` — safe, preserves structure

### B.3. Make invalid states unrepresentable

- ❌ `status: string` — any garbage is valid
- ✅ `type status = Pending | Active | Closed` — compiler enforces

### B.4. Separate pure from effectful

- ❌ Function that parses AND writes AND logs
- ✅ `parse` (pure) → `decide` (pure) → `execute` (effectful)

### B.5. Bound all iteration

- ❌ `while true` with implicit break
- ✅ `for i = 1 to max_attempts` — explicit bound

### B.6. Make operations idempotent

- ❌ Append without checking if already done
- ✅ Check state before mutating — safe to run twice

### B.7. Use absolute paths for exec

- ❌ `execvp "cn"` — PATH lookup, might find wrong binary
- ✅ `execvp "/usr/local/bin/cn"` — explicit target

---

## Reference

For case study (auto-update with 10 issues across both sections): `references/auto-update-case.md`
