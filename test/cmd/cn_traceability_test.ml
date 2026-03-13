(** cn_traceability_test.ml — Traceability contract smoke tests (I3)

    Validates that the readiness projection writer (cn_trace_state.ml)
    produces output matching the required field schema from the protocol
    contract (docs/alpha/schemas/protocol-contract.json).

    These are deterministic structural checks. They write projections
    to a temp hub and then validate the JSON shape against the contract. *)

(* === Helpers === *)

let tmp_counter = ref 0

let make_tmp_hub () =
  incr tmp_counter;
  let base = Filename.concat (Filename.get_temp_dir_name ())
    (Printf.sprintf "cn-traceability-test-%d-%d" (Unix.getpid ()) !tmp_counter) in
  Cn_ffi.Fs.ensure_dir (Filename.concat base "state");
  base

(** Check that a JSON object has a specific key. Returns true/false. *)
let has_key key = function
  | Cn_json.Object fields -> List.exists (fun (k, _) -> k = key) fields
  | _ -> false

(** Check that a JSON object has all required keys. Print result. *)
let check_required_fields ~label ~required json =
  let missing = List.filter (fun k -> not (has_key k json)) required in
  match missing with
  | [] -> Printf.printf "%s: ok (%d fields present)\n" label (List.length required)
  | ms -> Printf.printf "%s: MISSING [%s]\n" label (String.concat ", " ms)

(** Load contract from repo *)
let load_contract () =
  let candidates = [
    "protocol-contract.json";
  ] in
  match List.find_opt Sys.file_exists candidates with
  | Some p ->
    let content = Cn_ffi.Fs.read p in
    (match Cn_json.parse content with
     | Ok obj -> obj
     | Error e -> failwith (Printf.sprintf "Contract parse error: %s" e))
  | None ->
    let cwd = Sys.getcwd () in
    failwith (Printf.sprintf "protocol-contract.json not found (cwd=%s)" cwd)

let get_required_fields contract path =
  let rec drill json = function
    | [] -> json
    | k :: rest ->
      match Cn_json.get k json with
      | Some sub -> drill sub rest
      | None -> failwith (Printf.sprintf "Missing contract path: %s" k)
  in
  let target = drill contract path in
  match target with
  | Cn_json.Array items ->
    List.filter_map (function Cn_json.String s -> Some s | _ -> None) items
  | _ -> failwith "Expected array for required fields"

(* === Full ready.json shape test === *)

let make_full_ready () : Cn_trace_state.ready_projection =
  { status = Ready;
    boot_id = "20260315-140203-abcd";
    updated_at = "2026-03-15T14:02:04.000Z";
    blocked_reason = None;
    mind = Some {
      profile = "engineer";
      packages = ["cnos.core@1.0.0"; "cnos.eng@1.0.0"];
      doctrine_required = 6;
      doctrine_loaded = 6;
      doctrine_hash = "sha256:abc123";
      mindsets_required = 9;
      mindsets_loaded = 9;
      mindsets_hash = "sha256:def456";
      skills_indexed = 24;
      skills_selected_last = ["eng/review"; "agent-ops"];
      capabilities_hash = "sha256:ghi789";
      two_pass = "auto";
      apply_mode = "branch";
      exec_enabled = false;
    };
    body = Some {
      fsm_state = "idle";
      lock_held = false;
      current_cycle = None;
      queue_depth = 0;
    };
    sensors_telegram = Some {
      enabled = true;
      offset = 12345;
      last_poll_status = "ok";
      last_poll_at = "2026-03-15T14:01:59.000Z";
    };
  }

let%expect_test "I3: ready.json top-level fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with
    | Ok obj -> obj
    | Error e -> failwith (Printf.sprintf "Parse error: %s" e) in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "top_level"] in
  check_required_fields ~label:"ready.json top_level" ~required json;
  [%expect {| ready.json top_level: ok (4 fields present) |}]

let%expect_test "I3: ready.json mind section fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let mind = match Cn_json.get "mind" json with
    | Some m -> m
    | None -> failwith "missing mind section" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "mind"] in
  check_required_fields ~label:"ready.json mind" ~required mind;
  [%expect {| ready.json mind: ok (6 fields present) |}]

let%expect_test "I3: ready.json mind.doctrine fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let mind = match Cn_json.get "mind" json with Some m -> m | None -> failwith "no mind" in
  let doctrine = match Cn_json.get "doctrine" mind with Some d -> d | None -> failwith "no doctrine" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "mind_doctrine"] in
  check_required_fields ~label:"ready.json mind.doctrine" ~required doctrine;
  [%expect {| ready.json mind.doctrine: ok (3 fields present) |}]

let%expect_test "I3: ready.json mind.mindsets fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let mind = match Cn_json.get "mind" json with Some m -> m | None -> failwith "no mind" in
  let mindsets = match Cn_json.get "mindsets" mind with Some m -> m | None -> failwith "no mindsets" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "mind_mindsets"] in
  check_required_fields ~label:"ready.json mind.mindsets" ~required mindsets;
  [%expect {| ready.json mind.mindsets: ok (3 fields present) |}]

let%expect_test "I3: ready.json mind.skills fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let mind = match Cn_json.get "mind" json with Some m -> m | None -> failwith "no mind" in
  let skills = match Cn_json.get "skills" mind with Some s -> s | None -> failwith "no skills" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "mind_skills"] in
  check_required_fields ~label:"ready.json mind.skills" ~required skills;
  [%expect {| ready.json mind.skills: ok (2 fields present) |}]

let%expect_test "I3: ready.json mind.capabilities fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let mind = match Cn_json.get "mind" json with Some m -> m | None -> failwith "no mind" in
  let caps = match Cn_json.get "capabilities" mind with Some c -> c | None -> failwith "no capabilities" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "mind_capabilities"] in
  check_required_fields ~label:"ready.json mind.capabilities" ~required caps;
  [%expect {| ready.json mind.capabilities: ok (4 fields present) |}]

let%expect_test "I3: ready.json body fields match contract" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  let body = match Cn_json.get "body" json with Some b -> b | None -> failwith "no body" in
  let contract = load_contract () in
  let required = get_required_fields contract
    ["readiness"; "ready_json_required_fields"; "body"] in
  check_required_fields ~label:"ready.json body" ~required body;
  [%expect {| ready.json body: ok (4 fields present) |}]

let%expect_test "I3: ready.json schema value is cn.ready.v1" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub (make_full_ready ());
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  (match Cn_json.get_string "schema" json with
   | Some "cn.ready.v1" -> print_endline "ok: schema is cn.ready.v1"
   | Some other -> Printf.printf "WRONG: schema is %s\n" other
   | None -> print_endline "MISSING: no schema field");
  [%expect {| ok: schema is cn.ready.v1 |}]

let%expect_test "I3: runtime.json schema value is cn.runtime.v1" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_runtime hub {
    boot_id = "test-boot";
    current_cycle_id = None; current_pass = None;
    active_trigger = None; queue_depth = 0;
    lock_held = false; lock_boot_id = None;
    pending_projection = None;
    updated_at = "2026-03-15T14:00:00.000Z";
  };
  let path = Filename.concat hub "state/runtime.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  (match Cn_json.get_string "schema" json with
   | Some "cn.runtime.v1" -> print_endline "ok: schema is cn.runtime.v1"
   | Some other -> Printf.printf "WRONG: schema is %s\n" other
   | None -> print_endline "MISSING: no schema field");
  [%expect {| ok: schema is cn.runtime.v1 |}]

let%expect_test "I3: coherence.json schema value is cn.coherence.v1" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_coherence hub {
    boot_id = "test-boot"; status = "coherent";
    config = Ok_; lockfile = Ok_; doctrine = Ok_;
    mindsets = Ok_; packages = Ok_; capabilities = Ok_;
    transport = Ok_; updated_at = "2026-03-15T14:00:00.000Z";
  };
  let path = Filename.concat hub "state/coherence.json" in
  let content = Cn_ffi.Fs.read path in
  let json = match Cn_json.parse content with Ok o -> o | Error e -> failwith e in
  (match Cn_json.get_string "schema" json with
   | Some "cn.coherence.v1" -> print_endline "ok: schema is cn.coherence.v1"
   | Some other -> Printf.printf "WRONG: schema is %s\n" other
   | None -> print_endline "MISSING: no schema field");
  [%expect {| ok: schema is cn.coherence.v1 |}]
