(* inbox: Check and process inbound messages from peers
   
   Usage: node inbox.js <action> <hub-path> [agent-name]
   
   Actions:
     check   - list inbound branches
     process - triage one message (interactive)
     flush   - triage all messages
   
   Example: node inbox.js check ./cn-sigma sigma
*)

open Inbox_lib

(* === Node.js bindings === *)

module Process = struct
  external cwd : unit -> string = "cwd" [@@mel.module "process"]
  external argv : string array = "argv" [@@mel.module "process"]
  external exit : int -> unit = "exit" [@@mel.module "process"]
end

module Child_process = struct
  type exec_options
  external make_options : encoding:string -> exec_options = "" [@@mel.obj]
  external exec_sync : string -> exec_options -> string = "execSync" [@@mel.module "child_process"]
end

module Fs = struct
  external read_file_sync : string -> encoding:string -> string = "readFileSync" [@@mel.module "fs"]
  external exists_sync : string -> bool = "existsSync" [@@mel.module "fs"]
end

module Path = struct
  external join : string -> string -> string = "join" [@@mel.module "path"]
  external dirname : string -> string = "dirname" [@@mel.module "path"]
  external resolve : string -> string -> string = "resolve" [@@mel.module "path"]
end

(* === Shell execution === *)

let run_cmd cmd =
  try Some (Child_process.exec_sync cmd (Child_process.make_options ~encoding:"utf8"))
  with _ -> None

(* Check for inbound branches in MY repo from a specific peer: origin/<peer-name>/* *)
let find_inbound_from_peer hub_path peer_name =
  let cmd = Printf.sprintf "cd %s && git branch -r 2>/dev/null | grep 'origin/%s/' || true" hub_path peer_name in
  run_cmd cmd
  |> Option.value ~default:""
  |> filter_branches
  |> List.map (fun b -> 
      (* Strip "origin/" prefix for cleaner output *)
      match strip_prefix ~pre:"origin/" b with
      | Some rest -> rest
      | None -> b)

(* Fetch my repo and check for branches from a peer *)
let check_peer_inbound hub_path peer =
  (* Fetch my repo first *)
  let _ = run_cmd (Printf.sprintf "cd %s && git fetch --all 2>&1" hub_path) in
  let branches = find_inbound_from_peer hub_path peer.name in
  Fetched (peer.name, branches)

(* === Actions === *)

let run_check hub_path my_name peers =
  print_endline (Printf.sprintf "Checking inbox for %s (%d peers)...\n" my_name (List.length peers));
  
  let results = peers |> List.map (check_peer_inbound hub_path) in
  results |> List.iter (fun r -> print_endline (report_result r));
  
  let alerts = collect_alerts results in
  print_endline "";
  format_alerts alerts |> List.iter print_endline;
  
  match alerts with [] -> 0 | _ -> 2

(* === Action execution === *)

module Fs_write = struct
  external write_file_sync : string -> string -> unit = "writeFileSync" [@@mel.module "fs"]
  external append_file_sync : string -> string -> unit = "appendFileSync" [@@mel.module "fs"]
  external mkdir_sync : string -> < recursive : bool > Js.t -> unit = "mkdirSync" [@@mel.module "fs"]
end

let execute_action ~hub_path action =
  try
    match git_cmd_of_action ~hub_path action with
    | Some cmd -> 
        (* Git action: run the generated command *)
        run_cmd cmd |> Option.is_some
    | None ->
        (* File action: use Node.js fs *)
        match action with
        | File_write (p, content) -> 
            Fs_write.write_file_sync p content; true
        | Dir_create p -> 
            Fs_write.mkdir_sync p [%mel.obj { recursive = true }]; true
        | Log_append (p, line) ->
            let dir = Path.dirname p in
            Fs_write.mkdir_sync dir [%mel.obj { recursive = true }];
            Fs_write.append_file_sync p (line ^ "\n"); true
        | _ -> false  (* shouldn't happen *)
  with _ -> 
    print_endline (Printf.sprintf "  ✗ Failed: %s" (string_of_atomic_action action));
    false

let execute_actions ~hub_path actions =
  let rec go = function
    | [] -> true
    | action :: rest ->
        print_endline (Printf.sprintf "  → %s" (string_of_atomic_action action));
        if execute_action ~hub_path action then go rest else false
  in
  go actions

(* === Materialize branches as threads === *)

let get_branch_content hub_path branch =
  (* Get commit message and diff summary for the branch - from MY repo *)
  let cmd = Printf.sprintf 
    "cd %s && git log origin/%s --oneline -5 2>/dev/null" 
    hub_path branch in
  run_cmd cmd |> Option.value ~default:"(no commits)"

let materialize_branch hub_path my_name peer branch =
  let threads_dir = Path.join hub_path "threads" in
  (* branch already has peer prefix like "pi/batch-response" *)
  let content = get_branch_content hub_path branch in
  (* Extract short name for filename: "pi/batch-response" -> "batch-response" *)
  let short_name = match String.split_on_char '/' branch with
    | _ :: rest -> String.concat "-" rest
    | [] -> branch
  in
  let thread_content = Printf.sprintf 
    "# Inbound: %s\n\n**From:** %s\n**Branch:** %s\n**To:** %s\n\n## Commits\n\n```\n%s\n```\n\n## Decision\n\n<!-- Write your triage decision here: delete:<reason> | defer:<reason> | delegate:<actor> | do:merge -->\n\n```\ndecision: \n```\n"
    branch peer branch my_name content
  in
  (* Use short name for thread file path *)
  let actions = materialize_thread_actions ~threads_dir ~branch:short_name ~peer ~content:thread_content in
  print_endline (Printf.sprintf "Materializing %s..." branch);
  if execute_actions ~hub_path actions then
    print_endline "  ✓ Thread created"
  else
    print_endline "  ✗ Failed to create thread"

let run_process hub_path my_name peers =
  print_endline (Printf.sprintf "Materializing inbox for %s...\n" my_name);
  
  (* Collect all inbound branches from MY repo *)
  let results = peers |> List.map (check_peer_inbound hub_path) in
  let all_branches = collect_branches results in
  
  match all_branches with
  | [] ->
      print_endline "No inbound branches to process.";
      0
  | branches ->
      print_endline (Printf.sprintf "Found %d inbound branch(es).\n" (List.length branches));
      branches |> List.iter (fun b -> 
        materialize_branch hub_path my_name b.peer b.branch);
      print_endline "";
      print_endline "Threads created in threads/inbox/";
      print_endline "Review and add 'decision: <triage>' to each thread.";
      print_endline "Then run 'inbox flush' to execute decisions.";
      0

(* === Read decisions from threads and execute === *)

let read_decision_from_thread thread_path =
  try
    let content = Fs.read_file_sync thread_path ~encoding:"utf8" in
    (* Look for "decision: <value>" pattern *)
    let lines = String.split_on_char '\n' content in
    lines |> List.find_map (fun line ->
      let trimmed = String.trim line in
      match strip_prefix ~pre:"decision:" trimmed with
      | Some rest -> 
          let decision_str = String.trim rest in
          if String.length decision_str > 0 then triage_of_string decision_str else None
      | None -> 
          match strip_prefix ~pre:"decision: " trimmed with
          | Some rest -> 
              let decision_str = String.trim rest in
              if String.length decision_str > 0 then triage_of_string decision_str else None
          | None -> None
    )
  with _ -> None

let extract_branch_from_thread thread_path =
  try
    let content = Fs.read_file_sync thread_path ~encoding:"utf8" in
    let lines = String.split_on_char '\n' content in
    lines |> List.find_map (fun line ->
      let trimmed = String.trim line in
      match strip_prefix ~pre:"**Branch:**" trimmed with
      | Some rest -> Some (String.trim rest)
      | None -> 
          match strip_prefix ~pre:"**Branch:** " trimmed with
          | Some rest -> Some (String.trim rest)
          | None -> None
    )
  with _ -> None

let list_inbox_threads hub_path =
  let inbox_dir = Path.join hub_path "threads/inbox" in
  let cmd = Printf.sprintf "ls %s/*.md 2>/dev/null || true" inbox_dir in
  run_cmd cmd
  |> Option.value ~default:""
  |> String.split_on_char '\n'
  |> List.filter non_empty

let run_flush hub_path _my_name _peers =
  print_endline "Processing inbox decisions...\n";
  
  let threads = list_inbox_threads hub_path in
  match threads with
  | [] ->
      print_endline "No threads in threads/inbox/";
      print_endline "Run 'inbox process' first to materialize branches.";
      0
  | _ ->
      print_endline (Printf.sprintf "Found %d thread(s).\n" (List.length threads));
      let log_path = Path.join hub_path "logs/inbox.md" in
      let processed = ref 0 in
      let skipped = ref 0 in
      
      threads |> List.iter (fun thread_path ->
        let filename = thread_path |> String.split_on_char '/' |> List.rev |> List.hd in
        match read_decision_from_thread thread_path with
        | None ->
            print_endline (Printf.sprintf "⏸ %s - no decision yet" filename);
            incr skipped
        | Some decision ->
            let branch = extract_branch_from_thread thread_path |> Option.value ~default:"unknown" in
            print_endline (Printf.sprintf "▶ %s - %s" filename (string_of_triage decision));
            let actions = triage_to_actions ~log_path ~branch decision in
            print_endline "  Actions:";
            format_action_plan actions |> List.iter print_endline;
            if execute_actions ~hub_path actions then begin
              (* Remove processed thread *)
              let _ = run_cmd (Printf.sprintf "rm %s" thread_path) in
              print_endline "  ✓ Done (thread removed)";
              incr processed
            end else begin
              print_endline "  ✗ Execution failed";
              incr skipped
            end
      );
      
      print_endline "";
      print_endline (Printf.sprintf "Processed: %d | Skipped: %d" !processed !skipped);
      if !skipped > 0 then 1 else 0

let run_command cmd hub_path my_name peers =
  match cmd with
  | Check -> run_check hub_path my_name peers
  | Process -> run_process hub_path my_name peers
  | Flush -> run_flush hub_path my_name peers

(* === Usage === *)

let usage () =
  print_endline "Usage: node inbox.js <action> <hub-path> [agent-name]";
  print_endline "";
  print_endline "Actions:";
  print_endline "  check   - list inbound branches";
  print_endline "  process - triage one message";
  print_endline "  flush   - triage all messages";
  print_endline "";
  print_endline "Example: node inbox.js check ./cn-sigma sigma"

(* === Main === *)

let () =
  let argv = Process.argv in
  
  match Array.length argv with
  | n when n < 4 ->
      usage ();
      Process.exit 1
  | _ ->
      let action_str = argv.(2) in
      match command_of_string action_str with
      | None ->
          print_endline (Printf.sprintf "Unknown action: %s" action_str);
          print_endline (Printf.sprintf "Valid actions: %s" 
            (all_commands |> List.map string_of_command |> String.concat ", "));
          Process.exit 1
      | Some cmd ->
          let hub_path = Path.resolve (Process.cwd ()) argv.(3) in
          let my_name = match Array.length argv > 4 with
            | true -> argv.(4)
            | false -> derive_name hub_path
          in
          let workspace = Path.dirname hub_path in
          let peers_file = Path.join hub_path "state/peers.md" in
          
          match Fs.exists_sync peers_file with
          | false ->
              print_endline (Printf.sprintf "No state/peers.md at %s" peers_file);
              Process.exit 1
          | true ->
              let peers = 
                Fs.read_file_sync peers_file ~encoding:"utf8"
                |> parse_peers
                |> List.map (make_peer ~join:Path.join workspace)
              in
              let exit_code = run_command cmd hub_path my_name peers in
              Process.exit exit_code
