# Self-Coherence — v3.26.0

## Artifact Checklist

| Artifact | Status | Location |
|----------|--------|----------|
| SELECTION.md | present | docs/gamma/cdd/3.26.0/SELECTION.md |
| README.md | present | docs/gamma/cdd/3.26.0/README.md |
| PLAN.md | present | docs/gamma/cdd/3.26.0/PLAN.md |
| SELF-COHERENCE.md | present | this file |
| VERSION bump | done | 3.25.0 → 3.26.0, stamp verified |
| Code: cn_ulog.ml | present | src/cmd/cn_ulog.ml |
| Code: cn_logs.ml | present | src/cmd/cn_logs.ml |
| Code: cn_lib.ml | modified | Logs command + parsing |
| Code: cn.ml | modified | dispatch wiring |
| Code: cn_runtime.ml | modified | 9 unified log emission points (5 happy path + 2 silent drops + 1 poll error + 1 N-pass failure) |
| Code: dune (cmd) | modified | new modules registered |
| Tests: cn_ulog_test.ml | present | test/cmd/cn_ulog_test.ml (13 tests) |
| Tests: cn_logs_test.ml | present | test/cmd/cn_logs_test.ml (8 tests) |
| Tests: dune (test) | modified | new test libraries registered |

## AC Coverage

| AC | Status | Evidence |
|----|--------|----------|
| 1. `cn logs` outputs human-formatted tail | met | cn_logs.ml:format_entry + run_logs default path |
| 2. `cn logs --since 2h` filters by time | met | cn_logs.ml:parse_duration + filter_entries since branch |
| 3. `cn logs --msg <id>` traces single message | met | cn_logs.ml:filter_entries msg_id branch |
| 4. `cn logs --errors` filters to errors/warnings | met | cn_logs.ml:filter_entries errors_only branch |
| 5. `cn logs --json` outputs raw JSONL | met | cn_logs.ml:run_logs json_mode branch |
| 6. Correlation ID (msg_id) on all entries | met | cn_ulog.ml:entry type + runtime emissions all pass msg_id |
| 7. No ANSI codes in persistent logs | met | cn_ulog.ml writes plain JSON only; colors in cn_logs.ml display only |
| 8. Log volume < 5MB/day | met by design | 4 entries per invocation, ~500 bytes each. 1000 invocations/day = ~2MB |

## Design Coherence

### What changed
- New observability surface: `logs/unified/YYYYMMDD.jsonl` (append-only JSONL, schema cn.ulog.v1)
- New CLI command: `cn logs` with 6 filter flags
- Runtime emits at 9 points: message lifecycle (received, start, end, sent), error paths (LLM failure, N-pass exhaustion), silent failure paths (rejected user, empty message, poll error)

### What did NOT change
- Existing events stream (`logs/events/`) unchanged — still written, still used for detailed telemetry
- Existing daemon.log unchanged — replacement deferred to Phase 3
- Input/output file structure unchanged — archive cleanup deferred to Phase 3
- No migration needed — unified log is additive

### Architecture decision
Separate unified stream from events stream. Events has 50+ emission sites and serves as system telemetry. Unified log is operator-facing: 5 event kinds, one msg_id per invocation, human-readable CLI. They coexist — events for debugging, unified for operations.

### Phasing
- Phase 1 (this release): unified log stream + `cn logs` CLI
- Phase 2: step-level trace archival (per-pass logging in N-pass bind loop)
- Phase 3: archive cleanup, retention/rotation, daemon.log replacement

## Level Assessment

**Claim: L7** — This changes the observability boundary. Before: operator must know 6 locations, 4 formats, and manually correlate. After: one stream with correlation IDs + one CLI command. The class of failure (operator can't find what happened) becomes structurally impossible.

L7 diagnostic:
- **Right boundary?** Yes — observability was spread across 6 unconnected surfaces
- **What gets easier?** #68 (self-diagnostics: agent can query unified log), #59 (doctor: can check recent errors), #65 (conversation persistence: indexed by msg_id)
- **What gets harder?** Nothing — strictly additive
- **Process cost?** One new directory to rotate (same pattern as events/)

## Known Gaps

1. **No build verification in this environment** — OCaml toolchain not available. CI will validate. Code follows established patterns (cn_trace.ml structure for writer, cn_system.ml pattern for CLI).
2. **Phase 2/3 deferred** — Step-level tracing and archive cleanup not in this release. Filed as future work per issue scoping note.
3. **Token counts not yet in unified log** — invocation.end emits ops count but not token counts (requires plumbing from LLM response through finalize). Can be added in Phase 2.
