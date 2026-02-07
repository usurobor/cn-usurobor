(** cn: Main CLI entrypoint (Melange -> Node.js).
    
    Follows FUNCTIONAL.md:
    - Pipelines over sequences
    - Fold over mutation
    - Option over exceptions
    - Effects at boundaries *)

open Cn_lib

(* === Node.js FFI Modules === *)

module Process = struct
  external argv : string array = "argv" [@@mel.scope "process"]
  external cwd : unit -> string = "cwd" [@@mel.scope "process"]
  external exit : int -> unit = "exit" [@@mel.scope "process"]
  external env : string Js.Dict.t = "env" [@@mel.scope "process"]
end

module Fs = struct
  external exists_sync : string -> bool = "existsSync" [@@mel.module "fs"]
  external read_file_sync : string -> string -> string = "readFileSync" [@@mel.module "fs"]
  external write_file_sync : string -> string -> unit = "writeFileSync" [@@mel.module "fs"]
  external append_file_sync : string -> string -> unit = "appendFileSync" [@@mel.module "fs"]
  external unlink_sync : string -> unit = "unlinkSync" [@@mel.module "fs"]
  external readdir_sync : string -> string array = "readdirSync" [@@mel.module "fs"]
  external mkdir_sync : string -> < recursive : bool > Js.t -> unit = "mkdirSync" [@@mel.module "fs"]
  
  let exists = exists_sync
  let read path = read_file_sync path "utf8"
  let write = write_file_sync
  let append = append_file_sync
  let unlink = unlink_sync
  let readdir path = readdir_sync path |> Array.to_list
  let mkdir_p path = mkdir_sync path [%mel.obj { recursive = true }]
  let ensure_dir path = if not (exists path) then mkdir_p path
end

module Path = struct
  external join : string -> string -> string = "join" [@@mel.module "path"]
  external dirname : string -> string = "dirname" [@@mel.module "path"]
  external basename : string -> string = "basename" [@@mel.module "path"]
  external basename_ext : string -> string -> string = "basename" [@@mel.module "path"]
end

module Child_process = struct
  external exec_sync : string -> < cwd : string ; encoding : string ; stdio : string array > Js.t -> string = "execSync" [@@mel.module "child_process"]
  external exec_sync_simple : string -> < encoding : string > Js.t -> string = "execSync" [@@mel.module "child_process"]
  
  let exec_in ~cwd cmd =
    match exec_sync cmd [%mel.obj { cwd; encoding = "utf8"; stdio = [|"pipe"; "pipe"; "pipe"|] }] with
    | result -> Some result
    | exception Js.Exn.Error _ -> None
  
  let exec cmd =
    match exec_sync_simple cmd [%mel.obj { encoding = "utf8" }] with
    | result -> Some result
    | exception Js.Exn.Error _ -> None
end

module Json = struct
  external stringify : 'a -> string = "stringify" [@@mel.scope "JSON"]
end

(* === Time === *)

let now_iso () = Js.Date.toISOString (Js.Date.make ())

(* === Output === *)

let no_color = Js.Dict.get Process.env "NO_COLOR" |> Option.is_some

let color code s = if no_color then s else Printf.sprintf "\027[%sm%s\027[0m" code s
let green = color "32"
let red = color "31"
let yellow = color "33"
let cyan = color "36"
let dim = color "2"

let ok msg = green "✓ " ^ msg
let fail msg = red "✗ " ^ msg
let warn msg = yellow "⚠ " ^ msg
let info = cyan

(* === Hub Detection === *)

let rec find_hub_path dir =
  match dir with
  | "/" -> None
  | _ ->
      let has_config = Fs.exists (Path.join dir ".cn/config.json") in
      let has_peers = Fs.exists (Path.join dir "state/peers.md") in
      match has_config || has_peers with
      | true -> Some dir
      | false -> find_hub_path (Path.dirname dir)

(* === Logging === *)

let log_action hub_path action details =
  let logs_dir = Path.join hub_path "logs" in
  Fs.ensure_dir logs_dir;
  let entry = [%mel.obj { ts = now_iso (); action; details }] in
  Fs.append (Path.join logs_dir "cn.log") (Json.stringify entry ^ "\n")

(* === Peers === *)

let load_peers hub_path =
  let peers_path = Path.join hub_path "state/peers.md" in
  match Fs.exists peers_path with
  | true -> parse_peers_md (Fs.read peers_path)
  | false -> []

(* === Helpers === *)

let is_md_file = ends_with ~suffix:".md"
let split_lines s = String.split_on_char '\n' s |> List.filter non_empty

(* === Result Types === *)

type branch_info = { peer: string; branch: string }

(* === Inbox Operations === *)

let get_peer_branches hub_path peer_name =
  Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" peer_name
  |> Child_process.exec_in ~cwd:hub_path
  |> Option.map split_lines
  |> Option.value ~default:[]
  |> List.map (fun branch -> { peer = peer_name; branch })

let inbox_check hub_path name =
  let _ = Child_process.exec_in ~cwd:hub_path "git fetch origin" in
  let peers = load_peers hub_path in
  
  print_endline (info (Printf.sprintf "Checking inbox for %s..." name));
  
  let total = peers |> List.fold_left (fun acc peer ->
    match peer.kind with
    | Some "template" -> acc
    | _ ->
        let branches = get_peer_branches hub_path peer.name in
        (match branches with
         | [] -> print_endline (dim (Printf.sprintf "  %s: no inbound" peer.name))
         | bs ->
             print_endline (warn (Printf.sprintf "From %s: %d inbound" peer.name (List.length bs)));
             bs |> List.iter (fun b -> print_endline (Printf.sprintf "  ← %s" b.branch)));
        acc + List.length branches
  ) 0 in
  
  if total = 0 then print_endline (ok "Inbox clear")

let materialize_branch hub_path inbox_dir peer_name branch =
  let diff_cmd = Printf.sprintf "git diff main...origin/%s --name-only 2>/dev/null || git diff master...origin/%s --name-only" branch branch in
  Child_process.exec_in ~cwd:hub_path diff_cmd
  |> Option.map split_lines
  |> Option.value ~default:[]
  |> List.filter is_md_file
  |> List.filter_map (fun file ->
      let show_cmd = Printf.sprintf "git show origin/%s:%s" branch file in
      match Child_process.exec_in ~cwd:hub_path show_cmd with
      | None -> None
      | Some content ->
          let branch_slug = match branch |> String.split_on_char '/' |> List.rev with
            | x :: _ -> x
            | [] -> branch
          in
          let inbox_file = Printf.sprintf "%s-%s.md" peer_name branch_slug in
          let inbox_path = Path.join inbox_dir inbox_file in
          match Fs.exists inbox_path with
          | true -> None
          | false ->
              let meta = [("from", peer_name); ("branch", branch); ("file", file); ("received", now_iso ())] in
              Fs.write inbox_path (update_frontmatter content meta);
              log_action hub_path "inbox.materialize" inbox_file;
              Some inbox_file)

let inbox_process hub_path =
  print_endline (info "Processing inbox...");
  let inbox_dir = Path.join hub_path "threads/inbox" in
  Fs.ensure_dir inbox_dir;
  
  let peers = load_peers hub_path in
  let materialized = peers |> List.fold_left (fun acc peer ->
    match peer.kind with
    | Some "template" -> acc
    | _ ->
        let branches = get_peer_branches hub_path peer.name in
        let files = branches |> List.concat_map (fun b ->
          materialize_branch hub_path inbox_dir peer.name b.branch)
        in
        acc @ files
  ) [] in
  
  materialized |> List.iter (fun f -> print_endline (ok (Printf.sprintf "Materialized: %s" f)));
  match materialized with
  | [] -> print_endline (info "No new threads to materialize")
  | fs -> print_endline (ok (Printf.sprintf "Processed %d thread(s)" (List.length fs)))

(* === Outbox Operations === *)

let outbox_check hub_path =
  let outbox_dir = Path.join hub_path "threads/outbox" in
  match Fs.exists outbox_dir with
  | false -> print_endline (ok "Outbox clear")
  | true ->
      match Fs.readdir outbox_dir |> List.filter is_md_file with
      | [] -> print_endline (ok "Outbox clear")
      | ts ->
          print_endline (warn (Printf.sprintf "%d pending send(s):" (List.length ts)));
          ts |> List.iter (fun f ->
            let content = Fs.read (Path.join outbox_dir f) in
            let meta = parse_frontmatter content in
            let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
              |> Option.value ~default:"(no recipient)" in
            print_endline (Printf.sprintf "  → %s: %s" to_peer f))

let send_thread hub_path name peers outbox_dir sent_dir file =
  let file_path = Path.join outbox_dir file in
  let content = Fs.read file_path in
  let meta = parse_frontmatter content in
  
  let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None) in
  
  match to_peer with
  | None ->
      log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s reason:no recipient" file);
      print_endline (warn (Printf.sprintf "Skipping %s: no 'to:' in frontmatter" file));
      None
  | Some to_name ->
      let peer = peers |> List.find_opt (fun p -> p.name = to_name) in
      match peer with
      | None ->
          log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:unknown peer" file to_name);
          print_endline (fail (Printf.sprintf "Unknown peer: %s" to_name));
          None
      | Some { clone = None; _ } ->
          log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:no clone path" file to_name);
          print_endline (fail (Printf.sprintf "No clone path for peer: %s" to_name));
          None
      | Some { clone = Some clone_path; _ } ->
          let thread_name = Path.basename_ext file ".md" in
          let branch_name = Printf.sprintf "%s/%s" name thread_name in
          
          match Child_process.exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" with
          | None ->
              log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s error:checkout failed" to_name file);
              print_endline (fail (Printf.sprintf "Failed to send %s" file));
              None
          | Some _ ->
              let _ = Child_process.exec_in ~cwd:clone_path "git pull --ff-only 2>/dev/null || true" in
              let _ = Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch_name branch_name) in
              
              let peer_thread_dir = Path.join clone_path "threads/adhoc" in
              Fs.ensure_dir peer_thread_dir;
              Fs.write (Path.join peer_thread_dir file) content;
              let _ = Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git add 'threads/adhoc/%s'" file) in
              let _ = Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git commit -m '%s: %s'" name thread_name) in
              let _ = Child_process.exec_in ~cwd:clone_path (Printf.sprintf "git push -u origin %s -f" branch_name) in
              let _ = Child_process.exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" in
              
              Fs.write (Path.join sent_dir file) (update_frontmatter content [("sent", now_iso ())]);
              Fs.unlink file_path;
              
              log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s" to_name file);
              print_endline (ok (Printf.sprintf "Sent to %s: %s" to_name file));
              Some file

let outbox_flush hub_path name =
  let outbox_dir = Path.join hub_path "threads/outbox" in
  let sent_dir = Path.join hub_path "threads/sent" in
  
  if not (Fs.exists outbox_dir) then print_endline (ok "Outbox clear")
  else begin
    Fs.ensure_dir sent_dir;
    let threads = Fs.readdir outbox_dir |> List.filter is_md_file in
    match threads with
    | [] -> print_endline (ok "Outbox clear")
    | ts ->
        print_endline (info (Printf.sprintf "Flushing %d thread(s)..." (List.length ts)));
        let peers = load_peers hub_path in
        let _ = ts |> List.filter_map (send_thread hub_path name peers outbox_dir sent_dir) in
        print_endline (ok "Outbox flush complete")
  end

(* === Next Inbox Item === *)

let get_next_inbox_item hub_path =
  let inbox_dir = Path.join hub_path "threads/inbox" in
  if not (Fs.exists inbox_dir) then None
  else
    Fs.readdir inbox_dir
    |> List.filter is_md_file
    |> List.sort String.compare
    |> function
      | [] -> None
      | file :: _ ->
          let file_path = Path.join inbox_dir file in
          let content = Fs.read file_path in
          let meta = parse_frontmatter content in
          let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
            |> Option.value ~default:"unknown" in
          Some (Path.basename_ext file ".md", "inbox", from, content)

let run_next hub_path =
  match get_next_inbox_item hub_path with
  | None -> print_endline "(inbox empty)"
  | Some (id, cadence, from, content) ->
      Printf.printf "[cadence: %s]\n[from: %s]\n[id: %s]\n\n%s\n" cadence from id content

(* === GTD Operations === *)

let find_thread hub_path thread_id =
  let locations = ["inbox"; "outbox"; "doing"; "deferred"; "daily"; "adhoc"] in
  match String.contains thread_id '/' with
  | true ->
      let path = Path.join hub_path (Printf.sprintf "threads/%s.md" thread_id) in
      (match Fs.exists path with true -> Some path | false -> None)
  | false ->
      locations |> List.find_map (fun loc ->
        let path = Path.join hub_path (Printf.sprintf "threads/%s/%s.md" loc thread_id) in
        match Fs.exists path with true -> Some path | false -> None)

let gtd_delete hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      Fs.unlink path;
      log_action hub_path "gtd.delete" thread_id;
      print_endline (ok (Printf.sprintf "Deleted: %s" thread_id))

let gtd_defer hub_path thread_id until =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let deferred_dir = Path.join hub_path "threads/deferred" in
      Fs.ensure_dir deferred_dir;
      let content = Fs.read path in
      let until_str = Option.value until ~default:"unspecified" in
      Fs.write (Path.join deferred_dir (Path.basename path)) 
        (update_frontmatter content [("deferred", now_iso ()); ("until", until_str)]);
      Fs.unlink path;
      log_action hub_path "gtd.defer" (Printf.sprintf "%s until:%s" thread_id until_str);
      let suffix = match until with Some u -> " until " ^ u | None -> "" in
      print_endline (ok (Printf.sprintf "Deferred: %s%s" thread_id suffix))

let gtd_delegate hub_path name thread_id peer =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let outbox_dir = Path.join hub_path "threads/outbox" in
      Fs.ensure_dir outbox_dir;
      let content = Fs.read path in
      Fs.write (Path.join outbox_dir (Path.basename path))
        (update_frontmatter content [("to", peer); ("delegated", now_iso ()); ("delegated-by", name)]);
      Fs.unlink path;
      log_action hub_path "gtd.delegate" (Printf.sprintf "%s to:%s" thread_id peer);
      print_endline (ok (Printf.sprintf "Delegated to %s: %s" peer thread_id));
      print_endline (info "Run \"cn sync\" to send")

let gtd_do hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let doing_dir = Path.join hub_path "threads/doing" in
      Fs.ensure_dir doing_dir;
      let content = Fs.read path in
      Fs.write (Path.join doing_dir (Path.basename path))
        (update_frontmatter content [("started", now_iso ())]);
      Fs.unlink path;
      log_action hub_path "gtd.do" thread_id;
      print_endline (ok (Printf.sprintf "Started: %s" thread_id))

let gtd_done hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let archived_dir = Path.join hub_path "threads/archived" in
      Fs.ensure_dir archived_dir;
      let content = Fs.read path in
      Fs.write (Path.join archived_dir (Path.basename path))
        (update_frontmatter content [("completed", now_iso ())]);
      Fs.unlink path;
      log_action hub_path "gtd.done" thread_id;
      print_endline (ok (Printf.sprintf "Completed: %s → archived" thread_id))

(* === Read Thread === *)

let run_read hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let content = Fs.read path in
      let cadence = cadence_of_path path |> string_of_cadence in
      let meta = parse_frontmatter content in
      Printf.printf "[cadence: %s]\n" cadence;
      meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
        |> Option.iter (Printf.printf "[from: %s]\n");
      meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
        |> Option.iter (Printf.printf "[to: %s]\n");
      print_endline "";
      print_endline content

(* === Inbox/Outbox List === *)

let run_inbox_list hub_path =
  let inbox_dir = Path.join hub_path "threads/inbox" in
  if not (Fs.exists inbox_dir) then print_endline "(empty)"
  else
    match Fs.readdir inbox_dir |> List.filter is_md_file with
    | [] -> print_endline "(empty)"
    | ts -> ts |> List.iter (fun f ->
        let id = Path.basename_ext f ".md" in
        let meta = Fs.read (Path.join inbox_dir f) |> parse_frontmatter in
        let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
          |> Option.value ~default:"unknown" in
        Printf.printf "%s/%s\n" from id)

let run_outbox_list hub_path =
  let outbox_dir = Path.join hub_path "threads/outbox" in
  if not (Fs.exists outbox_dir) then print_endline "(empty)"
  else
    match Fs.readdir outbox_dir |> List.filter is_md_file with
    | [] -> print_endline "(empty)"
    | ts -> ts |> List.iter (fun f ->
        let id = Path.basename_ext f ".md" in
        let meta = Fs.read (Path.join outbox_dir f) |> parse_frontmatter in
        let to_peer = meta |> List.find_map (fun (k, v) -> if k = "to" then Some v else None)
          |> Option.value ~default:"unknown" in
        Printf.printf "→ %s  \"%s\"\n" to_peer id)

(* === Git Operations === *)

let run_commit hub_path name msg =
  match Child_process.exec_in ~cwd:hub_path "git status --porcelain" with
  | Some status when String.trim status = "" -> print_endline (info "Nothing to commit")
  | _ ->
      let message = match msg with
        | Some m -> m
        | None -> Printf.sprintf "%s: auto-commit %s" name (String.sub (now_iso ()) 0 10)
      in
      let _ = Child_process.exec_in ~cwd:hub_path "git add -A" in
      let escaped = Js.String.replaceByRe ~regexp:[%mel.re "/\"/g"] ~replacement:"\\\"" message in
      match Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git commit -m \"%s\"" escaped) with
      | Some _ ->
          log_action hub_path "commit" message;
          print_endline (ok (Printf.sprintf "Committed: %s" message))
      | None ->
          log_action hub_path "commit" (Printf.sprintf "error:%s" message);
          print_endline (fail "Commit failed")

let run_push hub_path =
  match Child_process.exec_in ~cwd:hub_path "git branch --show-current" with
  | None -> print_endline (fail "Could not determine current branch")
  | Some branch ->
      let branch = String.trim branch in
      match Child_process.exec_in ~cwd:hub_path (Printf.sprintf "git push origin %s" branch) with
      | Some _ ->
          log_action hub_path "push" branch;
          print_endline (ok (Printf.sprintf "Pushed to origin/%s" branch))
      | None ->
          log_action hub_path "push" "error";
          print_endline (fail "Push failed")

(* === Send Message === *)

let run_send hub_path peer message =
  let outbox_dir = Path.join hub_path "threads/outbox" in
  Fs.ensure_dir outbox_dir;
  
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
    peer (now_iso ()) first_line message in
  
  Fs.write (Path.join outbox_dir file_name) content;
  log_action hub_path "send" (Printf.sprintf "to:%s thread:%s" peer slug);
  print_endline (ok (Printf.sprintf "Created message to %s: %s" peer slug));
  print_endline (info "Run \"cn sync\" to send")

(* === Reply === *)

let run_reply hub_path thread_id message =
  match find_thread hub_path thread_id with
  | None -> print_endline (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let reply = Printf.sprintf "\n\n## Reply (%s)\n\n%s" (now_iso ()) message in
      Fs.append path reply;
      log_action hub_path "reply" (Printf.sprintf "thread:%s" thread_id);
      print_endline (ok (Printf.sprintf "Replied to %s" thread_id))

(* === Status === *)

let run_status hub_path name =
  print_endline (info (Printf.sprintf "cn hub: %s" name));
  print_endline "";
  Printf.printf "hub..................... %s\n" (green "✓");
  Printf.printf "name.................... %s %s\n" (green "✓") name;
  Printf.printf "path.................... %s %s\n" (green "✓") hub_path;
  print_endline "";
  print_endline (dim (Printf.sprintf "[status] ok version=%s" version))

(* === Doctor === *)

type check_result = { name: string; passed: bool; value: string }

let run_doctor hub_path =
  Printf.printf "cn v%s\n" version;
  print_endline (info "Checking health...");
  print_endline "";
  
  let checks = [
    (match Child_process.exec "git --version" with
     | Some v -> { name = "git"; passed = true; value = Js.String.replace ~search:"git version " ~replacement:"" (String.trim v) }
     | None -> { name = "git"; passed = false; value = "not installed" });
    
    (match Child_process.exec "git config user.name" with
     | Some v -> { name = "git user.name"; passed = true; value = String.trim v }
     | None -> { name = "git user.name"; passed = false; value = "not set" });
    
    (match Child_process.exec "git config user.email" with
     | Some v -> { name = "git user.email"; passed = true; value = String.trim v }
     | None -> { name = "git user.email"; passed = false; value = "not set" });
    
    { name = "hub directory"; passed = Fs.exists hub_path; 
      value = if Fs.exists hub_path then "exists" else "not found" };
    
    (let p = Path.join hub_path ".cn/config.json" in
     { name = ".cn/config.json"; passed = Fs.exists p; 
       value = if Fs.exists p then "exists" else "missing" });
    
    (let p = Path.join hub_path "spec/SOUL.md" in
     { name = "spec/SOUL.md"; passed = Fs.exists p; 
       value = if Fs.exists p then "exists" else "missing (optional)" });
    
    (let p = Path.join hub_path "state/peers.md" in
     if Fs.exists p then
       let count = Js.String.match_ ~regexp:[%mel.re "/- name:/g"] (Fs.read p)
         |> Option.map Array.length |> Option.value ~default:0 in
       { name = "state/peers.md"; passed = true; value = Printf.sprintf "%d peer(s)" count }
     else { name = "state/peers.md"; passed = false; value = "missing" });
    
    (match Child_process.exec_in ~cwd:hub_path "git remote get-url origin" with
     | Some _ -> { name = "origin remote"; passed = true; value = "configured" }
     | None -> { name = "origin remote"; passed = false; value = "not configured" });
  ] in
  
  let width = 22 in
  checks |> List.iter (fun c ->
    let dots = String.make (max 1 (width - String.length c.name)) '.' in
    let status = if c.passed then green ("✓ " ^ c.value) else red ("✗ " ^ c.value) in
    Printf.printf "%s%s %s\n" c.name dots status);
  
  print_endline "";
  let fails = checks |> List.filter (fun c -> not c.passed) |> List.length in
  let oks = List.length checks - fails in
  (if fails = 0 then print_endline (ok "All critical checks passed.")
   else print_endline (fail (Printf.sprintf "%d issue(s) found." fails)));
  print_endline (dim (Printf.sprintf "[status] ok=%d warn=0 fail=%d version=%s" oks fails version))

(* === Queue Operations === *)

let queue_dir hub_path = Path.join hub_path "state/queue"

let queue_add hub_path id from content =
  let dir = queue_dir hub_path in
  Fs.ensure_dir dir;
  
  (* Timestamp-based filename for FIFO ordering *)
  let ts = now_iso () |> Js.String.replaceByRe ~regexp:[%mel.re "/[:.]/g"] ~replacement:"-" in
  let file_name = Printf.sprintf "%s-%s-%s.md" ts from id in
  let file_path = Path.join dir file_name in
  
  let queued_content = Printf.sprintf "---\nid: %s\nfrom: %s\nqueued: %s\n---\n\n%s" 
    id from (now_iso ()) content in
  Fs.write file_path queued_content;
  
  log_action hub_path "queue.add" (Printf.sprintf "id:%s from:%s" id from);
  file_name

let queue_pop hub_path =
  let dir = queue_dir hub_path in
  if not (Fs.exists dir) then None
  else
    Fs.readdir dir
    |> List.filter is_md_file
    |> List.sort String.compare  (* FIFO: oldest first *)
    |> function
      | [] -> None
      | file :: _ ->
          let file_path = Path.join dir file in
          let content = Fs.read file_path in
          Fs.unlink file_path;
          Some content

let queue_count hub_path =
  let dir = queue_dir hub_path in
  if not (Fs.exists dir) then 0
  else Fs.readdir dir |> List.filter is_md_file |> List.length

let queue_list hub_path =
  let dir = queue_dir hub_path in
  if not (Fs.exists dir) then []
  else Fs.readdir dir |> List.filter is_md_file |> List.sort String.compare

(* === IO Paths === *)

let input_path hub_path = Path.join hub_path "state/input.md"
let output_path hub_path = Path.join hub_path "state/output.md"
let logs_input_dir hub_path = Path.join hub_path "logs/input"
let logs_output_dir hub_path = Path.join hub_path "logs/output"

(* === Get ID from file === *)

let get_file_id path =
  if not (Fs.exists path) then None
  else
    let content = Fs.read path in
    let meta = parse_frontmatter content in
    meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)

(* === Archive completed IO pair === *)

let archive_io_pair hub_path =
  let inp = input_path hub_path in
  let outp = output_path hub_path in
  
  match get_file_id inp, get_file_id outp with
  | Some input_id, Some output_id when input_id = output_id ->
      (* IDs match - archive both *)
      let logs_in = logs_input_dir hub_path in
      let logs_out = logs_output_dir hub_path in
      Fs.ensure_dir logs_in;
      Fs.ensure_dir logs_out;
      
      let archive_name = input_id ^ ".md" in
      Fs.write (Path.join logs_in archive_name) (Fs.read inp);
      Fs.write (Path.join logs_out archive_name) (Fs.read outp);
      Fs.unlink inp;
      Fs.unlink outp;
      
      log_action hub_path "io.archive" (Printf.sprintf "id:%s" input_id);
      print_endline (ok (Printf.sprintf "Archived IO pair: %s" input_id));
      true
  | Some _, Some _ ->
      print_endline (fail "ID mismatch between input.md and output.md");
      false
  | Some _, None ->
      (* Input exists but no output yet - agent still working *)
      false
  | None, Some _ ->
      (* Output without input - orphan, shouldn't happen *)
      print_endline (warn "Orphan output.md found (no input.md)");
      false
  | None, None ->
      (* Neither exists - ready for new work *)
      true

(* === Queue inbox items === *)

let queue_inbox_items hub_path =
  let inbox_dir = Path.join hub_path "threads/inbox" in
  if not (Fs.exists inbox_dir) then 0
  else
    Fs.readdir inbox_dir
    |> List.filter is_md_file
    |> List.filter_map (fun file ->
        let file_path = Path.join inbox_dir file in
        let content = Fs.read file_path in
        let meta = parse_frontmatter content in
        
        let is_queued = List.exists (fun (k, _) -> k = "queued-for-processing") meta in
        if is_queued then None
        else begin
          let id = Path.basename_ext file ".md" in
          let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
            |> Option.value ~default:"unknown" in
          
          let _ = queue_add hub_path id from content in
          Fs.write file_path (update_frontmatter content [("queued-for-processing", now_iso ())]);
          
          print_endline (ok (Printf.sprintf "Queued: %s (from %s)" id from));
          Some file
        end)
    |> List.length

(* === Feed next input === *)

let feed_next_input hub_path =
  let inp = input_path hub_path in
  
  match queue_pop hub_path with
  | None -> 
      print_endline (ok "Queue empty - nothing to process");
      false
  | Some content ->
      Fs.ensure_dir (Path.join hub_path "state");
      Fs.write inp content;
      
      let meta = parse_frontmatter content in
      let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
        |> Option.value ~default:"unknown" in
      let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
        |> Option.value ~default:"unknown" in
      
      log_action hub_path "process.feed" (Printf.sprintf "id:%s from:%s" id from);
      print_endline (ok (Printf.sprintf "Wrote state/input.md: %s (from %s)" id from));
      
      let remaining = queue_count hub_path in
      if remaining > 0 then
        print_endline (info (Printf.sprintf "Queue depth: %d remaining" remaining));
      
      true

(* === Wake agent === *)

let wake_agent () =
  print_endline (info "Triggering OpenClaw wake...");
  let wake_cmd = "curl -s -X POST http://localhost:18789/cron/wake -H 'Content-Type: application/json' -d '{\"text\":\"input.md ready\",\"mode\":\"now\"}'" in
  match Child_process.exec wake_cmd with
  | Some _ -> print_endline (ok "Wake triggered")
  | None -> print_endline (warn "Wake trigger failed - is OpenClaw running?")

(* === Process (Actor Loop) === *)

let run_process hub_path =
  print_endline (info "cn process: actor loop...");
  
  (* Step 1: Queue any new inbox items *)
  let queued = queue_inbox_items hub_path in
  if queued > 0 then
    print_endline (info (Printf.sprintf "Added %d item(s) to queue" queued));
  
  (* Step 2: Check if completed IO pair exists, archive if so *)
  let inp = input_path hub_path in
  let outp = output_path hub_path in
  
  if Fs.exists inp && Fs.exists outp then begin
    (* Agent completed work - archive and continue *)
    if archive_io_pair hub_path then begin
      (* Feed next input *)
      if feed_next_input hub_path then wake_agent ()
    end
  end
  else if Fs.exists inp then begin
    (* Input exists but no output - agent still working *)
    print_endline (info "Agent working (input.md exists, awaiting output.md)");
    print_endline (info (Printf.sprintf "Queue depth: %d" (queue_count hub_path)))
  end
  else begin
    (* No input - feed next *)
    if feed_next_input hub_path then wake_agent ()
  end

(* === Sync === *)

let run_sync hub_path name =
  print_endline (info "Syncing...");
  inbox_check hub_path name;
  inbox_process hub_path;
  outbox_flush hub_path name;
  print_endline (ok "Sync complete")

(* === Queue Commands === *)

let run_queue_list hub_path =
  let items = queue_list hub_path in
  match items with
  | [] -> print_endline "(queue empty)"
  | _ ->
      print_endline (info (Printf.sprintf "Queue depth: %d" (List.length items)));
      items |> List.iter (fun file ->
        let file_path = Path.join (queue_dir hub_path) file in
        let content = Fs.read file_path in
        let meta = parse_frontmatter content in
        let id = meta |> List.find_map (fun (k, v) -> if k = "id" then Some v else None)
          |> Option.value ~default:"?" in
        let from = meta |> List.find_map (fun (k, v) -> if k = "from" then Some v else None)
          |> Option.value ~default:"?" in
        print_endline (Printf.sprintf "  %s (from %s)" id from))

let run_queue_clear hub_path =
  let dir = queue_dir hub_path in
  if not (Fs.exists dir) then print_endline (ok "Queue already empty")
  else
    let items = Fs.readdir dir |> List.filter is_md_file in
    items |> List.iter (fun file -> Fs.unlink (Path.join dir file));
    log_action hub_path "queue.clear" (Printf.sprintf "count:%d" (List.length items));
    print_endline (ok (Printf.sprintf "Cleared %d item(s) from queue" (List.length items)))

(* === Init === *)

let run_init name =
  let hub_name = match name with
    | Some n -> n
    | None -> Path.basename (Process.cwd ())
  in
  let hub_dir = "cn-" ^ hub_name in
  
  if Fs.exists hub_dir then begin
    print_endline (fail (Printf.sprintf "Directory %s already exists" hub_dir));
    Process.exit 1
  end;
  
  print_endline (info (Printf.sprintf "Initializing hub: %s" hub_name));
  
  (* Create directory structure *)
  Fs.mkdir_p hub_dir;
  Fs.mkdir_p (Path.join hub_dir ".cn");
  Fs.mkdir_p (Path.join hub_dir "spec");
  Fs.mkdir_p (Path.join hub_dir "state");
  Fs.mkdir_p (Path.join hub_dir "threads/inbox");
  Fs.mkdir_p (Path.join hub_dir "threads/outbox");
  Fs.mkdir_p (Path.join hub_dir "threads/daily");
  Fs.mkdir_p (Path.join hub_dir "threads/adhoc");
  Fs.mkdir_p (Path.join hub_dir "threads/archived");
  Fs.mkdir_p (Path.join hub_dir "logs");
  
  (* Create config *)
  let config = Printf.sprintf {|{
  "name": "%s",
  "version": "1.0.0",
  "created": "%s"
}|} hub_name (now_iso ()) in
  Fs.write (Path.join hub_dir ".cn/config.json") config;
  
  (* Create SOUL.md template *)
  let soul = Printf.sprintf {|# SOUL.md - Core Contract

*%s is an agent on the Coherent Network.*

## Identity

- **Name:** %s
- **Role:** (define your role)
- **Mode:** Collaborative

## What %s Does

- (define responsibilities)

## Conduct

- Be genuinely helpful
- Be resourceful before asking
- Earn trust through competence
|} hub_name hub_name hub_name in
  Fs.write (Path.join hub_dir "spec/SOUL.md") soul;
  
  (* Create USER.md template *)
  let user = {|# USER.md - About Your Human

- **Name:** (your human's name)
- **Timezone:** (timezone)

## Preferences

- **Communication:** (style)
- **Autonomy:** (level)
|} in
  Fs.write (Path.join hub_dir "spec/USER.md") user;
  
  (* Create peers.md *)
  let peers = Printf.sprintf {|# Peers

Agents and repos this hub communicates with.

- name: cn-agent
  hub: https://github.com/usurobor/cn-agent.git
  kind: template
|} in
  Fs.write (Path.join hub_dir "state/peers.md") peers;
  
  (* Initialize git *)
  let _ = Child_process.exec_in ~cwd:hub_dir "git init" in
  let _ = Child_process.exec_in ~cwd:hub_dir "git add -A" in
  let _ = Child_process.exec_in ~cwd:hub_dir (Printf.sprintf "git commit -m 'Initialize %s hub'" hub_name) in
  
  (* Write runtime.md *)
  update_runtime hub_dir;
  
  print_endline (ok (Printf.sprintf "Created hub: %s" hub_dir));
  print_endline (info "Next steps:");
  print_endline (Printf.sprintf "  cd %s" hub_dir);
  print_endline "  git remote add origin <your-repo-url>";
  print_endline "  git push -u origin main"

(* === Peer Commands === *)

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
  let peers : peer_info list = load_peers hub_path in
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
  let peers : peer_info list = load_peers hub_path in
  let exists = List.exists (fun (p : peer_info) -> p.name = peer_name) peers in
  if exists then begin
    print_endline (fail (Printf.sprintf "Peer already exists: %s" peer_name));
    Process.exit 1
  end;
  
  let new_peer : peer_info = { name = peer_name; hub = Some url; clone = None; kind = None } in
  let updated = peers @ [new_peer] in
  Fs.write (Path.join hub_path "state/peers.md") (format_peers_md updated);
  
  log_action hub_path "peer.add" (Printf.sprintf "name:%s hub:%s" peer_name url);
  print_endline (ok (Printf.sprintf "Added peer: %s" peer_name))

let run_peer_remove hub_path peer_name =
  let peers : peer_info list = load_peers hub_path in
  let exists = List.exists (fun (p : peer_info) -> p.name = peer_name) peers in
  if not exists then begin
    print_endline (fail (Printf.sprintf "Peer not found: %s" peer_name));
    Process.exit 1
  end;
  
  let updated = List.filter (fun (p : peer_info) -> p.name <> peer_name) peers in
  Fs.write (Path.join hub_path "state/peers.md") (format_peers_md updated);
  
  log_action hub_path "peer.remove" peer_name;
  print_endline (ok (Printf.sprintf "Removed peer: %s" peer_name))

let run_peer_sync hub_path =
  let peers = load_peers hub_path in
  print_endline (info "Syncing peers...");
  
  peers |> List.iter (fun peer ->
    match peer.clone with
    | None -> print_endline (dim (Printf.sprintf "  %s: no clone path" peer.name))
    | Some clone_path ->
        if Fs.exists clone_path then begin
          match Child_process.exec_in ~cwd:clone_path "git fetch origin && git pull --ff-only" with
          | Some _ -> print_endline (ok (Printf.sprintf "  %s: updated" peer.name))
          | None -> print_endline (warn (Printf.sprintf "  %s: fetch failed" peer.name))
        end else
          print_endline (warn (Printf.sprintf "  %s: clone not found at %s" peer.name clone_path)));
  
  print_endline (ok "Peer sync complete")

(* === Inbox Flush (delete processed branches) === *)

let inbox_flush hub_path _name =
  print_endline (info "Flushing inbox (deleting processed branches)...");
  let inbox_dir = Path.join hub_path "threads/inbox" in
  
  if not (Fs.exists inbox_dir) then begin
    print_endline (ok "Inbox empty");
    ()
  end else begin
    let threads = Fs.readdir inbox_dir |> List.filter is_md_file in
    
    (* For each materialized thread, check if it's been triaged (has reply/completed marker) *)
    let flushed = threads |> List.filter_map (fun file ->
      let file_path = Path.join inbox_dir file in
      let content = Fs.read file_path in
      let meta = parse_frontmatter content in
      
      (* Check if triaged *)
      let is_triaged = 
        List.exists (fun (k, _) -> k = "reply" || k = "completed" || k = "deleted" || k = "deferred") meta in
      
      if not is_triaged then None
      else begin
        (* Get the branch name and delete it from origin *)
        match List.find_map (fun (k, v) -> if k = "branch" then Some v else None) meta with
        | None -> None
        | Some branch ->
            let delete_cmd = Printf.sprintf "git push origin --delete %s 2>/dev/null || true" branch in
            let _ = Child_process.exec_in ~cwd:hub_path delete_cmd in
            
            (* Move to archived *)
            let archived_dir = Path.join hub_path "threads/archived" in
            Fs.ensure_dir archived_dir;
            Fs.write (Path.join archived_dir file) 
              (update_frontmatter content [("flushed", now_iso ())]);
            Fs.unlink file_path;
            
            log_action hub_path "inbox.flush" (Printf.sprintf "branch:%s file:%s" branch file);
            print_endline (ok (Printf.sprintf "Flushed: %s" file));
            Some file
      end
    ) in
    
    match flushed with
    | [] -> print_endline (info "No triaged threads to flush")
    | fs -> print_endline (ok (Printf.sprintf "Flushed %d thread(s)" (List.length fs)))
  end

(* === Update === *)

let update_cron hub_path =
  let cron_line = Printf.sprintf "*/5 * * * * cd %s && cn sync && cn process >> /var/log/cn.log 2>&1" hub_path in
  print_endline (info "Updating crontab (5 min intervals)...");
  let cmd = Printf.sprintf "echo '%s' | crontab -" cron_line in
  match Child_process.exec cmd with
  | Some _ -> print_endline (ok "Crontab updated")
  | None -> print_endline (warn "Crontab update failed - update manually")

let update_runtime hub_path =
  let runtime_path = Path.join hub_path "state/runtime.md" in
  let cn_ver = match Child_process.exec "cn --version 2>/dev/null" with
    | Some v -> String.trim v |> fun s -> 
        (match String.split_on_char ' ' s with 
         | _ :: v :: _ -> v 
         | _ -> "unknown")
    | None -> "unknown"
  in
  let oc_ver = match Child_process.exec "openclaw --version 2>/dev/null" with
    | Some v -> String.trim v
    | None -> "unknown"
  in
  let hub_name = derive_name hub_path in
  let hub_commit = match Child_process.exec_in ~cwd:hub_path "git rev-parse --short HEAD 2>/dev/null" with
    | Some c -> String.trim c
    | None -> "unknown"
  in
  let cn_commit = match Child_process.exec "git -C $(npm root -g)/cnagent rev-parse --short HEAD 2>/dev/null" with
    | Some c -> String.trim c
    | None -> "unknown"
  in
  let peers_path = Path.join hub_path "state/peers.md" in
  let peer_count = match Fs.exists peers_path with
    | true -> 
        let content = Fs.read peers_path in
        let lines = String.split_on_char '\n' content in
        lines |> List.filter (fun l -> String.length l > 2 && String.sub l 0 2 = "- ") |> List.length
    | false -> 0
  in
  let content = Printf.sprintf {|# Runtime State

Auto-generated by `cn update`. Do not edit manually.

```yaml
session_start: %s
cn_version: %s
cn_commit: %s
template_version: %s
openclaw_version: %s
hub_name: %s
hub_commit: %s
peer_count: %d
```
|} (now_iso ()) cn_ver cn_commit cn_ver oc_ver hub_name hub_commit peer_count in
  Fs.write runtime_path content;
  print_endline (ok "Updated state/runtime.md")

let run_update () =
  print_endline (info "Checking for updates...");
  
  (* Get current version *)
  print_endline (Printf.sprintf "Current version: %s" version);
  
  (* Check latest version *)
  match Child_process.exec "npm view cnagent version 2>/dev/null" with
  | None ->
      print_endline (fail "Could not check npm registry");
      Process.exit 1
  | Some latest_raw ->
      let latest = String.trim latest_raw in
      match latest = version with
      | true -> print_endline (ok "Already up to date")
      | false ->
          print_endline (info (Printf.sprintf "New version available: %s" latest));
          print_endline (info "Updating...");
          match Child_process.exec "npm install -g cnagent@latest" with
          | Some _ -> print_endline (ok (Printf.sprintf "Updated to v%s" latest))
          | None -> print_endline (fail "Update failed. Try: npm install -g cnagent@latest")

let run_update_with_cron hub_path =
  run_update ();
  update_cron hub_path;
  update_runtime hub_path

(* === Main === *)

let drop n lst =
  let rec go n lst = match n, lst with
    | 0, lst -> lst
    | _, [] -> []
    | n, _ :: rest -> go (n - 1) rest
  in go n lst

let () =
  let args = Process.argv |> Array.to_list |> drop 2 in
  let flags, cmd_args = parse_flags args in
  let _ = flags in
  
  match parse_command cmd_args with
  | None ->
      (match cmd_args with cmd :: _ -> print_endline (fail (Printf.sprintf "Unknown command: %s" cmd)) | [] -> ());
      print_endline help_text;
      Process.exit 1
  | Some Help -> print_endline help_text
  | Some Version -> Printf.printf "cn %s\n" version
  | Some Update ->
      (match find_hub_path (Process.cwd ()) with
       | Some hub_path -> run_update_with_cron hub_path
       | None -> run_update ())
  | Some (Init name) -> run_init name
  | Some cmd ->
      match find_hub_path (Process.cwd ()) with
      | None ->
          print_endline (fail "Not in a cn hub.");
          print_endline "";
          print_endline "Either:";
          print_endline "  1) cd into an existing hub (cn-sigma, cn-pi, etc.)";
          print_endline "  2) cn init <name> to create a new one";
          Process.exit 1
      | Some hub_path ->
          let name = derive_name hub_path in
          match cmd with
          | Status -> run_status hub_path name
          | Doctor -> run_doctor hub_path
          | Inbox Inbox_check -> inbox_check hub_path name
          | Inbox Inbox_process -> inbox_process hub_path
          | Inbox Inbox_flush -> inbox_flush hub_path name
          | Outbox Outbox_check -> outbox_check hub_path
          | Outbox Outbox_flush -> outbox_flush hub_path name
          | Sync -> run_sync hub_path name
          | Next -> run_next hub_path
          | Process -> run_process hub_path
          | Read t -> run_read hub_path t
          | Reply (t, m) -> run_reply hub_path t m
          | Send (p, m) -> run_send hub_path p m
          | Gtd (GtdDelete t) -> gtd_delete hub_path t
          | Gtd (GtdDefer (t, u)) -> gtd_defer hub_path t u
          | Gtd (GtdDelegate (t, p)) -> gtd_delegate hub_path name t p
          | Gtd (GtdDo t) -> gtd_do hub_path t
          | Gtd (GtdDone t) -> gtd_done hub_path t
          | Commit msg -> run_commit hub_path name msg
          | Push -> run_push hub_path
          | Save msg -> run_commit hub_path name msg; run_push hub_path
          | Peer Peer_list -> run_peer_list hub_path
          | Peer (Peer_add (n, url)) -> run_peer_add hub_path n url
          | Peer (Peer_remove n) -> run_peer_remove hub_path n
          | Peer Peer_sync -> run_peer_sync hub_path
          | Queue Queue_list -> run_queue_list hub_path
          | Queue Queue_clear -> run_queue_clear hub_path
          | Help | Version | Init _ | Update -> () (* handled above *)
