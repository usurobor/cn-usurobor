(** cn_mail.ml — Inbox/outbox mail transport

    Branch operations, orphan detection, materialization,
    inbox check/process/flush, outbox check/flush/send.
    The largest domain module — mail transport is cohesive. *)

open Cn_lib

(* === Branch Operations === *)

let delete_remote_branch hub_path ~my_name branch =
  (* Hard rule: only delete branches you own (your prefix) *)
  let prefix = my_name ^ "/" in
  let owns_branch = String.length branch > String.length prefix &&
    String.sub branch 0 (String.length prefix) = prefix in
  if not owns_branch then begin
    print_endline (Cn_fmt.fail (Printf.sprintf "BLOCKED: refusing to delete %s (not owned by %s)" branch my_name));
    Cn_hub.log_action hub_path "branch.delete.blocked" (Printf.sprintf "%s owner_check_failed" branch);
    false
  end
  else if Cn_fmt.would (Printf.sprintf "delete remote branch %s" branch) then true
  else begin
    let cmd = Printf.sprintf "git push origin --delete %s 2>/dev/null" (Filename.quote branch) in
    match Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd with
    | Some _ ->
        Cn_hub.log_action hub_path "branch.delete" branch;
        print_endline (Cn_fmt.dim (Printf.sprintf "  Deleted remote: %s" branch));
        true
    | None -> false
  end

(* === Orphan Branch Detection === *)

let is_orphan_branch hub_path branch =
  let b = Filename.quote branch in
  let cmd = Printf.sprintf "git merge-base main origin/%s 2>/dev/null || git merge-base master origin/%s 2>/dev/null" b b in
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path cmd with
  | Some _ -> false
  | None -> true

(* Deterministic rejection filename — same (peer, branch) always maps to same file.
   This prevents the amplification loop where timestamped filenames caused
   unbounded rejection messages for the same orphan branch. (#144) *)
let rejection_filename peer_name branch =
  let slug = Cn_hub.slugify branch in
  Printf.sprintf "rejected-%s-%s.md" peer_name slug

let is_already_rejected hub_path peer_name branch =
  let filename = rejection_filename peer_name branch in
  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  let sent_dir = Cn_hub.threads_mail_sent hub_path in
  Cn_ffi.Fs.exists (Cn_ffi.Path.join outbox_dir filename)
  || (Cn_ffi.Fs.exists sent_dir
      && Cn_ffi.Fs.exists (Cn_ffi.Path.join sent_dir filename))

let reject_orphan_branch hub_path peer_name branch =
  (* Use fetched peer identity (peer_name) as authoritative sender.
     git log author is informational only — not used for routing. (#144) *)
  if is_already_rejected hub_path peer_name branch then begin
    print_endline (Cn_fmt.dim (Printf.sprintf "  Already rejected: %s (from %s)" branch peer_name));
    Cn_hub.log_action hub_path "inbox.reject.dedup"
      (Printf.sprintf "branch:%s peer:%s reason:already_rejected" branch peer_name)
  end
  else if !(Cn_fmt.dry_run_mode) then begin
    print_endline (Cn_fmt.dim (Printf.sprintf "Would: reject orphan %s (from %s)" branch peer_name));
    print_endline (Cn_fmt.dim (Printf.sprintf "Would: send rejection notice to %s" peer_name))
  end else begin
    let ts = Cn_fmt.now_iso () in
    let filename = rejection_filename peer_name branch in

    let content = Printf.sprintf
      "---\nto: %s\nfrom: %s\ncreated: %s\nsubject: Branch rejected (orphan)\n---\n\n\
       Branch `%s` rejected and deleted.\n\n\
       **Reason:** No merge base with main.\n\n\
       This branch was pushed directly or from the wrong repository. \
       Branches must share a merge base with main to be accepted.\n\n\
       **Fix:**\n\
       1. Delete the orphan branch: `git branch -D %s`\n\
       2. Push `%s/{topic}` to your own hub repo so the recipient can fetch it\n"
      peer_name (derive_name hub_path) ts branch branch peer_name in

    let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
    Cn_ffi.Fs.ensure_dir outbox_dir;
    Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir filename) content;

    Cn_hub.log_action hub_path "inbox.reject"
      (Printf.sprintf "branch:%s peer:%s reason:orphan" branch peer_name);
    print_endline (Cn_fmt.fail (Printf.sprintf "Rejected orphan: %s (from %s)" branch peer_name))
  end

(* === Rejection Terminal Cleanup === *)

let parse_rejected_branch content =
  match String.split_on_char '`' content with
  | _ :: branch :: _ :: _ when String.length branch > 0
      && String.length content >= 8
      && String.sub content 0 8 = "Branch `" ->
      Some branch
  | _ -> None

let cleanup_rejected_branch hub_path branch =
  let cmd = Printf.sprintf "git branch -D %s 2>/dev/null" (Filename.quote branch) in
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
  Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" (Filename.quote my_name)
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
    (* Don't delete sender's branch — only sender deletes their own branches *)
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
      (* Don't delete sender's branch — only sender deletes their own branches *)
      print_endline (Cn_fmt.dim (Printf.sprintf "  Skipping duplicate: %s" branch));
      []
    end
    else if !(Cn_fmt.dry_run_mode) then begin
      print_endline (Cn_fmt.dim (Printf.sprintf "Would: materialize %s → %s-%s" branch peer_name branch_slug));
      print_endline (Cn_fmt.dim (Printf.sprintf "Would: delete remote branch %s" branch));
      [Cn_hub.make_thread_filename (Printf.sprintf "%s-%s" peer_name branch_slug)]
    end
    else begin
      let _ = advance Cn_protocol.RE_IsNew in

      (* Phase 0 fix (#150): pull clone main before diffing to prevent stale merge base.
         Without this, git diff main...origin/<branch> returns noise files when the
         clone's main diverges from the peer's main. *)
      let _ = Cn_ffi.Child_process.exec_in ~cwd:clone_path
        "git checkout main 2>/dev/null && git pull origin main --ff-only 2>/dev/null; git checkout - 2>/dev/null" in

      let bq = Filename.quote branch in
      (* Phase 0 fix (#150): use explicit merge-base to isolate branch-introduced files.
         Falls back to main...branch only if merge-base computation fails. *)
      let merge_base_cmd = Printf.sprintf "git merge-base main origin/%s 2>/dev/null" bq in
      let diff_cmd = match Cn_ffi.Child_process.exec_in ~cwd:clone_path merge_base_cmd with
        | Some base ->
            let base_sha = String.trim base in
            Printf.sprintf "git diff %s origin/%s --name-only" (Filename.quote base_sha) bq
        | None ->
            Printf.sprintf "git diff main...origin/%s --name-only 2>/dev/null || git diff master...origin/%s --name-only" bq bq
      in
      let files = Cn_ffi.Child_process.exec_in ~cwd:clone_path diff_cmd
        |> Option.map Cn_hub.split_lines
        |> Option.value ~default:[]
        |> List.filter (fun f ->
             String.length f > 11 &&
             String.sub f 0 11 = "threads/in/" &&
             Cn_hub.is_md_file f) in

      (* Phase 0 fix (#150): fail closed on ambiguous candidates.
         0 files = nothing to materialize (empty branch or wrong path).
         >1 files = ambiguous; refuse to guess which is the message.
         Exactly 1 file = unambiguous, proceed. *)
      match files with
      | [] ->
          Cn_trace.gemit ~component:"mail" ~layer:Body
            ~event:"inbox.reject" ~severity:Warn ~status:Degraded
            ~reason_code:"zero_candidates"
            ~details:[
              "branch", Cn_json.String branch;
              "peer", Cn_json.String peer_name;
            ] ();
          print_endline (Cn_fmt.fail (Printf.sprintf "Rejected %s: no message file in branch (zero candidates)" branch));
          Cn_hub.log_action hub_path "inbox.reject"
            (Printf.sprintf "branch:%s peer:%s reason:zero_candidates" branch peer_name);
          let _ = advance Cn_protocol.RE_WriteFail in
          []
      | _ :: _ :: _ ->
          Cn_trace.gemit ~component:"mail" ~layer:Body
            ~event:"inbox.reject" ~severity:Warn ~status:Degraded
            ~reason_code:"multiple_candidates"
            ~details:[
              "branch", Cn_json.String branch;
              "peer", Cn_json.String peer_name;
              "count", Cn_json.Int (List.length files);
              "files", Cn_json.String (String.concat ", " files);
            ] ();
          print_endline (Cn_fmt.fail (Printf.sprintf "Rejected %s: ambiguous (%d message files, expected 1)" branch (List.length files)));
          Cn_hub.log_action hub_path "inbox.reject"
            (Printf.sprintf "branch:%s peer:%s reason:multiple_candidates count:%d" branch peer_name (List.length files));
          let _ = advance Cn_protocol.RE_WriteFail in
          []
      | [file] ->
          (* Exactly one candidate — safe to materialize *)
          let trigger =
            Cn_ffi.Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git rev-parse origin/%s" (Filename.quote branch))
            |> Option.map String.trim
            |> Option.value ~default:"unknown" in

          let inbox_file = Cn_hub.make_thread_filename (Printf.sprintf "%s-%s" peer_name branch_slug) in
          let inbox_path = Cn_ffi.Path.join inbox_dir inbox_file in

          let show_cmd = Printf.sprintf "git show %s" (Filename.quote (Printf.sprintf "origin/%s:%s" branch file)) in
          (match Cn_ffi.Child_process.exec_in ~cwd:clone_path show_cmd with
          | None ->
              Cn_trace.gemit ~component:"mail" ~layer:Body
                ~event:"inbox.reject" ~severity:Warn ~status:Degraded
                ~reason_code:"content_read_failed"
                ~details:[
                  "branch", Cn_json.String branch;
                  "peer", Cn_json.String peer_name;
                  "file", Cn_json.String file;
                ] ();
              print_endline (Cn_fmt.fail (Printf.sprintf "Rejected %s: could not read message content" branch));
              let _ = advance Cn_protocol.RE_WriteFail in
              []
          | Some content ->
              let meta = [("state", "received"); ("from", peer_name); ("branch", branch);
                          ("trigger", trigger); ("file", file); ("received", Cn_fmt.now_iso ())] in
              Cn_ffi.Fs.write inbox_path (update_frontmatter content meta);
              Cn_hub.log_action hub_path "inbox.materialize" (Printf.sprintf "%s trigger:%s" inbox_file trigger);
              Cn_trace.gemit ~component:"mail" ~layer:Body
                ~event:"inbox.materialized" ~severity:Info ~status:Ok_
                ~details:[
                  "branch", Cn_json.String branch;
                  "peer", Cn_json.String peer_name;
                  "file", Cn_json.String file;
                  "inbox_file", Cn_json.String inbox_file;
                  "trigger", Cn_json.String trigger;
                ] ();
              process_rejection_cleanup hub_path content;
              let _ = advance Cn_protocol.RE_WriteOk in
              [inbox_file])
    end
  end

(* Phase 1 (#150): materialize validated packet refs.
   Packet refs live under refs/cn/msg/{sender}/{msg_id}. Each ref points to
   a root commit with packet/envelope.json + packet/message.md. Validation
   pipeline runs all checks before any inbox write. *)
let materialize_packet ~clone_path ~hub_path ~inbox_dir ~local_name ~peer_name ref_name =
  match Cn_packet.parse_packet_ref ref_name with
  | None ->
      Cn_trace.gemit ~component:"mail" ~layer:Body
        ~event:"packet.rejected" ~severity:Warn ~status:Degraded
        ~reason_code:"invalid_ref"
        ~details:["ref", Cn_json.String ref_name; "peer", Cn_json.String peer_name] ();
      None
  | Some (ref_sender, ref_msg_id) ->
      (* Convert refs/cn/msg/... to origin remote ref for reading *)
      let remote_ref = Printf.sprintf "origin/cn/msg/%s/%s" ref_sender ref_msg_id in

      (* Dedup check *)
      let index_path = Cn_ffi.Path.join hub_path "state/inbound-index.json" in
      let index = Cn_packet.load_dedup_index index_path in

      match Cn_packet.read_git_packet ~cwd:clone_path ~ref_name:remote_ref with
      | Error e ->
          Cn_trace.gemit ~component:"mail" ~layer:Body
            ~event:"packet.rejected" ~severity:Warn ~status:Degraded
            ~reason_code:e.reason_code
            ~details:["ref", Cn_json.String ref_name;
                       "peer", Cn_json.String peer_name;
                       "reason", Cn_json.String e.reason] ();
          print_endline (Cn_fmt.fail (Printf.sprintf "Packet rejected [%s]: %s" ref_name e.reason));
          None
      | Ok (envelope_json, payload_content) ->
          match Cn_packet.validate_packet ~ref_sender ~ref_msg_id
                  ~local_name ~envelope_json ~payload_content with
          | Error e ->
              Cn_trace.gemit ~component:"mail" ~layer:Body
                ~event:"packet.rejected" ~severity:Warn ~status:Degraded
                ~reason_code:e.reason_code
                ~details:["ref", Cn_json.String ref_name;
                           "msg_id", Cn_json.String ref_msg_id;
                           "peer", Cn_json.String peer_name;
                           "reason", Cn_json.String e.reason] ();
              print_endline (Cn_fmt.fail (Printf.sprintf "Packet rejected [%s]: %s" ref_msg_id e.reason));
              None
          | Ok (env, content) ->
              let payload_sha = env.Cn_packet.payload_sha256 in
              (* Dedup/equivocation check *)
              match Cn_packet.check_dedup index
                      ~msg_id:env.Cn_packet.msg_id
                      ~sender:env.Cn_packet.pkt_sender
                      ~payload_sha256:payload_sha with
              | Cn_packet.Duplicate ->
                  Cn_trace.gemit ~component:"mail" ~layer:Body
                    ~event:"packet.duplicate" ~severity:Info ~status:Ok_
                    ~details:["msg_id", Cn_json.String env.Cn_packet.msg_id;
                               "peer", Cn_json.String peer_name] ();
                  print_endline (Cn_fmt.dim (Printf.sprintf "  Duplicate packet: %s" env.Cn_packet.msg_id));
                  None
              | Cn_packet.Equivocation ->
                  Cn_trace.gemit ~component:"mail" ~layer:Body
                    ~event:"packet.equivocation" ~severity:Warn ~status:Degraded
                    ~reason_code:"equivocation"
                    ~details:["msg_id", Cn_json.String env.Cn_packet.msg_id;
                               "peer", Cn_json.String peer_name;
                               "payload_sha256", Cn_json.String payload_sha] ();
                  print_endline (Cn_fmt.fail (Printf.sprintf "EQUIVOCATION: %s from %s (different content, same msg_id)" env.Cn_packet.msg_id peer_name));
                  let entry = Cn_packet.{ dedup_msg_id = env.msg_id; dedup_sender = env.pkt_sender;
                                          dedup_payload_sha = payload_sha; dedup_status = Equivocation } in
                  Cn_packet.save_dedup_index index_path (entry :: index);
                  None
              | Cn_packet.Accepted | Cn_packet.Rejected_dedup ->
                  (* Materialize exact validated payload bytes *)
                  let topic_slug = Cn_hub.slugify env.Cn_packet.pkt_topic in
                  let inbox_file = Cn_hub.make_thread_filename (Printf.sprintf "%s-%s" peer_name topic_slug) in
                  let inbox_path = Cn_ffi.Path.join inbox_dir inbox_file in
                  let meta = [("state", "received"); ("from", peer_name);
                              ("msg_id", env.Cn_packet.msg_id);
                              ("trigger", env.Cn_packet.payload_sha256);
                              ("topic", env.Cn_packet.pkt_topic);
                              ("received", Cn_fmt.now_iso ())] in
                  Cn_ffi.Fs.write inbox_path (update_frontmatter content meta);
                  Cn_hub.log_action hub_path "packet.materialize"
                    (Printf.sprintf "%s msg_id:%s sha256:%s" inbox_file env.Cn_packet.msg_id payload_sha);
                  Cn_trace.gemit ~component:"mail" ~layer:Body
                    ~event:"packet.materialized" ~severity:Info ~status:Ok_
                    ~details:["msg_id", Cn_json.String env.Cn_packet.msg_id;
                               "peer", Cn_json.String peer_name;
                               "inbox_file", Cn_json.String inbox_file;
                               "payload_sha256", Cn_json.String payload_sha] ();
                  (* Update dedup index *)
                  let entry = Cn_packet.{ dedup_msg_id = env.msg_id; dedup_sender = env.pkt_sender;
                                          dedup_payload_sha = payload_sha; dedup_status = Accepted } in
                  Cn_packet.save_dedup_index index_path (entry :: index);
                  Some inbox_file

let inbox_process hub_path =
  print_endline (Cn_fmt.info "Processing inbox...");
  let inbox_dir = Cn_hub.threads_mail_inbox hub_path in
  Cn_ffi.Fs.ensure_dir inbox_dir;
  Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.join hub_path "state");

  let my_name = derive_name hub_path in
  let peers = Cn_hub.load_peers hub_path in
  let materialized = peers |> List.fold_left (fun acc peer ->
    match peer.kind, peer.clone with
    | Some "template", _ -> acc
    | _, None -> acc
    | _, Some clone_path ->
        if not (Cn_ffi.Fs.exists clone_path) then acc
        else begin
          (* Fetch all refs including packet namespace *)
          let _ = Cn_ffi.Child_process.exec_in ~cwd:clone_path "git fetch origin --prune" in
          let _ = Cn_ffi.Child_process.exec_in ~cwd:clone_path
            (Printf.sprintf "git fetch origin '+refs/cn/msg/%s/*:refs/remotes/origin/cn/msg/%s/*' 2>/dev/null"
              peer.name peer.name) in

          (* Phase 1: process packet refs first *)
          let packet_refs = Cn_packet.list_packet_refs ~cwd:clone_path ~sender:peer.name in
          let packet_files = packet_refs |> List.filter_map (fun ref_name ->
            materialize_packet ~clone_path ~hub_path ~inbox_dir
              ~local_name:my_name ~peer_name:peer.name ref_name) in

          (* Legacy path: process old-style branches *)
          let branches = get_inbound_branches clone_path my_name in
          let branch_files = branches |> List.concat_map (fun branch ->
            materialize_branch ~clone_path ~hub_path ~inbox_dir ~peer_name:peer.name ~branch) in

          acc @ packet_files @ branch_files
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
      Cn_trace.gemit ~component:"mail" ~layer:Body
        ~event:"outbox.skip" ~severity:Warn ~status:Degraded
        ~reason_code:"no_recipient"
        ~details:[
          "thread", Cn_json.String file;
        ] ();
      print_endline (Cn_fmt.warn (Printf.sprintf "Skipping %s: no 'to:' in frontmatter" file));
      None
  | Some to_name ->
      (* Self-send guard: prevent outbox flush when to == my_name (#144) *)
      if to_name = name then begin
        Cn_trace.gemit ~component:"mail" ~layer:Body
          ~event:"outbox.skip" ~severity:Warn ~status:Degraded
          ~reason_code:"self_send"
          ~details:[
            "thread", Cn_json.String file;
            "peer", Cn_json.String to_name;
          ] ();
        print_endline (Cn_fmt.warn (Printf.sprintf "Skipping %s: self-send (to=%s)" file to_name));
        None
      end else
      let peer = peers |> List.find_opt (fun p -> p.name = to_name) in
      match peer with
      | None ->
          Cn_trace.gemit ~component:"mail" ~layer:Body
            ~event:"outbox.skip" ~severity:Warn ~status:Degraded
            ~reason_code:"unknown_peer"
            ~details:[
              "thread", Cn_json.String file;
              "peer", Cn_json.String to_name;
            ] ();
          print_endline (Cn_fmt.fail (Printf.sprintf "Unknown peer: %s" to_name));
          None
      | Some _peer_info ->
          let ( let* ) = Result.bind in

          let thread_name = Cn_ffi.Path.basename_ext file ".md" in

          if !(Cn_fmt.dry_run_mode) then begin
            print_endline (Cn_fmt.dim (Printf.sprintf "Would: send %s to %s (packet)" file to_name));
            Some file
          end else

          (* Phase 1 (#150): send as canonical packet via refs/cn/msg/ namespace.
             Packet commits are root commits containing only packet/envelope.json
             and packet/message.md — no branch checkout needed. *)
          let msg_id = Cn_packet.make_msg_id name in
          let created_at = Cn_fmt.now_iso () in

          let send_result =
            let* s = Cn_protocol.sender_transition Cn_protocol.S_Pending Cn_protocol.SE_CreateBranch in
            let* (env, refname) = Cn_packet.create_git_packet
              ~cwd:hub_path ~sender:name ~recipient:to_name
              ~topic:thread_name ~content ~msg_id ~created_at
              |> Result.map_error (fun e -> e.Cn_packet.reason) in

            (* Push packet ref + verify *)
            let* s = Cn_protocol.sender_transition s Cn_protocol.SE_Push in
            let push_exit_ok = Cn_ffi.Child_process.exec_in ~cwd:hub_path
              (Printf.sprintf "git push origin %s -f" (Filename.quote refname))
              |> Option.is_some in
            let push_verified = push_exit_ok &&
              (Cn_ffi.Child_process.exec_in ~cwd:hub_path
                (Printf.sprintf "git ls-remote origin %s" (Filename.quote refname))
               |> Option.map (fun s -> String.length (String.trim s) > 0)
               |> Option.value ~default:false) in
            let* s = Cn_protocol.sender_transition s
              (if push_verified then Cn_protocol.SE_PushOk else Cn_protocol.SE_PushFail) in

            (* Cleanup: move to sent if pushed *)
            match s with
            | Cn_protocol.S_Pushed ->
                Cn_trace.gemit ~component:"mail" ~layer:Body
                  ~event:"packet.sent" ~severity:Info ~status:Ok_
                  ~details:[
                    "msg_id", Cn_json.String msg_id;
                    "sender", Cn_json.String name;
                    "recipient", Cn_json.String to_name;
                    "topic", Cn_json.String thread_name;
                    "payload_sha256", Cn_json.String env.Cn_packet.payload_sha256;
                    "ref", Cn_json.String refname;
                  ] ();
                Cn_ffi.Fs.write (Cn_ffi.Path.join sent_dir file)
                  (update_frontmatter content [
                    ("state", "sent"); ("sent", created_at);
                    ("msg_id", msg_id); ("payload_sha256", env.Cn_packet.payload_sha256)]);
                Cn_ffi.Fs.unlink file_path;
                let* s = Cn_protocol.sender_transition s Cn_protocol.SE_Cleanup in
                Ok (s, Some file)
            | _ ->
                Ok (s, None)
          in
          (match send_result with
           | Ok (s, result) ->
               let state_str = Cn_protocol.string_of_sender_state s in
               (match result with
                | Some _ ->
                    Cn_hub.log_action hub_path "outbox.send"
                      (Printf.sprintf "to:%s thread:%s msg_id:%s state:%s" to_name file msg_id state_str);
                    print_endline (Cn_fmt.ok (Printf.sprintf "Sent to %s: %s [%s]" to_name file msg_id))
                | None ->
                    Cn_hub.log_action hub_path "outbox.send"
                      (Printf.sprintf "to:%s thread:%s state:%s" to_name file state_str);
                    print_endline (Cn_fmt.fail (Printf.sprintf "Send failed for %s (state: %s)" file state_str)));
               result
           | Error e ->
               print_endline (Cn_fmt.fail (Printf.sprintf "Sender FSM: %s" e));
               None)

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
        | Some _branch ->
            (* Don't delete sender's branch — only sender deletes their own branches *)
            let archived_dir = Cn_ffi.Path.join hub_path "threads/archived" in
            Cn_ffi.Fs.ensure_dir archived_dir;
            Cn_ffi.Fs.write (Cn_ffi.Path.join archived_dir file)
              (update_frontmatter content [("flushed", Cn_fmt.now_iso ())]);
            Cn_ffi.Fs.unlink file_path;

            Cn_hub.log_action hub_path "inbox.flush" (Printf.sprintf "file:%s" file);
            print_endline (Cn_fmt.ok (Printf.sprintf "Flushed: %s" file));
            Some file
      end
    ) in

    match flushed with
    | [] -> print_endline (Cn_fmt.info "No triaged threads to flush")
    | fs -> print_endline (Cn_fmt.ok (Printf.sprintf "Flushed %d thread(s)" (List.length fs)))
  end
