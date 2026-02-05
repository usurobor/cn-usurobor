(* inbox_lib: Pure functions for inbox tool (no FFI, testable) *)

(* === Actions (type-safe, exhaustive) === *)

type action =
  | Check    (* list inbound branches *)
  | Process  (* triage one message *)
  | Flush    (* triage all messages *)

(* === GTD Triage (Getting Things Done) === *)

type triage =
  | Delete    (* noise, stale, already handled — remove branch *)
  | Defer     (* important but not urgent — leave for later *)
  | Delegate  (* forward to another agent — push to their repo *)
  | Do        (* respond now — merge, reply, or take action *)

let triage_of_string = function
  | "delete" | "d" -> Some Delete
  | "defer" | "f" -> Some Defer
  | "delegate" | "g" -> Some Delegate
  | "do" | "o" -> Some Do
  | _ -> None

let string_of_triage = function
  | Delete -> "delete"
  | Defer -> "defer"
  | Delegate -> "delegate"
  | Do -> "do"

let triage_description = function
  | Delete -> "Remove branch (noise/stale/handled)"
  | Defer -> "Leave for later (important, not urgent)"
  | Delegate -> "Forward to another agent"
  | Do -> "Respond now (merge/reply/action)"

let all_triages = [Delete; Defer; Delegate; Do]

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
