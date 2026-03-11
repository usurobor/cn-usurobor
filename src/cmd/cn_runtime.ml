(** cn_runtime.ml — Agent runtime orchestrator

    Owns the full processing pipeline: dequeue → pack → call LLM →
    write output → archive → parse → execute → project → conversation.

    Replaces the previous run_inbound + feed_next_input + wake_agent
    split. Single entry points: process_one and run_cron.

    Uses atomic file locking (O_CREAT|O_EXCL) to prevent cron overlap
    and daemon race conditions on state/input.md and state/output.md.

    Prompt contract:
    - LLM is invoked with structured system blocks + message turns.
    - state/input.md contains a flattened audit view (frontmatter + markdown).
    - On recovery (State 2), the inbound message is extracted from input.md
      and re-packed to produce fresh structured data for the API call.

    Recovery model: process_one handles three entry states under lock:
    1. output.md exists → finalize existing cycle
    2. input.md exists (no output) → resume: call LLM, then finalize
    3. neither exists → dequeue, pack, call LLM, finalize *)

open Cn_lib

(* === Lock === *)

let lock_path hub_path = Cn_ffi.Path.join hub_path "state/agent.lock"
let lock_max_age_sec = 600.0 (* 10 minutes — stale lock threshold *)

(** Acquire an exclusive lock. Returns Ok fd on success, Error msg if busy. *)
let acquire_lock hub_path =
  let path = lock_path hub_path in
  Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
  (* Check for stale lock *)
  (if Cn_ffi.Fs.exists path then
     try
       let stat = Unix.stat path in
       let age = Unix.gettimeofday () -. stat.Unix.st_mtime in
       if age > lock_max_age_sec then begin
         Cn_trace.gemit ~component:"runtime" ~layer:Body
           ~event:"lock.stale" ~severity:Warn ~status:Ok_
           ~reason:(Printf.sprintf "age=%.0fs, removing" age) ();
         Cn_ffi.Fs.unlink path
       end
     with _ -> ());
  try
    let fd = Unix.openfile path [Unix.O_CREAT; Unix.O_EXCL; Unix.O_WRONLY] 0o644 in
    Cn_trace.gemit ~component:"runtime" ~layer:Body
      ~event:"lock.acquired" ~severity:Info ~status:Ok_ ();
    Ok fd
  with Unix.Unix_error (Unix.EEXIST, _, _) ->
    Cn_trace.gemit ~component:"runtime" ~layer:Body
      ~event:"lock.busy" ~severity:Info ~status:Skipped
      ~reason_code:"lock_busy" ();
    Error "agent already running (state/agent.lock exists)"

let release_lock hub_path fd =
  (try Unix.close fd with _ -> ());
  (try Cn_ffi.Fs.unlink (lock_path hub_path) with _ -> ());
  Cn_trace.gemit ~component:"runtime" ~layer:Body
    ~event:"lock.released" ~severity:Info ~status:Ok_ ()

(* === Helpers === *)

(** Extract the original inbound message from packed context.
    Cn_context.pack always emits "## Inbound Message\n\n" as the last
    section. On recovery paths, extract_body returns the full packed
    context, so we slice out just the inbound part for conversation. *)
let extract_inbound_message packed_body =
  match String.split_on_char '\n' packed_body
        |> List.fold_left (fun (found, acc) line ->
             if found then (true, line :: acc)
             else if line = "## Inbound Message" then (true, acc)
             else (false, acc)
           ) (false, [])
  with
  | (true, lines) ->
      let text = lines |> List.rev |> String.concat "\n" |> String.trim in
      (* Skip the **From**: and **ID**: metadata lines *)
      let lines = String.split_on_char '\n' text in
      let body_lines = lines |> List.filter (fun l ->
        let trimmed = String.trim l in
        not (String.length trimmed >= 8 && String.sub trimmed 0 8 = "**From**")
        && not (String.length trimmed >= 6 && String.sub trimmed 0 6 = "**ID**")) in
      String.concat "\n" body_lines |> String.trim
  | (false, _) -> packed_body (* fallback: no marker found *)

(** Derive the Telegram payload from resolved ops and body.
    Priority: body (if present) > first Reply msg > "(acknowledged)" *)
let telegram_payload (ops : agent_op list) body =
  match body with
  | Some b -> b
  | None ->
      (* Look for a Reply op with a message *)
      let reply_msg = ops |> List.find_map (fun (op : agent_op) ->
        match op with Reply (_, msg) -> Some msg | _ -> None) in
      match reply_msg with
      | Some msg -> msg
      | None -> "(acknowledged)"

(* === Conversation persistence === *)

let conversation_path hub_path =
  Cn_ffi.Path.join hub_path "state/conversation.json"

(** Append a user+assistant exchange to state/conversation.json.
    Creates the file if missing. Keeps last 50 entries to bound growth. *)
let append_conversation hub_path ~trigger_id ~user_msg ~assistant_msg =
  let path = conversation_path hub_path in
  let existing =
    if Cn_ffi.Fs.exists path then
      match Cn_ffi.Fs.read path |> Cn_json.parse with
      | Ok (Cn_json.Array items) -> items
      | _ -> []
    else []
  in
  (* Dedup: if any entry already carries this trigger_id, this is a
     recovery replay — skip to avoid double-appending conversation. *)
  let already_appended = existing |> List.exists (fun entry ->
    Cn_json.get_string "trigger_id" entry = Some trigger_id
  ) in
  if already_appended then
    Cn_hub.log_action hub_path "process.conversation_skip"
      (Printf.sprintf "trigger:%s already in conversation" trigger_id)
  else begin
    let new_entries = existing @ [
      Cn_json.Object [
        "role", Cn_json.String "user";
        "content", Cn_json.String user_msg;
        "trigger_id", Cn_json.String trigger_id];
      Cn_json.Object [
        "role", Cn_json.String "assistant";
        "content", Cn_json.String assistant_msg];
    ] in
    (* Keep last 50 entries *)
    let len = List.length new_entries in
    let trimmed = if len > 50 then
      List.filteri (fun i _ -> i >= len - 50) new_entries
    else new_entries in
    Cn_ffi.Fs.write path (Cn_json.to_string (Cn_json.Array trimmed) ^ "\n")
  end

(* === Archive (raw — no ops, no deletes) === *)

(** Copy input.md and output.md to logs/ for audit.
    Does NOT execute ops or delete state files — caller handles those. *)
let archive_raw hub_path ~trigger_id =
  let inp = Cn_agent.input_path hub_path in
  let outp = Cn_agent.output_path hub_path in
  let logs_in = Cn_agent.logs_input_dir hub_path in
  let logs_out = Cn_agent.logs_output_dir hub_path in
  Cn_ffi.Fs.ensure_dir logs_in;
  Cn_ffi.Fs.ensure_dir logs_out;
  let archive_name = trigger_id ^ ".md" in
  (if Cn_ffi.Fs.exists inp then
     Cn_ffi.Fs.write (Cn_ffi.Path.join logs_in archive_name) (Cn_ffi.Fs.read inp));
  (if Cn_ffi.Fs.exists outp then
     Cn_ffi.Fs.write (Cn_ffi.Path.join logs_out archive_name) (Cn_ffi.Fs.read outp));
  Cn_hub.log_action hub_path "io.archive" (Printf.sprintf "trigger:%s" trigger_id)

(** Clean up state files after a cycle is fully complete. *)
let cleanup_state hub_path =
  let inp = Cn_agent.input_path hub_path in
  let outp = Cn_agent.output_path hub_path in
  (if Cn_ffi.Fs.exists inp then Cn_ffi.Fs.unlink inp);
  (if Cn_ffi.Fs.exists outp then Cn_ffi.Fs.unlink outp)

(* === Input construction === *)

(** Build state/input.md with frontmatter + audit text.
    Frontmatter is runtime metadata; the body is a flattened view of what
    was sent to the LLM (for human audit and recovery). *)
let build_input_md ~trigger_id ~from ~chat_id_opt ~audit_text =
  let buf = Buffer.create (String.length audit_text + 128) in
  Buffer.add_string buf "---\n";
  Buffer.add_string buf (Printf.sprintf "id: %s\n" trigger_id);
  Buffer.add_string buf (Printf.sprintf "from: %s\n" from);
  (match chat_id_opt with
   | Some cid -> Buffer.add_string buf (Printf.sprintf "chat_id: %d\n" cid)
   | None -> ());
  Buffer.add_string buf (Printf.sprintf "date: %s\n" (Cn_fmt.now_iso ()));
  Buffer.add_string buf "---\n\n";
  Buffer.add_string buf audit_text;
  Buffer.contents buf

(* === Finalize checkpoint === *)

(** Ops-done marker path: state/finalized/{trigger_id}.ops_done
    Created atomically after all ops execute successfully.
    Checked on recovery replay to skip re-execution of side effects. *)
let ops_done_path hub_path trigger_id =
  Cn_ffi.Path.join hub_path
    (Cn_ffi.Path.join "state/finalized" (trigger_id ^ ".ops_done"))

let mark_ops_done hub_path trigger_id =
  let path = ops_done_path hub_path trigger_id in
  Cn_ffi.Fs.ensure_dir (Filename.dirname path);
  (try
     let fd = Unix.openfile path
                [Unix.O_CREAT; Unix.O_EXCL; Unix.O_WRONLY] 0o644 in
     Unix.close fd
   with Unix.Unix_error (Unix.EEXIST, _, _) -> ())

let ops_already_done hub_path trigger_id =
  Sys.file_exists (ops_done_path hub_path trigger_id)

let clear_ops_done hub_path trigger_id =
  let path = ops_done_path hub_path trigger_id in
  (try Sys.remove path with Sys_error _ -> ())

(* === Shared boot sequence (TRACEABILITY §7) === *)

(** Boot result: asset summary + coherence state for projection writes. *)
type boot_info = {
  session : Cn_trace.session;
  summary : Cn_assets.asset_summary;
  lock_ok : bool;
  pkg_names : string list;
  total_skills : int;
}

(** Run the full boot/readiness sequence and write projections.
    Called from daemon, cron, and stdio. Mode is "daemon"/"cron"/"stdio".
    Returns Ok boot_info on success, Error msg if boot is blocked. *)
let boot_sequence ~(config : Cn_config.config) ~hub_path ~mode =
  let session = match Cn_trace.get_global () with
    | Some s -> s
    | None -> Cn_trace.init_global hub_path
  in

  (* 1. boot.start *)
  Cn_trace.emit_simple session ~component:"runtime" ~layer:Body
    ~event:"boot.start" ~severity:Info ~status:Ok_
    ~details:["mode", Cn_json.String mode] ();

  (* 2. config.loaded *)
  Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
    ~event:"config.loaded" ~severity:Info ~status:Ok_
    ~details:[
      "model", Cn_json.String config.model;
      "poll_interval", Cn_json.Int config.poll_interval;
      "poll_timeout", Cn_json.Int config.poll_timeout;
    ] ();

  (* 3. deps.lock.loaded *)
  let lock_ok = Cn_ffi.Fs.exists (Cn_ffi.Path.join hub_path ".cn/deps.lock.json") in
  Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
    ~event:"deps.lock.loaded" ~severity:Info
    ~status:(if lock_ok then Ok_ else Degraded) ();

  (* 4. assets.validated *)
  let assets_ok = match Cn_assets.validate_packages ~hub_path with
    | Ok () ->
        Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
          ~event:"assets.validated" ~severity:Info ~status:Ok_ ();
        true
    | Error msg ->
        Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
          ~event:"boot.blocked" ~severity:Error_ ~status:Blocked
          ~reason_code:"core_doctrine_missing" ~reason:msg ();
        Cn_trace_state.write_ready hub_path {
          status = Blocked; boot_id = session.boot_id;
          updated_at = Cn_fmt.now_iso ();
          blocked_reason = Some "core_doctrine_missing";
          mind = None; body = None; sensors_telegram = None;
        };
        false
  in
  if not assets_ok then
    Error "Boot blocked: core assets missing"
  else begin
    (* 5-8. doctrine, mindsets, skills, capabilities *)
    let summary = Cn_assets.summarize ~hub_path in
    let total_skills = List.fold_left (fun acc (_, c) -> acc + c) 0 summary.packages in

    (* Doctrine: per-file detail *)
    Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
      ~event:"doctrine.loaded" ~severity:Info ~status:Ok_
      ~details:[
        "count", Cn_json.Int summary.doctrine_count;
        "required", Cn_json.Array (List.map (fun s ->
          Cn_json.String s) Cn_assets.required_doctrine);
      ] ();

    (* Mindsets: count + hub overrides *)
    Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
      ~event:"mindsets.loaded" ~severity:Info ~status:Ok_
      ~details:[
        "count", Cn_json.Int summary.mindset_count;
        "required", Cn_json.Array (List.map (fun s ->
          Cn_json.String s) Cn_assets.required_mindsets);
        "hub_overrides", Cn_json.Int summary.hub_overrides_mindsets;
      ] ();

    (* Skills: per-package breakdown *)
    Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
      ~event:"skills.indexed" ~severity:Info ~status:Ok_
      ~details:[
        "count", Cn_json.Int total_skills;
        "per_package", Cn_json.Object (List.map (fun (pkg, count) ->
          (pkg, Cn_json.Int count)) summary.packages);
        "hub_overrides", Cn_json.Int summary.hub_overrides_skills;
      ] ();

    (* Capabilities: config + profile *)
    Cn_trace.emit_simple session ~component:"runtime" ~layer:Mind
      ~event:"capabilities.rendered" ~severity:Info ~status:Ok_
      ~details:[
        "profile", Cn_json.String
          (Option.value ~default:"engineer" summary.profile);
        "two_pass", Cn_json.String config.shell.two_pass;
        "apply_mode", Cn_json.String config.shell.apply_mode;
        "exec_enabled", Cn_json.Bool config.shell.exec_enabled;
      ] ();

    (* 9. boot.ready *)
    Cn_trace.emit_simple session ~component:"runtime" ~layer:Body
      ~event:"boot.ready" ~severity:Info ~status:Ok_ ();

    let pkg_names = List.map (fun (name, _) -> name) summary.packages in

    (* Write ready.json — mode-aware sensor block *)
    let sensors_telegram = match mode with
      | "daemon" -> Some {
          Cn_trace_state.enabled = true;
          offset = 0; (* daemon will update after offset load *)
          last_poll_status = "starting";
          last_poll_at = Cn_fmt.now_iso ();
        }
      | _ -> None
    in
    Cn_trace_state.write_ready hub_path {
      status = Ready; boot_id = session.boot_id;
      updated_at = Cn_fmt.now_iso ();
      blocked_reason = None;
      mind = Some {
        profile = Option.value ~default:"engineer" summary.profile;
        packages = pkg_names;
        doctrine_required = List.length Cn_assets.required_doctrine;
        doctrine_loaded = summary.doctrine_count;
        doctrine_hash = "";
        mindsets_required = List.length Cn_assets.required_mindsets;
        mindsets_loaded = summary.mindset_count;
        mindsets_hash = "";
        skills_indexed = total_skills;
        skills_selected_last = [];
        capabilities_hash = "";
        two_pass = config.shell.two_pass;
        apply_mode = config.shell.apply_mode;
        exec_enabled = config.shell.exec_enabled;
      };
      body = Some {
        fsm_state = "idle";
        lock_held = false;
        current_cycle = None;
        queue_depth = Cn_agent.queue_depth hub_path;
      };
      sensors_telegram;
    };

    (* Write coherence.json *)
    Cn_trace_state.write_coherence hub_path {
      boot_id = session.boot_id;
      status = "coherent";
      config = Ok_;
      lockfile = (if lock_ok then Ok_ else Missing);
      doctrine = Ok_;
      mindsets = Ok_;
      packages = Ok_;
      capabilities = Ok_;
      transport = (match mode with "daemon" -> Ok_ | _ -> Missing);
      updated_at = Cn_fmt.now_iso ();
    };

    (* Write initial runtime.json — idle state *)
    Cn_trace_state.write_runtime hub_path {
      boot_id = session.boot_id;
      current_cycle_id = None;
      current_pass = None;
      active_trigger = None;
      queue_depth = Cn_agent.queue_depth hub_path;
      lock_held = false;
      lock_boot_id = None;
      pending_projection = None;
      updated_at = Cn_fmt.now_iso ();
    };

    Ok { session; summary; lock_ok; pkg_names; total_skills }
  end

(** Update runtime.json projection for common state transitions. *)
let update_runtime_projection hub_path ~cycle_id ~pass ~trigger ~lock_held
    ~pending_projection =
  match Cn_trace.get_global () with
  | Some session ->
      Cn_trace_state.write_runtime hub_path {
        boot_id = session.boot_id;
        current_cycle_id = cycle_id;
        current_pass = pass;
        active_trigger = trigger;
        queue_depth = Cn_agent.queue_depth hub_path;
        lock_held;
        lock_boot_id = (if lock_held then Some session.boot_id else None);
        pending_projection;
        updated_at = Cn_fmt.now_iso ();
      }
  | None -> ()

(** Update ready.json body section for FSM state changes.
    Uses read-modify-write to preserve mind and sensors_telegram fields. *)
let update_ready_body hub_path ~fsm_state ~lock_held ~current_cycle =
  match Cn_trace.get_global () with
  | Some session ->
      Cn_trace_state.update_ready_body hub_path
        ~boot_id:session.boot_id
        ~updated_at:(Cn_fmt.now_iso ())
        { fsm_state; lock_held; current_cycle;
          queue_depth = Cn_agent.queue_depth hub_path }
  | None -> ()

(* === Finalize: archive → execute → project → conversation → cleanup === *)

(** Run the post-LLM pipeline on an existing input.md + output.md pair.
    inbound_message is the original user message (not the full packed context). *)
let finalize ~(config : Cn_config.config) ~hub_path ~name
      ~trigger_id ~from ~inbound_message ~output_content =
  Cn_trace.gemit ~component:"runtime" ~layer:Body
    ~event:"finalize.start" ~severity:Info ~status:Ok_
    ~trigger_id
    ~refs:{ input = Some (Printf.sprintf "logs/input/%s.md" trigger_id);
            output = Some (Printf.sprintf "logs/output/%s.md" trigger_id);
            receipts = None } ();

  (* 1. Archive raw BEFORE effects *)
  archive_raw hub_path ~trigger_id;

  (* 2. Parse output *)
  let output_meta = parse_frontmatter output_content in
  let ops = extract_ops output_meta in
  let body = extract_body output_content in
  let ops = List.map (resolve_payload body) ops in

  (* 3. Execute operations (skipped on recovery if already done) *)
  if ops_already_done hub_path trigger_id then begin
    Cn_trace.gemit ~component:"runtime" ~layer:Body
      ~event:"effects.execute.skip" ~severity:Info ~status:Skipped
      ~trigger_id ~reason_code:"ops_already_done" ()
  end else begin
    Cn_trace.gemit ~component:"runtime" ~layer:Body
      ~event:"effects.execute.start" ~severity:Info ~status:Ok_
      ~trigger_id
      ~details:["op_count", Cn_json.Int (List.length ops)] ();
    List.iter (fun op ->
      Cn_agent.execute_op hub_path name trigger_id op
    ) ops;
    mark_ops_done hub_path trigger_id;
    Cn_trace.gemit ~component:"runtime" ~layer:Body
      ~event:"effects.execute.complete" ~severity:Info ~status:Ok_
      ~trigger_id ()
  end;

  (* 4. Project to Telegram if from Telegram.
        Uses Cn_projection.project_reply for crash-recovery idempotency:
        marker state/projected/telegram/{trigger_id}.sent is created
        atomically (O_CREAT|O_EXCL) before sending. On recovery replay,
        the marker prevents duplicate messages.

        On send failure: marker is REMOVED and finalize returns Error,
        which blocks offset advancement. The daemon will not advance
        state/telegram.offset, so Telegram re-delivers the update and
        the runtime retries projection on the next cycle. *)
  let projection_result =
    if from <> "telegram" then Ok ()
    else match config.telegram_token with
    | None ->
        Cn_trace.gemit ~component:"projection" ~layer:Sensor
          ~event:"projection.skipped" ~severity:Info ~status:Skipped
          ~trigger_id ~reason_code:"no_token" ();
        Ok ()
    | Some token ->
        let inp = Cn_agent.input_path hub_path in
        let input_meta =
          if Cn_ffi.Fs.exists inp then parse_frontmatter (Cn_ffi.Fs.read inp)
          else []
        in
        let chat_id_str = input_meta |> List.find_map (fun (k, v) ->
          if k = "chat_id" then Some v else None) |> Option.value ~default:"" in
        match int_of_string_opt chat_id_str with
        | None ->
            Cn_trace.gemit ~component:"projection" ~layer:Sensor
              ~event:"projection.skipped" ~severity:Info ~status:Skipped
              ~trigger_id ~reason_code:"no_chat_id" ();
            Ok ()
        | Some chat_id ->
            Cn_trace.gemit ~component:"projection" ~layer:Sensor
              ~event:"projection.start" ~severity:Info ~status:Ok_
              ~trigger_id
              ~details:["chat_id", Cn_json.Int chat_id] ();
            match Cn_projection.project_reply ~hub_path
                    ~projection:"telegram" ~trigger_id with
            | `Already_projected ->
                Cn_trace.gemit ~component:"projection" ~layer:Sensor
                  ~event:"projection.marker.exists" ~severity:Info ~status:Skipped
                  ~trigger_id ~reason_code:"already_projected" ();
                Ok ()
            | `Send ->
                Cn_trace.gemit ~component:"projection" ~layer:Sensor
                  ~event:"projection.marker.created" ~severity:Info ~status:Ok_
                  ~trigger_id ();
                let payload = telegram_payload ops body in
                match Cn_telegram.send_message ~token ~chat_id ~text:payload with
                | Ok () ->
                    Cn_trace.gemit ~component:"projection" ~layer:Sensor
                      ~event:"projection.ok" ~severity:Info ~status:Ok_
                      ~trigger_id
                      ~details:["chat_id", Cn_json.Int chat_id] ();
                    Ok ()
                | Error msg ->
                    Cn_projection.unmark ~hub_path
                      ~projection:"telegram" ~trigger_id;
                    Cn_trace.gemit ~component:"projection" ~layer:Sensor
                      ~event:"projection.error" ~severity:Error_ ~status:Error_status
                      ~trigger_id ~reason_code:"send_failed"
                      ~reason:"Telegram send failed"
                      ~details:["chat_id", Cn_json.Int chat_id] ();
                    Cn_trace.gemit ~component:"projection" ~layer:Sensor
                      ~event:"projection.marker.removed" ~severity:Info ~status:Ok_
                      ~trigger_id ();
                    print_endline (Cn_fmt.warn
                      (Printf.sprintf "Telegram reply failed (retryable): %s"
                         msg));
                    Error (Printf.sprintf "Telegram projection failed: %s" msg)
  in
  match projection_result with
  | Error msg -> Error msg
  | Ok () ->

  (* 5. Append to conversation history *)
  let assistant_text = telegram_payload ops body in
  append_conversation hub_path ~trigger_id
    ~user_msg:inbound_message ~assistant_msg:assistant_text;

  (* 6. Cleanup state files FIRST, then clear ops_done marker.
        Order matters for crash safety:
        - cleanup_state removes input.md + output.md (State 1 trigger)
        - clear_ops_done removes the checkpoint
        If crash between cleanup and clear: no state files remain,
        so State 1 recovery cannot fire — stale ops_done is harmless.
        If clear happened first: crash before cleanup would leave
        state files without ops_done, causing duplicate op execution. *)
  cleanup_state hub_path;
  clear_ops_done hub_path trigger_id;

  Cn_trace.gemit ~component:"runtime" ~layer:Body
    ~event:"finalize.complete" ~severity:Info ~status:Ok_
    ~trigger_id
    ~details:["op_count", Cn_json.Int (List.length ops)]
    ~refs:{ input = Some (Printf.sprintf "logs/input/%s.md" trigger_id);
            output = Some (Printf.sprintf "logs/output/%s.md" trigger_id);
            receipts = Some (Printf.sprintf "state/receipts/%s.json" trigger_id) }
    ();

  (* Update projections: cycle complete, back to idle *)
  update_runtime_projection hub_path
    ~cycle_id:None ~pass:None ~trigger:None
    ~lock_held:true ~pending_projection:None;
  update_ready_body hub_path ~fsm_state:"idle"
    ~lock_held:true ~current_cycle:None;

  print_endline (Cn_fmt.ok
    (Printf.sprintf "Processed: %s (%d ops)" trigger_id (List.length ops)));
  Ok ()

(* === Pipeline === *)

(** Process one cycle. Handles inbox queueing, update checks, and three
    recovery states, all under lock.
    Returns Ok () on success or when idle. Error on LLM/processing failure. *)
let process_one ~(config : Cn_config.config) ~hub_path ~name =
  match acquire_lock hub_path with
  | Error msg ->
      print_endline (Cn_fmt.info msg);
      Ok () (* Not an error — normal for cron overlap *)
  | Ok lock_fd ->
    let finally () =
      release_lock hub_path lock_fd;
      (* Update projections on lock release *)
      update_runtime_projection hub_path
        ~cycle_id:None ~pass:None ~trigger:None
        ~lock_held:false ~pending_projection:None;
      update_ready_body hub_path ~fsm_state:"idle"
        ~lock_held:false ~current_cycle:None
    in
    (* Update projections on lock acquire *)
    update_runtime_projection hub_path
      ~cycle_id:None ~pass:None ~trigger:None
      ~lock_held:true ~pending_projection:None;
    match
      let inp = Cn_agent.input_path hub_path in
      let outp = Cn_agent.output_path hub_path in

      (* === State 1: output.md exists → finalize existing cycle === *)
      if Cn_ffi.Fs.exists outp && Cn_ffi.Fs.exists inp then begin
        let input_content = Cn_ffi.Fs.read inp in
        let output_content = Cn_ffi.Fs.read outp in
        let meta = parse_frontmatter input_content in
        let get k = meta |> List.find_map (fun (key, v) ->
          if key = k then Some v else None) |> Option.value ~default:"unknown" in
        let trigger_id = get "id" in
        let from = get "from" in
        let packed_body = match extract_body input_content with
          | Some b -> b | None -> "" in
        let inbound_message = extract_inbound_message packed_body in
        (* Update projections: recovering *)
        update_runtime_projection hub_path
          ~cycle_id:(Some trigger_id) ~pass:None
          ~trigger:(Some trigger_id) ~lock_held:true
          ~pending_projection:None;
        Cn_trace.gemit ~component:"runtime" ~layer:Body
          ~event:"cycle.recover" ~severity:Info ~status:Ok_
          ~trigger_id ~reason_code:"recovery_output_present"
          ~reason:"output.md exists, resuming finalize" ();
        finalize ~config ~hub_path ~name
          ~trigger_id ~from ~inbound_message ~output_content

      (* === State 2: input.md exists, no output → resume LLM call === *)
      end else if Cn_ffi.Fs.exists inp then begin
        let input_content = Cn_ffi.Fs.read inp in
        let meta = parse_frontmatter input_content in
        let get k = meta |> List.find_map (fun (key, v) ->
          if key = k then Some v else None) |> Option.value ~default:"unknown" in
        let trigger_id = get "id" in
        let from = get "from" in
        let packed_body = match extract_body input_content with
          | Some b -> b | None -> "" in
        let inbound_message = extract_inbound_message packed_body in

        (* Update projections: recovering with LLM call pending *)
        update_runtime_projection hub_path
          ~cycle_id:(Some trigger_id) ~pass:None
          ~trigger:(Some trigger_id) ~lock_held:true
          ~pending_projection:None;
        Cn_trace.gemit ~component:"runtime" ~layer:Body
          ~event:"cycle.recover" ~severity:Info ~status:Ok_
          ~trigger_id ~reason_code:"recovery_input_present"
          ~reason:"input.md exists without output, resuming LLM call" ();

        (* Re-pack to get structured system/messages for the API call.
           The audit text in input.md is for humans; the LLM needs the
           structured format with system prompt + message turns. *)
        let packed = Cn_context.pack ~hub_path ~trigger_id
          ~message:inbound_message ~from ~shell_config:config.shell () in

        Cn_trace.gemit ~component:"runtime" ~layer:Mind
          ~event:"llm.call.start" ~severity:Info ~status:Ok_
          ~trigger_id
          ~details:["model", Cn_json.String config.model] ();

        match Cn_llm.call ~api_key:config.anthropic_key
                ~model:config.model ~max_tokens:config.max_tokens
                ~system:packed.system ~messages:packed.messages with
        | Error msg ->
            Cn_trace.gemit ~component:"runtime" ~layer:Mind
              ~event:"llm.call.error" ~severity:Error_ ~status:Error_status
              ~trigger_id ~reason_code:"llm_error" ();
            Error (Printf.sprintf "LLM call failed: %s" msg)
        | Ok response ->
            Cn_ffi.Fs.write outp response.content;
            Cn_trace.gemit ~component:"runtime" ~layer:Mind
              ~event:"llm.call.ok" ~severity:Info ~status:Ok_
              ~trigger_id
              ~details:[
                "input_tokens", Cn_json.Int response.input_tokens;
                "output_tokens", Cn_json.Int response.output_tokens;
                "stop_reason", Cn_json.String response.stop_reason;
              ] ();
            finalize ~config ~hub_path ~name
              ~trigger_id ~from ~inbound_message
              ~output_content:response.content

      (* === State 3: neither exists → queue inbox + dequeue + pipeline === *)
      end else begin
        (* GC: sweep stale ops_done markers left by crashes after
           cleanup_state but before clear_ops_done. Safe here because
           no input.md/output.md exist — no recovery can fire. *)
        let finalized_dir = Cn_ffi.Path.join hub_path "state/finalized" in
        (if Cn_ffi.Fs.exists finalized_dir then
           Cn_ffi.Fs.readdir finalized_dir
           |> List.iter (fun f ->
                let path = Cn_ffi.Path.join finalized_dir f in
                (try Sys.remove path with Sys_error _ -> ());
                Cn_hub.log_action hub_path "process.gc_ops_done"
                  (Printf.sprintf "removed stale marker: %s" f)));

        (* Queue inbox items under lock to prevent overlap races *)
        let queued = Cn_agent.queue_inbox_items hub_path in
        if queued > 0 then
          print_endline (Cn_fmt.ok
            (Printf.sprintf "Queued %d inbox item(s)" queued));

        match Cn_agent.queue_pop hub_path with
        | None ->
            Cn_trace.gemit ~component:"runtime" ~layer:Body
              ~event:"cycle.idle" ~severity:Debug ~status:Ok_
              ~reason_code:"queue_empty" ();
            print_endline (Cn_fmt.ok "Queue empty");
            Ok ()
        | Some raw_content ->
            let meta = parse_frontmatter raw_content in
            let get k = meta |> List.find_map (fun (key, v) ->
              if key = k then Some v else None) |> Option.value ~default:"unknown" in
            let trigger_id = get "id" in
            let from = get "from" in
            let chat_id_opt = meta |> List.find_map (fun (k, v) ->
              if k = "chat_id" then int_of_string_opt v else None) in
            let inbound_message = match extract_body raw_content with
              | Some b -> b | None -> "" in

            Cn_trace.gemit ~component:"runtime" ~layer:Body
              ~event:"cycle.start" ~severity:Info ~status:Ok_
              ~cycle_id:trigger_id ~trigger_id
              ~reason_code:"fresh_dequeue"
              ~details:["from", Cn_json.String from] ();

            Cn_trace.gemit ~component:"runtime" ~layer:Body
              ~event:"queue.dequeue" ~severity:Info ~status:Ok_
              ~trigger_id ();

            (* Update projections: cycle in progress *)
            update_runtime_projection hub_path
              ~cycle_id:(Some trigger_id) ~pass:(Some "A")
              ~trigger:(Some trigger_id) ~lock_held:true
              ~pending_projection:None;
            update_ready_body hub_path ~fsm_state:"processing"
              ~lock_held:true ~current_cycle:(Some trigger_id);

            (* Pack context into structured system blocks + message turns *)
            Cn_trace.gemit ~component:"runtime" ~layer:Mind
              ~event:"pack.start" ~severity:Info ~status:Ok_
              ~trigger_id ();
            let packed = Cn_context.pack ~hub_path ~trigger_id
              ~message:inbound_message ~from ~shell_config:config.shell () in
            Cn_trace.gemit ~component:"runtime" ~layer:Mind
              ~event:"pack.complete" ~severity:Info ~status:Ok_
              ~trigger_id ();

            (* Write input.md = frontmatter + audit text (human-readable) *)
            let input_doc = build_input_md ~trigger_id ~from ~chat_id_opt
              ~audit_text:packed.audit_text in
            Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
            Cn_ffi.Fs.write inp input_doc;

            (* Call LLM with structured system prompt + message turns *)
            Cn_trace.gemit ~component:"runtime" ~layer:Mind
              ~event:"llm.call.start" ~severity:Info ~status:Ok_
              ~trigger_id
              ~details:["model", Cn_json.String config.model] ();

            match Cn_llm.call ~api_key:config.anthropic_key
                    ~model:config.model ~max_tokens:config.max_tokens
                    ~system:packed.system ~messages:packed.messages with
            | Error msg ->
                Cn_trace.gemit ~component:"runtime" ~layer:Mind
                  ~event:"llm.call.error" ~severity:Error_ ~status:Error_status
                  ~trigger_id ~reason_code:"llm_error" ();
                Error (Printf.sprintf "LLM call failed: %s" msg)
            | Ok response ->
                Cn_ffi.Fs.write outp response.content;
                Cn_trace.gemit ~component:"runtime" ~layer:Mind
                  ~event:"llm.call.ok" ~severity:Info ~status:Ok_
                  ~trigger_id
                  ~details:[
                    "input_tokens", Cn_json.Int response.input_tokens;
                    "output_tokens", Cn_json.Int response.output_tokens;
                    "stop_reason", Cn_json.String response.stop_reason;
                  ] ();
                finalize ~config ~hub_path ~name
                  ~trigger_id ~from ~inbound_message
                  ~output_content:response.content
      end
    with
    | result -> finally (); result
    | exception exn -> finally (); raise exn

(** Cron/daemon entry point. Runs update check when idle, then calls
    process_one which handles all state mutation under lock. *)
let run_cron ~(config : Cn_config.config) ~hub_path ~name =
  (* Full boot sequence with projections (shared across all modes) *)
  (match Cn_trace.get_global () with
   | Some _ -> () (* Already booted — e.g. resumed from daemon *)
   | None ->
       match boot_sequence ~config ~hub_path ~mode:"cron" with
       | Error msg ->
           print_endline (Cn_fmt.fail msg);
           Cn_ffi.Process.exit 1
       | Ok _ -> ());

  (* Auto-update check (only when truly idle — no state files, no lock) *)
  let inp = Cn_agent.input_path hub_path in
  let outp = Cn_agent.output_path hub_path in
  if not (Cn_ffi.Fs.exists inp) && not (Cn_ffi.Fs.exists outp)
     && not (Cn_ffi.Fs.exists (lock_path hub_path)) then begin
    let update_info = Cn_agent.check_for_update hub_path in
    match update_info with
    | Cn_agent.Update_skip -> ()
    | Cn_agent.Update_git ver | Cn_agent.Update_binary ver ->
        print_endline (Cn_fmt.info
          (Printf.sprintf "Update available: %s -> %s" Cn_lib.version ver));
        Cn_hub.log_action hub_path "actor.update"
          (Printf.sprintf "checking:%s" ver);
        let result = Cn_agent.do_update update_info in
        match result with
        | Cn_protocol.Update_complete ->
            Cn_hub.log_action hub_path "actor.update"
              (Printf.sprintf "complete:%s" ver);
            print_endline (Cn_fmt.ok
              (Printf.sprintf "Updated to %s, re-executing..." ver));
            Cn_agent.re_exec ()
        | Cn_protocol.Update_fail ->
            Cn_hub.log_action hub_path "actor.update" "failed";
            print_endline (Cn_fmt.warn
              "Update failed, continuing with current version")
        | _ -> ()
  end;

  (* process_one handles inbox queueing + all recovery states under lock *)
  ignore (process_one ~config ~hub_path ~name)

(* === Telegram daemon === *)

(** Offset persistence: read state/telegram.offset (returns 0 if missing). *)
let read_offset hub_path =
  let path = Cn_ffi.Path.join hub_path "state/telegram.offset" in
  if Cn_ffi.Fs.exists path then
    match String.trim (Cn_ffi.Fs.read path) |> int_of_string_opt with
    | Some n -> n
    | None ->
        Cn_hub.log_action hub_path "daemon.offset_corrupt" "resetting to 0";
        0
  else 0

(** Write offset to state/telegram.offset. *)
let write_offset hub_path n =
  Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
  Cn_ffi.Fs.write
    (Cn_ffi.Path.join hub_path "state/telegram.offset")
    (Printf.sprintf "%d\n" n)

(** Check allowed_users list. [] = deny all (documented security default). *)
let is_allowed_user (config : Cn_config.config) user_id =
  match config.allowed_users with
  | [] -> false
  | ids -> List.mem user_id ids

(** Check whether a trigger ID is already in-flight (in state/input.md or
    state/output.md). Prevents duplicate enqueue when daemon re-polls
    while processor is recovering. *)
let is_in_flight hub_path trigger_id =
  let check path =
    if Cn_ffi.Fs.exists path then
      let content = Cn_ffi.Fs.read path in
      let meta = parse_frontmatter content in
      meta |> List.exists (fun (k, v) -> k = "id" && v = trigger_id)
    else false
  in
  check (Cn_agent.input_path hub_path)
  || check (Cn_agent.output_path hub_path)

(** Check whether a trigger ID is still queued in state/queue/. *)
let is_queued hub_path trigger_id =
  let dir = Cn_ffi.Path.join hub_path "state/queue" in
  if Cn_ffi.Fs.exists dir then
    Cn_ffi.Fs.readdir dir
    |> List.exists (fun f ->
         ends_with ~suffix:(Printf.sprintf "-telegram-%s.md" trigger_id) f)
  else false

(** Enqueue a Telegram message to state/queue/ with chat_id in frontmatter.
    Idempotent: skips if already queued or already in-flight. *)
let enqueue_telegram hub_path (msg : Cn_telegram.message) =
  let dir = Cn_ffi.Path.join hub_path "state/queue" in
  Cn_ffi.Fs.ensure_dir dir;
  let trigger_id = Printf.sprintf "tg-%d" msg.update_id in
  if not (is_queued hub_path trigger_id)
     && not (is_in_flight hub_path trigger_id) then begin
    let ts = Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ()) in
    let file_name = Printf.sprintf "%s-telegram-%s.md" ts trigger_id in
    let file_path = Cn_ffi.Path.join dir file_name in
    let content = Printf.sprintf
      "---\nid: %s\nfrom: telegram\nchat_id: %d\ndate: %d\nqueued: %s\n---\n\n%s"
      trigger_id msg.chat_id msg.date (Cn_fmt.now_iso ()) msg.text in
    Cn_ffi.Fs.write file_path content;
    Cn_hub.log_action hub_path "daemon.enqueue"
      (Printf.sprintf "id:%s chat_id:%d" trigger_id msg.chat_id)
  end

(** Telegram long-poll daemon. Polls for updates, enqueues accepted
    messages, processes one per update, persists offset after success.
    Loops forever. Per v3.1.3:
    - allowed_users = [] → deny all
    - Offset persisted to state/telegram.offset
    - Offset advanced only after successful processing (ack boundary)
    - Rejected users advance offset immediately (handled by dropping)
    - Messages processed in ascending update_id order; stops at first failure *)
let run_daemon ~(config : Cn_config.config) ~hub_path ~name =
  match config.telegram_token with
  | None ->
      print_endline (Cn_fmt.fail "Daemon mode requires TELEGRAM_TOKEN");
      Cn_ffi.Process.exit 1
  | Some token ->
      (* Shared boot sequence — writes ready.json, coherence.json, runtime.json *)
      let boot = match boot_sequence ~config ~hub_path ~mode:"daemon" with
        | Error msg ->
            print_endline (Cn_fmt.fail msg);
            Cn_ffi.Process.exit 1
        | Ok b -> b
      in

      (* Daemon-specific: Telegram transport readiness *)
      let offset = ref (read_offset hub_path) in
      Cn_trace.emit_simple boot.session ~component:"telegram" ~layer:Sensor
        ~event:"telegram.offset.loaded" ~severity:Info ~status:Ok_
        ~details:["offset", Cn_json.Int !offset] ();

      (* Update ready.json with actual telegram offset *)
      Cn_trace_state.write_ready hub_path {
        status = Ready; boot_id = boot.session.boot_id;
        updated_at = Cn_fmt.now_iso ();
        blocked_reason = None;
        mind = Some {
          profile = Option.value ~default:"engineer" boot.summary.profile;
          packages = boot.pkg_names;
          doctrine_required = List.length Cn_assets.required_doctrine;
          doctrine_loaded = boot.summary.doctrine_count;
          doctrine_hash = "";
          mindsets_required = List.length Cn_assets.required_mindsets;
          mindsets_loaded = boot.summary.mindset_count;
          mindsets_hash = "";
          skills_indexed = boot.total_skills;
          skills_selected_last = [];
          capabilities_hash = "";
          two_pass = config.shell.two_pass;
          apply_mode = config.shell.apply_mode;
          exec_enabled = config.shell.exec_enabled;
        };
        body = Some {
          fsm_state = "idle";
          lock_held = false;
          current_cycle = None;
          queue_depth = Cn_agent.queue_depth hub_path;
        };
        sensors_telegram = Some {
          enabled = true;
          offset = !offset;
          last_poll_status = "starting";
          last_poll_at = Cn_fmt.now_iso ();
        };
      };

      (* Daemon poll start *)
      Cn_trace.emit_simple boot.session ~component:"telegram" ~layer:Sensor
        ~event:"daemon.poll.start" ~severity:Info ~status:Ok_ ();

      print_endline (Cn_fmt.ok (Printf.sprintf
        "Telegram daemon started (poll=%ds timeout=%ds)"
        config.poll_interval config.poll_timeout));
      while true do
        (match Cn_telegram.get_updates ~token ~offset:!offset
                ~timeout:config.poll_timeout with
        | Error msg ->
            Cn_trace.gemit ~component:"telegram" ~layer:Sensor
              ~event:"daemon.poll.error" ~severity:Warn ~status:Error_status
              ~reason_code:"poll_error" ();
            print_endline (Cn_fmt.warn (Printf.sprintf "Poll error: %s" msg))
        | Ok messages ->
            (* Sort ascending by update_id for monotonic offset advancement *)
            let sorted = List.sort
              (fun (a : Cn_telegram.message) (b : Cn_telegram.message) ->
                compare a.update_id b.update_id)
              messages in
            (* Process sequentially; stop at first failure *)
            let rec drain = function
              | [] -> ()
              | (msg : Cn_telegram.message) :: rest ->
                  if not (is_allowed_user config msg.user_id) then begin
                    Cn_trace.gemit ~component:"telegram" ~layer:Sensor
                      ~event:"daemon.offset.advanced" ~severity:Info ~status:Ok_
                      ~reason_code:"rejected_user"
                      ~details:["update_id", Cn_json.Int msg.update_id] ();
                    offset := max !offset (msg.update_id + 1);
                    write_offset hub_path !offset;
                    drain rest
                  end else begin
                    let trigger_id = Printf.sprintf "tg-%d" msg.update_id in
                    (* Visual feedback: react to inbound + show typing *)
                    Cn_telegram.set_reaction ~token
                      ~chat_id:msg.chat_id ~message_id:msg.message_id
                      ~emoji:"\xF0\x9F\xA4\x94"; (* 🤔 *)
                    Cn_telegram.send_typing ~token ~chat_id:msg.chat_id;
                    enqueue_telegram hub_path msg;
                    match process_one ~config ~hub_path ~name with
                    | Ok () ->
                        (* Only ack if no longer queued or in-flight.
                           Handles the case where process_one returned Ok ()
                           because the lock was busy (overlap) or it processed
                           a different queued item. *)
                        if not (is_queued hub_path trigger_id)
                           && not (is_in_flight hub_path trigger_id) then begin
                          Cn_telegram.clear_reaction ~token
                            ~chat_id:msg.chat_id ~message_id:msg.message_id;
                          Cn_trace.gemit ~component:"telegram" ~layer:Sensor
                            ~event:"daemon.offset.advanced" ~severity:Info ~status:Ok_
                            ~trigger_id
                            ~details:["offset", Cn_json.Int (msg.update_id + 1)] ();
                          offset := max !offset (msg.update_id + 1);
                          write_offset hub_path !offset;
                          drain rest
                        end else begin
                          Cn_trace.gemit ~component:"telegram" ~layer:Sensor
                            ~event:"daemon.offset.blocked" ~severity:Info ~status:Blocked
                            ~trigger_id
                            ~reason_code:(if is_queued hub_path trigger_id
                                          then "still_queued" else "still_in_flight") ();
                          Cn_trace.gemit ~component:"telegram" ~layer:Sensor
                            ~event:"daemon.pending" ~severity:Info ~status:Ok_
                            ~trigger_id ()
                        end
                    | Error err ->
                        Cn_trace.gemit ~component:"telegram" ~layer:Sensor
                          ~event:"daemon.offset.blocked" ~severity:Warn ~status:Error_status
                          ~trigger_id
                          ~reason_code:"processing_failed" ();
                        print_endline (Cn_fmt.warn (Printf.sprintf
                          "Processing failed for tg-%d: %s (will retry)"
                          msg.update_id err))
                  end
            in
            drain sorted);
        (* Always sleep poll_interval between cycles *)
        Unix.sleepf (float_of_int config.poll_interval)
      done

(* === Interactive stdio mode === *)

(** Interactive mode: read from stdin, enqueue, process, print response.
    Each line is a separate message. Ctrl-D to exit. *)
let run_stdio ~(config : Cn_config.config) ~hub_path ~name =
  (* Full boot sequence with projections (shared across all modes) *)
  (match Cn_trace.get_global () with
   | Some _ -> ()
   | None ->
       match boot_sequence ~config ~hub_path ~mode:"stdio" with
       | Error msg ->
           print_endline (Cn_fmt.fail msg);
           Cn_ffi.Process.exit 1
       | Ok _ -> ());

  print_endline (Cn_fmt.info "Interactive mode (stdin -> LLM -> stdout)");
  print_endline (Cn_fmt.dim "Type a message and press Enter. Ctrl-D to exit.");
  let conv_path = conversation_path hub_path in
  try while true do
    print_string "> ";
    flush stdout;
    let line = input_line stdin in
    if String.trim line <> "" then begin
      let trigger_id = Printf.sprintf "stdio-%s"
        (Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ())) in
      ignore (Cn_agent.queue_add hub_path trigger_id "stdio" line);
      match process_one ~config ~hub_path ~name with
      | Ok () ->
          (* Print the last assistant message from conversation *)
          if Cn_ffi.Fs.exists conv_path then
            (match Cn_ffi.Fs.read conv_path |> Cn_json.parse with
             | Ok (Cn_json.Array items) ->
                 (match List.rev items with
                  | last :: _ ->
                      (match Cn_json.get_string "content" last with
                       | Some text -> print_endline text
                       | None -> ())
                  | [] -> ())
             | _ -> ())
      | Error msg ->
          print_endline (Cn_fmt.fail msg)
    end
  done with End_of_file ->
    print_endline ""
