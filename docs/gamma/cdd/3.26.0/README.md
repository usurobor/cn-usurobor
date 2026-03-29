# v3.26.0 — Unified Log Stream + cn logs CLI

**Issue:** #74 — Rethink logs structure for operator observability
**Level:** L7 — System-shaping (changes observability boundary)
**Phase:** 1 of 3

## Gap

Operator investigating "what happened?" must check 6 log locations, 4 formats, with no correlation. The events stream has the right architecture (append-only JSONL) but wrong completeness (missing message content, missing correlation IDs, scheduler noise dominates).

## Change

1. **Unified log writer (`cn_ulog.ml`)**: Append-only JSONL to `logs/unified/YYYYMMDD.jsonl` with schema `cn.ulog.v1`. High-signal events only: message.received, invocation.start, invocation.end, message.sent, errors. Correlation via `msg_id` on every entry.

2. **`cn logs` CLI (`cn_logs.ml`)**: Single command for all log access.
   - `cn logs` — human-formatted tail (last 20 entries)
   - `cn logs --since <duration>` — time filter (e.g. `2h`, `30m`, `1d`)
   - `cn logs --msg <id>` — trace single message
   - `cn logs --errors` — errors/warnings only
   - `cn logs --json` — raw JSONL for piping
   - `cn logs --kind <kind>` — filter by event kind

3. **Runtime integration**: Emit unified log events at message receive, invocation start/end, and message send points in `cn_runtime.ml`.

## Acceptance Criteria

1. `cn logs` outputs human-formatted tail of unified log stream
2. `cn logs --since 2h` filters by time
3. `cn logs --msg <id>` traces single message receipt → processing → response
4. `cn logs --errors` filters to errors/warnings only
5. `cn logs --json` outputs raw JSONL for piping
6. Correlation ID (`msg_id`) on all entries for a single invocation
7. No ANSI codes in persistent log files
8. Log volume < 5MB/day for typical single-user agent

## Files Changed

- `VERSION` — 3.25.0 → 3.26.0
- `cn.json`, `packages/*/cn.package.json` — version stamp
- `src/cmd/cn_ulog.ml` — unified log writer (new)
- `src/cmd/cn_logs.ml` — cn logs CLI (new)
- `src/lib/cn_lib.ml` — add Logs command variant + parsing
- `src/cli/cn.ml` — wire Logs dispatch
- `src/cmd/cn_runtime.ml` — emit unified log events
- `src/cmd/dune` — register new modules
- `src/cli/dune` — add dependency if needed
- `test/cmd/cn_ulog_test.ml` �� unified log tests (new)
- `test/cmd/cn_logs_test.ml` — cn logs CLI tests (new)
- `test/cmd/dune` — register test modules
