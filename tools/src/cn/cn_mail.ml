(** cn_mail.ml — Inbox/outbox mail transport

    Branch operations, orphan detection, materialization,
    inbox check/process/flush, outbox check/flush/send.
    The largest domain module — mail transport is cohesive. *)

open Cn_lib

(* === Branch Operations === *)

let delete_remote_branch hub_path branch =
  if Cn_fmt.would (Printf.sprintf "delete remote branch %s" branch) then true
  else begin
    let cmd = Printf.sprintf "git push origin --delete %s 2>/dev/null" branch in
    match Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd with
    | Some _ ->
        Cn_hub.log_action hub_path "branch.delete" branch;
        print_endline (Cn_fmt.dim (Printf.sprintf "  Deleted remote: %s" branch));
        true
    | None -> false
  end

(* === Orphan Branch Detection === *)

let is_orphan_branch hub_path branch =
  let cmd = Printf.sprintf "git merge-base main origin/%s 2>/dev/null || git merge-base master origin/%s 2>/dev/null" branch branch in
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd with
  | Some _ -> false
  | None -> true

let get_branch_author hub_path branch =
  let cmd = Printf.sprintf "git log -1 --format='%%an <%%ae>' origin/%s 2>/dev/null" branch in
  Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd
  |> Option.map String.trim
  |> Option.value ~default:"unknown"

let reject_orphan_branch hub_path peer_name branch =
  let author = get_branch_author hub_path branch in

  if !(Cn_fmt.dry_run_mode) then begin
    print_endline (Cn_fmt.dim (Printf.sprintf "Would: reject orphan %s (from %s)" branch author));
    print_endline (Cn_fmt.dim (Printf.sprintf "Would: send rejection notice to %s" peer_name))
  end else begin
    let ts = Cn_fmt.now_iso () in
    let slug = Cn_hub.slugify branch in
    let filename = Cn_hub.make_thread_filename (Printf.sprintf "rejected-%s" slug) in

    let content = Printf.sprintf
      "---\nto: %s\ncreated: %s\nsubject: Branch rejected (orphan)\n---\n\n\
       Branch `%s` rejected and deleted.\n\n\
       **Reason:** No merge base with main.\n\n\
       This happens when pushing from `cn-%s` instead of `cn-{recipient}-clone`.\n\n\
       **Author:** %s\n\n\
       **Fix:**\n\
       1. Delete local branch: `git branch -D %s`\n\
       2. Re-send via cn outbox (uses clone automatically)\n"
      peer_name ts branch peer_name author branch in

    let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
    Cn_ffi.Fs.ensure_dir outbox_dir;
    Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir filename) content
  end;

  Cn_hub.log_action hub_path "inbox.reject" (Printf.sprintf "branch:%s peer:%s author:%s reason:orphan" branch peer_name author);
  print_endline (Cn_fmt.fail (Printf.sprintf "Rejected orphan: %s (from %s)" branch author))

(* === Rejection Terminal Cleanup === *)

let parse_rejected_branch content =
  match String.split_on_char '`' content with
  | _ :: branch :: _ when String.length branch > 0
      && String.length content >= 8
      && String.sub content 0 8 = "Branch `" ->
      Some branch
  | _ -> None

let cleanup_rejected_branch hub_path branch =
  let cmd = Printf.sprintf "git branch -D %s 2>/dev/null" branch in
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd with
  | Some _ ->
      Cn_hub.log_action hub_path "rejection.cleanup" (Printf.sprintf "deleted local branch %s" branch);
      print_endline (Cn_fmt.dim (Printf.sprintf "  Cleaned up rejected branch: %s" branch));
      true
  | None -> false

let process_rejection_cleanup hub_path content =
  match parse_rejected_branch content with
  | Some branch ->
      let _ = cleanup_rejected_branch hub_path branch in
      ()
  | None -> ()

(* === Inbox Operations === *)

type branch_info = { peer: string; branch: string }

let get_inbound_branches clone_path my_name =
  Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" my_name
  |> Cn_ffi.Child_process.exec_in ~cwd:clone_path
  |> Option.map Cn_hub.split_lines
  |> Option.value ~default:[]

let inbox_check hub_path name =
  let peers = Cn_hub.load_peers hub_path in

  print_endline (Cn_fmt.info (Printf.sprintf "Checking inbox for %s..." name));

  let total = peers |> List.fold_left (fun acc peer ->
    match peer.kind, peer.clone with
    | Some "template", _ -> acc
    | _, None ->
        print_endline (Cn_fmt.dim (Printf.sprintf "  %s: no clone path" peer.name));
        acc
    | _, Some clone_path ->
        if not (Cn_ffi.Fs.exists clone_path) then begin
          print_endline (Cn_fmt.dim (Printf.sprintf "  %s: clone not found" peer.name));
          acc
        end else begin
          let _ = Cn_ffi.Child_process.exec_in ~cwd:clone_path "git fetch origin --prune" in
          let branches = get_inbound_branches clone_path name in
          (match branches with
           | [] -> print_endline (Cn_fmt.dim (Printf.sprintf "  %s: no inbound" peer.name))
           | bs ->
               print_endline (Cn_fmt.warn (Printf.sprintf "From %s: %d inbound" peer.name (List.length bs)));
               bs |> List.iter (fun b -> print_endline (Printf.sprintf "  ← %s" b)));
          acc + List.length branches
        end
  ) 0 in

  if total = 0 then print_endline (Cn_fmt.ok "Inbox clear")

let materialize_branch ~clone_path ~hub_path ~inbox_dir ~peer_name ~branch =
  (* Receiver FSM: Fetched → classify → materialize or skip → clean *)
  let fsm_state = ref Cn_protocol.R_Fetched in
  let advance event =
    match Cn_protocol.receiver_transition !fsm_state event with
    | Ok s -> fsm_state := s; true
    | Error e ->
        print_endline (Cn_fmt.fail (Printf.sprintf "Receiver FSM: %s" e)); false
  in

  (* Classify: orphan, duplicate, or new *)
  if is_orphan_branch clone_path branch then begin
    let _ = advance Cn_protocol.RE_IsOrphan in
    reject_orphan_branch hub_path peer_name branch;
    let _ = delete_remote_branch clone_path branch in
    let _ = advance Cn_protocol.RE_DeleteBranch in
    []
  end
  else begin
    let branch_slug = match branch |> String.split_on_char '/' |> List.rev with
      | x :: _ -> x
      | [] -> branch in
    let already_exists =
      Cn_ffi.Fs.readdir inbox_dir
      |> List.exists (fun f -> String.length f > 16 && ends_with ~suffix:(Printf.sprintf "%s-%s.md" peer_name branch_slug) f) in
    let archived_dir = Cn_ffi.Path.join inbox_dir "_archived" in
    let already_archived = Cn_ffi.Fs.exists archived_dir &&
      Cn_ffi.Fs.readdir archived_dir
      |> List.exists (fun f -> String.length f > 16 && ends_with ~suffix:(Printf.sprintf "%s-%s.md" peer_name branch_slug) f) in

    if already_exists || already_archived then begin
      let _ = advance Cn_protocol.RE_IsDuplicate in
      let _ = delete_remote_branch clone_path branch in
      let _ = advance Cn_protocol.RE_DeleteBranch in
      []
    end
    else if !(Cn_fmt.dry_run_mode) then begin
      print_endline (Cn_fmt.dim (Printf.sprintf "Would: materialize %s → %s-%s" branch peer_name branch_slug));
      print_endline (Cn_fmt.dim (Printf.sprintf "Would: delete remote branch %s" branch));
      [Cn_hub.make_thread_filename (Printf.sprintf "%s-%s" peer_name branch_slug)]
    end
    else begin
      let _ = advance Cn_protocol.RE_IsNew in

      let diff_cmd = Printf.sprintf "git diff main...origin/%s --name-only 2>/dev/null || git diff master...origin/%s --name-only" branch branch in
      let files = Cn_ffi.Child_process.exec_in ~cwd:clone_path diff_cmd
        |> Option.map Cn_hub.split_lines
        |> Option.value ~default:[]
        |> List.filter (fun f ->
             String.length f > 11 &&
             String.sub f 0 11 = "threads/in/" &&
             Cn_hub.is_md_file f) in

      let trigger =
        Cn_ffi.Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git rev-parse origin/%s" branch)
        |> Option.map String.trim
        |> Option.value ~default:"unknown" in

      let inbox_file = Cn_hub.make_thread_filename (Printf.sprintf "%s-%s" peer_name branch_slug) in
      let inbox_path = Cn_ffi.Path.join inbox_dir inbox_file in

      let result = files |> List.filter_map (fun file ->
        let show_cmd = Printf.sprintf "git show origin/%s:%s" branch file in
        match Cn_ffi.Child_process.exec_in ~cwd:clone_path show_cmd with
        | None -> None
        | Some content ->
            let meta = [("state", "received"); ("from", peer_name); ("branch", branch);
                        ("trigger", trigger); ("file", file); ("received", Cn_fmt.now_iso ())] in
            Cn_ffi.Fs.write inbox_path (update_frontmatter content meta);
            Cn_hub.log_action hub_path "inbox.materialize" (Printf.sprintf "%s trigger:%s" inbox_file trigger);
            process_rejection_cleanup hub_path content;
            Some inbox_file)
      in
      (* Transition: Materializing → Materialized → Cleaned *)
      if result <> [] then begin
        let _ = advance Cn_protocol.RE_WriteOk in
        let _ = delete_remote_branch clone_path branch in
        let _ = advance Cn_protocol.RE_DeleteBranch in
        ()
      end else begin
        let _ = advance Cn_protocol.RE_WriteFail in
        ()
      end;
      result
    end
  end

let inbox_process hub_path =
  print_endline (Cn_fmt.info "Processing inbox...");
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in
  Cn_ffi.Fs.ensure_dir inbox_dir;

  let my_name = derive_name hub_path in
  let peers = Cn_hub.load_peers hub_path in
  let materialized = peers |> List.fold_left (fun acc peer ->
    match peer.kind, peer.clone with
    | Some "template", _ -> acc
    | _, None -> acc
    | _, Some clone_path ->
        if not (Cn_ffi.Fs.exists clone_path) then acc
        else begin
          let _ = Cn_ffi.Child_process.exec_in ~cwd:clone_path "git fetch origin --prune" in
          let branches = get_inbound_branches clone_path my_name in
          let files = branches |> List.concat_map (fun branch ->
            materialize_branch ~clone_path ~hub_path ~inbox_dir ~peer_name:peer.name ~branch)
          in
          acc @ files
        end
  ) [] in

  materialized |> List.iter (fun f -> print_endline (Cn_fmt.ok (Printf.sprintf "Materialized: %s" f)));
  match materialized with
  | [] -> print_endline (Cn_fmt.info "No new threads to materialize")
  | fs -> print_endline (Cn_fmt.ok (Printf.sprintf "Processed %d thread(s)" (List.length fs)))

(* === Outbox Operations === *)

let outbox_check hub_path =
  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  match Cn_ffi.Fs.exists outbox_dir with
  | false -> print_endline (Cn_fmt.ok "Outbox clear")
  | true ->
      match Cn_ffi.Fs.readdir outbox_dir |> List.filter Cn_hub.is_md_file with
      | [] -> print_endline (Cn_fmt.ok "Outbox clear")
      | ts ->
          print_endline (Cn_fmt.warn (Printf.sprintf "%d pending send(s):" (List.length ts)));
          ts |> List.iter (fun f ->
            let content = Cn_ffi.Fs.read (Cn_ffi.Path.join outbox_dir f) in
            let meta = parse_frontmatter content in
            let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
              |> Option.value ~default:"(no recipient)" in
            print_endline (Printf.sprintf "  → %s: %s" to_peer f))

let send_thread hub_path name peers outbox_dir sent_dir file =
  let file_path = Cn_ffi.Path.join outbox_dir file in
  let content = Cn_ffi.Fs.read file_path in
  let meta = parse_frontmatter content in

  let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None) in

  match to_peer with
  | None ->
      Cn_hub.log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s reason:no recipient" file);
      print_endline (Cn_fmt.warn (Printf.sprintf "Skipping %s: no 'to:' in frontmatter" file));
      None
  | Some to_name ->
      let peer = peers |> List.find_opt (fun p -> p.name = to_name) in
      match peer with
      | None ->
          Cn_hub.log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:unknown peer" file to_name);
          print_endline (Cn_fmt.fail (Printf.sprintf "Unknown peer: %s" to_name));
          None
      | Some { clone = None; _ } ->
          Cn_hub.log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:no clone path" file to_name);
          print_endline (Cn_fmt.fail (Printf.sprintf "No clone path for peer: %s" to_name));
          None
      | Some { clone = Some _clone_path; _ } ->
          (* Sender FSM: Pending → BranchCreated → Pushing → Pushed → Delivered *)
          let fsm_state = ref Cn_protocol.S_Pending in
          let advance event =
            match Cn_protocol.sender_transition !fsm_state event with
            | Ok s -> fsm_state := s; true
            | Error e ->
                print_endline (Cn_fmt.fail (Printf.sprintf "Sender FSM: %s" e)); false
          in

          let thread_name = Cn_ffi.Path.basename_ext file ".md" in
          let branch_name = Printf.sprintf "%s/%s" to_name thread_name in

          if !(Cn_fmt.dry_run_mode) then begin
            print_endline (Cn_fmt.dim (Printf.sprintf "Would: send %s to %s (branch: %s)" file to_name branch_name));
            Some file
          end else
          match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git checkout main 2>/dev/null || git checkout master" with
          | None ->
              Cn_hub.log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s error:checkout failed" to_name file);
              print_endline (Cn_fmt.fail (Printf.sprintf "Failed to send %s" file));
              None
          | Some _ ->
              (* Create branch *)
              let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch_name branch_name) in
              let thread_dir = Cn_ffi.Path.join hub_path "threads/in" in
              Cn_ffi.Fs.ensure_dir thread_dir;
              Cn_ffi.Fs.write (Cn_ffi.Path.join thread_dir file) content;
              let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git add 'threads/in/%s'" file) in
              let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m '%s: %s'" name thread_name) in
              let _ = advance Cn_protocol.SE_CreateBranch in

              (* Push *)
              let _ = advance Cn_protocol.SE_Push in
              (match Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git push -u origin %s -f" branch_name) with
               | Some _ ->
                   let _ = advance Cn_protocol.SE_PushOk in
                   ()
               | None ->
                   let _ = advance Cn_protocol.SE_PushFail in
                   ());
              let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git checkout main 2>/dev/null || git checkout master" in

              (* Cleanup: move to sent *)
              if !fsm_state = Cn_protocol.S_Pushed then begin
                Cn_ffi.Fs.write (Cn_ffi.Path.join sent_dir file)
                  (update_frontmatter content [("state", "sent"); ("sent", Cn_fmt.now_iso ())]);
                Cn_ffi.Fs.unlink file_path;
                let _ = advance Cn_protocol.SE_Cleanup in

                Cn_hub.log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s branch:%s state:%s" to_name file branch_name
                  (Cn_protocol.string_of_sender_state !fsm_state));
                print_endline (Cn_fmt.ok (Printf.sprintf "Sent to %s: %s" to_name file));
                Some file
              end else begin
                Cn_hub.log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s state:%s" to_name file
                  (Cn_protocol.string_of_sender_state !fsm_state));
                print_endline (Cn_fmt.fail (Printf.sprintf "Send failed for %s (state: %s)" file
                  (Cn_protocol.string_of_sender_state !fsm_state)));
                None
              end

let outbox_flush hub_path name =
  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  let sent_dir = Cn_hub.threads_mail_sent hub_path in

  if not (Cn_ffi.Fs.exists outbox_dir) then print_endline (Cn_fmt.ok "Outbox clear")
  else begin
    Cn_ffi.Fs.ensure_dir sent_dir;
    let threads = Cn_ffi.Fs.readdir outbox_dir |> List.filter Cn_hub.is_md_file in
    match threads with
    | [] -> print_endline (Cn_fmt.ok "Outbox clear")
    | ts ->
        print_endline (Cn_fmt.info (Printf.sprintf "Flushing %d thread(s)..." (List.length ts)));
        let peers = Cn_hub.load_peers hub_path in
        let _ = ts |> List.filter_map (send_thread hub_path name peers outbox_dir sent_dir) in
        print_endline (Cn_fmt.ok "Outbox flush complete")
  end

(* === Next Inbox Item === *)

let get_next_inbox_item hub_path =
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in
  if not (Cn_ffi.Fs.exists inbox_dir) then None
  else
    Cn_ffi.Fs.readdir inbox_dir
    |> List.filter Cn_hub.is_md_file
    |> List.sort String.compare
    |> function
      | [] -> None
      | file :: _ ->
          let file_path = Cn_ffi.Path.join inbox_dir file in
          let content = Cn_ffi.Fs.read file_path in
          let meta = parse_frontmatter content in
          let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
            |> Option.value ~default:"unknown" in
          Some (Cn_ffi.Path.basename_ext file ".md", "inbox", from, content)

let run_next hub_path =
  match get_next_inbox_item hub_path with
  | None -> print_endline "(inbox empty)"
  | Some (id, cadence, from, content) ->
      Printf.printf "[cadence: %s]\n[from: %s]\n[id: %s]\n\n%s\n" cadence from id content

(* === Inbox Flush === *)

let inbox_flush hub_path _name =
  print_endline (Cn_fmt.info "Flushing inbox (deleting processed branches)...");
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in

  if not (Cn_ffi.Fs.exists inbox_dir) then begin
    print_endline (Cn_fmt.ok "Inbox empty");
    ()
  end else begin
    let threads = Cn_ffi.Fs.readdir inbox_dir |> List.filter Cn_hub.is_md_file in

    let flushed = threads |> List.filter_map (fun file ->
      let file_path = Cn_ffi.Path.join inbox_dir file in
      let content = Cn_ffi.Fs.read file_path in
      let meta = parse_frontmatter content in

      let is_triaged =
        List.exists (fun (k, _) -> k = "reply" || k = "completed" || k = "deleted" || k = "deferred") meta in

      if not is_triaged then None
      else begin
        match List.find_map (fun (k, v) -> if k = "branch" then Some v else None) meta with
        | None -> None
        | Some branch ->
            let delete_cmd = Printf.sprintf "git push origin --delete %s 2>/dev/null || true" branch in
            let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path delete_cmd in

            let archived_dir = Cn_ffi.Path.join hub_path "threads/archived" in
            Cn_ffi.Fs.ensure_dir archived_dir;
            Cn_ffi.Fs.write (Cn_ffi.Path.join archived_dir file)
              (update_frontmatter content [("flushed", Cn_fmt.now_iso ())]);
            Cn_ffi.Fs.unlink file_path;

            Cn_hub.log_action hub_path "inbox.flush" (Printf.sprintf "branch:%s file:%s" branch file);
            print_endline (Cn_fmt.ok (Printf.sprintf "Flushed: %s" file));
            Some file
      end
    ) in

    match flushed with
    | [] -> print_endline (Cn_fmt.info "No triaged threads to flush")
    | fs -> print_endline (Cn_fmt.ok (Printf.sprintf "Flushed %d thread(s)" (List.length fs)))
  end
