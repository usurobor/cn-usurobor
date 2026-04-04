## Self-Coherence Report -- v3.32.0

**Issue:** #152 -- Audit and eliminate all legacy fallback paths in src/

### Alpha (type-level clarity)

All deleted symbols had clear types. No type ambiguity introduced or removed.

- `run_inbound` (deleted): `string -> string -> unit` -- only caller was CLI dispatch, which already routes to `Cn_runtime.run_cron`
- `feed_next_input` (deleted): `string -> bool` -- only caller was `run_inbound`
- `wake_agent` (deleted): `string -> unit` -- only caller was `run_inbound`
- `hub_flat_mindsets_path` (deleted): `string -> string` -- pure path constructor
- `hub_flat_skills_path` (deleted): `string -> string` -- pure path constructor
- `read_opt` (converted): signature unchanged (`string -> string`), behavior unchanged for success/missing cases, now logs on exception
- All other converted functions: signatures unchanged, now log on exception before returning same fallback values

**Alpha score: A** -- No new types. Deleted code was unambiguous. Converted code preserves type signatures.

### Beta (authority surface agreement)

| Surface | Before | After | Agreement |
|---------|--------|-------|-----------|
| CLI dispatch (cn.ml:440) | Routes `cn in` to `Cn_runtime.run_cron` | Same | yes |
| cn_agent.ml | Contains dead `run_inbound` (120+ lines) | Deleted | yes |
| cn_runtime.ml docstring | References "Replaces previous run_inbound..." | Updated to remove reference | yes |
| cn_protocol_test.ml:611 | Comment references `run_inbound` | Updated to reference `run_cron` | yes |
| cn_assets.ml flat loaders | Flat path functions + loader blocks | Deleted | yes |
| cn_assets.ml silent swallows | 9 instances of `with _ -> []` / `with _ -> ()` / `with _ -> None` | All converted to log warning | yes |
| cn_deps.ml | 3 `with _ ->` silent swallows (collect_files_sorted, copy_tree, list_installed) | All converted to log warning | yes |
| cn_agent.ml remaining | 2 `with _ ->` (queue_count, resolve_bin_path proc_self) | Converted: queue_count logs, proc_self narrowed to Unix.Unix_error | yes |
| cn_sandbox.ml | `validate_path` realpath with `Unix.Unix_error _ -> None` | Kept -- already fail-closed (None leads to Error or ancestor denial) | yes |
| cn.ml:13 docstring | Says "(legacy: run_inbound deprecated)" | Updated to remove legacy note | yes |
| Audit table | 17 findings (R0) -> 25 (R1) -> 29 (R2) | Added cn_assets.ml, cn_deps.ml, cn_agent.ml silent swallows | yes |
| Scope section | Not present | Added: explicitly lists 21 `with _ ->` in 9 untouched files as out-of-scope | yes |
| PR summary | Said "17 findings" | Updated to 29 findings, 15 converts | yes |

**Beta score: A** -- All authority surfaces updated. No stale references. No cross-artifact disagreements. Scope explicitly acknowledged.

### Gamma (cycle economics)

- Audit: 29 findings across touched files + 21 out-of-scope instances acknowledged
- Dispositions: 7 remove, 7 keep, 15 convert
- Lines deleted: ~160 (cn_agent.ml) + ~25 (cn_assets.ml flat loaders) = ~185 lines removed
- Lines added: ~40 (warning logging across cn_assets.ml, cn_deps.ml, cn_agent.ml)
- Net: ~145 lines removed
- Rounds: R1 found 4 findings, R2 found 3 findings (scope narrowing, CI, cn_deps.ml)

### Pointers

| What | Where |
|------|-------|
| Audit table (29 rows) | docs/gamma/cdd/3.32.0/README.md |
| Scope acknowledgment (21 out-of-scope) | docs/gamma/cdd/3.32.0/README.md (Scope section) |
| Deleted: run_inbound, feed_next_input, wake_agent | cn_agent.ml (removed ~160 lines) |
| Deleted: flat path loaders | cn_assets.ml (removed ~25 lines) |
| Converted: 9 silent swallows | cn_assets.ml (read_opt, find_installed_package, list_installed_packages, walk_skills, collect_doctrine override, scan_mindsets_dir, summarize doctrine/mindset/override counts) |
| Converted: 3 silent swallows | cn_deps.ml (collect_files_sorted, copy_tree, list_installed) |
| Converted: 2 silent swallows | cn_agent.ml (queue_count, resolve_bin_path narrowed to Unix.Unix_error) |
| Kept: validate_path | cn_sandbox.ml (already fail-closed, no change needed) |
| Updated docstrings | cn_runtime.ml, cn.ml, cn_agent.ml |
| Updated test comment | cn_protocol_test.ml |

### Triadic Coherence Check

1. **Does every deleted function have zero callers?** Yes. `run_inbound` was not reachable from CLI dispatch. `feed_next_input` and `wake_agent` were only called from `run_inbound`. Flat path functions were only used in the deleted loader blocks.

2. **Does every "keep" path have fail-closed behavior?** Yes. `checkout_main` returns bool (caller checks). `delete_local_branch` returns bool. `release_lock` is idempotent cleanup. `extract_inbound_message` returns full content. `resolve_render` emits trace event. `load_file` warns to stderr. `validate_path` returns Error on unresolvable paths.

3. **Does every "convert" path now log on failure?** Yes. All 15 converted paths now call `Printf.eprintf "cn: warning: ..."` or narrow the catch clause before returning their fallback value. Zero `with _ ->` remains in any touched file.

4. **Do all branch artifacts agree on every item's disposition?** Yes. The audit table, PR summary, and self-coherence report all classify cn_sandbox.validate_path as "keep" (item #29). All 15 "convert" items are consistent across artifacts.

5. **Is the audit scope explicitly bounded?** Yes. The Scope section lists 21 `with _ ->` in 9 untouched files as out-of-scope, with justification that they are standard defensive I/O, not legacy fallback paths per the issue definition.

### Exit Criteria

- [x] AC1: Audit table written with 29 findings (complete -- no remaining `with _ ->` in any touched file). 21 instances in untouched files explicitly acknowledged as out-of-scope.
- [x] AC2: 7 "remove" paths deleted, no dead code
- [x] AC3: 7 "keep" paths justified with fail-closed guarantee + 15 "convert" paths now log warnings
- [x] AC4: `run_inbound` deleted (was dead code since v3.27)
- [x] AC5: No `main...origin/` or `master...origin/` patterns in src/
