# Case Study: Auto-Update Feature

10 issues found across 2 review rounds. Demonstrates why adversarial review matters.

## Context

Feature: cn auto-updates when idle (no input.md, no output.md).

## Round 1: Initial Implementation

Reviewer found 5 issues in ~100 lines:

| # | Issue | Category | Severity |
|---|-------|----------|----------|
| 1 | Shell injection in re_exec | Shell & Exec | D |
| 2 | Mutable ref coupling check/do | State | C |
| 3 | No cleanup on partial download | File Ops | B |
| 4 | FSM transitions not called | Design | B |
| 5 | String compare for version | Version | D |

### Issue 1: Shell Injection

**Bad:**
```ocaml
let args_str = List.tl argv |> String.concat " " in
Cn_ffi.Child_process.exec (Printf.sprintf "cn %s" args_str)
```

**Why bad:** If argv contains shell metacharacters, arbitrary command execution.

**Fix:**
```ocaml
Unix.execvp "cn" argv
```

### Issue 5: String Version Compare

**Bad:**
```ocaml
if latest <> Cn_lib.version then (* update *)
```

**Why bad:** `"2.4.10" <> "2.4.9"` is true, but doesn't tell you which is newer.

**Fix:**
```ocaml
if is_newer_version latest Cn_lib.version then (* update *)
```

## Round 2: Reliability Issues

Second reviewer (Claude Code) found 5 more critical issues:

| # | Issue | Category | Severity |
|---|-------|----------|----------|
| 1 | No recursion guard | Loops | D |
| 2 | Git pull doesn't rebuild | Design | D |
| 3 | No binary validation | File Ops | C |
| 4 | No cooldown (API spam) | External | C |
| 5 | PATH lookup in re_exec | Shell & Exec | C |

### Issue 1: No Recursion Guard

**The killer:** re_exec → new cn process → check_for_update → re_exec → infinite loop

**Irony:** We just fixed an infinite loop bug (actor timeout). Then wrote code that causes infinite loops.

**Fix:**
```ocaml
let is_updating () = Sys.getenv_opt "CN_UPDATING" = Some "1"

let check_for_update hub_path =
  if is_updating () then Update_skip  (* guard *)
  else ...

let re_exec () =
  Unix.putenv "CN_UPDATING" "1";  (* set guard *)
  Unix.execv bin_path argv
```

### Issue 2: Git Pull Doesn't Rebuild

**The silent failure:** `git pull` updates source code, but cn is a compiled binary. Pull without rebuild = no update.

**Fix:** Removed git path entirely. Binary-only updates.

### Issue 4: No Cooldown

**The spam:** Every 5-minute cron cycle hits GitHub API. 288 requests/day per agent.

**Fix:**
```ocaml
let should_check_update hub_path =
  let age_hours = time_since_last_check hub_path in
  age_hours >= 6.0  (* only check every 6 hours *)
```

## Lessons

1. **Pattern recurrence:** We fixed infinite loop, then wrote infinite loop. Always ask "does new code have same bug?"

2. **Silent failures are worst:** Git pull "succeeding" but not updating is worse than a loud error.

3. **External resources need guards:** APIs need cooldowns, downloads need validation.

4. **Fresh eyes find more:** Author missed all 10 issues. Two external reviewers found them.

5. **The 4th and 5th failures:** First 3 failure modes are obvious. Push to find 5 — that's where the bugs hide.
