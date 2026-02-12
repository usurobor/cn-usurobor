# Failure Modes Checklist

Run through this checklist for every feature before shipping.

## Loops & Recursion

- [ ] **Infinite loop** — Can this loop forever? What's the exit condition?
- [ ] **Recursion without base case** — Does recursive call always terminate?
- [ ] **Re-exec loops** — If process re-execs itself, can it trigger another re-exec?
- [ ] **Retry storms** — If retry on failure, is there a backoff/limit?

**Guard pattern:**
```ocaml
(* Set env var before re-exec, check at start *)
if is_already_running () then exit
Unix.putenv "GUARD" "1";
re_exec ()
```

## External Resources

- [ ] **API rate limits** — Are you hammering an API? Add cooldown.
- [ ] **Network failures** — What if curl/fetch fails? Timeout?
- [ ] **Partial downloads** — Is the file complete? Validate size/checksum.
- [ ] **Stale cache** — Is cached data still valid? TTL?

**Guard pattern:**
```ocaml
(* Cooldown file with timestamp *)
let should_check () =
  let age = time_since_last_check () in
  age > cooldown_hours * 3600
```

## File Operations

- [ ] **Atomic writes** — If write fails mid-way, is file corrupted?
- [ ] **Cleanup on failure** — Are temp files removed on error?
- [ ] **Path traversal** — Can input manipulate paths (../../)?
- [ ] **Permissions** — What if file isn't writable?

**Guard pattern:**
```ocaml
(* Write to .new, validate, then atomic mv *)
write_to path_new;
if validate path_new then
  mv path_new path
else
  rm path_new
```

## Shell & Exec

- [ ] **Shell injection** — Is user input passed to shell? Quote/escape?
- [ ] **PATH lookup** — Does execvp find the right binary? Use absolute path.
- [ ] **Env inheritance** — Does child get wrong env vars?
- [ ] **Stdout/stderr lost** — If exec fails, do you see why?

**Guard pattern:**
```ocaml
(* Absolute path, no shell *)
Unix.execv "/usr/local/bin/cn" argv
(* NOT: Unix.execvp "cn" argv *)
```

## State & Concurrency

- [ ] **Race condition** — Can two processes modify same state?
- [ ] **Stale state** — Is in-memory state synced with disk?
- [ ] **Mutable refs** — Is shared mutable state necessary? Can it be passed explicitly?
- [ ] **Partial updates** — If update fails halfway, is state consistent?

## Version & Compatibility

- [ ] **Semver comparison** — String compare fails: "2.4.10" < "2.4.9". Use tuple comparison.
- [ ] **Protocol mismatch** — What if peer is on different version?
- [ ] **Rollback safety** — Can old version read new version's state?

**Guard pattern:**
```ocaml
(* Parse to tuple, compare numerically *)
let cmp = (major, minor, patch) > (old_maj, old_min, old_patch)
(* NOT: version_string > old_version_string *)
```

## Error Handling

- [ ] **Silent failure** — Does error case just return quietly?
- [ ] **Error swallowing** — Is exception caught and ignored?
- [ ] **Missing else branch** — What happens in the case you didn't handle?
- [ ] **Partial success** — If 3/5 operations succeed, is state valid?

## Resource Exhaustion

- [ ] **Memory leak** — Does long-running process accumulate memory?
- [ ] **Disk fill** — Do logs/temp files grow unbounded?
- [ ] **File descriptor leak** — Are files/sockets closed on error paths?
- [ ] **Queue growth** — Can queue grow faster than it drains?
