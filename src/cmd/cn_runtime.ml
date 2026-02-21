(** cn_runtime.ml — Agent runtime orchestrator

    Owns the full processing pipeline: dequeue → pack → call LLM →
    write output → archive → parse → execute → project → conversation.

    Replaces the previous run_inbound + feed_next_input + wake_agent
    split. Single entry points: process_one and run_cron.

    Uses atomic file locking (O_CREAT|O_EXCL) to prevent cron overlap
    and daemon race conditions on state/input.md and state/output.md. *)

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
         Cn_hub.log_action hub_path "lock.stale"
           (Printf.sprintf "age=%.0fs, removing" age);
         Cn_ffi.Fs.unlink path
       end
     with _ -> ());
  try
    let fd = Unix.openfile path [Unix.O_CREAT; Unix.O_EXCL; Unix.O_WRONLY] 0o644 in
    Ok fd
  with Unix.Unix_error (Unix.EEXIST, _, _) ->
    Error "agent already running (state/agent.lock exists)"

let release_lock hub_path fd =
  (try Unix.close fd with _ -> ());
  (try Cn_ffi.Fs.unlink (lock_path hub_path) with _ -> ())

(* === Conversation persistence === *)

let conversation_path hub_path =
  Cn_ffi.Path.join hub_path "state/conversation.json"

(** Append a user+assistant exchange to state/conversation.json.
    Creates the file if missing. Keeps last 50 entries to bound growth. *)
let append_conversation hub_path ~user_msg ~assistant_msg =
  let path = conversation_path hub_path in
  let existing =
    if Cn_ffi.Fs.exists path then
      match Cn_ffi.Fs.read path |> Cn_json.parse with
      | Ok (Cn_json.Array items) -> items
      | _ -> []
    else []
  in
  let new_entries = existing @ [
    Cn_json.Object ["role", Cn_json.String "user"; "content", Cn_json.String user_msg];
    Cn_json.Object ["role", Cn_json.String "assistant"; "content", Cn_json.String assistant_msg];
  ] in
  (* Keep last 50 entries *)
  let len = List.length new_entries in
  let trimmed = if len > 50 then
    List.filteri (fun i _ -> i >= len - 50) new_entries
  else new_entries in
  Cn_ffi.Fs.write path (Cn_json.to_string (Cn_json.Array trimmed) ^ "\n")

(* === Pipeline === *)

(** Process one queued item through the full pipeline.
    Returns Ok () on success, Error msg on failure or empty queue. *)
let process_one ~(config : Cn_config.config) ~hub_path ~name =
  match acquire_lock hub_path with
  | Error msg ->
      print_endline (Cn_fmt.info msg);
      Ok () (* Not an error — normal for cron overlap *)
  | Ok lock_fd ->
    let finally () = release_lock hub_path lock_fd in
    match
      (* 1. Dequeue *)
      match Cn_agent.queue_pop hub_path with
      | None ->
          print_endline (Cn_fmt.ok "Queue empty");
          Ok ()
      | Some raw_content ->
          let meta = parse_frontmatter raw_content in
          let get k = meta |> List.find_map (fun (key, v) ->
            if key = k then Some v else None) |> Option.value ~default:"unknown" in
          let trigger_id = get "id" in
          let from = get "from" in
          let message = match extract_body raw_content with
            | Some b -> b | None -> "" in

          Cn_hub.log_action hub_path "process.start"
            (Printf.sprintf "id:%s from:%s" trigger_id from);

          (* 2. Pack context *)
          let packed = Cn_context.pack ~hub_path ~trigger_id ~message ~from in
          let inp = Cn_agent.input_path hub_path in
          Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
          Cn_ffi.Fs.write inp raw_content;

          (* 3. Call LLM *)
          (match Cn_llm.call ~api_key:config.anthropic_key
                   ~model:config.model ~max_tokens:config.max_tokens
                   ~content:packed.content with
           | Error msg ->
               Cn_hub.log_action hub_path "process.llm_error"
                 (Printf.sprintf "id:%s error:%s" trigger_id msg);
               Error (Printf.sprintf "LLM call failed: %s" msg)
           | Ok response ->
               (* 4. Write output *)
               let outp = Cn_agent.output_path hub_path in
               Cn_ffi.Fs.write outp response.content;

               Cn_hub.log_action hub_path "process.llm_done"
                 (Printf.sprintf "id:%s in=%d out=%d stop=%s"
                    trigger_id response.input_tokens response.output_tokens
                    response.stop_reason);

               (* 5. Archive BEFORE effects *)
               let _archived = Cn_agent.archive_io_pair hub_path name in

               (* 6. Parse output *)
               let output_meta = parse_frontmatter response.content in
               let ops = extract_ops output_meta in
               let body = extract_body response.content in
               let ops = List.map (resolve_payload body) ops in

               (* 7. Execute operations *)
               List.iter (fun op ->
                 Cn_agent.execute_op hub_path name trigger_id op
               ) ops;

               (* 8. Project to Telegram if from Telegram *)
               (if from = "telegram" then
                  match config.telegram_token with
                  | Some token ->
                      (* Extract chat_id from frontmatter *)
                      let chat_id_str = get "chat_id" in
                      (match int_of_string_opt chat_id_str with
                       | Some chat_id ->
                           let payload = match body with
                             | Some b -> b | None -> response.content in
                           (match Cn_telegram.send_message ~token ~chat_id ~text:payload with
                            | Ok () ->
                                Cn_hub.log_action hub_path "process.telegram_reply"
                                  (Printf.sprintf "chat_id:%d" chat_id)
                            | Error msg ->
                                Cn_hub.log_action hub_path "process.telegram_error"
                                  (Printf.sprintf "chat_id:%d error:%s" chat_id msg);
                                print_endline (Cn_fmt.warn
                                  (Printf.sprintf "Telegram reply failed: %s" msg)))
                       | None ->
                           Cn_hub.log_action hub_path "process.telegram_skip"
                             "no chat_id in frontmatter")
                  | None ->
                      Cn_hub.log_action hub_path "process.telegram_skip" "no token");

               (* 9. Append to conversation history *)
               append_conversation hub_path
                 ~user_msg:message ~assistant_msg:response.content;

               print_endline (Cn_fmt.ok
                 (Printf.sprintf "Processed: %s (ops=%d, tokens=%d+%d)"
                    trigger_id (List.length ops)
                    response.input_tokens response.output_tokens));
               Ok ())
    with
    | result -> finally (); result
    | exception exn -> finally (); raise exn

(** Cron/daemon entry point. Queues inbox items, derives FSM state,
    handles archive/timeout, then processes one item. *)
let run_cron ~(config : Cn_config.config) ~hub_path ~name =
  (* Queue inbox items *)
  let queued = Cn_agent.queue_inbox_items hub_path in
  if queued > 0 then
    print_endline (Cn_fmt.ok (Printf.sprintf "Queued %d inbox item(s)" queued));

  (* Derive actor state from filesystem *)
  let inp = Cn_agent.input_path hub_path in
  let outp = Cn_agent.output_path hub_path in

  let input_age_min =
    if Cn_ffi.Fs.exists inp then
      try
        let stat = Unix.stat inp in
        (Unix.gettimeofday () -. stat.Unix.st_mtime) /. 60.0
      with _ -> 0.0
    else 0.0
  in
  let cron_period_min =
    match Cn_ffi.Process.getenv_opt "CN_CRON_PERIOD_MIN" with
    | Some s -> (match int_of_string_opt s with Some i -> float_of_int i | None -> 5.0)
    | None -> 5.0
  in
  let timeout_cycles =
    match Cn_ffi.Process.getenv_opt "CN_TIMEOUT_CYCLES" with
    | Some s -> (match int_of_string_opt s with Some i -> float_of_int i | None -> 3.0)
    | None -> 3.0
  in
  let max_age_min = cron_period_min *. timeout_cycles in

  let state = Cn_protocol.actor_derive_state_with_timeout
    ~input_exists:(Cn_ffi.Fs.exists inp)
    ~output_exists:(Cn_ffi.Fs.exists outp)
    ~input_age_min ~max_age_min
  in

  Cn_hub.log_action hub_path "cron.state"
    (Printf.sprintf "state=%s queue=%d"
       (Cn_protocol.string_of_actor_state state)
       (Cn_agent.queue_count hub_path));

  match state with
  | Cn_protocol.OutputReady ->
      (* Archive previous IO pair, then process next *)
      let _archived = Cn_agent.archive_io_pair hub_path name in
      Cn_agent.auto_save hub_path name;
      ignore (process_one ~config ~hub_path ~name)

  | Cn_protocol.TimedOut ->
      (* Archive timeout, then process next *)
      let _archived = Cn_agent.archive_timeout hub_path name in
      Cn_agent.auto_save hub_path name;
      ignore (process_one ~config ~hub_path ~name)

  | Cn_protocol.Idle ->
      (* Auto-update check with FSM transitions, then process *)
      let update_info = Cn_agent.check_for_update hub_path in
      (match update_info with
       | Cn_agent.Update_skip ->
           ignore (process_one ~config ~hub_path ~name)
       | Cn_agent.Update_git ver | Cn_agent.Update_binary ver ->
           print_endline (Cn_fmt.info
             (Printf.sprintf "Update available: %s -> %s" Cn_lib.version ver));
           Cn_hub.log_action hub_path "actor.update"
             (Printf.sprintf "checking:%s" ver);
           let result = Cn_agent.do_update update_info in
           (match result with
            | Cn_protocol.Update_complete ->
                Cn_hub.log_action hub_path "actor.update"
                  (Printf.sprintf "complete:%s" ver);
                print_endline (Cn_fmt.ok
                  (Printf.sprintf "Updated to %s, re-executing..." ver));
                Cn_agent.re_exec ()
            | Cn_protocol.Update_fail ->
                Cn_hub.log_action hub_path "actor.update" "failed";
                print_endline (Cn_fmt.warn
                  "Update failed, continuing with current version");
                ignore (process_one ~config ~hub_path ~name)
            | _ ->
                ignore (process_one ~config ~hub_path ~name)))

  | Cn_protocol.Processing ->
      print_endline (Cn_fmt.info
        (Printf.sprintf "Agent processing (age=%.0fm, timeout=%.0fm)"
           input_age_min max_age_min))

  | Cn_protocol.InputReady ->
      (* Input written but not processed — resume via process_one.
         Note: process_one will find queue empty, but that's fine —
         the existing input.md will be picked up by the next cron cycle
         after it moves to OutputReady state. *)
      print_endline (Cn_fmt.info "Input ready, awaiting processing")

  | Cn_protocol.Updating ->
      print_endline (Cn_fmt.info "Update in progress")
