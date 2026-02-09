(* Prelude for SYSTEM.md executable spec
   This defines types and mocks for documentation examples *)

(* === Core Types === *)

type peer_info = {
  name: string;
  hub: string option;
  clone: string option;
  kind: string option;
}

type branch_info = {
  peer: string;
  branch: string;
}

type validation_result = 
  | Valid of { merge_base: string }
  | Orphan of { author: string; reason: string }

type operation =
  | Send of { peer: string; message: string; body: string option }
  | Done of string
  | Fail of { id: string; reason: string }
  | Reply of { thread_id: string; message: string }
  | Delegate of { thread_id: string; peer: string }
  | Defer of { id: string; until: string option }
  | Delete of string
  | Ack of string

type agent_input = {
  id: string;
  from: string;
  queued: string;
  content: string;
}

type agent_output = {
  id: string;
  status: int;
  tldr: string option;
  mca: string option;
  ops: operation list;
  body: string;
}

type thread_location =
  | In
  | Mail_inbox
  | Mail_outbox
  | Mail_sent
  | Reflections_daily
  | Reflections_weekly
  | Adhoc
  | Archived

(* === Mock State === *)

let mock_branches = ref [
  { peer = "pi"; branch = "pi/valid-topic" };
  { peer = "pi"; branch = "pi/orphan-topic" };
]

let mock_orphans = ref ["pi/orphan-topic"]

(* === Spec Functions (for documentation) === *)

let is_orphan_branch branch =
  List.mem branch !mock_orphans

let validate_branch branch : validation_result =
  if is_orphan_branch branch then
    Orphan { author = "Pi <pi@cn-agent.local>"; reason = "no merge base with main" }
  else
    Valid { merge_base = "abc123" }

let get_peer_branches peer =
  !mock_branches |> List.filter (fun b -> b.peer = peer)

let thread_path location name =
  let prefix = match location with
    | In -> "threads/in"
    | Mail_inbox -> "threads/mail/inbox"
    | Mail_outbox -> "threads/mail/outbox"
    | Mail_sent -> "threads/mail/sent"
    | Reflections_daily -> "threads/reflections/daily"
    | Reflections_weekly -> "threads/reflections/weekly"
    | Adhoc -> "threads/adhoc"
    | Archived -> "threads/archived"
  in
  prefix ^ "/" ^ name ^ ".md"

let timestamp_filename slug =
  "20260209-120000-" ^ slug ^ ".md"

(* === Example Agent Processing === *)

let example_input : agent_input = {
  id = "pi-review-request";
  from = "pi";
  queued = "2026-02-09T05:00:00Z";
  content = "Please review the changes";
}

let example_output : agent_output = {
  id = "pi-review-request";
  status = 200;
  tldr = Some "reviewed, approved";
  mca = Some "merge after CI passes";
  ops = [Send { peer = "pi"; message = "LGTM"; body = Some "Full review details..." }];
  body = "# Review Complete\n\nLooks good to merge.";
}

(* === Status Codes === *)

let status_meaning = function
  | 200 -> "OK — completed"
  | 201 -> "Created — new artifact"
  | 400 -> "Bad Request — malformed input"
  | 404 -> "Not Found — missing reference"
  | 422 -> "Unprocessable — understood but can't do"
  | 500 -> "Error — something broke"
  | n -> "Unknown status: " ^ string_of_int n

(* === Printing Helpers === *)

let pp_validation_result = function
  | Valid { merge_base } -> Printf.printf "Valid (merge_base: %s)\n" merge_base
  | Orphan { author; reason } -> Printf.printf "Orphan (author: %s, reason: %s)\n" author reason

let pp_operation = function
  | Send { peer; message; _ } -> Printf.printf "Send to %s: %s\n" peer message
  | Done id -> Printf.printf "Done: %s\n" id
  | Fail { id; reason } -> Printf.printf "Fail %s: %s\n" id reason
  | Reply { thread_id; message } -> Printf.printf "Reply to %s: %s\n" thread_id message
  | Delegate { thread_id; peer } -> Printf.printf "Delegate %s to %s\n" thread_id peer
  | Defer { id; until } -> Printf.printf "Defer %s until %s\n" id (Option.value until ~default:"unspecified")
  | Delete id -> Printf.printf "Delete: %s\n" id
  | Ack id -> Printf.printf "Ack: %s\n" id
