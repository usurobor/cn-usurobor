(** cn_commands.ml — Leaf user commands: peers + git

    Peer management (list/add/remove/sync) and git commands
    (commit/push/send/reply). Both are small, leaf-level commands
    with no shared primitives. Nothing depends on them except dispatch.

    Merged from: cn_peers + cn_git_cmd in the 14-module plan. *)

open Cn_lib

(* === Peer Management === *)

let format_peers_md (peers : peer_info list) : string =
  let header = "# Peers\n\nAgents and repos this hub communicates with.\n" in
  let format_peer (p : peer_info) =
    let lines = [Printf.sprintf "- name: %s" p.name] in
    let lines = match p.hub with Some h -> lines @ [Printf.sprintf "  hub: %s" h] | None -> lines in
    let lines = match p.clone with Some c -> lines @ [Printf.sprintf "  clone: %s" c] | None -> lines in
    let lines = match p.kind with Some k -> lines @ [Printf.sprintf "  kind: %s" k] | None -> lines in
    String.concat "\n" lines
  in
  let entries = peers |> List.map format_peer |> String.concat "\n\n" in
  header ^ "\n" ^ entries ^ "\n"

let run_peer_list hub_path =
  let peers : peer_info list = Cn_hub.load_peers hub_path in
  match peers with
  | [] -> print_endline "(no peers)"
  | ps ->
      let print_peer (p : peer_info) =
        let kind_str = match p.kind with Some k -> Printf.sprintf " (%s)" k | None -> "" in
        let hub_str = match p.hub with Some h -> Printf.sprintf " → %s" h | None -> "" in
        print_endline (Printf.sprintf "  %s%s%s" p.name kind_str hub_str)
      in
      ps |> List.iter print_peer

let run_peer_add hub_path peer_name url =
  let peers : peer_info list = Cn_hub.load_peers hub_path in
  let exists = List.exists (fun (p : peer_info) -> p.name = peer_name) peers in
  if exists then begin
    print_endline (Cn_fmt.fail (Printf.sprintf "Peer already exists: %s" peer_name));
    Cn_ffi.Process.exit 1
  end;

  let new_peer : peer_info = { name = peer_name; hub = Some url; clone = None; kind = None } in
  let updated = peers @ [new_peer] in
  Cn_ffi.Fs.write (Cn_ffi.Path.join hub_path "state/peers.md") (format_peers_md updated);

  Cn_hub.log_action hub_path "peer.add" (Printf.sprintf "name:%s hub:%s" peer_name url);
  print_endline (Cn_fmt.ok (Printf.sprintf "Added peer: %s" peer_name))

let run_peer_remove hub_path peer_name =
  let peers : peer_info list = Cn_hub.load_peers hub_path in
  let exists = List.exists (fun (p : peer_info) -> p.name = peer_name) peers in
  if not exists then begin
    print_endline (Cn_fmt.fail (Printf.sprintf "Peer not found: %s" peer_name));
    Cn_ffi.Process.exit 1
  end;

  let updated = List.filter (fun (p : peer_info) -> p.name <> peer_name) peers in
  Cn_ffi.Fs.write (Cn_ffi.Path.join hub_path "state/peers.md") (format_peers_md updated);

  Cn_hub.log_action hub_path "peer.remove" peer_name;
  print_endline (Cn_fmt.ok (Printf.sprintf "Removed peer: %s" peer_name))

let run_peer_sync hub_path =
  let peers = Cn_hub.load_peers hub_path in
  print_endline (Cn_fmt.info "Syncing peers...");

  peers |> List.iter (fun peer ->
    match peer.clone with
    | None -> print_endline (Cn_fmt.dim (Printf.sprintf "  %s: no clone path" peer.name))
    | Some clone_path ->
        if Cn_ffi.Fs.exists clone_path then begin
          match Cn_ffi.Child_process.exec_in ~cwd:clone_path "git fetch origin --prune && git pull --ff-only" with
          | Some _ -> print_endline (Cn_fmt.ok (Printf.sprintf "  %s: updated" peer.name))
          | None -> print_endline (Cn_fmt.warn (Printf.sprintf "  %s: fetch failed" peer.name))
        end else
          print_endline (Cn_fmt.warn (Printf.sprintf "  %s: clone not found at %s" peer.name clone_path)));

  print_endline (Cn_fmt.ok "Peer sync complete")

(* === Git Commands === *)

let run_commit hub_path name msg =
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git status --porcelain" with
  | Some status when String.trim status = "" -> print_endline (Cn_fmt.info "Nothing to commit")
  | _ ->
      let message = match msg with
        | Some m -> m
        | None -> Printf.sprintf "%s: auto-commit %s" name (String.sub (Cn_fmt.now_iso ()) 0 10)
      in
      let _ = Cn_ffi.Child_process.exec_in ~cwd:hub_path "git add -A" in
      let escaped = Js.String.replaceByRe ~regexp:[%mel.re "/\"/g"] ~replacement:"\\\"" message in
      match Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m \"%s\"" escaped) with
      | Some _ ->
          Cn_hub.log_action hub_path "commit" message;
          print_endline (Cn_fmt.ok (Printf.sprintf "Committed: %s" message))
      | None ->
          Cn_hub.log_action hub_path "commit" (Printf.sprintf "error:%s" message);
          print_endline (Cn_fmt.fail "Commit failed")

let run_push hub_path =
  match Cn_ffi.Child_process.exec_in ~cwd:hub_path "git branch --show-current" with
  | None -> print_endline (Cn_fmt.fail "Could not determine current branch")
  | Some branch ->
      let branch = String.trim branch in
      match Cn_ffi.Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git push origin %s" branch) with
      | Some _ ->
          Cn_hub.log_action hub_path "push" branch;
          print_endline (Cn_fmt.ok (Printf.sprintf "Pushed to origin/%s" branch))
      | None ->
          Cn_hub.log_action hub_path "push" "error";
          print_endline (Cn_fmt.fail "Push failed")

let run_send hub_path peer message =
  let outbox_dir = Cn_hub.threads_mail_outbox hub_path in
  Cn_ffi.Fs.ensure_dir outbox_dir;

  let slug =
    message
    |> Js.String.slice ~start:0 ~end_:30
    |> Js.String.toLowerCase
    |> Js.String.replaceByRe ~regexp:[%mel.re "/[^a-z0-9]+/g"] ~replacement:"-"
    |> Js.String.replaceByRe ~regexp:[%mel.re "/^-|-$/g"] ~replacement:""
  in
  let file_name = slug ^ ".md" in
  let first_line = match String.split_on_char '\n' message with
    | x :: _ -> x
    | [] -> message
  in
  let content = Printf.sprintf "---\nto: %s\ncreated: %s\n---\n\n# %s\n\n%s\n"
    peer (Cn_fmt.now_iso ()) first_line message in

  Cn_ffi.Fs.write (Cn_ffi.Path.join outbox_dir file_name) content;
  Cn_hub.log_action hub_path "send" (Printf.sprintf "to:%s thread:%s" peer slug);
  print_endline (Cn_fmt.ok (Printf.sprintf "Created message to %s: %s" peer slug));
  print_endline (Cn_fmt.info "Run \"cn sync\" to send")

let run_reply hub_path thread_id message =
  match Cn_gtd.find_thread hub_path thread_id with
  | None -> print_endline (Cn_fmt.fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let reply = Printf.sprintf "\n\n## Reply (%s)\n\n%s" (Cn_fmt.now_iso ()) message in
      Cn_ffi.Fs.append path reply;
      Cn_hub.log_action hub_path "reply" (Printf.sprintf "thread:%s" thread_id);
      print_endline (Cn_fmt.ok (Printf.sprintf "Replied to %s" thread_id))
