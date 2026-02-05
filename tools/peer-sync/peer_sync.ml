(* peer-sync: Fetch peers and check for inbound branches
   
   Usage: node peer_sync.js <hub-path> [agent-name]
   Example: node peer_sync.js ./cn-sigma sigma
*)

(* Node.js bindings *)
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

(* Types *)
type peer = { name : string; repo_path : string }
type sync_result = 
  | Fetched of string * string list  (* peer, inbound branches *)
  | Skipped of string * string       (* peer, reason *)

(* Shell execution *)
let run_cmd cmd =
  try Some (Child_process.exec_sync cmd (Child_process.make_options ~encoding:"utf8"))
  with _ -> None

(* String helpers *)
let prefix ~pre s =
  String.length s >= String.length pre &&
  String.sub s 0 (String.length pre) = pre

let strip_prefix ~pre s =
  match prefix ~pre s with
  | true -> Some (String.sub s (String.length pre) (String.length s - String.length pre))
  | false -> None

let non_empty s = String.length (String.trim s) > 0

(* Parse "- name: X" lines from peers.md *)
let parse_peers content =
  content
  |> String.split_on_char '\n'
  |> List.filter_map (fun line -> strip_prefix ~pre:"- name: " (String.trim line))

(* Derive agent name from hub path: /path/to/cn-sigma -> sigma *)
let derive_name hub_path =
  hub_path
  |> String.split_on_char '/'
  |> List.rev
  |> function
    | base :: _ -> strip_prefix ~pre:"cn-" base |> Option.value ~default:base
    | [] -> "agent"

(* Build peer record with repo path *)
let make_peer workspace name =
  let repo_path = match name with
    | "cn-agent" -> Path.join workspace "cn-agent"
    | _ -> Path.join workspace (Printf.sprintf "cn-%s-clone" name)
  in
  { name; repo_path }

(* Check for inbound branches: origin/<my-name>/* *)
let find_inbound_branches repo_path my_name =
  let cmd = Printf.sprintf "cd %s && git branch -r 2>/dev/null | grep 'origin/%s/' || true" repo_path my_name in
  run_cmd cmd
  |> Option.value ~default:""
  |> String.split_on_char '\n'
  |> List.map String.trim
  |> List.filter non_empty

(* Sync a single peer *)
let sync_peer my_name peer =
  match Fs.exists_sync peer.repo_path with
  | false -> 
      Skipped (peer.name, Printf.sprintf "not found: %s" peer.repo_path)
  | true ->
      let _ = run_cmd (Printf.sprintf "cd %s && git fetch --all 2>&1" peer.repo_path) in
      let branches = find_inbound_branches peer.repo_path my_name in
      Fetched (peer.name, branches)

(* Report results *)
let report_result = function
  | Fetched (name, []) -> 
      print_endline (Printf.sprintf "  ✓ %s (no inbound)" name)
  | Fetched (name, branches) -> 
      print_endline (Printf.sprintf "  ⚡ %s (%d inbound)" name (List.length branches))
  | Skipped (name, reason) -> 
      print_endline (Printf.sprintf "  · %s (%s)" name reason)

let report_alerts results =
  let alerts = results |> List.filter_map (function
    | Fetched (name, (_::_ as branches)) -> Some (name, branches)
    | _ -> None)
  in
  match alerts with
  | [] -> 
      print_endline "\nNo inbound branches. All clear.";
      0
  | _ ->
      print_endline "\n=== INBOUND BRANCHES ===";
      alerts |> List.iter (fun (peer, branches) ->
        print_endline (Printf.sprintf "From %s:" peer);
        branches |> List.iter (fun b -> print_endline (Printf.sprintf "  %s" b)));
      2

(* Main *)
let () =
  let argv = Process.argv in
  
  (* Parse args *)
  match Array.length argv with
  | n when n < 3 ->
      print_endline "Usage: node peer_sync.js <hub-path> [agent-name]";
      Process.exit 1
  | _ ->
      let hub_path = Path.resolve (Process.cwd ()) argv.(2) in
      let my_name = match Array.length argv > 3 with
        | true -> argv.(3)
        | false -> derive_name hub_path
      in
      let workspace = Path.dirname hub_path in
      let peers_file = Path.join hub_path "state/peers.md" in
      
      (* Load and sync *)
      match Fs.exists_sync peers_file with
      | false ->
          print_endline (Printf.sprintf "No state/peers.md at %s" peers_file);
          Process.exit 1
      | true ->
          let peers = 
            Fs.read_file_sync peers_file ~encoding:"utf8"
            |> parse_peers
            |> List.map (make_peer workspace)
          in
          print_endline (Printf.sprintf "Syncing %d peers as %s...\n" (List.length peers) my_name);
          
          let results = peers |> List.map (sync_peer my_name) in
          results |> List.iter report_result;
          
          Process.exit (report_alerts results)
