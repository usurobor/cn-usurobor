## Self-Coherence — v3.22.0

### Changes reviewed

1. `src/cmd/cn_agent.ml` — Added `check_binary_version_drift`: runs `{bin_path} --version`, parses output, compares against compiled-in `Cn_lib.version`. Returns `(string option, string) result`: `Ok None` (no drift), `Ok (Some disk_ver)` (drift detected), `Error reason` (can't determine).
2. `src/cmd/cn_maintenance.ml` — Added `version_drift_check_once` primitive: 8th maintenance primitive, runs after `update_check_once` under same idle guard. On drift: traces, logs, attempts `re_exec`. On re_exec failure: catches `Unix_error`, logs warning, returns `Degraded`. Added `drift_status` to `maintenance_result` and `is_degraded`.
3. `test/cmd/cn_cmd_test.ml` — Updated 5 existing test record literals with `drift_status = Ok`. Added 2 new tests: drift degradation propagation, version drift error path.

### α (structural)

**A-** — Clean separation: `check_binary_version_drift` is pure detection (no side effects beyond the subprocess call), `version_drift_check_once` is the maintenance integration (trace, log, re_exec). The detection function returns `Result` with `option` inner type — three cases (no drift, drift, error) map cleanly to the three maintenance outcomes (Ok, re_exec, Skipped).

One concern: the detection relies on parsing `--version` output (`cn 3.21.0 (abc1234)` → split on space → take second element). If the output format changes, parsing breaks silently (returns Error). Acceptable: the format is stable and controlled by the same codebase.

### β (relational)

**A-** — The drift check slots into the existing maintenance architecture:
- Same idle guard as `update_check_once` (AC3 drain safety)
- Same `substep_status` return type
- Same trace event pattern (`version_drift.check.start/ok/detected`)
- `is_degraded` updated to include `drift_status`
- `maintain_once` trace details include `drift`
- All existing test record literals updated

The two update paths are now complementary: `update_check_once` handles proactive updates (GitHub API check → download → re_exec), `version_drift_check_once` handles reactive detection (binary already replaced → re_exec).

### γ (process)

**B+** — Active skills applied: eng/ocaml (Result type, Unix_error catch, no bare exceptions), eng/testing (degradation propagation test, error path test), eng/coding (minimal change, one detection function + one primitive).

Cannot verify compilation (no OCaml toolchain). CI is the compilation check. Test coverage is structural — the drift detection can't be fully e2e tested without binary replacement, but the error path and degradation propagation are covered.
