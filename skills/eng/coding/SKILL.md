---
name: coding
description: Ship code that handles failure, not just success. Use before implementing features, during review, or when asked "is this safe to ship". Triggers on coding tasks, implementation, pre-ship review, or "check for bugs".
---

# Coding

**Coherent code: handles not just success but how it fails.**

Incoherent code works in testing, breaks in production — infinite loops, corrupt state, silent degradation.

## Process

1. **Before implementing:** "5 ways this fails silently or catastrophically?"
2. **During implementing:** Add guards for each failure mode
3. **Before shipping:** Test garbage inputs, not just valid ones

## Rules

### 1. Enumerate failure modes before implementing

- ❌ Implement → "it works"
- ✅ "What if the API returns HTML? What if this re-execs itself?"

### 2. Validate before destructive operations

- ❌ `curl ... && mv new old`
- ✅ `curl ... && ./new --version && mv new old`

### 3. Guard recursive/re-entrant paths

- ❌ `re_exec()` with no loop guard
- ✅ Set `ALREADY_RUNNING=1` before exec, check on entry

### 4. Clean up on all failure paths

- ❌ Download fails, `.new` file left behind
- ✅ `if exists new_path then remove new_path` on every exit

### 5. Add cooldowns for external APIs

- ❌ Check GitHub releases on every heartbeat
- ✅ Skip if checked within 1 hour (use mtime of state file)

### 6. Test garbage inputs

- ❌ "2.4.3 parses correctly" (happy path)
- ✅ "garbage, empty string, HTML blob all return None/false safely"

### 7. Explain ordering when it matters

- ❌ Tests in arbitrary order
- ✅ "CN_UPDATE_RUNNING test last — no Unix.unsetenv in OCaml"

## Reference

For case study (auto-update with 5 failure modes): `references/auto-update-case.md`
