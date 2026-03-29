# Plan — v3.26.0

## Architecture Decision

**Separate unified stream from existing events stream.** The events stream (`logs/events/`) has 50+ emission sites and serves as detailed system telemetry. The unified log (`logs/unified/`) is operator-facing: high-signal, low-noise, complete per-invocation story. They coexist — events for debugging, unified for operations.

**Schema:** `cn.ulog.v1` — flat JSONL with required fields: `ts`, `schema`, `kind`, `severity`. Optional per-kind: `msg_id`, `source`, `user_msg`, `response_preview`, `passes`, `ops`, `tokens_in`, `tokens_out`, `duration_ms`, `error`, `details`.

## Implementation Order

### 1. cn_ulog.ml — Unified log writer

Pure module with:
- `type kind` — discriminated union of event kinds (Message_received, Invocation_start, Invocation_end, Message_sent, Error)
- `type entry` — structured entry with all fields
- `entry_to_json` — serialize to JSON
- `write` — append one entry to `logs/unified/YYYYMMDD.jsonl`
- `read_day` — read all entries for a given date
- `read_since` — read entries since a timestamp
- No global state — takes hub_path as parameter

### 2. cn_logs.ml — CLI reader/formatter

- `run_logs` — main entry point, takes hub_path + options
- `type log_opts` — parsed CLI options (since, msg_id, errors_only, json_mode, kind_filter)
- `parse_duration` — parse "2h", "30m", "1d" into seconds
- `format_entry` — human-readable one-line format per entry
- `filter_entries` — apply filters (time, msg_id, errors, kind)
- Read from `logs/unified/` directory, most recent files first
- Default: last 20 entries from today's file

### 3. cn_lib.ml — Command variant

- Add `Logs of Logs.cmd` to `command` type
- Add `Logs` module with `type cmd` and parsing
- Add to `parse_command`, `string_of_command`, `help_text`

### 4. cn.ml — Dispatch

- Wire `Logs` command to `Cn_logs.run_logs`

### 5. cn_runtime.ml — Emission points

Four emission points in the runtime:
1. **message.received** — when a trigger is dequeued (in `process_one` or daemon telegram handler)
2. **invocation.start** — at the start of the processing pipeline
3. **invocation.end** — at finalization, with pass count, op count, token counts, duration
4. **message.sent** — after response is sent (Telegram reply or conversation store write)

Error events emitted on LLM failures, processing failures, lock contention.

### 6. Tests

- `cn_ulog_test.ml` — entry serialization, write/read roundtrip, filtering, JSONL format
- `cn_logs_test.ml` — duration parsing, human formatting, filter logic

### 7. dune wiring

- Add `cn_ulog` and `cn_logs` to `src/cmd/dune` modules list
- Add test libraries to `test/cmd/dune`

## Invariants

1. Every unified log entry has `ts`, `schema`, `kind`, `severity` — enforced by type
2. Every invocation-related entry has `msg_id` — enforced by constructor
3. No ANSI codes ever reach `logs/unified/` — writer uses plain text only
4. JSONL: one JSON object per line, no embedded newlines — enforced by serializer
5. Daily rotation by filename convention — same pattern as events/

## Risk

- **Volume**: The unified log is strictly additive (new directory alongside events/). If it turns out to be too noisy, we can raise the emission threshold. The events stream is unchanged.
- **Performance**: One file append per emission point (4 per invocation). Same pattern as events/, proven at scale.
- **Migration**: No migration needed — new directory, new schema. Old logs untouched.
