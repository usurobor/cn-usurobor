(* inbox_lib: Pure functions for inbox tool (no FFI, testable) *)

(* === Actions (type-safe, exhaustive) === *)

type action =
  | Check    (* list inbound branches *)
  | Process  (* triage one message *)
  | Flush    (* triage all messages *)

(* === GTD Triage (Getting Things Done) === *)

(* What to do when triaging as "Do" *)
type do_action =
  | Merge                     (* merge the branch *)
  | Reply of string           (* push reply branch with given name *)
  | Custom of string          (* custom action description *)

(* GTD 4 Ds — each with required context *)
type triage =
  | Delete of string          (* reason: why remove? e.g. "stale", "duplicate" *)
  | Defer of string           (* reason: why later? e.g. "blocked on X" *)
  | Delegate of string        (* actor: who handles? e.g. "pi" *)
  | Do of do_action           (* action: what to do? *)

(* Parse do_action from string *)
let do_action_of_string s =
  if s = "merge" then Some Merge
  else match String.split_on_char ':' s with
    | ["reply"; name] -> Some (Reply name)
    | ["custom"; desc] -> Some (Custom desc)
    | _ -> None

let string_of_do_action = function
  | Merge -> "merge"
  | Reply name -> Printf.sprintf "reply:%s" name
  | Custom desc -> Printf.sprintf "custom:%s" desc

(* Helper: require non-empty payload *)
let non_empty_payload parts =
  let payload = String.concat ":" parts in
  if String.length payload > 0 then Some payload else None

(* Parse triage from "action:payload" format — payload required *)
let triage_of_string s =
  match String.split_on_char ':' s with
  | ("delete" | "d") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Delete r)
  | ("defer" | "f") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Defer r)
  | ("delegate" | "g") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Delegate r)
  | [("do" | "o"); "merge"] -> Some (Do Merge)
  | ("do" | "o") :: "reply" :: name -> 
      non_empty_payload name |> Option.map (fun n -> Do (Reply n))
  | ("do" | "o") :: "custom" :: desc -> 
      non_empty_payload desc |> Option.map (fun d -> Do (Custom d))
  | _ -> None

let string_of_triage = function
  | Delete reason -> Printf.sprintf "delete:%s" reason
  | Defer reason -> Printf.sprintf "defer:%s" reason
  | Delegate actor -> Printf.sprintf "delegate:%s" actor
  | Do action -> Printf.sprintf "do:%s" (string_of_do_action action)

let triage_kind = function
  | Delete _ -> "delete"
  | Defer _ -> "defer"
  | Delegate _ -> "delegate"
  | Do _ -> "do"

let triage_description = function
  | Delete reason -> Printf.sprintf "Remove branch (%s)" reason
  | Defer reason -> Printf.sprintf "Defer (%s)" reason
  | Delegate actor -> Printf.sprintf "Delegate to %s" actor
  | Do Merge -> "Merge branch"
  | Do (Reply name) -> Printf.sprintf "Reply with branch %s" name
  | Do (Custom desc) -> Printf.sprintf "Action: %s" desc

let action_of_string = function
  | "check" -> Some Check
  | "process" -> Some Process
  | "flush" -> Some Flush
  | _ -> None

let string_of_action = function
  | Check -> "check"
  | Process -> "process"
  | Flush -> "flush"

let all_actions = [Check; Process; Flush]

(* === String helpers === *)

let prefix ~pre s =
  String.length s >= String.length pre &&
  String.sub s 0 (String.length pre) = pre

let strip_prefix ~pre s =
  match prefix ~pre s with
  | true -> Some (String.sub s (String.length pre) (String.length s - String.length pre))
  | false -> None

let non_empty s = String.length (String.trim s) > 0

(* === Peers === *)

type peer = { name : string; repo_path : string }

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
let make_peer ~join workspace name =
  let repo_path = match name with
    | "cn-agent" -> join workspace "cn-agent"
    | _ -> join workspace (Printf.sprintf "cn-%s-clone" name)
  in
  { name; repo_path }

(* === Sync results === *)

type sync_result = 
  | Fetched of string * string list  (* peer, inbound branches *)
  | Skipped of string * string       (* peer, reason *)

(* Filter non-empty trimmed strings *)
let filter_branches output =
  output
  |> String.split_on_char '\n'
  |> List.map String.trim
  |> List.filter non_empty

(* === Reporting === *)

let report_result = function
  | Fetched (name, []) -> 
      Printf.sprintf "  ✓ %s (no inbound)" name
  | Fetched (name, branches) -> 
      Printf.sprintf "  ⚡ %s (%d inbound)" name (List.length branches)
  | Skipped (name, reason) -> 
      Printf.sprintf "  · %s (%s)" name reason

let collect_alerts results =
  results |> List.filter_map (function
    | Fetched (name, (_::_ as branches)) -> Some (name, branches)
    | _ -> None)

type inbound_branch = {
  peer: string;
  branch: string;
  full_ref: string;
}

let collect_branches results =
  results |> List.concat_map (function
    | Fetched (peer, branches) -> 
        branches |> List.map (fun b -> 
          { peer; branch = b; full_ref = Printf.sprintf "origin/%s" b })
    | Skipped _ -> [])

let format_alerts alerts =
  match alerts with
  | [] -> ["No inbound branches. All clear."]
  | _ ->
      "=== INBOUND BRANCHES ===" ::
      (alerts |> List.concat_map (fun (peer, branches) ->
        Printf.sprintf "From %s:" peer ::
        (branches |> List.map (fun b -> Printf.sprintf "  %s" b))))
