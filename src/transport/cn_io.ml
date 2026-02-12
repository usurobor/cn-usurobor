(** cn_io.ml — CN protocol I/O operations

    DESIGN: This module implements CN protocol semantics over Git.
    All I/O (git operations, file writes) lives here.

    Layering (deliberate):
      cn.ml     → CLI commands, user interaction
      cn_io.ml  → Protocol execution (THIS FILE)
      cn_lib.ml → Pure types, parsing (no I/O)
      git.ml    → Raw git operations

    Why separate from cn_lib?
    - cn_lib.ml is PURE (no I/O) — fully testable with ppx_expect
    - cn_io.ml has SIDE EFFECTS — needs integration tests
    - Clear boundary: types vs execution

    Key operations:
    - sync_inbox: fetch peer branches → materialize to threads/inbox/
    - flush_outbox: threads/outbox/ → push to peer repos
    - auto_commit/auto_push: hub state management

    CN Protocol:
    - Peers push branches to each other's repos
    - Branch name = {sender}/{topic}
    - Materialization = branch content → local .md file
*)

module Path = struct
  let join = Filename.concat
  let basename = Filename.basename
end

module Fs = struct
  let exists = Sys.file_exists

  let read path =
    let ic = open_in path in
    try
      let n = in_channel_length ic in
      let s = Bytes.create n in
      really_input ic s 0 n;
      close_in ic;
      Bytes.to_string s
    with e ->
      close_in_noerr ic;
      raise e

  let write path content =
    let oc = open_out path in
    try
      output_string oc content;
      close_out oc
    with e ->
      close_out_noerr oc;
      raise e

  let readdir path = Sys.readdir path |> Array.to_list
  let readdir_list = readdir

  let unlink = Sys.remove

  let rec mkdir_p path =
    if path <> "" && path <> "/" && not (Sys.file_exists path) then begin
      mkdir_p (Filename.dirname path);
      try Unix.mkdir path 0o755
      with Unix.Unix_error (Unix.EEXIST, _, _) -> ()
    end

  let ensure_dir path = if not (exists path) then mkdir_p path
end

let is_md_file f = Filename.check_suffix f ".md"

(* === Types === *)

type peer = {
  name : string;
  hub : string option;
  clone : string option;
}

type inbound_branch = {
  peer : string;
  branch : string;
  full_ref : string;
}

type thread = {
  id : string;
  to_ : string;
  content : string;
  path : string;
}

(* === Peer Operations === *)

let get_inbound_branches ~hub ~peer_name =
  Git.remote_branches ~cwd:hub ~prefix:peer_name
  |> List.map (fun branch -> {
    peer = peer_name;
    branch = branch;
    full_ref = "origin/" ^ branch;
  })

let get_branch_files ~hub ~branch =
  Git.diff_files ~cwd:hub ~base:"main" ~head:("origin/" ^ branch)
  |> List.filter is_md_file

let get_file_content ~hub ~branch ~file =
  Git.show ~cwd:hub ~ref:("origin/" ^ branch) ~path:file

(* === Inbox Operations === *)

let materialize_branch ~hub ~inbox_dir ~peer_name ~branch =
  let files = get_branch_files ~hub ~branch in
  files |> List.filter_map (fun file ->
    match get_file_content ~hub ~branch ~file with
    | None -> None
    | Some content ->
        let topic = Path.basename file
          |> Filename.chop_suffix_opt ~suffix:".md"
          |> Option.value ~default:(Path.basename file) in
        let inbox_name = Printf.sprintf "%s-%s.md" peer_name topic in
        let inbox_path = Path.join inbox_dir inbox_name in
        let archived_path = Path.join (Path.join inbox_dir "_archived") inbox_name in

        (* Skip if already archived *)
        if Fs.exists archived_path then None
        (* Skip if already in inbox *)
        else if Fs.exists inbox_path then None
        else begin
          Fs.write inbox_path content;
          Some inbox_name
        end)

let sync_inbox ~hub ~peers =
  let _ = Git.fetch ~cwd:hub in
  let inbox_dir = Path.join hub "threads/inbox" in
  Fs.ensure_dir inbox_dir;
  Fs.ensure_dir (Path.join inbox_dir "_archived");

  peers |> List.fold_left (fun acc peer ->
    let branches = get_inbound_branches ~hub ~peer_name:peer.name in
    let materialized = branches |> List.fold_left (fun acc2 b ->
      let files = materialize_branch ~hub ~inbox_dir ~peer_name:peer.name ~branch:b.branch in
      (* Clean up local branch after processing (regardless of materialization) *)
      let _ = Git.delete_local_branch ~cwd:hub ~branch:b.branch in
      acc2 + List.length files
    ) 0 in
    acc + materialized
  ) 0

(* === Outbox Operations === *)

let parse_to_header content =
  let lines = String.split_on_char '\n' content in
  lines |> List.find_map (fun line ->
    if String.length line > 4 && String.sub line 0 4 = "to: " then
      Some (String.sub line 4 (String.length line - 4) |> String.trim)
    else None)

let send_thread ~hub:_ ~from_name ~peer ~outbox_dir ~sent_dir ~file =
  let file_path = Path.join outbox_dir file in
  let content = Fs.read file_path in

  match peer.clone with
  | None -> None
  | Some clone_path ->
      if not (Fs.exists clone_path) then None
      else begin
        let topic = Filename.chop_suffix_opt ~suffix:".md" file |> Option.value ~default:file in
        let branch_name = Printf.sprintf "%s/%s" from_name topic in
        let adhoc_dir = Path.join clone_path "threads/adhoc" in

        Fs.ensure_dir adhoc_dir;

        let _ = Git.checkout_main ~cwd:clone_path in
        let _ = Git.pull_ff ~cwd:clone_path in
        let _ = Git.checkout_create ~cwd:clone_path ~branch:branch_name in

        Fs.write (Path.join adhoc_dir file) content;

        let _ = Git.add_all ~cwd:clone_path in
        let _ = Git.commit ~cwd:clone_path ~msg:(Printf.sprintf "%s: %s" from_name topic) in
        let _ = Git.push_branch ~cwd:clone_path ~branch:branch_name ~force:true in
        let _ = Git.checkout_main ~cwd:clone_path in

        (* Move to sent *)
        let sent_path = Path.join sent_dir file in
        Fs.write sent_path content;
        Fs.unlink file_path;

        Some file
      end

let flush_outbox ~hub ~from_name ~peers =
  let outbox_dir = Path.join hub "threads/outbox" in
  let sent_dir = Path.join hub "threads/sent" in

  if not (Fs.exists outbox_dir) then 0
  else begin
    Fs.ensure_dir sent_dir;
    let threads = Fs.readdir_list outbox_dir |> List.filter is_md_file in

    threads |> List.filter_map (fun file ->
      let file_path = Path.join outbox_dir file in
      let content = Fs.read file_path in
      match parse_to_header content with
      | None -> None
      | Some to_name ->
          let peer = peers |> List.find_opt (fun p -> p.name = to_name) in
          match peer with
          | None -> None
          | Some p -> send_thread ~hub ~from_name ~peer:p ~outbox_dir ~sent_dir ~file
    ) |> List.length
  end

(* === Hub Operations === *)

let auto_commit ~hub ~msg =
  if Git.is_dirty ~cwd:hub then begin
    let _ = Git.add_all ~cwd:hub in
    Git.commit ~cwd:hub ~msg
  end else false

let auto_push ~hub =
  Git.push ~cwd:hub

let save ~hub ~msg =
  let committed = auto_commit ~hub ~msg in
  if committed then auto_push ~hub else false
