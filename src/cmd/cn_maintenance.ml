(** cn_maintenance.ml — Unified maintenance engine (SCHEDULER-v3.7.0)

    Canonical maintenance primitives reusable from both daemon and oneshot
    schedulers. No scheduler logic or Telegram logic inside this module.

    Responsibilities:
    - peer sync (fetch, inbox materialization, outbox flush)
    - update checks
    - MCA/review tick
    - stale state cleanup

    Each primitive emits trace events via the global trace session. *)

open Cn_lib

(* === Maintenance result tracking === *)

type substep_status = Ok | Degraded of string | Skipped of string

type maintenance_result = {
  sync_status : substep_status;
  inbox_status : substep_status;
  outbox_status : substep_status;
  update_status : substep_status;
  review_status : substep_status;
  cleanup_status : substep_status;
}

let is_degraded result =
  let check = function Degraded _ -> true | _ -> false in
  check result.sync_status || check result.inbox_status ||
  check result.outbox_status || check result.update_status ||
  check result.review_status || check result.cleanup_status

let string_of_substep = function
  | Ok -> "ok"
  | Degraded msg -> Printf.sprintf "degraded:%s" msg
  | Skipped msg -> Printf.sprintf "skipped:%s" msg

(* === Sync primitive === *)

(** Run peer sync: fetch from peers, push to origin.
    Reuses the same logic as cn_system.run_sync but factored for reuse. *)
let sync_once ~hub_path ~name =
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"sync.start" ~severity:Info ~status:Ok_ ();
  try
    Cn_mail.inbox_check hub_path name;
    Cn_mail.inbox_process hub_path;
    Cn_mail.outbox_flush hub_path name;
    let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add -A" in
    let commit_result = Cn_ffi.Child_process.exec_in ~cwd:hub_path
      "git commit -m 'heartbeat' --allow-empty" in
    (match commit_result with
     | Some _ ->
         let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path
           "git push origin 2>/dev/null" in
         ()
     | None -> ());
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"sync.ok" ~severity:Info ~status:Ok_ ();
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"sync.error" ~severity:Warn ~status:Degraded
      ~reason_code:"sync_failed" ~reason:msg ();
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
     | Cn_agent.Update_available ver ->
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
          | _ -> Ok))
  with exn ->
    let msg = Printexc.to_string exn in
    Cn_trace.gemit ~component:"maintenance" ~layer:Body
      ~event:"update.check.error" ~severity:Warn ~status:Degraded
      ~reason_code:"update_check_error" ~reason:msg ();
    Degraded msg

(* === MCA review tick primitive === *)

(** Run MCA review tick if cycle count warrants it. *)
let review_tick_once ~hub_path ~name =
  try
    let cycle = Cn_mca.increment_mca_cycle hub_path in
    if cycle mod Cn_mca.mca_review_interval = 0
       && Cn_mca.mca_count hub_path > 0 then begin
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.start" ~severity:Info ~status:Ok_
        ~details:["cycle", Cn_json.Int cycle] ();
      let review = Cn_mca.prepare_mca_review hub_path name in
      let _ = Cn_agent.queue_add hub_path review.trigger "system" review.body in
      Cn_hub.log_action hub_path "mca.review-queued"
        (Printf.sprintf "trigger:%s count:%d" review.trigger review.count);
      print_endline (Cn_fmt.ok
        (Printf.sprintf "Queued MCA review (%d MCAs)" review.count));
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.complete" ~severity:Info ~status:Ok_
        ~details:["count", Cn_json.Int review.count] ();
      Ok
    end else begin
      Cn_trace.gemit ~component:"maintenance" ~layer:Body
        ~event:"review.tick.complete" ~severity:Info ~status:Skipped
        ~reason_code:"not_due" ();
      Skipped "not_due"
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
       && Cn_ffi.Fs.exists finalized_dir then
      Cn_ffi.Fs.readdir finalized_dir
      |> List.iter (fun f ->
           let path = Cn_ffi.Path.join finalized_dir f in
           (try Sys.remove path with Sys_error _ -> ());
           Cn_hub.log_action hub_path "maintenance.gc_ops_done"
             (Printf.sprintf "removed stale marker: %s" f));
    Ok
  with exn ->
    let msg = Printexc.to_string exn in
    Degraded msg

(* === Unified maintain_once === *)

(** Run one full maintenance tick: sync, inbox, outbox, update, review, cleanup.
    Returns a maintenance_result describing what happened.
    Sub-step failures degrade but do not crash the scheduler. *)
let maintain_once ~(config : Cn_config.config) ~hub_path ~name =
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"maintenance.start" ~severity:Info ~status:Ok_ ();

  let sync_status = sync_once ~hub_path ~name in
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
  let review_status = review_tick_once ~hub_path ~name in
  let cleanup_status = cleanup_once ~hub_path in

  let result = { sync_status; inbox_status; outbox_status;
                 update_status; review_status; cleanup_status } in

  let overall_status = if is_degraded result then "degraded" else "ok" in
  Cn_trace.gemit ~component:"maintenance" ~layer:Body
    ~event:"maintenance.complete" ~severity:Info
    ~status:(if is_degraded result then Degraded else Ok_)
    ~details:[
      "sync", Cn_json.String (string_of_substep sync_status);
      "inbox", Cn_json.String (string_of_substep inbox_status);
      "outbox", Cn_json.String (string_of_substep outbox_status);
      "update", Cn_json.String (string_of_substep update_status);
      "review", Cn_json.String (string_of_substep review_status);
      "cleanup", Cn_json.String (string_of_substep cleanup_status);
    ] ();
  ignore config;  (* config reserved for future interval-based gating *)

  print_endline (Cn_fmt.ok
    (Printf.sprintf "Maintenance complete (%s)" overall_status));
  result
