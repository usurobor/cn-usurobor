---
name: coding
description: Write reliable code with adversarial self-review. Use when implementing features, fixing bugs, or reviewing your own code before requesting external review.
---

# CODING

## Core Principle

**Coherent code: every path terminates, every failure is handled.**

If a code path can loop forever, fail silently, or corrupt state — fix it before shipping.

## Coherence at Each Level

### 1. Loops & Recursion

Every loop must terminate. Every recursion must have a base case.

1.1. **Bound all loops**
  - ❌ `while (condition) { ... }` with no guaranteed exit
  - ✅ `for (i = 0; i < MAX; i++) { ... }` with explicit bound

1.2. **Guard re-exec against infinite loops**
  - ❌ `re_exec()` that can trigger itself again
  - ✅ Set env guard before re-exec, check at startup:
    ```ocaml
    if Sys.getenv_opt "GUARD" = Some "1" then exit 0;
    Unix.putenv "GUARD" "1";
    re_exec ()
    ```

1.3. **Limit retries**
  - ❌ `while (failed) { retry() }` — retry storm
  - ✅ `for i = 0 to 3 do if not failed then break done` — bounded

### 2. External Resources

Network calls fail. APIs rate-limit. Downloads corrupt.

2.1. **Add cooldowns to external checks**
  - ❌ Check API every cron cycle (288 calls/day)
  - ✅ Track last check time, skip if < N hours

2.2. **Validate downloads before using**
  - ❌ `curl -o file && use file` — file may be truncated
  - ✅ `curl -o file && validate file && use file`
    ```ocaml
    if file_size path < 1_000_000 then fail "truncated"
    if not (run_version_check path) then fail "invalid"
    ```

2.3. **Clean up on failure**
  - ❌ Leave `.tmp` files on error path
  - ✅ Remove temp files in all exit paths

### 3. Shell & Process

Shell injection is easy to write, hard to spot.

3.1. **Never interpolate user input into shell**
  - ❌ `exec (sprintf "cmd %s" user_input)` — shell injection
  - ✅ `Unix.execv cmd [| arg1; arg2 |]` — no shell

3.2. **Use absolute paths for exec**
  - ❌ `Unix.execvp "cn" argv` — PATH lookup may find wrong binary
  - ✅ `Unix.execv "/usr/local/bin/cn" argv` — explicit

3.3. **Preserve error visibility**
  - ❌ `exec cmd 2>/dev/null` — errors disappear
  - ✅ Capture stderr, log on failure

### 4. State & Versions

Comparisons lie. State corrupts.

4.1. **Compare versions numerically, not lexically**
  - ❌ `"2.4.10" > "2.4.9"` → false (string compare)
  - ✅ `(2,4,10) > (2,4,9)` → true (tuple compare)

4.2. **Atomic writes for state**
  - ❌ Write directly to `state.json` — crash = corrupt
  - ✅ Write to `state.json.new`, then `mv` atomically

4.3. **Eliminate mutable refs when possible**
  - ❌ `let cache = ref None` — hidden state coupling
  - ✅ Pass value explicitly through function signatures

### 5. Self-Review

Review your own code as an attacker before shipping.

5.1. **Ask the failure question**
  - ❌ "Does it work?" (confirmation bias)
  - ✅ "What are 5 ways this can fail silently or catastrophically?"

5.2. **Check for pattern recurrence**
  - ❌ Fix bug X, write feature Y with same failure mode
  - ✅ After fixing X, explicitly check: "Can Y fail the same way?"

5.3. **Rate failures by severity**
  - Silent + Catastrophic = MUST FIX before ship
  - Noisy + Recoverable = document, fix later

## Pre-Ship Checklist

Before requesting review:

```
□ "5 ways this can fail?"
□ All loops bounded
□ No shell injection
□ External calls have cooldown/validation
□ Version comparisons use tuples
□ State writes are atomic
□ Pattern recurrence check done
```
