# RCA: Sync Commit Incomplete — 2026-02-11

## Incident

Pi sent a thread at 20:34 UTC. Sigma didn't process it until 21:05 UTC — 31 minutes later, only when user manually pinged.

System cron was running `cn sync` every 5 minutes. Looked healthy.

## Root Cause

`cn_system.ml:run_sync` only staged `state/runtime.md` before committing:

```ocaml
let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add state/runtime.md" in
let commit_result = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git commit -m 'heartbeat' --allow-empty" in
```

**Result:** Inbox files, queue files, and sent files were materialized on disk but never committed to git.

- 6 inbox files orphaned
- 7 queue files orphaned  
- Multiple sent files orphaned

Every `cn sync` showed "✓ Sync complete" but the files were invisible to git history.

## Timeline

- 20:34 UTC — Pi pushes `sigma/p1-fix-install-sh-to-download` branch
- 20:35 UTC — Sigma's `cn sync` materializes file to `threads/mail/inbox/`
- 20:35-21:05 UTC — Cron runs 6 times, commits only `runtime.md`, files stay untracked
- 21:05 UTC — User pings Sigma, manual sync runs, thread finally processed
- 21:10 UTC — RCA begins
- 21:15 UTC — Root cause identified: `git add state/runtime.md` vs `git add -A`
- 21:16 UTC — Fix committed, v2.4.1 released

## Lesson

**The checkmark lied again.**

"✓ Sync complete" said the sync worked. But `git status` showed 15+ untracked files. The sync *ran* but didn't *persist*.

## Fix

cn 2.4.1: Changed `git add state/runtime.md` to `git add -A`

```ocaml
let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add -A" in
```

## Prevention

1. Trust `git status`, not green checkmarks
2. When debugging "message not received", check if file exists but is untracked
3. `git add -A` is the safe default — staging specific files risks missing new ones
