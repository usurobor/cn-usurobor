(** cn: Main CLI entrypoint (Melange -> Node.js).
    
    Usage: cn <command> [subcommand] [options] *)

open Cn_lib

(* === Node.js FFI bindings === *)

external process_argv : string array = "argv" [@@mel.scope "process"]
external process_cwd : unit -> string = "cwd" [@@mel.scope "process"]
external process_exit : int -> unit = "exit" [@@mel.scope "process"]
external process_env : string Js.Dict.t = "env" [@@mel.scope "process"]

(* fs module *)
external fs_existsSync : string -> bool = "existsSync" [@@mel.module "fs"]
external fs_readFileSync : string -> string -> string = "readFileSync" [@@mel.module "fs"]
external fs_writeFileSync : string -> string -> unit = "writeFileSync" [@@mel.module "fs"]
external fs_appendFileSync : string -> string -> unit = "appendFileSync" [@@mel.module "fs"]
external fs_unlinkSync : string -> unit = "unlinkSync" [@@mel.module "fs"]
external fs_readdirSync : string -> string array = "readdirSync" [@@mel.module "fs"]
external fs_mkdirSync : string -> < recursive : bool > Js.t -> unit = "mkdirSync" [@@mel.module "fs"]
type fs_stats
external fs_statSync : string -> fs_stats = "statSync" [@@mel.module "fs"]
external fs_stats_isDirectory : fs_stats -> bool = "isDirectory" [@@mel.send]
external fs_rmSync : string -> < recursive : bool > Js.t -> unit = "rmSync" [@@mel.module "fs"]

(* path module *)
external path_join2 : string -> string -> string = "join" [@@mel.module "path"]
let path_join = path_join2
external path_dirname : string -> string = "dirname" [@@mel.module "path"]
external path_basename : string -> string = "basename" [@@mel.module "path"]
external path_basename_ext : string -> string -> string = "basename" [@@mel.module "path"]
external path_isAbsolute : string -> bool = "isAbsolute" [@@mel.module "path"]

(* child_process module *)
external execSync : string -> < cwd : string ; encoding : string ; stdio : string array > Js.t -> string = "execSync" [@@mel.module "child_process"]
external execSync_simple : string -> < encoding : string > Js.t -> string = "execSync" [@@mel.module "child_process"]

(* Date - use Js.Date from melange stdlib *)
let now_date () = Js.Date.make ()

(* JSON *)
external json_stringify : 'a -> string = "stringify" [@@mel.scope "JSON"]
external json_parse : string -> 'a = "parse" [@@mel.scope "JSON"]

(* === Helpers === *)

let now_iso () = Js.Date.toISOString (now_date ())
let today_str () = String.sub (now_iso ()) 0 10 |> String.split_on_char '-' |> String.concat ""

let file_exists = fs_existsSync
let read_file path = fs_readFileSync path "utf8"
let write_file path content = fs_writeFileSync path content
let append_file path content = fs_appendFileSync path content
let mkdir_p path = fs_mkdirSync path [%mel.obj { recursive = true }]
let is_dir path = file_exists path && fs_stats_isDirectory (fs_statSync path)
let readdir path = Array.to_list (fs_readdirSync path)

let no_color = Js.Dict.get process_env "NO_COLOR" |> Option.is_some

let println s = print_endline s

let exec_in ~cwd cmd =
  try 
    Some (execSync cmd [%mel.obj { cwd; encoding = "utf8"; stdio = [|"pipe"; "pipe"; "pipe"|] }])
  with _ -> None

let exec_silent cmd =
  try Some (execSync_simple cmd [%mel.obj { encoding = "utf8" }])
  with _ -> None

(* === Hub detection === *)

let rec find_hub_path dir =
  if dir = "/" then None
  else
    let config = path_join dir ".cn/config.json" in
    let peers = path_join dir "state/peers.md" in
    if file_exists config || file_exists peers then Some dir
    else find_hub_path (path_dirname dir)

(* === Action logging === *)

let log_action hub_path action details =
  let logs_dir = path_join hub_path "logs" in
  if not (file_exists logs_dir) then mkdir_p logs_dir;
  let entry = [%mel.obj { 
    ts = now_iso (); 
    action = action;
    details = details 
  }] in
  append_file (path_join logs_dir "cn.log") (json_stringify entry ^ "\n")

(* === Peers === *)

let load_peers hub_path =
  let peers_path = path_join hub_path "state/peers.md" in
  if file_exists peers_path then
    parse_peers_md (read_file peers_path)
  else []

(* === Inbox operations === *)

let inbox_check hub_path name =
  println (info (Printf.sprintf "Checking inbox for %s..." name));
  
  (* Fetch from origin *)
  let _ = exec_in ~cwd:hub_path "git fetch origin" in
  
  let peers = load_peers hub_path in
  let total_inbound = ref 0 in
  
  peers |> List.iter (fun peer ->
    if peer.kind <> Some "template" then
      let cmd = Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" peer.name in
      match exec_in ~cwd:hub_path cmd with
      | Some output when String.trim output <> "" ->
          let branches = String.split_on_char '\n' output |> List.filter (fun s -> String.trim s <> "") in
          total_inbound := !total_inbound + List.length branches;
          println (warn (Printf.sprintf "From %s: %d inbound" peer.name (List.length branches)));
          branches |> List.iter (fun b -> println (Printf.sprintf "  ← %s" b))
      | _ ->
          println (dim (Printf.sprintf "  %s: no inbound" peer.name))
  );
  
  if !total_inbound = 0 then println (ok "Inbox clear")

let inbox_process hub_path _name =
  println (info "Processing inbox...");
  let inbox_dir = path_join hub_path "threads/inbox" in
  if not (file_exists inbox_dir) then mkdir_p inbox_dir;
  
  let peers = load_peers hub_path in
  let processed = ref 0 in
  
  peers |> List.iter (fun peer ->
    if peer.kind <> Some "template" then
      let cmd = Printf.sprintf "git branch -r | grep 'origin/%s/' | sed 's/.*origin\\///'" peer.name in
      match exec_in ~cwd:hub_path cmd with
      | Some output when String.trim output <> "" ->
          let branches = String.split_on_char '\n' output |> List.filter (fun s -> String.trim s <> "") in
          branches |> List.iter (fun branch ->
            (* Get files changed in this branch *)
            let diff_cmd = Printf.sprintf "git diff main...origin/%s --name-only 2>/dev/null || git diff master...origin/%s --name-only" branch branch in
            match exec_in ~cwd:hub_path diff_cmd with
            | Some files_output ->
                let files = String.split_on_char '\n' files_output 
                  |> List.filter (fun f -> String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md") in
                files |> List.iter (fun file ->
                  let show_cmd = Printf.sprintf "git show origin/%s:%s" branch file in
                  match exec_in ~cwd:hub_path show_cmd with
                  | Some content ->
                      let branch_slug = branch |> String.split_on_char '/' |> List.rev |> List.hd in
                      let inbox_file = Printf.sprintf "%s-%s.md" peer.name branch_slug in
                      let inbox_path = path_join inbox_dir inbox_file in
                      
                      if not (file_exists inbox_path) then begin
                        let meta = [
                          ("from", peer.name);
                          ("branch", branch);
                          ("file", file);
                          ("received", now_iso ())
                        ] in
                        let final_content = update_frontmatter content meta in
                        write_file inbox_path final_content;
                        log_action hub_path "inbox.materialize" inbox_file;
                        println (ok (Printf.sprintf "Materialized: %s" inbox_file));
                        incr processed
                      end
                  | None -> ()
                )
            | None -> ()
          )
      | _ -> ()
  );
  
  if !processed = 0 then println (info "No new threads to materialize")
  else println (ok (Printf.sprintf "Processed %d thread(s)" !processed))

let inbox_flush hub_path name =
  println (info "Scanning inbox for replies...");
  let inbox_dir = path_join hub_path "threads/inbox" in
  if not (file_exists inbox_dir) then begin println (info "No inbox"); () end
  else
    let peers = load_peers hub_path in
    let replied = ref 0 in
    
    readdir inbox_dir 
    |> List.filter (fun f -> String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md")
    |> List.iter (fun file ->
      let file_path = path_join inbox_dir file in
      let content = read_file file_path in
      let meta = parse_frontmatter content in
      
      (* Check for reply marker *)
      let has_reply = 
        List.exists (fun (k, v) -> k = "reply" && v = "true") meta ||
        String.length content > 0 && 
        (Js.String.includes ~search:"\n## Reply\n" content || Js.String.includes ~search:"\n## Response\n" content)
      in
      
      if has_reply then
        match List.find_opt (fun (k, _) -> k = "from") meta with
        | Some (_, from) ->
            (match List.find_opt (fun p -> p.name = from) peers with
            | Some peer when peer.clone <> None ->
                let clone_path = Option.get peer.clone in
                let thread_name = path_basename_ext file ".md" in
                let branch_name = Printf.sprintf "%s/%s-reply" name thread_name in
                
                (try
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" in
                  let _ = exec_in ~cwd:clone_path "git pull --ff-only 2>/dev/null || true" in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch_name branch_name) in
                  
                  let peer_thread_dir = path_join clone_path "threads/adhoc" in
                  if not (file_exists peer_thread_dir) then mkdir_p peer_thread_dir;
                  
                  let reply_file = Printf.sprintf "%s-%s-reply.md" name thread_name in
                  let _ = exec_in ~cwd:clone_path "cp" in (* placeholder *)
                  write_file (path_join peer_thread_dir reply_file) content;
                  
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git add 'threads/adhoc/%s'" reply_file) in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git commit -m '%s: reply to %s'" name thread_name) in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git push -u origin %s -f" branch_name) in
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" in
                  
                  (* Archive *)
                  let archived_dir = path_join hub_path "threads/archived" in
                  if not (file_exists archived_dir) then mkdir_p archived_dir;
                  let archived_content = update_frontmatter content [("replied", now_iso ())] in
                  write_file (path_join archived_dir file) archived_content;
                  fs_unlinkSync file_path;
                  
                  log_action hub_path "inbox.reply" (Printf.sprintf "to:%s thread:%s" from file);
                  println (ok (Printf.sprintf "Replied to %s: %s" from file));
                  incr replied
                with _ ->
                  println (fail (Printf.sprintf "Failed to reply to %s" file));
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master 2>/dev/null || true" in
                  ()
                )
            | _ -> ())
        | None -> ()
    );
    
    if !replied = 0 then println (info "No replies to send")
    else println (ok (Printf.sprintf "Sent %d reply(s)" !replied))

(* === Outbox operations === *)

let outbox_check hub_path _name =
  let outbox_dir = path_join hub_path "threads/outbox" in
  if not (file_exists outbox_dir) then begin println (ok "Outbox clear"); () end
  else
    let threads = readdir outbox_dir |> List.filter (fun f -> 
      String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md") in
    if List.length threads = 0 then println (ok "Outbox clear")
    else begin
      println (warn (Printf.sprintf "%d pending send(s):" (List.length threads)));
      threads |> List.iter (fun f ->
        let content = read_file (path_join outbox_dir f) in
        let meta = parse_frontmatter content in
        let to_peer = List.find_map (fun (k, v) -> if k = "to" then Some v else None) meta 
          |> Option.value ~default:"(no recipient)" in
        println (Printf.sprintf "  → %s: %s" to_peer f)
      )
    end

let outbox_flush hub_path name =
  let outbox_dir = path_join hub_path "threads/outbox" in
  let sent_dir = path_join hub_path "threads/sent" in
  if not (file_exists outbox_dir) then begin println (ok "Outbox clear"); () end
  else begin
    if not (file_exists sent_dir) then mkdir_p sent_dir;
    
    let peers = load_peers hub_path in
    let threads = readdir outbox_dir |> List.filter (fun f -> 
      String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md") in
    
    if List.length threads = 0 then println (ok "Outbox clear")
    else begin
      println (info (Printf.sprintf "Flushing %d thread(s)..." (List.length threads)));
      
      threads |> List.iter (fun file ->
        let file_path = path_join outbox_dir file in
        let content = read_file file_path in
        let meta = parse_frontmatter content in
        
        match List.find_map (fun (k, v) -> if k = "to" then Some v else None) meta with
        | None ->
            log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s reason:no recipient" file);
            println (warn (Printf.sprintf "Skipping %s: no 'to:' in frontmatter" file))
        | Some to_peer ->
            match List.find_opt (fun p -> p.name = to_peer) peers with
            | None ->
                log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:unknown peer" file to_peer);
                println (fail (Printf.sprintf "Unknown peer: %s" to_peer))
            | Some peer when peer.clone = None ->
                log_action hub_path "outbox.skip" (Printf.sprintf "thread:%s to:%s reason:no clone path" file to_peer);
                println (fail (Printf.sprintf "No clone path for peer: %s" to_peer))
            | Some peer ->
                let clone_path = Option.get peer.clone in
                let thread_name = path_basename_ext file ".md" in
                let branch_name = Printf.sprintf "%s/%s" name thread_name in
                
                (try
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" in
                  let _ = exec_in ~cwd:clone_path "git pull --ff-only 2>/dev/null || true" in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git checkout -b %s 2>/dev/null || git checkout %s" branch_name branch_name) in
                  
                  let peer_thread_dir = path_join clone_path "threads/adhoc" in
                  if not (file_exists peer_thread_dir) then mkdir_p peer_thread_dir;
                  
                  write_file (path_join peer_thread_dir file) content;
                  
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git add 'threads/adhoc/%s'" file) in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git commit -m '%s: %s'" name thread_name) in
                  let _ = exec_in ~cwd:clone_path (Printf.sprintf "git push -u origin %s -f" branch_name) in
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || git checkout master" in
                  
                  (* Move to sent *)
                  let sent_content = update_frontmatter content [("sent", now_iso ())] in
                  write_file (path_join sent_dir file) sent_content;
                  fs_unlinkSync file_path;
                  
                  log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s" to_peer file);
                  println (ok (Printf.sprintf "Sent to %s: %s" to_peer file))
                with _ ->
                  log_action hub_path "outbox.send" (Printf.sprintf "to:%s thread:%s error:failed" to_peer file);
                  println (fail (Printf.sprintf "Failed to send %s" file));
                  let _ = exec_in ~cwd:clone_path "git checkout main 2>/dev/null || true" in
                  ()
                )
      );
      
      println (ok "Outbox flush complete")
    end
  end

(* === Next inbox item === *)

let get_next_inbox_item hub_path =
  let inbox_dir = path_join hub_path "threads/inbox" in
  if not (file_exists inbox_dir) then None
  else
    let threads = readdir inbox_dir 
      |> List.filter (fun f -> String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md")
      |> List.sort String.compare in
    match threads with
    | [] -> None
    | file :: _ ->
        let file_path = path_join inbox_dir file in
        let content = read_file file_path in
        let meta = parse_frontmatter content in
        let from = List.find_map (fun (k, v) -> if k = "from" then Some v else None) meta 
          |> Option.value ~default:"unknown" in
        Some (path_basename_ext file ".md", "inbox", from, content)

let run_next hub_path =
  match get_next_inbox_item hub_path with
  | None -> println "(inbox empty)"
  | Some (id, cadence, from, content) ->
      println (Printf.sprintf "[cadence: %s]" cadence);
      println (Printf.sprintf "[from: %s]" from);
      println (Printf.sprintf "[id: %s]" id);
      println "";
      println content

(* === GTD operations === *)

let find_thread hub_path thread_id =
  let locations = ["inbox"; "outbox"; "doing"; "deferred"; "daily"; "adhoc"] in
  if String.contains thread_id '/' then
    let path = path_join hub_path (Printf.sprintf "threads/%s.md" thread_id) in
    if file_exists path then Some path else None
  else
    List.find_map (fun loc ->
      let path = path_join hub_path (Printf.sprintf "threads/%s/%s.md" loc thread_id) in
      if file_exists path then Some path else None
    ) locations

let gtd_delete hub_path _name thread_id =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      fs_unlinkSync path;
      log_action hub_path "gtd.delete" thread_id;
      println (ok (Printf.sprintf "Deleted: %s" thread_id))

let gtd_defer hub_path _name thread_id until =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let deferred_dir = path_join hub_path "threads/deferred" in
      if not (file_exists deferred_dir) then mkdir_p deferred_dir;
      
      let content = read_file path in
      let until_str = Option.value until ~default:"unspecified" in
      let updated = update_frontmatter content [("deferred", now_iso ()); ("until", until_str)] in
      
      write_file (path_join deferred_dir (path_basename path)) updated;
      fs_unlinkSync path;
      
      log_action hub_path "gtd.defer" (Printf.sprintf "%s until:%s" thread_id until_str);
      println (ok (Printf.sprintf "Deferred: %s%s" thread_id (match until with Some u -> " until " ^ u | None -> "")))

let gtd_delegate hub_path name thread_id peer =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let outbox_dir = path_join hub_path "threads/outbox" in
      if not (file_exists outbox_dir) then mkdir_p outbox_dir;
      
      let content = read_file path in
      let updated = update_frontmatter content [
        ("to", peer);
        ("delegated", now_iso ());
        ("delegated-by", name)
      ] in
      
      write_file (path_join outbox_dir (path_basename path)) updated;
      fs_unlinkSync path;
      
      log_action hub_path "gtd.delegate" (Printf.sprintf "%s to:%s" thread_id peer);
      println (ok (Printf.sprintf "Delegated to %s: %s" peer thread_id));
      println (info "Run \"cn sync\" to send")

let gtd_do hub_path _name thread_id =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let doing_dir = path_join hub_path "threads/doing" in
      if not (file_exists doing_dir) then mkdir_p doing_dir;
      
      let content = read_file path in
      let updated = update_frontmatter content [("started", now_iso ())] in
      
      write_file (path_join doing_dir (path_basename path)) updated;
      fs_unlinkSync path;
      
      log_action hub_path "gtd.do" thread_id;
      println (ok (Printf.sprintf "Started: %s" thread_id))

let gtd_done hub_path _name thread_id =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let archived_dir = path_join hub_path "threads/archived" in
      if not (file_exists archived_dir) then mkdir_p archived_dir;
      
      let content = read_file path in
      let updated = update_frontmatter content [("completed", now_iso ())] in
      
      write_file (path_join archived_dir (path_basename path)) updated;
      fs_unlinkSync path;
      
      log_action hub_path "gtd.done" thread_id;
      println (ok (Printf.sprintf "Completed: %s → archived" thread_id))

(* === Read thread === *)

let run_read hub_path thread_id =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let content = read_file path in
      let cadence = cadence_of_path path |> string_of_cadence in
      let meta = parse_frontmatter content in
      
      println (Printf.sprintf "[cadence: %s]" cadence);
      (match List.find_map (fun (k, v) -> if k = "from" then Some v else None) meta with
       | Some from -> println (Printf.sprintf "[from: %s]" from)
       | None -> ());
      (match List.find_map (fun (k, v) -> if k = "to" then Some v else None) meta with
       | Some to_peer -> println (Printf.sprintf "[to: %s]" to_peer)
       | None -> ());
      println "";
      println content

(* === Inbox/Outbox list === *)

let run_inbox_list hub_path =
  let inbox_dir = path_join hub_path "threads/inbox" in
  if not (file_exists inbox_dir) then println "(empty)"
  else
    let threads = readdir inbox_dir 
      |> List.filter (fun f -> String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md") in
    if List.length threads = 0 then println "(empty)"
    else
      threads |> List.iter (fun f ->
        let id = path_basename_ext f ".md" in
        let content = read_file (path_join inbox_dir f) in
        let meta = parse_frontmatter content in
        let from = List.find_map (fun (k, v) -> if k = "from" then Some v else None) meta 
          |> Option.value ~default:"unknown" in
        println (Printf.sprintf "%s/%s" from id)
      )

let run_outbox_list hub_path =
  let outbox_dir = path_join hub_path "threads/outbox" in
  if not (file_exists outbox_dir) then println "(empty)"
  else
    let threads = readdir outbox_dir 
      |> List.filter (fun f -> String.length f > 3 && String.sub f (String.length f - 3) 3 = ".md") in
    if List.length threads = 0 then println "(empty)"
    else
      threads |> List.iter (fun f ->
        let id = path_basename_ext f ".md" in
        let content = read_file (path_join outbox_dir f) in
        let meta = parse_frontmatter content in
        let to_peer = List.find_map (fun (k, v) -> if k = "to" then Some v else None) meta 
          |> Option.value ~default:"unknown" in
        println (Printf.sprintf "→ %s  \"%s\"" to_peer id)
      )

(* === Git operations === *)

let run_commit hub_path name msg =
  match exec_in ~cwd:hub_path "git status --porcelain" with
  | Some status when String.trim status = "" ->
      println (info "Nothing to commit")
  | _ ->
      let message = match msg with
        | Some m -> m
        | None -> Printf.sprintf "%s: auto-commit %s" name (String.sub (now_iso ()) 0 10)
      in
      let _ = exec_in ~cwd:hub_path "git add -A" in
      (match exec_in ~cwd:hub_path (Printf.sprintf "git commit -m \"%s\"" (Js.String.replaceByRe ~regexp:[%mel.re "/\"/g"] ~replacement:"\\\"" message)) with
       | Some _ ->
           log_action hub_path "commit" message;
           println (ok (Printf.sprintf "Committed: %s" message))
       | None ->
           log_action hub_path "commit" (Printf.sprintf "error:%s" message);
           println (fail "Commit failed"))

let run_push hub_path _name =
  match exec_in ~cwd:hub_path "git branch --show-current" with
  | Some branch ->
      let branch = String.trim branch in
      (match exec_in ~cwd:hub_path (Printf.sprintf "git push origin %s" branch) with
       | Some _ ->
           log_action hub_path "push" branch;
           println (ok (Printf.sprintf "Pushed to origin/%s" branch))
       | None ->
           log_action hub_path "push" "error";
           println (fail "Push failed"))
  | None ->
      println (fail "Could not determine current branch")

(* === Send message === *)

let run_send hub_path _name peer message =
  let outbox_dir = path_join hub_path "threads/outbox" in
  if not (file_exists outbox_dir) then mkdir_p outbox_dir;
  
  let slug = 
    message 
    |> Js.String.slice ~start:0 ~end_:30 
    |> Js.String.toLowerCase 
    |> Js.String.replaceByRe ~regexp:[%mel.re "/[^a-z0-9]+/g"] ~replacement:"-"
    |> Js.String.replaceByRe ~regexp:[%mel.re "/^-|-$/g"] ~replacement:""
  in
  let file_name = slug ^ ".md" in
  let file_path = path_join outbox_dir file_name in
  
  let first_line = message |> String.split_on_char '\n' |> List.hd in
  let content = Printf.sprintf "---\nto: %s\ncreated: %s\n---\n\n# %s\n\n%s\n" 
    peer (now_iso ()) first_line message in
  
  write_file file_path content;
  log_action hub_path "send" (Printf.sprintf "to:%s thread:%s" peer slug);
  println (ok (Printf.sprintf "Created message to %s: %s" peer slug));
  println (info "Run \"cn sync\" to send")

(* === Reply === *)

let run_reply hub_path _name thread_id message =
  match find_thread hub_path thread_id with
  | None -> println (fail (Printf.sprintf "Thread not found: %s" thread_id))
  | Some path ->
      let timestamp = now_iso () in
      let reply = Printf.sprintf "\n\n## Reply (%s)\n\n%s" timestamp message in
      append_file path reply;
      log_action hub_path "reply" (Printf.sprintf "thread:%s" thread_id);
      println (ok (Printf.sprintf "Replied to %s" thread_id))

(* === Status === *)

let run_status hub_path name =
  println (info (Printf.sprintf "cn hub: %s" name));
  println "";
  println (Printf.sprintf "hub..................... %s" (green "✓"));
  println (Printf.sprintf "name.................... %s %s" (green "✓") name);
  println (Printf.sprintf "path.................... %s %s" (green "✓") hub_path);
  println "";
  println (dim (Printf.sprintf "[status] ok version=%s" version))

(* === Doctor === *)

let run_doctor hub_path =
  println (Printf.sprintf "cn v%s" version);
  println (info "Checking health...");
  println "";
  
  let checks = ref [] in
  let warnings = ref [] in
  
  (* Git version *)
  (match exec_silent "git --version" with
   | Some v -> checks := ("git", true, Js.String.replace ~search:"git version " ~replacement:"" (String.trim v)) :: !checks
   | None -> checks := ("git", false, "not installed") :: !checks);
  
  (* Git user.name *)
  (match exec_silent "git config user.name" with
   | Some v -> checks := ("git user.name", true, String.trim v) :: !checks
   | None -> checks := ("git user.name", false, "not set") :: !checks);
  
  (* Git user.email *)
  (match exec_silent "git config user.email" with
   | Some v -> checks := ("git user.email", true, String.trim v) :: !checks
   | None -> checks := ("git user.email", false, "not set") :: !checks);
  
  (* Hub directory *)
  checks := ("hub directory", file_exists hub_path, if file_exists hub_path then "exists" else "not found") :: !checks;
  
  (* .cn/config.json *)
  let config_path = path_join hub_path ".cn/config.json" in
  checks := (".cn/config.json", file_exists config_path, if file_exists config_path then "exists" else "missing") :: !checks;
  
  (* spec/SOUL.md *)
  let soul_path = path_join hub_path "spec/SOUL.md" in
  if file_exists soul_path then
    checks := ("spec/SOUL.md", true, "exists") :: !checks
  else
    warnings := ("spec/SOUL.md", "missing (optional)") :: !warnings;
  
  (* state/peers.md *)
  let peers_path = path_join hub_path "state/peers.md" in
  if file_exists peers_path then begin
    let content = read_file peers_path in
    let peer_count = List.length (Js.String.match_ ~regexp:[%mel.re "/- name:/g"] content |> Option.value ~default:[||] |> Array.to_list) in
    checks := ("state/peers.md", true, Printf.sprintf "%d peer(s)" peer_count) :: !checks
  end else
    checks := ("state/peers.md", false, "missing") :: !checks;
  
  (* origin remote *)
  (match exec_in ~cwd:hub_path "git remote get-url origin" with
   | Some _ -> checks := ("origin remote", true, "configured") :: !checks
   | None -> checks := ("origin remote", false, "not configured") :: !checks);
  
  (* Print checks *)
  let width = 22 in
  List.rev !checks |> List.iter (fun (name, is_ok, value) ->
    let dots = String.make (max 1 (width - String.length name)) '.' in
    let status = if is_ok then green ("✓ " ^ value) else red ("✗ " ^ value) in
    println (Printf.sprintf "%s%s %s" name dots status)
  );
  
  (* Print warnings *)
  List.rev !warnings |> List.iter (fun (name, value) ->
    let dots = String.make (max 1 (width - String.length name)) '.' in
    println (Printf.sprintf "%s%s %s" name dots (yellow ("⚠ " ^ value)))
  );
  
  println "";
  let fails = List.length (List.filter (fun (_, ok, _) -> not ok) !checks) in
  let warns = List.length !warnings in
  
  if fails = 0 then println (ok "All critical checks passed.")
  else println (fail (Printf.sprintf "%d issue(s) found." fails));
  
  println (dim (Printf.sprintf "[status] ok=%d warn=%d fail=%d version=%s" 
    (List.length !checks - fails) warns fails version))

(* === Process (actor loop) === *)

let run_process hub_path _name =
  println (info "Actor loop: checking for inbox items...");
  
  let input_path = path_join hub_path "state/input.md" in
  
  (* Check if input.md already exists (previous item not processed) *)
  if file_exists input_path then begin
    println (warn "state/input.md exists - previous item not processed");
    println (info "Agent should clear input.md when done");
    process_exit 1
  end;
  
  match get_next_inbox_item hub_path with
  | None ->
      println (ok "Inbox empty - nothing to process")
  | Some (id, _cadence, from, content) ->
      println (info (Printf.sprintf "Processing: %s (from %s)" id from));
      
      (* Write to input.md *)
      let state_dir = path_join hub_path "state" in
      if not (file_exists state_dir) then mkdir_p state_dir;
      
      let input_content = Printf.sprintf "---\nid: %s\nfrom: %s\nqueued: %s\n---\n\n%s" 
        id from (now_iso ()) content in
      write_file input_path input_content;
      
      log_action hub_path "process.queue" (Printf.sprintf "id:%s from:%s" id from);
      println (ok (Printf.sprintf "Wrote to state/input.md: %s" id));
      
      (* Trigger OC wake *)
      println (info "Triggering OpenClaw wake...");
      let wake_text = Printf.sprintf "cn input ready: %s from %s" id from in
      (match exec_silent (Printf.sprintf "curl -s -X POST http://localhost:18789/cron/wake -H 'Content-Type: application/json' -d '{\"text\":\"%s\",\"mode\":\"now\"}'" wake_text) with
       | Some _ -> println (ok "Wake triggered")
       | None -> println (warn "Wake trigger failed - is OpenClaw running?"));
      
      println (info "Actor loop complete. Agent will process input.md and clear when done.")

(* === Sync === *)

let run_sync hub_path name =
  println (info "Syncing...");
  inbox_check hub_path name;
  inbox_process hub_path name;
  outbox_flush hub_path name;
  println (ok "Sync complete")

(* === Main === *)

let () =
  let args = Array.to_list process_argv |> List.tl |> List.tl in (* skip node and script path *)
  let flags, cmd_args = parse_flags args in
  let _ = flags in (* TODO: use flags *)
  
  match parse_command cmd_args with
  | None ->
      if List.length cmd_args > 0 then
        println (fail (Printf.sprintf "Unknown command: %s" (List.hd cmd_args)));
      print_endline help_text;
      process_exit 1
  | Some Help ->
      print_endline help_text
  | Some Version ->
      println (Printf.sprintf "cn %s" version)
  | Some cmd ->
      (* Commands that need hub *)
      let needs_hub = match cmd with
        | Help | Version | Init _ -> false
        | _ -> true
      in
      
      if needs_hub then
        match find_hub_path (process_cwd ()) with
        | None ->
            println (fail "Not in a cn hub.");
            println "";
            println "Either:";
            println (Printf.sprintf "  1) cd into an existing hub (cn-sigma, cn-pi, etc.)");
            println (Printf.sprintf "  2) cn init <name> to create a new one");
            process_exit 1
        | Some hub_path ->
            let name = derive_name hub_path in
            (match cmd with
             | Status -> run_status hub_path name
             | Doctor -> run_doctor hub_path
             | Inbox Inbox_check -> inbox_check hub_path name
             | Inbox Inbox_process -> inbox_process hub_path name
             | Inbox Inbox_flush -> inbox_flush hub_path name
             | Outbox Outbox_check -> outbox_check hub_path name
             | Outbox Outbox_flush -> outbox_flush hub_path name
             | Sync -> run_sync hub_path name
             | Next -> run_next hub_path
             | Process -> run_process hub_path name
             | Read t -> run_read hub_path t
             | Reply (t, m) -> run_reply hub_path name t m
             | Send (p, m) -> run_send hub_path name p m
             | Gtd (GtdDelete t) -> gtd_delete hub_path name t
             | Gtd (GtdDefer (t, u)) -> gtd_defer hub_path name t u
             | Gtd (GtdDelegate (t, p)) -> gtd_delegate hub_path name t p
             | Gtd (GtdDo t) -> gtd_do hub_path name t
             | Gtd (GtdDone t) -> gtd_done hub_path name t
             | Commit msg -> run_commit hub_path name msg
             | Push -> run_push hub_path name
             | Save msg -> 
                 run_commit hub_path name msg;
                 run_push hub_path name
             | _ -> println (warn "Command not yet implemented"))
      else
        match cmd with
        | Init name ->
            let hub_name = Option.value name ~default:(path_basename (process_cwd ())) in
            println (info (Printf.sprintf "Initializing hub: %s" hub_name));
            println (warn "Not yet implemented")
        | _ -> ()
