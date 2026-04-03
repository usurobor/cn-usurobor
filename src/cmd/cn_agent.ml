(** cn_agent.ml — Agent I/O, queue, and execution

    Queue FIFO management, agent input/output processing,
    operation execution, and archival.

    Merged from: cn_agent + cn_queue in the 14-module plan.
    Queue is FIFO infrastructure for agent — not a separate domain. *)

open Cn_lib

(* === Queue FIFO === *)

let queue_dir hub_path = Cn_ffi.Path.join hub_path "state/queue"

(** Count items currently in the queue. *)
let queue_depth hub_path =
  let dir = queue_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then 0
  else
    try
      Cn_ffi.Fs.readdir dir
      |> List.filter Cn_hub.is_md_file
      |> List.length
    with _ -> 0

let queue_add hub_path id from content =
  let dir = queue_dir hub_path in
  Cn_ffi.Fs.ensure_dir dir;

  (* 2.8: idempotent — skip if already queued with same id *)
  let already_queued =
    Cn_ffi.Fs.readdir dir
    |> List.exists (fun f -> Cn_lib.ends_with ~suffix:(Printf.sprintf "-%s-%s.md" from id) f) in
  if already_queued then
    Printf.sprintf "(already queued: %s)" id
  else begin
    let ts = Cn_hub.sanitize_timestamp (Cn_fmt.now_iso ()) in
    let file_name = Printf.sprintf "%s-%s-%s.md" ts from id in
    let file_path = Cn_ffi.Path.join dir file_name in

    let queued_content = Printf.sprintf "---\nid: %s\nfrom: %s\nqueued: %s\n---\n\n%s"
      id from (Cn_fmt.now_iso ()) content in
    Cn_ffi.Fs.write file_path queued_content;

    Cn_hub.log_action hub_path "queue.add" (Printf.sprintf "id:%s from:%s" id from);
    file_name
  end

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

  (* 1.2: Filename.quote for shell safety — id could contain quotes *)
  let commit_msg = Filename.quote (Printf.sprintf "run: %s %s" gtd_type id) in
  let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path
    (Printf.sprintf "git add -A && git commit -m %s" commit_msg) in
  print_endline (Cn_fmt.ok "Committed run")

(* === Auto-save === *)

let auto_save hub_path name =
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git status --porcelain" with
  | Some status when String.trim status <> "" ->
      let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add -A" in
      let msg = Printf.sprintf "%s: auto-save %s" name (Cn_fmt.date_of_iso (Cn_fmt.now_iso ())) in
      (match Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m %s" (Filename.quote msg)) with
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
  match Sys.getenv_opt "CN_UPDATE_RUNNING" with
  | Some _ -> false  (* recursion guard: we are already a re-exec'd process *)
  | None ->
      match Sys.getenv_opt "CN_AUTO_UPDATE" with
      | Some "0" -> false
      | _ -> true

let resolve_bin_path () =
  match Sys.getenv_opt "CN_BIN" with
  | Some p when String.length p > 0 -> p
  | _ ->
    (* Linux: /proc/self/exe — read directly, no child process.
       Spawning a shell to readlink /proc/self/exe returns the shell's exe, not ours. *)
    let proc_self = try Some (Unix.readlink "/proc/self/exe") with _ -> None in
    match proc_self with
    | Some p when String.length p > 0 -> p
    | _ ->
      (* macOS / fallback: resolve symlinks on Sys.executable_name *)
      match Cn_ffi.Child_process.exec
              (Printf.sprintf "readlink -f '%s' 2>/dev/null" Sys.executable_name) with
      | Some p when String.length (String.trim p) > 0 -> String.trim p
      | _ -> Sys.executable_name

let resolve_repo () =
  match Sys.getenv_opt "CN_REPO" with
  | Some r when String.length r > 0 -> r
  | _ -> Cn_lib.cnos_repo

let bin_path = resolve_bin_path ()
let repo = resolve_repo ()
let update_cooldown_sec = 3600.0  (* 1 hour between update checks *)

(* Update info returned from check, passed to do_update — avoids mutable ref *)
type update_info =
  | Update_skip
  | Update_available of string  (* release tag — newer version *)
  | Update_patch of string      (* release tag — same version, different commit (#37) *)

(* Cooldown: don't check more than once per hour.
   Uses mtime of state/.last-update-check as the timestamp. *)
let update_check_path hub_path = Cn_ffi.Path.join hub_path "state/.last-update-check"

let should_check_update hub_path =
  let path = update_check_path hub_path in
  if not (Sys.file_exists path) then true
  else
    let stat = Unix.stat path in
    (Unix.time () -. stat.Unix.st_mtime) > update_cooldown_sec

let touch_update_check hub_path =
  let path = update_check_path hub_path in
  Cn_ffi.Fs.write path (Cn_fmt.now_iso ())

(* Release info from GitHub API: tag + commit SHA *)
type release_info = { tag : string; commit : string }

(* Get latest release tag and commit from GitHub API.
   Uses Cn_json for reliable parsing instead of grep/sed (#37). *)
let get_latest_release () =
  let url = Printf.sprintf "https://api.github.com/repos/%s/releases/latest" repo in
  let cmd = Printf.sprintf "curl -fsSL '%s' 2>/dev/null" url in
  match Cn_ffi.Child_process.exec cmd with
  | None -> None
  | Some body ->
      match Cn_json.parse body with
      | Error _ -> None
      | Ok json ->
          match Cn_json.get_string "tag_name" json with
          | None -> None
          | Some tag ->
              (* target_commitish is the full commit SHA the tag points to.
                 When a release is created manually, it may be a branch name
                 like "main" instead of a SHA. Only use it if it looks like
                 a hex SHA (length >= 40, all hex chars). *)
              let is_hex_sha s =
                String.length s >= 40 &&
                String.to_seq s |> Seq.for_all (fun c ->
                  (c >= '0' && c <= '9') || (c >= 'a' && c <= 'f') || (c >= 'A' && c <= 'F'))
              in
              let commit = match Cn_json.get_string "target_commitish" json with
                | Some c when is_hex_sha c -> String.sub c 0 7
                | _ -> "" in
              Some { tag = String.trim tag; commit }

(* Backward-compat wrapper — callers that only need the tag *)
let get_latest_release_tag () =
  match get_latest_release () with
  | Some r -> Some r.tag
  | None -> None

(* Semantic version comparison — defined in cn_lib, re-exported for tests *)
let version_to_tuple = Cn_lib.version_to_tuple
let is_newer_version = Cn_lib.is_newer_version

(* Detect platform for binary download *)
let get_platform_binary () =
  let os = match Cn_ffi.Child_process.exec "uname -s" with
    | Some s -> String.trim s | None -> "" in
  let arch = match Cn_ffi.Child_process.exec "uname -m" with
    | Some s -> String.trim s | None -> "" in
  let platform = match os with
    | "Linux" -> "linux" | "Darwin" -> "macos" | _ -> "" in
  let arch = match arch with
    | "x86_64" -> "x64" | "aarch64" | "arm64" -> "arm64" | _ -> "" in
  if platform = "" || arch = "" then None
  else Some (Printf.sprintf "cn-%s-%s" platform arch)

(* Check for updates — returns update_info for do_update.
   Respects cooldown: skips if checked within the last hour.
   Always uses GitHub Releases (pre-built binaries).
   #37: detects same-version patches via commit hash comparison. *)
let check_for_update hub_path =
  if not (auto_update_enabled ()) then Update_skip
  else if not (should_check_update hub_path) then Update_skip
  else begin
    touch_update_check hub_path;
    match get_latest_release () with
    | None -> Update_skip
    | Some rel ->
        if is_newer_version rel.tag Cn_lib.version then
          Update_available rel.tag
        else if rel.commit <> "" && rel.commit <> Cn_lib.cnos_commit then
          (* Same version, different commit — patch available (#37) *)
          Update_patch rel.tag
        else
          Update_skip
  end

(* Perform update — downloads pre-built binary from GitHub Releases.
   Workflow: detect platform → download → validate → atomic replace.
   #37: handles both version bumps and same-version patches. *)
let do_update info =
  match info with
  | Update_skip -> Cn_protocol.Update_skip
  | Update_patch tag | Update_available tag ->
      (* Skip update if binary path is not writable (e.g. non-root daemon) *)
      let bin_dir = Filename.dirname bin_path in
      let writable = try Unix.access bin_dir [Unix.W_OK]; true
                     with Unix.Unix_error _ -> false in
      if not writable then Cn_protocol.Update_skip
      else match get_platform_binary () with
      | None -> Cn_protocol.Update_fail
      | Some binary ->
          let new_path = bin_path ^ ".new" in
          if Sys.file_exists new_path then Sys.remove new_path;
          let url = Printf.sprintf "https://github.com/%s/releases/download/%s/%s" repo tag binary in
          let dl_cmd = Printf.sprintf "curl -fsSL -o '%s' '%s' 2>/dev/null && chmod +x '%s'" new_path url new_path in
          match Cn_ffi.Child_process.exec dl_cmd with
          | None ->
              if Sys.file_exists new_path then Sys.remove new_path;
              Cn_protocol.Update_fail
          | Some _ ->
              (* Validate binary before replacing: must respond to --version *)
              let verify_cmd = Printf.sprintf "'%s' --version 2>/dev/null" new_path in
              match Cn_ffi.Child_process.exec verify_cmd with
              | None ->
                  Sys.remove new_path;
                  Cn_protocol.Update_fail
              | Some _ ->
                  (* Verified — atomic replace *)
                  let mv_cmd = Printf.sprintf "mv '%s' '%s'" new_path bin_path in
                  match Cn_ffi.Child_process.exec mv_cmd with
                  | Some _ -> Cn_protocol.Update_complete
                  | None ->
                      if Sys.file_exists new_path then Sys.remove new_path;
                      Cn_protocol.Update_fail

(* Re-exec: replace this process with the updated binary.
   Uses absolute bin_path, not PATH lookup, to ensure we run the just-updated binary.
   Sets CN_UPDATE_RUNNING to prevent infinite recursion (see MCA: self-update-recursion). *)
let re_exec () =
  Unix.putenv "CN_UPDATE_RUNNING" "1";
  Unix.execvp bin_path (Cn_ffi.Process.argv)

(** Check whether the on-disk binary reports a different version than the
    running process. Detects external binary replacement (operator ran
    `cn update` from another terminal, CI replaced the binary, etc.).

    Returns:
    - Ok None — no drift, versions match
    - Ok (Some disk_version) — drift detected, disk has different version
    - Error reason — could not determine disk binary version *)
let check_binary_version_drift () =
  if not (Cn_ffi.Fs.exists bin_path) then
    Error "binary not found on disk"
  else
    let cmd = Printf.sprintf "'%s' --version 2>/dev/null" bin_path in
    match Cn_ffi.Child_process.exec cmd with
    | None -> Error "binary --version failed"
    | Some output ->
      (* Output format: "cn 3.21.0 (abc1234)" — extract version *)
      let trimmed = String.trim output in
      match String.split_on_char ' ' trimmed with
      | _ :: ver :: _ ->
        if ver = Cn_lib.version then Ok None
        else Ok (Some ver)
      | _ -> Error (Printf.sprintf "unexpected --version output: %s" trimmed)

