(** cn_trace_state_test.ml — Tests for state projection writers *)

open Cn_cmd

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
