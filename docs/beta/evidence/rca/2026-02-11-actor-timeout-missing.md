# RCA: Actor Timeout Missing — 2026-02-11

## Incident

Queue blocked at 363 items. Agent woken but never called `cn done`. `input.md` stuck since 09:35. Cron ran 148 times, each time printing "Agent working" and doing nothing.

## Root Cause

`cn in` has no timeout logic for the `Processing` state:

```ocaml
| Cn_protocol.Processing ->
    print_endline "Agent working (input.md exists, awaiting output.md)";
    print_endline (Printf.sprintf "Queue depth: %d" (queue_count hub_path))
    (* NO TIMEOUT CHECK — just prints and exits *)
```

**Failure modes with no recovery:**
1. Agent doesn't call `cn done` → stuck forever
2. Agent crashes → stuck forever
3. Wake event lost → stuck forever

## Evidence

```
$ grep -c "Agent working" /var/log/cn-20260211.log
148
```

148 cron cycles × 5 min = 12+ hours stuck.

Queue grew from 353 → 363 while blocked.

## Timeline

- 09:35 UTC — `cn in` writes input.md, sends wake
- 09:35 UTC — Agent woken (presumably), never calls `cn done`
- 09:40 - 21:55 UTC — Cron runs 148 times, each time "Agent working", no recovery
- 21:42 UTC — User notices 363 queue depth
- 21:57 UTC — Root cause identified: no timeout in Processing state

## Lesson

**Erlang principle: Supervisor must detect and recover from worker failure.**

Cron is the supervisor. It runs every 5 min but has no timeout logic. A proper supervisor would:
1. Track how long worker has been processing
2. After N cycles, declare timeout
3. Archive as failed, proceed to next item

## Proposed Fix

Add configurable timeout to `cn in`:

```ocaml
(* Config: state/config.yaml or environment *)
let cron_period_min = 5          (* how often cron runs *)
let timeout_cycles = 3           (* cycles before timeout = 15 min *)

| Cn_protocol.Processing ->
    let age_min = input_age_minutes hub_path in
    let max_age = cron_period_min * timeout_cycles in
    if age_min > max_age then begin
      archive_as_timeout hub_path;
      log_action "actor.timeout" (sprintf "age:%d max:%d" age_min max_age);
      feed_next_input hub_path
    end else
      print_endline (sprintf "Agent working (%d/%d min)" age_min max_age)
```

**Configurable parameters:**
- `CN_CRON_PERIOD_MIN` — cron interval (default: 5)
- `CN_TIMEOUT_CYCLES` — cycles before fail (default: 3 = 15 min)

## Prevention

1. Supervisor pattern: always have timeout/recovery for async operations
2. "Let it crash" + restart > infinite wait
3. Log age of input.md so stuck state is visible
4. Alert if queue depth grows while Processing (symptom of stuck actor)
