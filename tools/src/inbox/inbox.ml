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

(* Check for inbound branches: origin/<my-name>/* *)
let find_inbound_branches repo_path my_name =
  let cmd = Printf.sprintf "cd %s && git branch -r 2>/dev/null | grep 'origin/%s/' || true" repo_path my_name in
  run_cmd cmd
  |> Option.value ~default:""
  |> filter_branches

(* Fetch and check a single peer *)
let check_peer my_name peer =
  match Fs.exists_sync peer.repo_path with
  | false -> 
      Skipped (peer.name, Printf.sprintf "not found: %s" peer.repo_path)
  | true ->
      let _ = run_cmd (Printf.sprintf "cd %s && git fetch --all 2>&1" peer.repo_path) in
      let branches = find_inbound_branches peer.repo_path my_name in
      Fetched (peer.name, branches)

(* === Actions === *)

let run_check _hub_path my_name peers =
  print_endline (Printf.sprintf "Checking inbox for %s (%d peers)...\n" my_name (List.length peers));
  
  let results = peers |> List.map (check_peer my_name) in
  results |> List.iter (fun r -> print_endline (report_result r));
  
  let alerts = collect_alerts results in
  print_endline "";
  format_alerts alerts |> List.iter print_endline;
  
  match alerts with [] -> 0 | _ -> 2

let run_process _hub_path _my_name _peers =
  print_endline "inbox process: not yet implemented";
  print_endline "Will: show first inbound branch, prompt for triage action";
  1

let run_flush _hub_path _my_name _peers =
  print_endline "inbox flush: not yet implemented";
  print_endline "Will: process all inbound branches in sequence";
  1

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
