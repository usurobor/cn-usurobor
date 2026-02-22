(** cn_runtime.ml — Agent runtime orchestrator

    Owns the full processing pipeline: dequeue → pack → call LLM →
    write output → archive → parse → execute → project → conversation.

    Replaces the previous run_inbound + feed_next_input + wake_agent
    split. Single entry points: process_one and run_cron.

    Uses atomic file locking (O_CREAT|O_EXCL) to prevent cron overlap
    and daemon race conditions on state/input.md and state/output.md.

    Prompt contract (Option B):
    - LLM is invoked with the body below frontmatter (packed context only).
    - state/input.md frontmatter is runtime metadata (id, from, chat_id, date).
    - logs/input/ archives the full file for audit (metadata + prompt).

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
      let reply_msg = ops |> List.find_map (fun op ->
        match op with Reply (_, msg) -> Some msg | _ -> None) in
      match reply_msg with
      | Some msg -> msg
      | None -> "(acknowledged)"

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

(** Build state/input.md with frontmatter + packed context.
    Frontmatter is runtime metadata; the body below is the LLM prompt. *)
let build_input_md ~trigger_id ~from ~chat_id_opt ~packed_content =
  let buf = Buffer.create (String.length packed_content + 128) in
  Buffer.add_string buf "---\n";
  Buffer.add_string buf (Printf.sprintf "id: %s\n" trigger_id);
  Buffer.add_string buf (Printf.sprintf "from: %s\n" from);
  (match chat_id_opt with
   | Some cid -> Buffer.add_string buf (Printf.sprintf "chat_id: %d\n" cid)
   | None -> ());
  Buffer.add_string buf (Printf.sprintf "date: %s\n" (Cn_fmt.now_iso ()));
  Buffer.add_string buf "---\n\n";
  Buffer.add_string buf packed_content;
  Buffer.contents buf

(* === Finalize: archive → execute → project → conversation → cleanup === *)

(** Run the post-LLM pipeline on an existing input.md + output.md pair.
    inbound_message is the original user message (not the full packed context). *)
let finalize ~(config : Cn_config.config) ~hub_path ~name
      ~trigger_id ~from ~inbound_message ~output_content =
  (* 1. Archive raw BEFORE effects *)
  archive_raw hub_path ~trigger_id;

  (* 2. Parse output *)
  let output_meta = parse_frontmatter output_content in
  let ops = extract_ops output_meta in
  let body = extract_body output_content in
  let ops = List.map (resolve_payload body) ops in

  (* 3. Execute operations *)
  List.iter (fun op ->
    Cn_agent.execute_op hub_path name trigger_id op
  ) ops;

  (* 4. Project to Telegram if from Telegram *)
  (if from = "telegram" then
     match config.telegram_token with
     | Some token ->
         let inp = Cn_agent.input_path hub_path in
         let input_meta =
           if Cn_ffi.Fs.exists inp then parse_frontmatter (Cn_ffi.Fs.read inp)
           else []
         in
         let chat_id_str = input_meta |> List.find_map (fun (k, v) ->
           if k = "chat_id" then Some v else None) |> Option.value ~default:"" in
         (match int_of_string_opt chat_id_str with
          | Some chat_id ->
              let payload = telegram_payload ops body in
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
                "no chat_id in input frontmatter")
     | None ->
         Cn_hub.log_action hub_path "process.telegram_skip" "no token");

  (* 5. Append to conversation history *)
  let assistant_text = telegram_payload ops body in
  append_conversation hub_path
    ~user_msg:inbound_message ~assistant_msg:assistant_text;

  (* 6. Cleanup state files *)
  cleanup_state hub_path;

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
    let finally () = release_lock hub_path lock_fd in
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
        (* On recovery, extract_body is the full packed context.
           Extract just the inbound message for conversation history. *)
        let packed_body = match extract_body input_content with
          | Some b -> b | None -> "" in
        let inbound_message = extract_inbound_message packed_body in
        Cn_hub.log_action hub_path "process.resume_finalize"
          (Printf.sprintf "id:%s" trigger_id);
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

        Cn_hub.log_action hub_path "process.resume_llm"
          (Printf.sprintf "id:%s from:%s" trigger_id from);

        (* Call LLM with the input.md body (= packed context, Option B) *)
        match Cn_llm.call ~api_key:config.anthropic_key
                ~model:config.model ~max_tokens:config.max_tokens
                ~content:packed_body with
        | Error msg ->
            Cn_hub.log_action hub_path "process.llm_error"
              (Printf.sprintf "id:%s error:%s" trigger_id msg);
            Error (Printf.sprintf "LLM call failed: %s" msg)
        | Ok response ->
            Cn_ffi.Fs.write outp response.content;
            Cn_hub.log_action hub_path "process.llm_done"
              (Printf.sprintf "id:%s in=%d out=%d stop=%s"
                 trigger_id response.input_tokens response.output_tokens
                 response.stop_reason);
            finalize ~config ~hub_path ~name
              ~trigger_id ~from ~inbound_message
              ~output_content:response.content

      (* === State 3: neither exists → queue inbox + dequeue + pipeline === *)
      end else begin
        (* Queue inbox items under lock to prevent overlap races *)
        let queued = Cn_agent.queue_inbox_items hub_path in
        if queued > 0 then
          print_endline (Cn_fmt.ok
            (Printf.sprintf "Queued %d inbox item(s)" queued));

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
            let chat_id_opt = meta |> List.find_map (fun (k, v) ->
              if k = "chat_id" then int_of_string_opt v else None) in
            let inbound_message = match extract_body raw_content with
              | Some b -> b | None -> "" in

            Cn_hub.log_action hub_path "process.start"
              (Printf.sprintf "id:%s from:%s" trigger_id from);

            (* Pack context *)
            let packed = Cn_context.pack ~hub_path ~trigger_id
              ~message:inbound_message ~from in

            (* Write input.md = frontmatter + packed content *)
            let input_doc = build_input_md ~trigger_id ~from ~chat_id_opt
              ~packed_content:packed.content in
            Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
            Cn_ffi.Fs.write inp input_doc;

            (* Call LLM with packed body (Option B: body-only prompt) *)
            match Cn_llm.call ~api_key:config.anthropic_key
                    ~model:config.model ~max_tokens:config.max_tokens
                    ~content:packed.content with
            | Error msg ->
                Cn_hub.log_action hub_path "process.llm_error"
                  (Printf.sprintf "id:%s error:%s" trigger_id msg);
                Error (Printf.sprintf "LLM call failed: %s" msg)
            | Ok response ->
                Cn_ffi.Fs.write outp response.content;
                Cn_hub.log_action hub_path "process.llm_done"
                  (Printf.sprintf "id:%s in=%d out=%d stop=%s"
                     trigger_id response.input_tokens response.output_tokens
                     response.stop_reason);
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
      print_endline (Cn_fmt.ok (Printf.sprintf
        "Telegram daemon started (poll=%ds timeout=%ds)"
        config.poll_interval config.poll_timeout));
      Cn_hub.log_action hub_path "daemon.start" "telegram";
      let offset = ref (read_offset hub_path) in
      while true do
        (match Cn_telegram.get_updates ~token ~offset:!offset
                ~timeout:config.poll_timeout with
        | Error msg ->
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
                    (* Rejected: advance offset (handled by dropping) *)
                    Cn_hub.log_action hub_path "daemon.rejected"
                      (Printf.sprintf "user_id:%d" msg.user_id);
                    offset := max !offset (msg.update_id + 1);
                    write_offset hub_path !offset;
                    drain rest
                  end else begin
                    let trigger_id = Printf.sprintf "tg-%d" msg.update_id in
                    enqueue_telegram hub_path msg;
                    match process_one ~config ~hub_path ~name with
                    | Ok () ->
                        (* Only ack if no longer queued or in-flight.
                           Handles the case where process_one returned Ok ()
                           because the lock was busy (overlap) or it processed
                           a different queued item. *)
                        if not (is_queued hub_path trigger_id)
                           && not (is_in_flight hub_path trigger_id) then begin
                          offset := max !offset (msg.update_id + 1);
                          write_offset hub_path !offset;
                          drain rest
                        end
                        (* else: message still pending — stop and let next
                           poll cycle retry from current offset *)
                    | Error err ->
                        (* Do NOT advance offset — Telegram will retry *)
                        print_endline (Cn_fmt.warn (Printf.sprintf
                          "Processing failed for tg-%d: %s (will retry)"
                          msg.update_id err))
                        (* Stop: do not process later updates *)
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
