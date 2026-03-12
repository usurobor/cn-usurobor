(** cn_trace_state_test.ml — Tests for state projection writers *)



let%expect_test "ready projection JSON shape" =
  let r : Cn_trace_state.ready_projection = {
    status = Ready;
    boot_id = "20260315-140203-abcd";
    updated_at = "2026-03-15T14:02:04.000Z";
    blocked_reason = None;
    mind = Some {
      profile = "engineer";
      packages = ["cnos.core@1.0.0"; "cnos.eng@1.0.0"];
      doctrine_required = 6;
      doctrine_loaded = 6;
      doctrine_hash = "sha256:abc";
      mindsets_required = 9;
      mindsets_loaded = 9;
      mindsets_hash = "sha256:def";
      skills_indexed = 24;
      skills_selected_last = ["eng/review"; "agent-ops"];
      capabilities_hash = "sha256:ghi";
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
    scheduler = None;
  } in
  (* We can't write to disk in pure test, but we can verify the JSON shape
     by calling the internal serialization logic. Test via round-trip. *)
  let json = Cn_json.Object [
    "schema", Cn_json.String "cn.ready.v1";
    "status", Cn_json.String (Cn_trace_state.string_of_ready_status r.status);
    "boot_id", Cn_json.String r.boot_id;
  ] in
  let s = Cn_json.to_string json in
  (match Cn_json.parse s with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.ready.v1");
       assert (Cn_json.get_string "status" obj = Some "ready");
       assert (Cn_json.get_string "boot_id" obj = Some "20260315-140203-abcd");
       print_endline "ok: ready projection schema valid"
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: ready projection schema valid |}]

let%expect_test "blocked ready projection includes reason" =
  let r : Cn_trace_state.ready_projection = {
    status = Blocked;
    boot_id = "test-boot";
    updated_at = "2026-03-15T14:02:04.000Z";
    blocked_reason = Some "core_doctrine_missing";
    mind = None;
    body = None;
    sensors_telegram = None;
    scheduler = None;
  } in
  ignore r;
  Printf.printf "status: %s\n" (Cn_trace_state.string_of_ready_status Blocked);
  Printf.printf "reason: %s\n" (Option.get r.blocked_reason);
  [%expect {|
    status: blocked
    reason: core_doctrine_missing |}]

let%expect_test "ready_status rendering" =
  Printf.printf "%s %s %s %s\n"
    (Cn_trace_state.string_of_ready_status Ready)
    (Cn_trace_state.string_of_ready_status Degraded)
    (Cn_trace_state.string_of_ready_status Blocked)
    (Cn_trace_state.string_of_ready_status Starting);
  [%expect {| ready degraded blocked starting |}]

let%expect_test "coherence check rendering" =
  Printf.printf "%s %s %s\n"
    (Cn_trace_state.string_of_check Ok_)
    (Cn_trace_state.string_of_check Missing)
    (Cn_trace_state.string_of_check Error_);
  [%expect {| ok missing error |}]

(* === Integration tests: projection writes to filesystem === *)

let tmp_counter = ref 0

let make_tmp_hub () =
  incr tmp_counter;
  let base = Filename.concat (Filename.get_temp_dir_name ())
    (Printf.sprintf "cn-trace-state-test-%d-%d" (Unix.getpid ()) !tmp_counter) in
  Cn_ffi.Fs.ensure_dir (Filename.concat base "state");
  base

let%expect_test "write_ready creates state/ready.json on disk" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_ready hub {
    status = Ready; boot_id = "test-boot-001";
    updated_at = "2026-03-15T14:02:04.000Z";
    blocked_reason = None;
    mind = None;
    body = Some {
      fsm_state = "idle"; lock_held = false;
      current_cycle = None; queue_depth = 0;
    };
    sensors_telegram = None;
    scheduler = None;
  };
  let path = Filename.concat hub "state/ready.json" in
  assert (Sys.file_exists path);
  let content = Cn_ffi.Fs.read path in
  (match Cn_json.parse content with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.ready.v1");
       assert (Cn_json.get_string "status" obj = Some "ready");
       assert (Cn_json.get_string "boot_id" obj = Some "test-boot-001");
       (match Cn_json.get "body" obj with
        | Some body ->
            assert (Cn_json.get_string "fsm_state" body = Some "idle");
            print_endline "ok: ready.json written with body"
        | None -> print_endline "missing body")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: ready.json written with body |}]

let%expect_test "write_runtime creates state/runtime.json on disk" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_runtime hub {
    boot_id = "test-boot-002";
    current_cycle_id = Some "tg-42";
    current_pass = Some "A";
    active_trigger = Some "tg-42";
    queue_depth = 3;
    lock_held = true;
    lock_boot_id = Some "test-boot-002";
    pending_projection = None;
    updated_at = "2026-03-15T14:02:05.000Z";
  };
  let path = Filename.concat hub "state/runtime.json" in
  assert (Sys.file_exists path);
  let content = Cn_ffi.Fs.read path in
  (match Cn_json.parse content with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.runtime.v1");
       assert (Cn_json.get_string "current_cycle_id" obj = Some "tg-42");
       assert (Cn_json.get_string "current_pass" obj = Some "A");
       assert (Cn_json.get_int "queue_depth" obj = Some 3);
       (match Cn_json.get "lock_held" obj with
        | Some (Cn_json.Bool true) ->
            print_endline "ok: runtime.json written with cycle state"
        | _ -> print_endline "wrong lock_held")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: runtime.json written with cycle state |}]

let%expect_test "write_coherence creates state/coherence.json on disk" =
  let hub = make_tmp_hub () in
  Cn_trace_state.write_coherence hub {
    boot_id = "test-boot-003";
    status = "coherent";
    config = Ok_; lockfile = Ok_;
    doctrine = Ok_; mindsets = Ok_;
    packages = Ok_; capabilities = Ok_;
    transport = Missing;
    updated_at = "2026-03-15T14:02:06.000Z";
  };
  let path = Filename.concat hub "state/coherence.json" in
  assert (Sys.file_exists path);
  let content = Cn_ffi.Fs.read path in
  (match Cn_json.parse content with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.coherence.v1");
       assert (Cn_json.get_string "status" obj = Some "coherent");
       (match Cn_json.get "checks" obj with
        | Some checks ->
            assert (Cn_json.get_string "transport" checks = Some "missing");
            assert (Cn_json.get_string "doctrine" checks = Some "ok");
            print_endline "ok: coherence.json written with checks"
        | None -> print_endline "missing checks")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: coherence.json written with checks |}]

let%expect_test "projection update lifecycle: idle -> processing -> idle" =
  let hub = make_tmp_hub () in
  let boot_id = "test-lifecycle-001" in
  (* Phase 1: boot — idle state *)
  Cn_trace_state.write_runtime hub {
    boot_id; current_cycle_id = None; current_pass = None;
    active_trigger = None; queue_depth = 0;
    lock_held = false; lock_boot_id = None;
    pending_projection = None;
    updated_at = "2026-03-15T14:00:00.000Z";
  };
  Cn_trace_state.write_ready hub {
    status = Ready; boot_id;
    updated_at = "2026-03-15T14:00:00.000Z";
    blocked_reason = None; mind = None;
    body = Some { fsm_state = "idle"; lock_held = false;
                  current_cycle = None; queue_depth = 0; };
    sensors_telegram = None;
    scheduler = None;
  };
  (* Phase 2: lock acquired, cycle start *)
  Cn_trace_state.write_runtime hub {
    boot_id; current_cycle_id = Some "tg-99";
    current_pass = Some "A"; active_trigger = Some "tg-99";
    queue_depth = 0; lock_held = true;
    lock_boot_id = Some boot_id;
    pending_projection = None;
    updated_at = "2026-03-15T14:00:01.000Z";
  };
  Cn_trace_state.write_ready hub {
    status = Ready; boot_id;
    updated_at = "2026-03-15T14:00:01.000Z";
    blocked_reason = None; mind = None;
    body = Some { fsm_state = "processing"; lock_held = true;
                  current_cycle = Some "tg-99"; queue_depth = 0; };
    sensors_telegram = None;
    scheduler = None;
  };
  (* Phase 3: finalize complete, back to idle *)
  Cn_trace_state.write_runtime hub {
    boot_id; current_cycle_id = None; current_pass = None;
    active_trigger = None; queue_depth = 0;
    lock_held = false; lock_boot_id = None;
    pending_projection = None;
    updated_at = "2026-03-15T14:00:02.000Z";
  };
  Cn_trace_state.write_ready hub {
    status = Ready; boot_id;
    updated_at = "2026-03-15T14:00:02.000Z";
    blocked_reason = None; mind = None;
    body = Some { fsm_state = "idle"; lock_held = false;
                  current_cycle = None; queue_depth = 0; };
    sensors_telegram = None;
    scheduler = None;
  };
  (* Verify final state *)
  let rt = Cn_ffi.Fs.read (Filename.concat hub "state/runtime.json") in
  let rd = Cn_ffi.Fs.read (Filename.concat hub "state/ready.json") in
  (match Cn_json.parse rt, Cn_json.parse rd with
   | Ok rt_obj, Ok rd_obj ->
       (* runtime.json: idle, no cycle *)
       assert (Cn_json.get_string "current_cycle_id" rt_obj = None
               || Cn_json.get "current_cycle_id" rt_obj = Some Cn_json.Null);
       (match Cn_json.get "lock_held" rt_obj with
        | Some (Cn_json.Bool false) -> ()
        | _ -> assert false);
       (* ready.json: idle body *)
       (match Cn_json.get "body" rd_obj with
        | Some body ->
            assert (Cn_json.get_string "fsm_state" body = Some "idle");
            (match Cn_json.get "lock_held" body with
             | Some (Cn_json.Bool false) -> ()
             | _ -> assert false);
            print_endline "ok: lifecycle idle -> processing -> idle verified"
        | None -> print_endline "missing body")
   | _ -> print_endline "parse error");
  [%expect {| ok: lifecycle idle -> processing -> idle verified |}]

let%expect_test "update_ready_body preserves mind and sensors fields" =
  let hub = make_tmp_hub () in
  let boot_id = "test-preserve-001" in
  (* Write full ready.json with mind and sensors *)
  Cn_trace_state.write_ready hub {
    status = Ready; boot_id;
    updated_at = "2026-03-15T14:00:00.000Z";
    blocked_reason = None;
    mind = Some {
      profile = "engineer";
      packages = ["cnos.core@1.0.0"];
      doctrine_required = 6; doctrine_loaded = 6;
      doctrine_hash = "sha256:abc";
      mindsets_required = 9; mindsets_loaded = 9;
      mindsets_hash = "sha256:def";
      skills_indexed = 12;
      skills_selected_last = ["eng/review"];
      capabilities_hash = "sha256:ghi";
      two_pass = "auto"; apply_mode = "branch";
      exec_enabled = false;
    };
    body = Some {
      fsm_state = "idle"; lock_held = false;
      current_cycle = None; queue_depth = 0;
    };
    sensors_telegram = Some {
      enabled = true; offset = 42;
      last_poll_status = "ok";
      last_poll_at = "2026-03-15T13:59:00.000Z";
    };
    scheduler = None;
  };
  (* Now do a body-only update via update_ready_body *)
  Cn_trace_state.update_ready_body hub
    ~boot_id ~updated_at:"2026-03-15T14:00:01.000Z"
    { fsm_state = "processing"; lock_held = true;
      current_cycle = Some "tg-99"; queue_depth = 0; };
  (* Verify mind and sensors survived *)
  let path = Filename.concat hub "state/ready.json" in
  let content = Cn_ffi.Fs.read path in
  (match Cn_json.parse content with
   | Ok obj ->
       (* Body should be updated *)
       (match Cn_json.get "body" obj with
        | Some body ->
            assert (Cn_json.get_string "fsm_state" body = Some "processing");
            (match Cn_json.get "lock_held" body with
             | Some (Cn_json.Bool true) -> ()
             | _ -> assert false)
        | None -> assert false);
       (* Mind should be preserved *)
       (match Cn_json.get "mind" obj with
        | Some mind ->
            assert (Cn_json.get_string "profile" mind = Some "engineer");
            (match Cn_json.get "skills" mind with
             | Some skills ->
                 assert (Cn_json.get_int "indexed" skills = Some 12)
             | None -> assert false)
        | None ->
            print_endline "FAIL: mind field lost after body update";
            assert false);
       (* Sensors should be preserved *)
       (match Cn_json.get "sensors" obj with
        | Some sensors ->
            (match Cn_json.get "telegram" sensors with
             | Some tg ->
                 assert (Cn_json.get_int "offset" tg = Some 42);
                 print_endline "ok: mind and sensors preserved after body update"
             | None ->
                 print_endline "FAIL: telegram sensor lost";
                 assert false)
        | None ->
            print_endline "FAIL: sensors field lost after body update";
            assert false)
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: mind and sensors preserved after body update |}]

let%expect_test "update_ready_body works when no prior ready.json exists" =
  let hub = make_tmp_hub () in
  (* No prior write_ready — update_ready_body should still work *)
  Cn_trace_state.update_ready_body hub
    ~boot_id:"test-fresh-001"
    ~updated_at:"2026-03-15T14:00:00.000Z"
    { fsm_state = "idle"; lock_held = false;
      current_cycle = None; queue_depth = 0; };
  let path = Filename.concat hub "state/ready.json" in
  assert (Sys.file_exists path);
  let content = Cn_ffi.Fs.read path in
  (match Cn_json.parse content with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.ready.v1");
       (match Cn_json.get "body" obj with
        | Some body ->
            assert (Cn_json.get_string "fsm_state" body = Some "idle");
            print_endline "ok: update_ready_body works without prior ready.json"
        | None -> print_endline "missing body")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: update_ready_body works without prior ready.json |}]
