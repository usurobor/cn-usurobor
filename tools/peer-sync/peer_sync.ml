(* peer-sync: Fetch peers and check for inbound branches
   
   Usage: node peer_sync.js <hub-path> [agent-name]
   
   Example: node peer_sync.js ./cn-sigma sigma
*)

(* Node.js bindings via Melange *)
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

(* Run shell command, return output or empty string on failure *)
let run_cmd cmd =
  try 
    let opts = Child_process.make_options ~encoding:"utf8" in
    Child_process.exec_sync cmd opts
  with _ -> ""

(* Parse peers.md YAML to extract peer names *)
let parse_peers content =
  content
  |> String.split_on_char '\n'
  |> List.filter_map (fun line ->
      let trimmed = String.trim line in
      (* Look for "- name: X" pattern *)
      if String.length trimmed > 8 && 
         String.sub trimmed 0 8 = "- name: " then
        Some (String.sub trimmed 8 (String.length trimmed - 8))
      else
        None)

(* Check for inbound branches matching pattern *)
let check_inbound_branches repo_path my_name =
  let pattern = my_name ^ "/" in
  let cmd = Printf.sprintf "cd %s && git branch -r 2>/dev/null | grep 'origin/%s' || true" repo_path pattern in
  let output = run_cmd cmd in
  output
  |> String.split_on_char '\n'
  |> List.filter (fun s -> String.length (String.trim s) > 0)
  |> List.map String.trim

(* Fetch a peer repo *)
let fetch_peer repo_path =
  let cmd = Printf.sprintf "cd %s && git fetch --all 2>&1" repo_path in
  let _ = run_cmd cmd in
  ()

(* Main *)
let () =
  let argv = Process.argv in
  
  if Array.length argv < 3 then begin
    print_endline "Usage: node peer_sync.js <hub-path> [agent-name]";
    print_endline "  hub-path: path to the agent's hub (e.g., ./cn-sigma)";
    print_endline "  agent-name: the agent's name for branch matching (default: derived from hub path)";
    Process.exit 1
  end;
  
  let hub_path = Path.resolve (Process.cwd ()) argv.(2) in
  let my_name = 
    if Array.length argv > 3 then argv.(3)
    else 
      (* Derive from hub path: cn-sigma -> sigma *)
      let base = 
        match String.split_on_char '/' hub_path |> List.rev with
        | h :: _ -> h
        | [] -> "agent"
      in
      if String.length base > 3 && String.sub base 0 3 = "cn-" then
        String.sub base 3 (String.length base - 3)
      else base
  in
  
  let workspace = Path.dirname hub_path in
  let peers_file = Path.join hub_path "state/peers.md" in
  
  if not (Fs.exists_sync peers_file) then begin
    print_endline (Printf.sprintf "No state/peers.md found at %s" peers_file);
    Process.exit 1
  end;
  
  let content = Fs.read_file_sync peers_file ~encoding:"utf8" in
  let peers = parse_peers content in
  
  print_endline (Printf.sprintf "Syncing %d peers as %s..." (List.length peers) my_name);
  
  let alerts = ref [] in
  
  List.iter (fun peer_name ->
    (* Clone directory naming: cn-<name>-clone for external hubs, cn-<name> for template *)
    let repo_path = 
      if peer_name = "cn-agent" then Path.join workspace "cn-agent"
      else Path.join workspace (Printf.sprintf "cn-%s-clone" peer_name)
    in
    
    if Fs.exists_sync repo_path then begin
      print_endline (Printf.sprintf "  Fetching %s..." peer_name);
      fetch_peer repo_path;
      
      let branches = check_inbound_branches repo_path my_name in
      if List.length branches > 0 then begin
        alerts := (peer_name, branches) :: !alerts
      end
    end else
      print_endline (Printf.sprintf "  Skip %s (not found: %s)" peer_name repo_path)
  ) peers;
  
  print_endline "";
  
  if List.length !alerts > 0 then begin
    print_endline "=== INBOUND BRANCHES ===";
    List.iter (fun (peer, branches) ->
      print_endline (Printf.sprintf "From %s:" peer);
      List.iter (fun b -> print_endline (Printf.sprintf "  %s" b)) branches
    ) !alerts;
    Process.exit 2  (* Signal alerts found *)
  end else begin
    print_endline "No inbound branches. All clear.";
    Process.exit 0
  end
