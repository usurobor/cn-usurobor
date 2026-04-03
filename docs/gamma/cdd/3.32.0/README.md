## CDD Bootstrap -- v3.32.0

**Issue:** #152 -- Audit and eliminate all legacy fallback paths in src/
**Branch:** claude/execute-issue-152-cdd-O6Rl3
**Parent:** v3.31.0 (af4cf01)
**Mode:** MCA (targeted audit + cleanup)

### Gap

The codebase contains legacy code paths retained for backward compatibility
whose failed preconditions can silently degrade behavior. #150 proved the
worst case (stale-diff content swap). No systematic audit has been done.

### Acceptance Criteria

- AC1: Full audit table (file, symbol, why legacy, failure mode, risk, disposition, justification, expiry)
- AC2: Every "remove" path deleted, no dead code
- AC3: Every "keep" path has justification + fail-closed guarantee + expiry
- AC4: `run_inbound` removed or justified with concrete expiry
- AC5: No `main...origin/` or `master...origin/` diff patterns remain

### AC1: Audit Table

| # | File | Symbol | Why legacy | Failure mode | Risk | Disposition | Justification | Expiry |
|---|------|--------|-----------|--------------|------|-------------|---------------|--------|
| 1 | cn_agent.ml | `run_inbound` | Deprecated actor loop, replaced by `Cn_runtime.run_cron` | Executes full old pipeline (queue, FSM, LLM) on deprecated path; warns but does not fail | high | **remove** | Dead code -- no CLI path reaches it (`cn in` routes to `Cn_runtime.run_cron` since v3.27) | -- |
| 2 | cn_agent.ml | `wake_agent` | Deprecated no-op, prints warning | No-op with warning; called only from `run_inbound` | high | **remove** | Dead code -- only caller is `run_inbound` (also being removed) | -- |
| 3 | cn_agent.ml | `feed_next_input` | Deprecated queue feeder, replaced by `Cn_runtime.process_one` | Writes to state/input.md on deprecated path | high | **remove** | Dead code -- only caller is `run_inbound` | -- |
| 4 | cn_assets.ml | `hub_flat_mindsets_path` | Pre-package namespace compat (`agent/mindsets/*.md` without package dir) | Silently loads flat overrides into `cnos.core` namespace | medium | **remove** | Package namespace is the only supported layout since v3.25. Migration grace period expired. | -- |
| 5 | cn_assets.ml | `hub_flat_skills_path` | Pre-package namespace compat (`agent/skills/...` without package dir) | Silently loads flat overrides into `cnos.core` namespace | medium | **remove** | Same as #4 | -- |
| 6 | cn_assets.ml | flat mindset loader block | Backward compat block using `hub_flat_mindsets_path` | `with _ -> ()` swallows all read errors silently | medium | **remove** | Removing with #4 | -- |
| 7 | cn_assets.ml | flat skill loader block | Backward compat block using `hub_flat_skills_path` | Loads skills into wrong namespace silently if directory exists | medium | **remove** | Removing with #5 | -- |
| 8 | git.ml | `checkout_create` | Creates or switches to branch; `2>/dev/null` suppresses first-attempt error | If both `-b` and checkout fail, returns false -- caller handles | low | **keep** | Legitimate two-step git operation (create-or-switch). Caller checks return value. Not a legacy compat path -- correct "try create, else switch" pattern. | permanent |
| 9 | git.ml | `checkout_main` | `main` vs `master` fallback | If both fail, returns false -- caller handles | low | **keep** | Active backward compat for repos initialized before `main` convention. Caller (`cn_io.ml`) checks return. Fail-closed: false return propagates. | until main-only policy adopted |
| 10 | git.ml | `delete_local_branch` | `2>/dev/null` on branch -D | If delete fails, returns false | low | **keep** | Idempotent cleanup. Suppressing "not found" is correct behavior. Caller checks return. | permanent |
| 11 | cn_assets.ml | `read_opt` | `with _ -> ""` swallows all exceptions | File exists but unreadable -> returns "" silently (permission errors, I/O errors hidden) | medium | **convert** | Changed to log warning on exception. Keep fallback to "" (missing is OK, unreadable should warn). | -- |
| 12 | cn_assets.ml | `find_installed_package` | `with _ -> None` swallows readdir exceptions | Package directory unreadable -> returns None silently | medium | **convert** | Changed to log warning on exception. Keep fallback to None. | -- |
| 13 | cn_assets.ml | `list_installed_packages` | `with _ -> []` swallows readdir exceptions | Package root unreadable -> returns empty list silently | medium | **convert** | Changed to log warning on exception. Keep fallback to []. | -- |
| 14 | cn_assets.ml | `walk_skills` | `with _ -> []` swallows readdir exceptions during recursive walk | Directory unreadable -> silently returns no skills | medium | **convert** | Changed to log warning on exception. Keep fallback to []. | -- |
| 15 | cn_assets.ml | `collect_doctrine` override readdir | `with _ -> ()` swallows readdir exceptions | Doctrine override directory unreadable -> silently ignored | medium | **convert** | Changed to log warning on exception. Keep fallback to skip. | -- |
| 16 | cn_assets.ml | `scan_mindsets_dir` | `with _ -> []` swallows readdir exceptions | Mindset directory unreadable -> returns empty list silently | medium | **convert** | Changed to log warning on exception. Keep fallback to []. | -- |
| 17 | cn_assets.ml | `summarize` doctrine count | `with _ -> 0` swallows readdir exceptions | Doctrine count silently returns 0 on error | low | **convert** | Changed to log warning on exception. Keep fallback to 0. | -- |
| 18 | cn_assets.ml | `summarize` mindset count | `with _ -> ()` swallows readdir exceptions | Mindset count silently skips on error | low | **convert** | Changed to log warning on exception. Keep fallback to skip. | -- |
| 19 | cn_assets.ml | `summarize` hub override mindset count | `with _ -> ()` swallows readdir exceptions | Override count silently skips on error | low | **convert** | Changed to log warning on exception. Keep fallback to skip. | -- |
| 20 | cn_runtime.ml | `release_lock` | `with _ -> ()` on close/unlink | Lock cleanup errors suppressed | none | **keep** | Idempotent cleanup must not fail. Trace event emitted regardless. Standard pattern for lock release. | permanent |
| 21 | cn_runtime.ml | `extract_inbound_message` | Falls back to full packed_body when marker not found | Returns full content instead of parsed body | low | **keep** | Defensive: if structure unexpected, return everything rather than nothing. Not silent -- the fallback IS the content. | permanent |
| 22 | cn_runtime.ml | `resolve_render` Fallback arm | Render fallback with trace event | Logs degradation via `Cn_trace.gemit` at Warn/Degraded | none | **keep** | Explicitly traced fallback. Not silent -- emits structured event with reason. Correct design. | permanent |
| 23 | cn_dotenv.ml | `load_file` unreadable fallback | Warns to stderr, returns Ok [] | Logged to stderr -- not silent | none | **keep** | Correct: secrets.env is optional. Warns on unreadable. Permissions checked separately. | permanent |
| 24 | cn_deps.ml | `collect_files_sorted` | `with Sys_error _ / Unix.Unix_error _ -> []` | Silently skips unreadable directories during integrity hash collection | medium | **convert** | Changed to log warning. Silent skip during integrity checking could mask missing dependencies. | -- |
| 25 | cn_sandbox.ml | `validate_path` realpath failures | `with Unix.Unix_error _ -> None` | Treats unresolvable symlinks as non-existent in security-critical path | low | **keep** | Already fail-closed: None case leads to Error Path_escape or ancestor resolution which also denies on failure. No silent degradation -- the security boundary is preserved. | permanent |

### Summary

| Disposition | Count | Items |
|-------------|-------|-------|
| **remove** | 7 | #1-7 (deprecated agent functions + flat asset compat) |
| **keep** | 7 | #8-10, 20-23, 25 (legitimate patterns, all fail-closed or traced) |
| **convert** | 11 | #11-19, 24 (silent exception swallows -> log warning on failure) |

### AC5 Status

`grep -r 'main\.\.\.origin\|master\.\.\.origin' src/` returns zero matches.
The `materialize_branch` diff pattern was deleted in v3.31.0 (#150/#151).
AC5 is already met.

### Plan

1. Delete `run_inbound`, `feed_next_input`, `wake_agent` from `cn_agent.ml` (AC4)
2. Delete `hub_flat_mindsets_path`, `hub_flat_skills_path` and their loader blocks from `cn_assets.ml`
3. Update `cn.ml` module docstring (remove "legacy: run_inbound deprecated")
4. Convert all `with _ ->` silent swallows in `cn_assets.ml` to log warnings (9 instances)
5. Convert `collect_files_sorted` in `cn_deps.ml` to log warning on readdir failure
6. Reclassify `validate_path` in `cn_sandbox.ml` as keep -- already fail-closed
7. Write SELF-COHERENCE.md
