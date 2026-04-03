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
| cn_deps.ml | `collect_files_sorted` silently swallows errors | Now logs warning | yes |
| cn_sandbox.ml | `validate_path` realpath with `Unix.Unix_error _ -> None` | Kept -- already fail-closed (None leads to Error or ancestor denial) | yes |
| cn.ml:13 docstring | Says "(legacy: run_inbound deprecated)" | Updated to remove legacy note | yes |
| Audit table | 17 findings | 25 findings (added 8 missing cn_assets.ml silent swallows) | yes |
| PR summary vs audit table vs self-coherence | Item 17 disposition disagreed (convert vs keep) | Reconciled: cn_sandbox is keep (#25), all artifacts agree | yes |

**Beta score: A** -- All authority surfaces updated. No stale references. No cross-artifact disagreements.

### Gamma (cycle economics)

- Audit: 25 findings across 11 files
- Dispositions: 7 remove, 7 keep, 11 convert
- Lines deleted: ~160 (cn_agent.ml) + ~25 (cn_assets.ml flat loaders) = ~185 lines removed
- Lines added: ~30 (warning logging across cn_assets.ml + cn_deps.ml)
- Net: ~155 lines removed
- Rounds: R1 found 4 findings (audit incompleteness, artifact parity, hidden unicode, CI)

### Pointers

| What | Where |
|------|-------|
| Audit table (25 rows) | docs/gamma/cdd/3.32.0/README.md |
| Deleted: run_inbound, feed_next_input, wake_agent | cn_agent.ml (removed ~160 lines) |
| Deleted: flat path loaders | cn_assets.ml (removed ~25 lines) |
| Converted: 9 silent swallows | cn_assets.ml (read_opt, find_installed_package, list_installed_packages, walk_skills, collect_doctrine override, scan_mindsets_dir, summarize doctrine/mindset/override counts) |
| Converted: collect_files_sorted | cn_deps.ml |
| Kept: validate_path | cn_sandbox.ml (already fail-closed, no change needed) |
| Updated docstrings | cn_runtime.ml, cn.ml |
| Updated test comment | cn_protocol_test.ml |

### Triadic Coherence Check

1. **Does every deleted function have zero callers?** Yes. `run_inbound` was not reachable from CLI dispatch. `feed_next_input` and `wake_agent` were only called from `run_inbound`. Flat path functions were only used in the deleted loader blocks.

2. **Does every "keep" path have fail-closed behavior?** Yes. `checkout_main` returns bool (caller checks). `delete_local_branch` returns bool. `release_lock` is idempotent cleanup. `extract_inbound_message` returns full content. `resolve_render` emits trace event. `load_file` warns to stderr. `validate_path` returns Error on unresolvable paths.

3. **Does every "convert" path now log on failure?** Yes. All 11 converted paths now call `Printf.eprintf "cn: warning: ..."` before returning their fallback value.

4. **Do all branch artifacts agree on every item's disposition?** Yes. The audit table, PR summary, and self-coherence report all classify cn_sandbox.validate_path as "keep" (item #25). All 11 "convert" items are consistent across artifacts.

### Exit Criteria

- [x] AC1: Audit table written with 25 findings (complete -- no remaining `with _ ->` in touched files)
- [x] AC2: 7 "remove" paths deleted, no dead code
- [x] AC3: 7 "keep" paths justified with fail-closed guarantee
- [x] AC4: `run_inbound` deleted (was dead code since v3.27)
- [x] AC5: No `main...origin/` or `master...origin/` patterns in src/
