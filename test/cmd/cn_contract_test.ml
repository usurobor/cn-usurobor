(** cn_contract_test.ml — Protocol contract consistency checks (I2)

    Verifies that code constants match docs/α/schemas/protocol-contract.json.
    This is a deterministic structural check — no I/O to external systems.

    The contract is loaded at test time from the repo root.
    Any mismatch between code and contract fails the test. *)

(* === Contract loading === *)

(** Find the repo root by walking up from the test binary location.
    Falls back to common locations. *)
let find_contract_path () =
  let candidates = [
    (* dune runs tests from the repo root *)
    "docs/α/schemas/protocol-contract.json";
    (* fallback: absolute from build context *)
    "../../../docs/α/schemas/protocol-contract.json";
  ] in
  match List.find_opt Sys.file_exists candidates with
  | Some p -> p
  | None -> failwith "protocol-contract.json not found"

let load_contract () =
  let path = find_contract_path () in
  let content = Cn_ffi.Fs.read path in
  match Cn_json.parse content with
  | Ok obj -> obj
  | Error e -> failwith (Printf.sprintf "Failed to parse contract: %s" e)

(** Extract string list from a JSON array *)
let json_string_list json key =
  match Cn_json.get_list key json with
  | Some items ->
    List.filter_map (function Cn_json.String s -> Some s | _ -> None) items
  | None -> failwith (Printf.sprintf "Missing key '%s' in contract" key)

let json_string_list_at json keys =
  let rec drill j = function
    | [] -> j
    | k :: rest ->
      match Cn_json.get k j with
      | Some sub -> drill sub rest
      | None -> failwith (Printf.sprintf "Missing nested key '%s'" k)
  in
  let target = drill json (List.rev (List.tl (List.rev keys))) in
  json_string_list target (List.nth keys (List.length keys - 1))

(* === Helpers === *)

let sorted xs = List.sort String.compare xs

let check_match ~label ~expected ~actual =
  let exp = sorted expected in
  let act = sorted actual in
  if exp = act then
    Printf.printf "%s: ok (%d items)\n" label (List.length exp)
  else begin
    Printf.printf "%s: MISMATCH\n" label;
    Printf.printf "  expected: [%s]\n" (String.concat ", " exp);
    Printf.printf "  actual:   [%s]\n" (String.concat ", " act)
  end

(* === Contract checks === *)

let%expect_test "I2: coordination ops match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "coordination_ops" contract with
    | Some obj -> json_string_list obj "ops"
    | None -> failwith "Missing coordination_ops" in
  (* From cn_lib.ml parse_agent_op: keys that produce Some *)
  let actual = ["ack"; "done"; "fail"; "reply"; "send";
                "delegate"; "defer"; "delete"; "surface"; "mca"] in
  check_match ~label:"coordination_ops" ~expected ~actual;
  [%expect {| coordination_ops: ok (10 items) |}]

let%expect_test "I2: typed observe ops match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "typed_ops" contract with
    | Some obj -> json_string_list obj "observe"
    | None -> failwith "Missing typed_ops.observe" in
  (* From cn_shell.ml observe_kind_of_string *)
  let actual = ["fs_read"; "fs_list"; "fs_glob";
                "git_status"; "git_diff"; "git_log"; "git_grep"] in
  check_match ~label:"typed_ops.observe" ~expected ~actual;
  [%expect {| typed_ops.observe: ok (7 items) |}]

let%expect_test "I2: typed effect ops match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "typed_ops" contract with
    | Some obj -> json_string_list obj "effect"
    | None -> failwith "Missing typed_ops.effect" in
  (* From cn_shell.ml effect_kind_of_string *)
  let actual = ["fs_write"; "fs_patch"; "git_branch"; "git_commit"; "exec"] in
  check_match ~label:"typed_ops.effect" ~expected ~actual;
  [%expect {| typed_ops.effect: ok (5 items) |}]

let%expect_test "I2: receipt statuses match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "receipt_statuses" contract with
    | Some obj -> json_string_list obj "values"
    | None -> failwith "Missing receipt_statuses" in
  (* From cn_shell.ml string_of_receipt_status *)
  let actual = [
    Cn_shell.string_of_receipt_status Ok_status;
    Cn_shell.string_of_receipt_status Denied;
    Cn_shell.string_of_receipt_status Error_status;
    Cn_shell.string_of_receipt_status Skipped;
  ] in
  check_match ~label:"receipt_statuses" ~expected ~actual;
  [%expect {| receipt_statuses: ok (4 items) |}]

let%expect_test "I2: render reasons match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "render_reasons" contract with
    | Some obj -> json_string_list obj "values"
    | None -> failwith "Missing render_reasons" in
  (* From cn_output.ml string_of_render_reason *)
  let actual = [
    Cn_output.string_of_render_reason Control_plane_leak;
    Cn_output.string_of_render_reason Raw_frontmatter;
    Cn_output.string_of_render_reason Xml_tool_syntax;
    Cn_output.string_of_render_reason No_presentation_payload;
  ] in
  check_match ~label:"render_reasons" ~expected ~actual;
  [%expect {| render_reasons: ok (4 items) |}]

let%expect_test "I2: event layers match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "event_schema" contract with
    | Some obj -> json_string_list obj "layers"
    | None -> failwith "Missing event_schema.layers" in
  (* From cn_trace.ml string_of_layer *)
  let actual = [
    Cn_trace.string_of_layer Sensor;
    Cn_trace.string_of_layer Body;
    Cn_trace.string_of_layer Mind;
    Cn_trace.string_of_layer Governance;
    Cn_trace.string_of_layer World;
  ] in
  check_match ~label:"event_layers" ~expected ~actual;
  [%expect {| event_layers: ok (5 items) |}]

let%expect_test "I2: event severities match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "event_schema" contract with
    | Some obj -> json_string_list obj "severities"
    | None -> failwith "Missing event_schema.severities" in
  (* From cn_trace.ml string_of_severity *)
  let actual = [
    Cn_trace.string_of_severity Debug;
    Cn_trace.string_of_severity Info;
    Cn_trace.string_of_severity Warn;
    Cn_trace.string_of_severity Error_;
  ] in
  check_match ~label:"event_severities" ~expected ~actual;
  [%expect {| event_severities: ok (4 items) |}]

let%expect_test "I2: event statuses match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "event_schema" contract with
    | Some obj -> json_string_list obj "statuses"
    | None -> failwith "Missing event_schema.statuses" in
  (* From cn_trace.ml string_of_status *)
  let actual = [
    Cn_trace.string_of_status Ok_;
    Cn_trace.string_of_status Degraded;
    Cn_trace.string_of_status Blocked;
    Cn_trace.string_of_status Error_status;
    Cn_trace.string_of_status Skipped;
  ] in
  check_match ~label:"event_statuses" ~expected ~actual;
  [%expect {| event_statuses: ok (5 items) |}]

let%expect_test "I2: FSM thread states match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "thread_states"
    | None -> failwith "Missing fsm.thread_states" in
  (* From cn_protocol.ml string_of_thread_state *)
  let actual = [
    Cn_protocol.string_of_thread_state Received;
    Cn_protocol.string_of_thread_state Queued;
    Cn_protocol.string_of_thread_state Active;
    Cn_protocol.string_of_thread_state Doing;
    Cn_protocol.string_of_thread_state Deferred;
    Cn_protocol.string_of_thread_state Delegated;
    Cn_protocol.string_of_thread_state Archived;
    Cn_protocol.string_of_thread_state Deleted;
  ] in
  check_match ~label:"fsm.thread_states" ~expected ~actual;
  [%expect {| fsm.thread_states: ok (8 items) |}]

let%expect_test "I2: FSM thread events match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "thread_events"
    | None -> failwith "Missing fsm.thread_events" in
  (* From cn_protocol.ml string_of_thread_event *)
  let actual = [
    Cn_protocol.string_of_thread_event Enqueue;
    Cn_protocol.string_of_thread_event Feed;
    Cn_protocol.string_of_thread_event Claim;
    Cn_protocol.string_of_thread_event Complete;
    Cn_protocol.string_of_thread_event Defer;
    Cn_protocol.string_of_thread_event Delegate;
    Cn_protocol.string_of_thread_event Discard;
    Cn_protocol.string_of_thread_event Resurface;
  ] in
  check_match ~label:"fsm.thread_events" ~expected ~actual;
  [%expect {| fsm.thread_events: ok (8 items) |}]

let%expect_test "I2: FSM actor states match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "actor_states"
    | None -> failwith "Missing fsm.actor_states" in
  (* From cn_protocol.ml string_of_actor_state *)
  let actual = [
    Cn_protocol.string_of_actor_state Idle;
    Cn_protocol.string_of_actor_state Updating;
    Cn_protocol.string_of_actor_state InputReady;
    Cn_protocol.string_of_actor_state Processing;
    Cn_protocol.string_of_actor_state OutputReady;
    Cn_protocol.string_of_actor_state TimedOut;
  ] in
  check_match ~label:"fsm.actor_states" ~expected ~actual;
  [%expect {| fsm.actor_states: ok (6 items) |}]

let%expect_test "I2: FSM actor events match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "actor_events"
    | None -> failwith "Missing fsm.actor_events" in
  (* From cn_protocol.ml string_of_actor_event *)
  let actual = [
    Cn_protocol.string_of_actor_event Update_available;
    Cn_protocol.string_of_actor_event Update_complete;
    Cn_protocol.string_of_actor_event Update_fail;
    Cn_protocol.string_of_actor_event Update_skip;
    Cn_protocol.string_of_actor_event Queue_pop;
    Cn_protocol.string_of_actor_event Queue_empty;
    Cn_protocol.string_of_actor_event Wake;
    Cn_protocol.string_of_actor_event Output_received;
    Cn_protocol.string_of_actor_event Timeout;
    Cn_protocol.string_of_actor_event Archive_complete;
    Cn_protocol.string_of_actor_event Archive_fail;
  ] in
  check_match ~label:"fsm.actor_events" ~expected ~actual;
  [%expect {| fsm.actor_events: ok (11 items) |}]

let%expect_test "I2: FSM sender states match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "sender_states"
    | None -> failwith "Missing fsm.sender_states" in
  (* From cn_protocol.ml string_of_sender_state *)
  let actual = [
    Cn_protocol.string_of_sender_state S_Pending;
    Cn_protocol.string_of_sender_state S_BranchCreated;
    Cn_protocol.string_of_sender_state S_Pushing;
    Cn_protocol.string_of_sender_state S_Pushed;
    Cn_protocol.string_of_sender_state S_Failed;
    Cn_protocol.string_of_sender_state S_Delivered;
  ] in
  check_match ~label:"fsm.sender_states" ~expected ~actual;
  [%expect {| fsm.sender_states: ok (6 items) |}]

let%expect_test "I2: FSM receiver states match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "fsm" contract with
    | Some obj -> json_string_list obj "receiver_states"
    | None -> failwith "Missing fsm.receiver_states" in
  (* From cn_protocol.ml string_of_receiver_state *)
  let actual = [
    Cn_protocol.string_of_receiver_state R_Fetched;
    Cn_protocol.string_of_receiver_state R_Materializing;
    Cn_protocol.string_of_receiver_state R_Materialized;
    Cn_protocol.string_of_receiver_state R_Skipped;
    Cn_protocol.string_of_receiver_state R_Rejected;
    Cn_protocol.string_of_receiver_state R_Cleaned;
  ] in
  check_match ~label:"fsm.receiver_states" ~expected ~actual;
  [%expect {| fsm.receiver_states: ok (6 items) |}]

let%expect_test "I2: readiness statuses match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "readiness" contract with
    | Some obj -> json_string_list obj "statuses"
    | None -> failwith "Missing readiness.statuses" in
  (* From cn_trace_state.ml string_of_ready_status *)
  let actual = [
    Cn_trace_state.string_of_ready_status Ready;
    Cn_trace_state.string_of_ready_status Degraded;
    Cn_trace_state.string_of_ready_status Blocked;
    Cn_trace_state.string_of_ready_status Starting;
  ] in
  check_match ~label:"readiness.statuses" ~expected ~actual;
  [%expect {| readiness.statuses: ok (4 items) |}]

let%expect_test "I2: coherence checks match contract" =
  let contract = load_contract () in
  let expected = match Cn_json.get "readiness" contract with
    | Some obj -> json_string_list obj "coherence_checks"
    | None -> failwith "Missing readiness.coherence_checks" in
  (* From cn_trace_state.ml string_of_check *)
  let actual = [
    Cn_trace_state.string_of_check Ok_;
    Cn_trace_state.string_of_check Missing;
    Cn_trace_state.string_of_check Error_;
  ] in
  check_match ~label:"readiness.coherence_checks" ~expected ~actual;
  [%expect {| readiness.coherence_checks: ok (3 items) |}]
