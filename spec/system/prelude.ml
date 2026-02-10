(* CNOS Spec Prelude — shared types and mocks for all specs *)

(* === Git Layer === *)

type branch_info = {
  peer: string;
  branch: string;
}

let parse_branch_name name =
  match String.split_on_char '/' name with
  | peer :: _ -> { peer; branch = name }
  | [] -> { peer = "unknown"; branch = name }

let orphans = ref ["pi/orphan-topic"]

let has_merge_base branch =
  not (List.mem branch !orphans)

let git_operations = ["fetch"; "push"; "branch -r"; "merge-base"; "show"; "log"]

(* === Protocol Layer === *)

type peer_info = {
  name: string;
  hub: string option;
  clone: string option;
  kind: string option;
}

type validation_result =
  | Valid of { merge_base: string }
  | Orphan of { reason: string }

let example_peer = {
  name = "pi";
  hub = Some "https://github.com/user/cn-pi";
  clone = Some "/path/to/cn-pi-clone";
  kind = Some "agent";
}

let validate_branch branch =
  if List.mem branch !orphans then
    Orphan { reason = "no merge base with main" }
  else
    Valid { merge_base = "abc123" }

let rejection_notice peer branch =
  Printf.sprintf "Branch %s rejected: no merge base with main" branch

(* === Rejection Terminal Cleanup === *)

type cleanup_result =
  | Deleted of string
  | NotFound of string

type rejection_result = {
  materialized: bool;
  branch_deleted: string option;
}

(* Parse rejected branch name from rejection notice body *)
(* Pattern: "Branch `<branch>` rejected" *)
let parse_rejected_branch content =
  match String.split_on_char '`' content with
  | _ :: branch :: _ when String.length branch > 0 
      && String.length content >= 8
      && String.sub content 0 8 = "Branch `" ->
      Some branch
  | _ -> None

(* Mock: tracks deleted branches for testing *)
let deleted_branches = ref []
let local_branches = ref ["pi/failed-topic"; "pi/other-topic"]

let rejection_cleanup ~hub_path ~branch =
  if List.mem branch !local_branches then begin
    local_branches := List.filter ((<>) branch) !local_branches;
    deleted_branches := branch :: !deleted_branches;
    Deleted branch
  end else
    NotFound branch

let process_rejection_notice ~hub_path ~content =
  match parse_rejected_branch content with
  | Some branch ->
      let _ = rejection_cleanup ~hub_path ~branch in
      { materialized = true; branch_deleted = Some branch }
  | None ->
      { materialized = true; branch_deleted = None }

(* Message direction: you push to YOUR repo, peers pull from you *)
type direction = PushToSelf_PeerPulls

let message_direction = PushToSelf_PeerPulls

(* Outbound: create branch named <recipient>/<topic> in YOUR repo *)
let outbound_branch ~sender:_ ~recipient ~topic =
  recipient ^ "/" ^ topic

(* Inbound: look for branches named <your-name>/* in peer's clone *)
let inbound_pattern ~my_name =
  "origin/" ^ my_name ^ "/*"

let sync_phases = ["fetch_peers"; "check_inbound"; "materialize"; "flush_outbox"]

let required_frontmatter = ["to"; "created"]
let optional_frontmatter = ["from"; "subject"; "in-reply-to"; "branch"; "trigger"]

(* === Hub Layer === *)

type thread_location =
  | In
  | Mail_inbox
  | Mail_outbox
  | Mail_sent
  | Reflections_daily
  | Reflections_weekly
  | Reflections_monthly
  | Adhoc
  | Archived

let thread_path location name =
  let prefix = match location with
    | In -> "threads/in"
    | Mail_inbox -> "threads/mail/inbox"
    | Mail_outbox -> "threads/mail/outbox"
    | Mail_sent -> "threads/mail/sent"
    | Reflections_daily -> "threads/reflections/daily"
    | Reflections_weekly -> "threads/reflections/weekly"
    | Reflections_monthly -> "threads/reflections/monthly"
    | Adhoc -> "threads/adhoc"
    | Archived -> "threads/archived"
  in
  prefix ^ "/" ^ name ^ ".md"

let timestamp_filename slug =
  "20260209-120000-" ^ slug ^ ".md"

let state_path name = "state/" ^ name
let log_path name = "logs/" ^ name

(* === Agent Layer === *)

type agent_input = {
  id: string;
  from: string;
  queued: string;
  content: string;
}

type operation =
  | Send of { peer: string; message: string }
  | Done of string
  | Fail of { id: string; reason: string }
  | Reply of { thread_id: string; message: string }
  | Delegate of { thread_id: string; peer: string }
  | Defer of { id: string; until: string option }
  | Delete of string
  | Ack of string

type agent_output = {
  id: string;
  status: int;
  ops: operation list;
  body: string;
}

let example_input = {
  id = "pi-review";
  from = "pi";
  queued = "2026-02-09T05:00:00Z";
  content = "Please review";
}

let example_output = {
  id = "pi-review";
  status = 200;
  ops = [Done "pi-review"];
  body = "Done";
}

let status_meaning = function
  | 200 -> "OK — completed"
  | 201 -> "Created — new artifact"
  | 400 -> "Bad Request — malformed input"
  | 404 -> "Not Found — missing reference"
  | 422 -> "Unprocessable — understood but can't do"
  | 500 -> "Error — something broke"
  | n -> "Unknown: " ^ string_of_int n

let pp_operation = function
  | Send { peer; message } -> Printf.printf "Send to %s: %s\n" peer message
  | Done id -> Printf.printf "Done: %s\n" id
  | Fail { id; reason } -> Printf.printf "Fail %s: %s\n" id reason
  | Reply { thread_id; message } -> Printf.printf "Reply to %s: %s\n" thread_id message
  | Delegate { thread_id; peer } -> Printf.printf "Delegate %s to %s\n" thread_id peer
  | Defer { id; until } -> 
      Printf.printf "Defer %s until %s\n" id (Option.value until ~default:"unspecified")
  | Delete id -> Printf.printf "Delete: %s\n" id
  | Ack id -> Printf.printf "Ack: %s\n" id
