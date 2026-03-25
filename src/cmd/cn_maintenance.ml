(** cn_maintenance.ml — Unified maintenance engine (SCHEDULER-v3.7.0)

    Interoceptive (self-driven) protocol duties reusable from both daemon
    and oneshot schedulers. No scheduler logic or Telegram logic inside
    this module — exteroceptive concerns live in cn_runtime.ml.

    Each primitive emits trace events via the global trace session.
    sync_once uses Git result variants (argv-style via Process.exec_args)
    for error propagation. Other git callers in Git module still use
    shell-based Child_process.exec_in for convenience.

    Primitive boundaries (each does exactly one thing):
    - inbox_check_once: fetch inbound peer branches, triage to inbox
    - sync_once: git fetch, add, heartbeat commit, push (transport-level)
    - materialize_inbox_once: queue inbox items for processing
    - flush_outbox_once: send pending outbox messages to peers
    - update_check_once: check for binary updates
    - review_tick_once: time-gated MCA review (wall-clock via review_interval_sec)
    - cleanup_once: GC stale finalized markers *)

(* === Maintenance result tracking === *)

type substep_status = Ok | Degraded of string | Skipped of string

type maintenance_result = {
  inbox_check_status : substep_status;
  sync_status : substep_status;
  inbox_status : substep_status;  (* materialization *)
  outbox_status : substep_status;
  update_status : substep_status;
  review_status : substep_status;
  cleanup_status : substep_status;
}

let is_degraded result =
  let check = function Degraded _ -> true | _ -> false in
  check result.inbox_check_status || check result.sync_status ||
  check result.inbox_status || check result.outbox_status ||
  check result.update_status || check result.review_status ||
  check result.cleanup_status

let string_of_substep = function
  | Ok -> "ok"
  | Degraded msg -> Printf.sprintf "degraded:%s" msg
  | Skipped msg -> Printf.sprintf "skipped:%s" msg

(** Short status string for projection fields: "ok", "degraded", or "skipped". *)
let status_string = function
  | Ok -> "ok"
  | Degraded _ -> "degraded"
  | Skipped _ -> "skipped"

(* === Review timestamp tracking === *)

let last_review_path hub_path =
  Cn_ffi.Path.join hub_path "state/.last-review-at"

let read_last_review_at hub_path =
  let path = last_review_path hub_path in
  if Cn_ffi.Fs.exists path then
    (try
       let s = String.trim (Cn_ffi.Fs.read path) in
       Some (float_of_string s)
     with _ -> None)
  else None

let write_last_review_at hub_path =
  Cn_ffi.Fs.write (last_review_path hub_path)
    (Printf.sprintf "%.0f" (Unix.gettimeofday ()))

(* === Sync primitive === *)

(** Peer sync: fetch, stage local changes, heartbeat commit, push.
    Uses argv-style Git result variants (Git.fetch_r etc.) for proper
    error propagation — a failed git op produces Degraded, not silent Ok.
    The heartbeat commit advances HEAD even when idle, signaling liveness. *)
let sync_once ~hub_path =
  let sync_t0 = Unix.gettimeofday () in
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"sync.start" ~severity:Info ~status:Ok_ ();
  let degrade step code out =
    let msg = Printf.sprintf "%s failed (exit %d): %s" step code (String.trim out) in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"sync.error" ~severity:Warn ~status:Degraded
      ~reason_code:"sync_failed" ~reason:msg
      ~details:[
        "step", Cn_json.String step;
        "exit_code", Cn_json.Int code;
      ] ();
    Degraded msg
  in
  try
    (* Fetch — network failure is non-fatal; we can still stage+commit+push local *)
    let fetch_warn = match Git.fetch_r ~cwd:hub_path with
      | Ok _ -> None
      | Error (code, out) -> Some (degrade "git-fetch" code out)
    in
    (* Stage — failure is fatal for commit *)
    (match Git.add_all_r ~cwd:hub_path with
     | Error (code, out) -> degrade "git-add" code out
     | Ok _ ->
    (* Commit — failure is fatal for push *)
    match Git.commit_allow_empty_r ~cwd:hub_path ~msg:"heartbeat" with
     | Error (code, out) -> degrade "git-commit" code out
     | Ok _ ->
    (* Push — failure degrades *)
    match Git.push_r ~cwd:hub_path with
     | Error (code, out) -> degrade "git-push" code out
     | Ok _ ->
    (* All local ops succeeded; report fetch warning if any *)
    match fetch_warn with
     | Some status -> status
     | None ->
         let duration_ms = int_of_float ((Unix.gettimeofday () -. sync_t0) *. 1000.0) in
         Cn_trace.gemit ~component:"maintenance" ~layer:Body
           ~event:"sync.ok" ~severity:Info ~status:Ok_
           ~details:["duration_ms", Cn_json.Int duration_ms] ();
         Ok)
  with exn ->
    let msg = Printexc.to_string exn in
    let duration_ms = int_of_float ((Unix.gettimeofday () -. sync_t0) *. 1000.0) in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"sync.error" ~severity:Warn ~status:Degraded
      ~reason_code:"sync_failed" ~reason:msg
      ~details:["duration_ms", Cn_json.Int duration_ms] ();
    Degraded msg

(* === Inbox check primitive === *)

(** Fetch inbound peer branches and triage to inbox.
    Separate from sync_once: this is protocol-level inbox work,
    not git-level transport. *)
let inbox_check_once ~hub_path ~name =
  try
    Cn_mail.inbox_check hub_path name;
    Cn_mail.inbox_process hub_path;
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"inbox.checked" ~severity:Info ~status:Ok_ ();
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"inbox.checked" ~severity:Warn ~status:Degraded
      ~reason_code:"inbox_check_failed" ~reason:msg ();
    Degraded msg

(* === Inbox materialization primitive === *)

(** Materialize inbox items from peer branches into queue. *)
let materialize_inbox_once ~hub_path =
  try
    let queued = Cn_agent.queue_inbox_items hub_path in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"inbox.materialized" ~severity:Info ~status:Ok_
      ~details:["count", Cn_json.Int queued] ();
    if queued > 0 then
      print_endline (Cn_fmt.ok
        (Printf.sprintf "Queued %d inbox item(s)" queued));
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"inbox.materialized" ~severity:Warn ~status:Degraded
      ~reason_code:"inbox_failed" ~reason:msg ();
    Degraded msg

(* === Outbox flush primitive === *)

(** Flush outbox — send pending messages to peers. *)
let flush_outbox_once ~hub_path ~name =
  try
    Cn_mail.outbox_flush hub_path name;
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"outbox.flushed" ~severity:Info ~status:Ok_ ();
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"outbox.flushed" ~severity:Warn ~status:Degraded
      ~reason_code:"outbox_failed" ~reason:msg ();
    Degraded msg

(* === Update check primitive === *)

(** Check for binary updates. Only runs when cooldown allows. *)
let update_check_once ~hub_path =
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"update.check.start" ~severity:Info ~status:Ok_ ();
  try
    let update_info = Cn_agent.check_for_update hub_path in
    (match update_info with
     | Cn_agent.Update_skip ->
         Cn_trace.gemit ~component:"maintenance" ~layer:Body
           ~event:"update.check.ok" ~severity:Info ~status:Ok_
           ~reason_code:"up_to_date" ();
         Ok
     | Cn_agent.Update_patch ver | Cn_agent.Update_available ver ->
         print_endline (Cn_fmt.info
           (Printf.sprintf "Update available: %s -> %s" Cn_lib.version ver));
         Cn_hub.log_action hub_path "maintenance.update"
           (Printf.sprintf "available:%s" ver);
         let result = Cn_agent.do_update update_info in
         (match result with
          | Cn_protocol.Update_complete ->
              Cn_hub.log_action hub_path "maintenance.update"
                (Printf.sprintf "complete:%s" ver);
              Cn_trace.gemit ~component:"maintenance" ~layer:Body
                ~event:"update.check.ok" ~severity:Info ~status:Ok_
                ~reason_code:"updated"
                ~details:["version", Cn_json.String ver] ();
              print_endline (Cn_fmt.ok
                (Printf.sprintf "Updated to %s, re-executing..." ver));
              Cn_agent.re_exec ()
          | Cn_protocol.Update_fail ->
              Cn_hub.log_action hub_path "maintenance.update" "failed";
              Cn_trace.gemit ~component:"maintenance" ~layer:Body
                ~event:"update.check.ok" ~severity:Warn ~status:Degraded
                ~reason_code:"update_failed" ();
              print_endline (Cn_fmt.warn
                "Update failed, continuing with current version");
              Degraded "update_failed"
          | Cn_protocol.Update_skip ->
              (* Binary path not writable (non-root daemon) — skip gracefully *)
              Cn_trace.gemit ~component:"maintenance" ~layer:Body
                ~event:"update.check.ok" ~severity:Info ~status:Ok_
                ~reason_code:"not_writable" ();
              print_endline (Cn_fmt.dim
                "Update skipped (binary not writable)");
              Ok
          | _ -> Ok))
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"update.check.error" ~severity:Warn ~status:Degraded
      ~reason_code:"update_check_error" ~reason:msg ();
    Degraded msg

(* === MCA review tick primitive === *)

(** Run MCA review tick if time-gated interval has elapsed.
    Uses wall-clock time (state/.last-review-at) gated by
    config.scheduler.review_interval_sec. Falls back to cycle-based
    gating only if no config interval applies. *)
let review_tick_once ~hub_path ~name ~review_interval_sec =
  try
    let now = Unix.gettimeofday () in
    let last = read_last_review_at hub_path in
    let elapsed = match last with
      | Some t -> now -. t
      | None -> infinity  (* never reviewed → due *)
    in
    let interval = float_of_int review_interval_sec in
    (* Only review if MCA directory has been touched since last review *)
    let mca_changed = match last with
      | None -> true  (* never reviewed → always due *)
      | Some last_t ->
          let dir = Cn_hub.mca_dir hub_path in
          if Cn_ffi.Fs.exists dir then
            try
              Cn_ffi.Fs.readdir dir
              |> List.exists (fun f ->
                let path = Cn_ffi.Path.join dir f in
                try (Unix.stat path).st_mtime > last_t
                with Unix.Unix_error _ -> false)
            with _ -> false
          else false
    in
    if review_interval_sec > 0 && elapsed >= interval && Cn_mca.mca_count hub_path > 0 && mca_changed then begin
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.start" ~severity:Info ~status:Ok_
        ~details:[
          "elapsed_sec", Cn_json.Int (int_of_float elapsed);
          "interval_sec", Cn_json.Int review_interval_sec;
        ] ();
      let review = Cn_mca.prepare_mca_review hub_path name in
      let _ = Cn_agent.queue_add hub_path review.trigger "system" review.body in
      Cn_hub.log_action hub_path "mca.review-queued"
        (Printf.sprintf "trigger:%s count:%d" review.trigger review.count);
      write_last_review_at hub_path;
      print_endline (Cn_fmt.ok
        (Printf.sprintf "Queued MCA review (%d MCAs)" review.count));
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.complete" ~severity:Info ~status:Ok_
        ~details:["count", Cn_json.Int review.count] ();
      Ok
    end else begin
      let reason = if review_interval_sec = 0 then "disabled"
                   else if Cn_mca.mca_count hub_path = 0 then "no_mcas"
                   else if not mca_changed then "no_new_mcas"
                   else "not_due" in
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.complete" ~severity:Info ~status:Skipped
        ~reason_code:reason ();
      Skipped reason
    end
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"review.tick.complete" ~severity:Warn ~status:Degraded
      ~reason_code:"review_failed" ~reason:msg ();
    Degraded msg

(* === Stale state cleanup primitive === *)

(** Clean up stale finalized markers and other runtime debris. *)
let cleanup_once ~hub_path =
  try
    let finalized_dir = Cn_ffi.Path.join hub_path "state/finalized" in
    let inp = Cn_agent.input_path hub_path in
    let outp = Cn_agent.output_path hub_path in
    (* Only GC stale markers when no state files exist *)
    if not (Cn_ffi.Fs.exists inp) && not (Cn_ffi.Fs.exists outp)
       && Cn_ffi.Fs.exists finalized_dir then begin
      let markers = Cn_ffi.Fs.readdir finalized_dir in
      let removed = ref 0 in
      markers |> List.iter (fun f ->
           let path = Cn_ffi.Path.join finalized_dir f in
           (try Sys.remove path; incr removed with Sys_error _ -> ());
           Cn_hub.log_action hub_path "maintenance.gc_ops_done"
             (Printf.sprintf "removed stale marker: %s" f));
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"cleanup.complete" ~severity:Info ~status:Ok_
        ~details:["removed", Cn_json.Int !removed] ()
    end else
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"cleanup.complete" ~severity:Info ~status:Skipped
        ~reason_code:"nothing_to_clean" ();
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"cleanup.complete" ~severity:Warn ~status:Degraded
      ~reason_code:"cleanup_failed" ~reason:msg ();
    Degraded msg

(* === Unified maintain_once === *)

(** Run one full maintenance tick (interoception — self-driven protocol duties).
    Returns a maintenance_result describing what happened.
    Sub-step failures degrade but do not crash the scheduler.

    Primitive sequence:
    1. inbox_check_once — fetch inbound peer branches, triage to inbox
    2. sync_once — stage, heartbeat commit, push (transport + liveness)
    3. materialize_inbox_once — queue inbox items for processing
    4. flush_outbox_once — send pending outbox to peers
    5. update_check_once — binary update (when idle)
    6. review_tick_once — MCA review (time-gated)
    7. cleanup_once — GC stale markers *)
let maintain_once ~(config : Cn_config.config) ~hub_path ~name =
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"maintenance.start" ~severity:Info ~status:Ok_ ();

  (* Inbox check before sync: fetch peer branches so sync commits include them *)
  let inbox_check_status = inbox_check_once ~hub_path ~name in
  let sync_status = sync_once ~hub_path in
  let inbox_status = materialize_inbox_once ~hub_path in
  let outbox_status = flush_outbox_once ~hub_path ~name in
  let update_status =
    (* Only check updates when truly idle *)
    let lock_path = Cn_ffi.Path.join hub_path "state/agent.lock" in
    if not (Cn_ffi.Fs.exists (Cn_agent.input_path hub_path))
       && not (Cn_ffi.Fs.exists (Cn_agent.output_path hub_path))
       && not (Cn_ffi.Fs.exists lock_path) then
      update_check_once ~hub_path
    else
      Skipped "agent_busy"
  in
  let review_status =
    review_tick_once ~hub_path ~name
      ~review_interval_sec:config.scheduler.review_interval_sec
  in
  let cleanup_status = cleanup_once ~hub_path in

  let result = { inbox_check_status; sync_status; inbox_status;
                 outbox_status; update_status; review_status;
                 cleanup_status } in

  let overall_status = if is_degraded result then "degraded" else "ok" in
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"maintenance.complete" ~severity:Info
    ~status:(if is_degraded result then Degraded else Ok_)
    ~details:[
      "inbox_check", Cn_json.String (string_of_substep inbox_check_status);
      "sync", Cn_json.String (string_of_substep sync_status);
      "inbox", Cn_json.String (string_of_substep inbox_status);
      "outbox", Cn_json.String (string_of_substep outbox_status);
      "update", Cn_json.String (string_of_substep update_status);
      "review", Cn_json.String (string_of_substep review_status);
      "cleanup", Cn_json.String (string_of_substep cleanup_status);
    ] ();

  print_endline (Cn_fmt.ok
    (Printf.sprintf "Maintenance complete (%s)" overall_status));
  result
