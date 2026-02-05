(* inbox_lib: Pure functions for inbox tool (no FFI, testable) *)

(* === CLI Commands (type-safe, exhaustive) === *)

type command =
  | Check    (* list inbound branches *)
  | Process  (* triage one message *)
  | Flush    (* triage all messages *)

let command_of_string = function
  | "check" -> Some Check
  | "process" -> Some Process
  | "flush" -> Some Flush
  | _ -> None

let string_of_command = function
  | Check -> "check"
  | Process -> "process"
  | Flush -> "flush"

let all_commands = [Check; Process; Flush]

(* === GTD Triage (Getting Things Done) === *)

(* Wrapper types — true type safety, PascalCase constructors *)
type reason = Reason of string           (* why: "stale", "blocked on X" *)
type actor = Actor of string             (* who: "pi", "omega" *)
type branch_name = BranchName of string  (* branch: "response-thread" *)
type description = Description of string (* what: "update docs first" *)

(* What to do when triaging as "Do" *)
type action =
  | Merge                             (* merge the branch *)
  | Reply of branch_name              (* push reply branch *)
  | Custom of description             (* custom action *)

(* GTD 4 Ds — each with required context *)
type triage =
  | Delete of reason                  (* Delete (Reason "stale") *)
  | Defer of reason                   (* Defer (Reason "blocked") *)
  | Delegate of actor                 (* Delegate (Actor "pi") *)
  | Do of action                      (* Do Merge *)

(* Parse action from string *)
let action_of_string s =
  if s = "merge" then Some Merge
  else match String.split_on_char ':' s with
    | ["reply"; name] -> Some (Reply (BranchName name))
    | ["custom"; desc] -> Some (Custom (Description desc))
    | _ -> None

let string_of_action = function
  | Merge -> "merge"
  | Reply (BranchName name) -> Printf.sprintf "reply:%s" name
  | Custom (Description desc) -> Printf.sprintf "custom:%s" desc

(* Helper: require non-empty payload *)
let non_empty_payload parts =
  let payload = String.concat ":" parts in
  if String.length payload > 0 then Some payload else None

(* Parse triage from "action:payload" format — payload required *)
let triage_of_string s =
  match String.split_on_char ':' s with
  | ("delete" | "d") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Delete (Reason r))
  | ("defer" | "f") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Defer (Reason r))
  | ("delegate" | "g") :: rest -> 
      non_empty_payload rest |> Option.map (fun r -> Delegate (Actor r))
  | [("do" | "o"); "merge"] -> Some (Do Merge)
  | ("do" | "o") :: "reply" :: name -> 
      non_empty_payload name |> Option.map (fun n -> Do (Reply (BranchName n)))
  | ("do" | "o") :: "custom" :: desc -> 
      non_empty_payload desc |> Option.map (fun d -> Do (Custom (Description d)))
  | _ -> None

let string_of_triage = function
  | Delete (Reason r) -> Printf.sprintf "delete:%s" r
  | Defer (Reason r) -> Printf.sprintf "defer:%s" r
  | Delegate (Actor a) -> Printf.sprintf "delegate:%s" a
  | Do action -> Printf.sprintf "do:%s" (string_of_action action)

let triage_kind = function
  | Delete _ -> "delete"
  | Defer _ -> "defer"
  | Delegate _ -> "delegate"
  | Do _ -> "do"

let triage_description = function
  | Delete (Reason r) -> Printf.sprintf "Remove branch (%s)" r
  | Defer (Reason r) -> Printf.sprintf "Defer (%s)" r
  | Delegate (Actor a) -> Printf.sprintf "Delegate to %s" a
  | Do Merge -> "Merge branch"
  | Do (Reply (BranchName name)) -> Printf.sprintf "Reply with branch %s" name
  | Do (Custom (Description desc)) -> Printf.sprintf "Action: %s" desc

(* === Triage Log (audit trail) === *)

type triage_entry = {
  timestamp: string;    (* ISO 8601 *)
  branch: string;       (* branch that was triaged *)
  peer: string;         (* where it came from *)
  decision: triage;     (* what was decided *)
  actor: string;        (* who made the decision *)
}

let format_log_entry entry =
  Printf.sprintf "- %s | %s | %s/%s | %s"
    entry.timestamp
    entry.actor
    entry.peer
    entry.branch
    (string_of_triage entry.decision)

let format_log_entry_human entry =
  Printf.sprintf "[%s] %s triaged %s/%s → %s"
    entry.timestamp
    entry.actor
    entry.peer
    entry.branch
    (triage_description entry.decision)

(* Parse log entry from "- timestamp | actor | peer/branch | decision" *)
let parse_log_entry line =
  match String.split_on_char '|' line with
  | [ts; actor_str; peer_branch; decision_str] ->
      let ts_trimmed = String.trim ts in
      let timestamp = 
        if String.length ts_trimmed > 2 && String.sub ts_trimmed 0 2 = "- " 
        then String.sub ts_trimmed 2 (String.length ts_trimmed - 2)
        else ts_trimmed 
      in
      let actor = String.trim actor_str in
      let peer, branch = match String.split_on_char '/' (String.trim peer_branch) with
        | peer :: rest -> (peer, String.concat "/" rest)
        | [] -> ("", "")
      in
      let decision = triage_of_string (String.trim decision_str) in
      (match decision with
       | Some d -> Some { timestamp; branch; peer; decision = d; actor }
       | None -> None)
  | _ -> None

(* === Daily Log Files === *)

(* logs/inbox/YYYYMMDD.md *)
let log_dir = "logs/inbox"

let daily_log_path date_str =
  Printf.sprintf "%s/%s.md" log_dir date_str

let daily_log_header date_str =
  Printf.sprintf "# Inbox Log: %s\n\n| Time | Actor | Source | Decision |\n|------|-------|--------|----------|"
    (String.sub date_str 0 4 ^ "-" ^ String.sub date_str 4 2 ^ "-" ^ String.sub date_str 6 2)

let format_log_row entry =
  (* Extract time from ISO timestamp *)
  let time = 
    try String.sub entry.timestamp 11 5  (* HH:MM *)
    with _ -> entry.timestamp 
  in
  Printf.sprintf "| %s | %s | %s/%s | `%s` |"
    time
    entry.actor
    entry.peer
    entry.branch
    (string_of_triage entry.decision)

(* Summary stats for daily log *)
type daily_stats = {
  total: int;
  deleted: int;
  deferred: int;
  delegated: int;
  done_count: int;
}

let empty_stats = { total = 0; deleted = 0; deferred = 0; delegated = 0; done_count = 0 }

let update_stats stats = function
  | Delete _ -> { stats with total = stats.total + 1; deleted = stats.deleted + 1 }
  | Defer _ -> { stats with total = stats.total + 1; deferred = stats.deferred + 1 }
  | Delegate _ -> { stats with total = stats.total + 1; delegated = stats.delegated + 1 }
  | Do _ -> { stats with total = stats.total + 1; done_count = stats.done_count + 1 }

let format_daily_summary stats =
  Printf.sprintf "\n## Summary\n- Processed: %d\n- Delete: %d\n- Defer: %d\n- Delegate: %d\n- Do: %d"
    stats.total stats.deleted stats.deferred stats.delegated stats.done_count

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
