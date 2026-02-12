(** cn_agent.ml — Agent I/O, queue, and execution

    Queue FIFO management, agent input/output processing,
    operation execution, archival, and the inbound actor loop.

    Merged from: cn_agent + cn_queue in the 14-module plan.
    Queue is FIFO infrastructure for agent — not a separate domain. *)

open Cn_lib

(* === Queue FIFO === *)

let queue_dir hub_path = Cn_ffi.Path.join hub_path "state/queue"

let queue_add hub_path id from content =
  let dir = queue_dir hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  let ts = Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ()) in
  let file_name = Printf.sprintf "%s-%s-%s.md" ts from id in
  let file_path = Cn_ffi.Path.join dir file_name in

  let queued_content = Printf.sprintf "---\nid: %s\nfrom: %s\nqueued: %s\n---\n\n%s"
    id from (Cn_fmt.now_iso ()) content in
  Cn_ffi.Fs.write file_path queued_content;

  Cn_hub.log_action hub_path "queue.add" (Printf.sprintf "id:%s from:%s" id from);
  file_name

let queue_pop hub_path =
  let dir = queue_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then None
  else
    Cn_ffi.Fs.readdir dir
    |> List.filter Cn_hub.is_md_file
    |> List.sort String.compare
    |> function
      | [] -> None
      | file :: _ ->
          let file_path = Cn_ffi.Path.join dir file in
          let content = Cn_ffi.Fs.read file_path in
          Cn_ffi.Fs.unlink file_path;
          Some content

let queue_count hub_path =
  let dir = queue_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then 0
  else Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file |> List.length

let queue_list hub_path =
  let dir = queue_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then []
  else Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file |> List.sort String.compare

(* === IO Paths === *)

let input_path hub_path = Cn_ffi.Path.join hub_path "state/input.md"
let output_path hub_path = Cn_ffi.Path.join hub_path "state/output.md"
let logs_input_dir hub_path = Cn_ffi.Path.join hub_path "logs/input"
let logs_output_dir hub_path = Cn_ffi.Path.join hub_path "logs/output"

(* === Get ID from file === *)

let get_file_id path =
  if not (Cn_ffi.Fs.exists path) then None
  else
    let content = Cn_ffi.Fs.read path in
    let meta = parse_frontmatter content in
    meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)

(* === Execute Agent Operations === *)

let execute_op hub_path name input_id op =
  match op with
  | Ack _ ->
      Cn_hub.log_action hub_path "op.ack" input_id;
      print_endline (Cn_fmt.ok (Printf.sprintf "Ack: %s" input_id))
  | Done id ->
      Cn_hub.log_action hub_path "op.done" id;
      print_endline (Cn_fmt.ok (Printf.sprintf "Done: %s" id))
  | Fail (id, reason) ->
      Cn_hub.log_action hub_path "op.fail" (Printf.sprintf "id:%s reason:%s" id reason);
      print_endline (Cn_fmt.warn (Printf.sprintf "Failed: %s - %s" id reason))
  | Reply (id, msg) ->
      (match Cn_gtd.find_thread hub_path id with
       | Some path ->
           let reply = Printf.sprintf "\n\n## Reply (%s)\n\n%s" (Cn_fmt.now_iso ()) msg in
           Cn_ffi.Fs.append path reply;
           Cn_hub.log_action hub_path "op.reply" (Printf.sprintf "thread:%s" id);
           print_endline (Cn_fmt.ok (Printf.sprintf "Replied to %s" id))
       | None ->
           Cn_hub.log_action hub_path "op.reply" (Printf.sprintf "thread:%s (not found)" id);
           print_endline (Cn_fmt.warn (Printf.sprintf "Thread not found for reply: %s" id)))
  | Send (peer, msg, body_opt) ->
      let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
      Cn_ffi.Fs.ensure_dir outbox_dir;
      let slug = Cn_hub.slugify ~max_len:30 msg in
      let file_name = slug ^ ".md" in
      let first_line = match String.split_on_char '\n' msg with x :: _ -> x | [] -> msg in
      let body = match body_opt with Some b -> b | None -> msg in
      let content = Printf.sprintf "---\nto: %s\ncreated: %s\nfrom: %s\n---\n\n# %s\n\n%s\n"
        peer (Cn_fmt.now_iso ()) name first_line body in
      Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir file_name) content;
      Cn_hub.log_action hub_path "op.send" (Printf.sprintf "to:%s thread:%s" peer slug);
      print_endline (Cn_fmt.ok (Printf.sprintf "Queued message to %s" peer))
  | Delegate (id, peer) ->
      (match Cn_gtd.find_thread hub_path id with
       | Some path ->
           let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
           Cn_ffi.Fs.ensure_dir outbox_dir;
           let content = Cn_ffi.Fs.read path in
           Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir (Cn_ffi.Path.basename path))
             (update_frontmatter content [("to", peer); ("delegated", Cn_fmt.now_iso ()); ("delegated-by", name)]);
           Cn_ffi.Fs.unlink path;
           Cn_hub.log_action hub_path "op.delegate" (Printf.sprintf "%s to:%s" id peer);
           print_endline (Cn_fmt.ok (Printf.sprintf "Delegated %s to %s" id peer))
       | None ->
           print_endline (Cn_fmt.warn (Printf.sprintf "Thread not found for delegate: %s" id)))
  | Defer (id, until) ->
      (match Cn_gtd.find_thread hub_path id with
       | Some path ->
           let deferred_dir = Cn_ffi.Path.join hub_path "threads/deferred" in
           Cn_ffi.Fs.ensure_dir deferred_dir;
           let content = Cn_ffi.Fs.read path in
           let until_str = Option.value until ~default:"unspecified" in
           Cn_ffi.Fs.write (Cn_ffi.Path.join deferred_dir (Cn_ffi.Path.basename path))
             (update_frontmatter content [("deferred", Cn_fmt.now_iso ()); ("until", until_str)]);
           Cn_ffi.Fs.unlink path;
           Cn_hub.log_action hub_path "op.defer" (Printf.sprintf "%s until:%s" id until_str);
           print_endline (Cn_fmt.ok (Printf.sprintf "Deferred %s" id))
       | None ->
           print_endline (Cn_fmt.warn (Printf.sprintf "Thread not found for defer: %s" id)))
  | Delete id ->
      (match Cn_gtd.find_thread hub_path id with
       | Some path ->
           Cn_ffi.Fs.unlink path;
           Cn_hub.log_action hub_path "op.delete" id;
           print_endline (Cn_fmt.ok (Printf.sprintf "Deleted %s" id))
       | None ->
           Cn_hub.log_action hub_path "op.delete" (Printf.sprintf "%s (not found)" id);
           print_endline (Cn_fmt.info (Printf.sprintf "Thread already gone: %s" id)))
  | Surface desc ->
      let dir = Cn_hub.mca_dir hub_path in
      Cn_ffi.Fs.ensure_dir dir;
      let ts = Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ()) in
      let slug = Cn_hub.slugify ~max_len:40 desc in
      let file_name = Printf.sprintf "%s-%s.md" ts slug in
      let content = Printf.sprintf "---\nid: %s\nsurfaced-by: %s\ncreated: %s\nstatus: open\n---\n\n# MCA\n\n%s\n"
        slug name (Cn_fmt.now_iso ()) desc in
      Cn_ffi.Fs.write (Cn_ffi.Path.join dir file_name) content;
      Cn_hub.log_action hub_path "op.surface" (Printf.sprintf "id:%s desc:%s" slug desc);
      print_endline (Cn_fmt.ok (Printf.sprintf "Surfaced MCA: %s" desc))

(* === Archive completed IO pair === *)

let generate_trigger () =
  Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ())

let archive_timeout hub_path _name =
  let inp = input_path hub_path in
  let trigger = get_file_id inp |> Option.value ~default:(generate_trigger ()) in
  
  if not (Cn_ffi.Fs.exists inp) then begin
    print_endline (Cn_fmt.warn "No input.md to archive");
    false
  end
  else begin
    let logs_in = logs_input_dir hub_path in
    Cn_ffi.Fs.ensure_dir logs_in;
    
    let archive_name = trigger ^ "-timeout.md" in
    let input_content = Cn_ffi.Fs.read inp in
    
    (* Prepend timeout marker to archived input *)
    let timeout_header = Printf.sprintf "---\nstatus: timeout\narchived: %s\n---\n\n" (Cn_fmt.now_iso ()) in
    Cn_ffi.Fs.write (Cn_ffi.Path.join logs_in archive_name) (timeout_header ^ input_content);
    
    (* Clear input.md *)
    Cn_ffi.Fs.unlink inp;
    
    Cn_hub.log_action hub_path "io.timeout" (Printf.sprintf "trigger:%s" trigger);
    print_endline (Cn_fmt.ok (Printf.sprintf "Archived timeout: %s" archive_name));
    true
  end

let archive_io_pair hub_path name =
  let inp = input_path hub_path in
  let outp = output_path hub_path in

  let trigger = get_file_id inp |> Option.value ~default:(generate_trigger ()) in

  if not (Cn_ffi.Fs.exists outp) then begin
    print_endline (Cn_fmt.info (Printf.sprintf "Waiting: trigger=%s, no output yet" trigger));
    false
  end
  else begin
    let logs_in = logs_input_dir hub_path in
    let logs_out = logs_output_dir hub_path in
    Cn_ffi.Fs.ensure_dir logs_in;
    Cn_ffi.Fs.ensure_dir logs_out;

    let output_content = Cn_ffi.Fs.read outp in
    let archive_name = trigger ^ ".md" in
    Cn_ffi.Fs.write (Cn_ffi.Path.join logs_in archive_name) (Cn_ffi.Fs.read inp);
    Cn_ffi.Fs.write (Cn_ffi.Path.join logs_out archive_name) output_content;

    let output_meta = parse_frontmatter output_content in
    let ops = extract_ops output_meta in
    ops |> List.iter (fun op ->
      print_endline (Cn_fmt.info (Printf.sprintf "Executing: %s" (string_of_agent_op op)));
      execute_op hub_path name trigger op);

    Cn_ffi.Fs.unlink inp;
    Cn_ffi.Fs.unlink outp;

    Cn_hub.log_action hub_path "io.archive" (Printf.sprintf "trigger:%s ops:%d" trigger (List.length ops));
    print_endline (Cn_fmt.ok (Printf.sprintf "Archived: %s (%d ops)" trigger (List.length ops)));
    true
  end

(* === Queue inbox items === *)

let queue_inbox_items hub_path =
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in
  if not (Cn_ffi.Fs.exists inbox_dir) then 0
  else
    Cn_ffi.Fs.readdir inbox_dir
    |> List.filter Cn_hub.is_md_file
    |> List.filter_map (fun file ->
        let file_path = Cn_ffi.Path.join inbox_dir file in
        let content = Cn_ffi.Fs.read file_path in
        let meta = parse_frontmatter content in

        let is_queued = List.exists (fun (k, _) -> k = "queued-for-processing") meta in
        if is_queued then None
        else begin
          let trigger = meta |> List.find_map (fun (k, v) -> if k = "trigger" then Some v else None)
            |> Option.value ~default:(Cn_ffi.Path.basename_ext file ".md") in
          let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
            |> Option.value ~default:"unknown" in

          let _ = queue_add hub_path trigger from content in
          Cn_ffi.Fs.write file_path (update_frontmatter content [("queued-for-processing", Cn_fmt.now_iso ())]);

          print_endline (Cn_fmt.ok (Printf.sprintf "Queued: %s (from %s)" trigger from));
          Some file
        end)
    |> List.length

(* === Feed next input === *)

let feed_next_input hub_path =
  let inp = input_path hub_path in

  match queue_pop hub_path with
  | None ->
      print_endline (Cn_fmt.ok "Queue empty - nothing to process");
      false
  | Some content ->
      Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");
      Cn_ffi.Fs.write inp content;

      let meta = parse_frontmatter content in
      let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
        |> Option.value ~default:"unknown" in
      let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
        |> Option.value ~default:"unknown" in

      Cn_hub.log_action hub_path "process.feed" (Printf.sprintf "id:%s from:%s" id from);
      print_endline (Cn_fmt.ok (Printf.sprintf "Wrote state/input.md: %s (from %s)" id from));

      let remaining = queue_count hub_path in
      if remaining > 0 then
        print_endline (Cn_fmt.info (Printf.sprintf "Queue depth: %d remaining" remaining));

      true

(* === Wake agent === *)

let shell_escape s =
  let buf = Buffer.create (String.length s * 2) in
  String.iter (fun c ->
    if c = '\'' then Buffer.add_string buf "'\\''"
    else Buffer.add_char buf c
  ) s;
  Buffer.contents buf

let wake_agent hub_path =
  let inp = input_path hub_path in
  if not (Cn_ffi.Fs.exists inp) then begin
    print_endline (Cn_fmt.warn "No input.md to wake with");
  end else begin
    let content = Cn_ffi.Fs.read inp in
    let escaped = shell_escape content in
    print_endline (Cn_fmt.info "Triggering OpenClaw wake with input content...");
    let wake_cmd = Printf.sprintf "openclaw system event --text '%s' --mode now 2>/dev/null" escaped in
    match Cn_ffi.Child_process.exec wake_cmd with
    | Some _ -> print_endline (Cn_fmt.ok "Wake triggered with input content")
    | None -> print_endline (Cn_fmt.warn "Wake trigger failed - is OpenClaw running?")
  end

(* === Queue Commands === *)

let run_queue_list hub_path =
  let items = queue_list hub_path in
  match items with
  | [] -> print_endline "(queue empty)"
  | _ ->
      print_endline (Cn_fmt.info (Printf.sprintf "Queue depth: %d" (List.length items)));
      items |> List.iter (fun file ->
        let file_path = Cn_ffi.Path.join (queue_dir hub_path) file in
        let content = Cn_ffi.Fs.read file_path in
        let meta = parse_frontmatter content in
        let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
          |> Option.value ~default:"?" in
        let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
          |> Option.value ~default:"?" in
        print_endline (Printf.sprintf "  %s (from %s)" id from))

let run_queue_clear hub_path =
  let dir = queue_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then print_endline (Cn_fmt.ok "Queue already empty")
  else
    let items = Cn_ffi.Fs.readdir dir |> List.filter Cn_hub.is_md_file in
    items |> List.iter (fun file -> Cn_ffi.Fs.unlink (Cn_ffi.Path.join dir file));
    Cn_hub.log_action hub_path "queue.clear" (Printf.sprintf "count:%d" (List.length items));
    print_endline (Cn_fmt.ok (Printf.sprintf "Cleared %d item(s) from queue" (List.length items)))

(* === Agent Output (cn out) === *)

let run_out hub_path name gtd =
  let start_time = Cn_fmt.now_iso () in
  let inp = input_path hub_path in
  let outp = output_path hub_path in

  let input_content = if Cn_ffi.Fs.exists inp then Cn_ffi.Fs.read inp else "" in
  let input_meta = if input_content <> "" then Some (parse_frontmatter input_content) else None in
  let get_meta key = match input_meta with
    | Some m -> m |> List.find_map (fun (k, v) -> if k = key then Some v else None)
    | None -> None in
  let id = get_meta "id" |> Option.value ~default:"unknown" in
  let from = get_meta "from" |> Option.value ~default:"unknown" in

  let (gtd_type, op_details, op_kind) = match gtd with
    | Out.Do (Out.Reply { message }) -> ("do", Printf.sprintf "reply: %s" message, `Reply message)
    | Out.Do (Out.Send { to_; message }) -> ("do", Printf.sprintf "send: %s|%s" to_ message, `Send (to_, message))
    | Out.Do (Out.Surface { desc }) -> ("do", Printf.sprintf "surface: %s" desc, `Surface desc)
    | Out.Do (Out.Noop { reason }) -> ("do", Printf.sprintf "noop: %s" reason, `Noop)
    | Out.Do (Out.Commit { artifact }) -> ("do", Printf.sprintf "commit: %s" artifact, `Commit artifact)
    | Out.Defer { reason } -> ("defer", Printf.sprintf "reason: %s" reason, `Defer)
    | Out.Delegate { to_ } -> ("delegate", Printf.sprintf "to: %s" to_, `Delegate to_)
    | Out.Delete { reason } -> ("delete", Printf.sprintf "reason: %s" reason, `Delete)
  in

  let run_ts = String.map (fun c -> if c = ':' then '-' else c) start_time in
  let run_dir = Cn_ffi.Path.join hub_path (Printf.sprintf "logs/runs/%s-%s" run_ts id) in
  Cn_ffi.Fs.mkdir_p run_dir;

  if input_content <> "" then begin
    Cn_ffi.Fs.write (Cn_ffi.Path.join run_dir "input.md") input_content;
    print_endline (Cn_fmt.dim (Printf.sprintf "Archived input → %s" run_dir))
  end;

  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  Cn_ffi.Fs.ensure_dir outbox_dir;
  (match op_kind with
   | `Reply message ->
       let reply_file = Printf.sprintf "%s-reply-%s.md" from id in
       let reply_content = Printf.sprintf {|---
to: %s
in-reply-to: %s
created: %s
---

%s
|} from id (Cn_fmt.now_iso ()) message in
       Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir reply_file) reply_content;
       print_endline (Cn_fmt.ok (Printf.sprintf "Reply → outbox/%s" reply_file))
   | `Send (to_, message) ->
       let send_file = Printf.sprintf "%s-%s.md" to_ id in
       let send_content = Printf.sprintf {|---
to: %s
created: %s
---

%s
|} to_ (Cn_fmt.now_iso ()) message in
       Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir send_file) send_content;
       print_endline (Cn_fmt.ok (Printf.sprintf "Send → outbox/%s" send_file))
   | `Surface desc ->
       let mca_d = Cn_hub.mca_dir hub_path in
       Cn_ffi.Fs.mkdir_p mca_d;
       let mca_file = Printf.sprintf "%s.md" id in
       Cn_ffi.Fs.write (Cn_ffi.Path.join mca_d mca_file) desc;
       print_endline (Cn_fmt.ok (Printf.sprintf "Surfaced MCA: %s" desc))
   | `Noop -> print_endline (Cn_fmt.dim "Noop - no action taken")
   | `Commit artifact -> print_endline (Cn_fmt.ok (Printf.sprintf "Commit recorded: %s" artifact))
   | `Defer -> print_endline (Cn_fmt.dim "Deferred - will resurface later")
   | `Delegate to_ -> print_endline (Cn_fmt.ok (Printf.sprintf "Delegated to %s" to_))
   | `Delete -> print_endline (Cn_fmt.dim "Deleted - removed from queue"));

  let output_content = Printf.sprintf {|---
id: %s
gtd: %s
%s
created: %s
---
|} id gtd_type op_details (Cn_fmt.now_iso ()) in
  Cn_ffi.Fs.write outp output_content;

  Cn_ffi.Fs.write (Cn_ffi.Path.join run_dir "output.md") output_content;

  let end_time = Cn_fmt.now_iso () in
  let meta_content = Printf.sprintf {|{
  "id": "%s",
  "from": "%s",
  "gtd": "%s",
  "start": "%s",
  "end": "%s",
  "agent": "%s"
}
|} id from gtd_type start_time end_time name in
  Cn_ffi.Fs.write (Cn_ffi.Path.join run_dir "meta.json") meta_content;

  Cn_ffi.Fs.write inp "";
  Cn_ffi.Fs.write outp "";
  print_endline (Cn_fmt.ok "State cleared");

  Cn_hub.log_action hub_path "out" (Printf.sprintf "id:%s gtd:%s run:%s" id gtd_type run_dir);
  print_endline (Cn_fmt.ok (Printf.sprintf "Run complete: %s (%s)" gtd_type id));

  let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path
    (Printf.sprintf "git add -A && git commit -m 'run: %s %s'" gtd_type id) in
  print_endline (Cn_fmt.ok "Committed run")

(* === Auto-save === *)

let auto_save hub_path name =
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git status --porcelain" with
  | Some status when String.trim status <> "" ->
      let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add -A" in
      let msg = Printf.sprintf "%s: auto-save %s" name (String.sub (Cn_fmt.now_iso ()) 0 10) in
      (match Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m \"%s\"" msg) with
       | Some _ ->
           Cn_hub.log_action hub_path "auto-save.commit" msg;
           print_endline (Cn_fmt.ok "Auto-committed changes");
           (match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git push" with
            | Some _ ->
                Cn_hub.log_action hub_path "auto-save.push" "success";
                print_endline (Cn_fmt.ok "Auto-pushed to origin")
            | None ->
                Cn_hub.log_action hub_path "auto-save.push" "failed";
                print_endline (Cn_fmt.warn "Auto-push failed"))
       | None ->
           Cn_hub.log_action hub_path "auto-save.commit" "failed";
           print_endline (Cn_fmt.warn "Auto-commit failed"))
  | _ -> ()

(* === Auto-Update (when idle) === *)

let auto_update_enabled () =
  match Sys.getenv_opt "CN_AUTO_UPDATE" with
  | Some "0" -> false
  | _ -> true

let install_dir = "/usr/local/lib/cnos"

let check_for_update () =
  if not (auto_update_enabled ()) then Cn_protocol.Update_skip
  else if not (Sys.file_exists install_dir) then Cn_protocol.Update_skip
  else
    let fetch_cmd = Printf.sprintf "cd %s && git fetch origin main --quiet 2>/dev/null" install_dir in
    let _ = Cn_ffi.Child_process.exec fetch_cmd in
    let version_cmd = Printf.sprintf "cd %s && git show origin/main:tools/src/cn/cn_lib.ml 2>/dev/null | grep 'let version' | head -1 | sed 's/.*\"\\([^\"]*\\)\".*/\\1/'" install_dir in
    match Cn_ffi.Child_process.exec version_cmd with
    | None -> Cn_protocol.Update_skip
    | Some latest_raw ->
        let latest = String.trim latest_raw in
        if latest <> Cn_lib.version && latest <> "" then Cn_protocol.Update_available
        else Cn_protocol.Update_skip

let do_update () =
  let pull_cmd = Printf.sprintf "cd %s && git pull --ff-only 2>/dev/null" install_dir in
  match Cn_ffi.Child_process.exec pull_cmd with
  | Some _ -> Cn_protocol.Update_complete
  | None -> Cn_protocol.Update_fail

let re_exec () =
  let args = Cn_ffi.Process.argv |> Array.to_list in
  let args_str = args |> List.tl |> String.concat " " in
  let _ = Cn_ffi.Child_process.exec (Printf.sprintf "cn %s" args_str) in
  Cn_ffi.Process.exit 0

(* === Inbound (Actor Loop — FSM-driven) === *)

let run_inbound hub_path name =
  print_endline (Cn_fmt.info "cn in: handling external input...");

  (* Step 1: Queue any new inbox items *)
  let queued = queue_inbox_items hub_path in
  if queued > 0 then
    print_endline (Cn_fmt.info (Printf.sprintf "Added %d item(s) to queue" queued));

  (* Step 2: Check MCA review cycle *)
  let cycle = Cn_mca.increment_mca_cycle hub_path in
  if cycle mod Cn_mca.mca_review_interval = 0 && Cn_mca.mca_count hub_path > 0 then begin
    let review = Cn_mca.prepare_mca_review hub_path name in
    let _ = queue_add hub_path review.trigger "system" review.body in
    Cn_hub.log_action hub_path "mca.review-queued" (Printf.sprintf "trigger:%s count:%d" review.trigger review.count);
    print_endline (Cn_fmt.ok (Printf.sprintf "Queued MCA review (%d MCAs) trigger:%s" review.count (String.sub review.trigger 0 7)))
  end;

  (* Step 3: Actor FSM — derive state, apply transitions *)
  let inp = input_path hub_path in
  let outp = output_path hub_path in
  
  (* Timeout config: read from env or use defaults *)
  let cron_period_min = match Sys.getenv_opt "CN_CRON_PERIOD_MIN" with
    | Some s -> (try int_of_string s with _ -> 5)
    | None -> 5 in
  let timeout_cycles = match Sys.getenv_opt "CN_TIMEOUT_CYCLES" with
    | Some s -> (try int_of_string s with _ -> 3)
    | None -> 3 in
  let max_age_min = cron_period_min * timeout_cycles in
  
  (* Calculate input.md age in minutes *)
  let input_age_min = 
    if Cn_ffi.Fs.exists inp then
      let stat = Unix.stat inp in
      let age_sec = Unix.time () -. stat.Unix.st_mtime in
      int_of_float (age_sec /. 60.0)
    else 0 in
  
  let actor_state = Cn_protocol.actor_derive_state_with_timeout
    ~input_exists:(Cn_ffi.Fs.exists inp)
    ~output_exists:(Cn_ffi.Fs.exists outp)
    ~input_age_min
    ~max_age_min in

  print_endline (Cn_fmt.dim (Printf.sprintf "Actor state: %s"
    (Cn_protocol.string_of_actor_state actor_state)));

  match actor_state with
  | Cn_protocol.OutputReady ->
      (* output.md exists — archive, then feed next *)
      (match Cn_protocol.actor_transition actor_state Cn_protocol.Archive_complete with
       | Error e -> print_endline (Cn_fmt.fail (Printf.sprintf "Actor FSM error: %s" e))
       | Ok Cn_protocol.Idle ->
           if archive_io_pair hub_path name then begin
             auto_save hub_path name;
             if feed_next_input hub_path then wake_agent hub_path
           end
       | Ok _ -> ())
  | Cn_protocol.TimedOut ->
      (* Agent timed out — archive as failed, proceed to next *)
      print_endline (Cn_fmt.warn (Printf.sprintf "Agent timeout (age=%d min, max=%d min)" input_age_min max_age_min));
      Cn_hub.log_action hub_path "actor.timeout" (Printf.sprintf "age:%d max:%d" input_age_min max_age_min);
      if archive_timeout hub_path name then begin
        auto_save hub_path name;
        if feed_next_input hub_path then wake_agent hub_path
      end
  | Cn_protocol.Processing ->
      (* Agent working — show progress *)
      print_endline (Cn_fmt.info (Printf.sprintf "Agent working (%d/%d min)" input_age_min max_age_min));
      print_endline (Cn_fmt.info (Printf.sprintf "Queue depth: %d" (queue_count hub_path)))
  | Cn_protocol.Idle ->
      (* Auto-update check before processing queue *)
      let update_event = check_for_update () in
      (match update_event with
       | Cn_protocol.Update_available ->
           print_endline (Cn_fmt.info (Printf.sprintf "Update available (current: %s)" Cn_lib.version));
           Cn_hub.log_action hub_path "actor.update" "checking";
           let result = do_update () in
           (match result with
            | Cn_protocol.Update_complete ->
                Cn_hub.log_action hub_path "actor.update" "complete";
                print_endline (Cn_fmt.ok "Update installed, re-executing...");
                re_exec ()
            | Cn_protocol.Update_fail ->
                Cn_hub.log_action hub_path "actor.update" "failed";
                print_endline (Cn_fmt.warn "Update failed, continuing with current version");
                if feed_next_input hub_path then wake_agent hub_path
            | _ -> ())
       | Cn_protocol.Update_skip | _ ->
           if feed_next_input hub_path then wake_agent hub_path)
  | Cn_protocol.Updating ->
      (* Transient state — should not be derived from filesystem *)
      print_endline (Cn_fmt.warn "Unexpected Updating state in actor loop")
  | Cn_protocol.InputReady ->
      (* input.md written but agent not woken — wake it *)
      wake_agent hub_path
