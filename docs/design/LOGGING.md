# CN Logging Architecture

**Status:** Current
**Date:** 2026-02-11
**Author:** Sigma

---

## Principle

cn does all effects. All effects are traceable. The agent's work is auditable without reading git history.

## Log Structure

```
logs/
 +-- input/              Archived agent inputs (one file per trigger)
 |    +-- {trigger}.md
 +-- output/             Archived agent outputs (one file per trigger)
 |    +-- {trigger}.md
 +-- runs/               Per-run directories from cn out commands
      +-- {timestamp}-{id}/
           +-- input.md
```

Additionally, system-level logging goes to `/var/log/cn-YYYYMMDD.log` via cron stdout.

## Audit Trail: IO Pairs

The primary audit mechanism. Every time the actor loop processes agent output, cn archives both sides:

```
state/input.md   →  logs/input/{trigger}.md    (what the agent saw)
state/output.md  →  logs/output/{trigger}.md   (what the agent decided)
```

Implementation in `cn_agent.ml`:

```ocaml
(* Archive IO pair before executing *)
let archive_name = trigger ^ ".md" in
Cn_ffi.Fs.write (Cn_ffi.Path.join logs_in archive_name) (Cn_ffi.Fs.read inp);
Cn_ffi.Fs.write (Cn_ffi.Path.join logs_out archive_name) output_content;

(* Then parse and execute ops *)
let ops = extract_ops output_meta in
ops |> List.iter (fun op -> execute_op hub_path name trigger op);

(* Then clean up *)
Cn_ffi.Fs.unlink inp;
Cn_ffi.Fs.unlink outp;
```

The trigger ID (from input frontmatter or auto-generated) links an input to its output. This gives a complete audit trail: for any past action, you can find what the agent saw and what it decided.

## Audit Trail: cn out Runs

When the agent uses `cn out` (structured output), a run directory is created:

```
logs/runs/{timestamp}-{id}/
 +-- input.md            The thread that was being processed
```

Implementation in `cn_agent.ml`:

```ocaml
let run_dir = Cn_ffi.Path.join hub_path
  (Printf.sprintf "logs/runs/%s-%s" run_ts id) in
Cn_ffi.Fs.mkdir_p run_dir;
Cn_ffi.Fs.write (Cn_ffi.Path.join run_dir "input.md") input_content;
```

## Traceability Properties

Every agent action has:

| Property | Source |
|----------|--------|
| **What the agent saw** | `logs/input/{trigger}.md` |
| **What the agent decided** | `logs/output/{trigger}.md` |
| **When it happened** | Trigger ID contains timestamp |
| **What cn executed** | Ops extracted from output frontmatter |
| **System-level log** | `/var/log/cn-YYYYMMDD.log` (cron stdout) |

## What Changed

Hub-level JSONL logging (`logs/cn.log`) was removed. It was redundant with system log + IO pair archives. The `Cn_hub.log_action` function is now a no-op:

```ocaml
let log_action _hub_path _action _details =
  (* Removed: hub log redundant with system log + logs/runs/
     System log: /var/log/cn-YYYYMMDD.log (cron stdout)
     Audit trail: logs/runs/ (input + output + meta) *)
  ()
```

The IO pair archive (`logs/input/` + `logs/output/`) provides richer traceability than JSONL because it preserves full thread content, not just action summaries.

## Related

- [ARCHITECTURE.md](../ARCHITECTURE.md) — directory layout, data flow
- [SECURITY-MODEL.md](SECURITY-MODEL.md) — audit trail as security mechanism
