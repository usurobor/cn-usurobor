# MCA: Self-Update Infinite Recursion

**Status:** Open
**Severity:** High (caused Pi to max CPU for 1 hour)
**Date:** 2026-02-11

## Evidence

Pi process showed cn.js repeated 60+ times in command line:
```
node /usr/local/lib/cnos/tools/dist/cn.js /usr/local/lib/cnos/tools/dist/cn.js ...
```

Load average: 3.12. SSH connections timing out.

## Root Cause

`self_update_check()` in `cn_system.ml`:
1. Detects newer version on origin
2. Pulls update
3. Re-executes `cn` with same arguments
4. No guard to prevent re-entry

If the re-executed cn also detects a version difference (or any condition that triggers update), it recurses infinitely.

## Fix Required

Add recursion guard:
```ocaml
let self_update_check () =
  (* Guard: check env var to prevent recursion *)
  match Sys.getenv_opt "CN_UPDATE_RUNNING" with
  | Some _ -> ()  (* already in update, skip *)
  | None ->
      (* Set guard before re-exec *)
      Unix.putenv "CN_UPDATE_RUNNING" "1";
      (* ... existing update logic ... *)
```

Or simpler: don't re-exec at all. Just update and exit with message "Updated to X.Y.Z, please re-run."

## Workaround

Update to native binary (2.4.0) — the bug existed in Node.js wrapper era. Verify if native binary has same issue.
