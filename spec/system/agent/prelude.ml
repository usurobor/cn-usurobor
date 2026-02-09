(* Agent layer prelude *)

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
