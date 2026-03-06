(** cn_projection_test: ppx_expect tests for projection idempotency

    Tests atomic marker creation, deduplication, and crash-recovery
    semantics per AGENT-RUNTIME-v3.3.6 §reply idempotency requirement.

    Marker path: state/projected/{projection}/{trigger_id}.sent
    Mechanism: O_CREAT|O_EXCL (atomic, no TOCTOU) *)

(* === Temp hub setup === *)

let mk_temp_dir prefix =
  let base = Filename.get_temp_dir_name () in
  let rec attempt k =
    if k = 0 then failwith "mk_temp_dir: exhausted attempts";
    let dir =
      Filename.concat base
        (Printf.sprintf "%s-%d-%06d" prefix (Unix.getpid ()) (Random.int 1_000_000))
    in
    try Unix.mkdir dir 0o700; dir
    with Unix.Unix_error (Unix.EEXIST, _, _) -> attempt (k - 1)
  in
  Random.self_init ();
  attempt 50

let with_test_hub f =
  let hub = mk_temp_dir "cn-proj-test" in
  Cn_ffi.Fs.ensure_dir (Filename.concat hub "state");
  Fun.protect ~finally:(fun () ->
    let rec rm path =
      if Sys.is_directory path then begin
        Sys.readdir path |> Array.iter (fun entry ->
          rm (Filename.concat path entry)
        );
        Unix.rmdir path
      end else
        Sys.remove path
    in
    (try rm hub with _ -> ())
  ) (fun () -> f hub)

(* ============================================================ *)
(* === MARKER PATH                                            === *)
(* ============================================================ *)

let%expect_test "marker_path: follows spec shape" =
  let p = Cn_projection.marker_path ~hub_path:"/hub" ~projection:"telegram"
            ~trigger_id:"tg-12345" in
  print_endline p;
  [%expect {| /hub/state/projected/telegram/tg-12345.sent |}]

let%expect_test "marker_path: different projection" =
  let p = Cn_projection.marker_path ~hub_path:"/hub" ~projection:"slack"
            ~trigger_id:"slack-001" in
  print_endline p;
  [%expect {| /hub/state/projected/slack/slack-001.sent |}]

(* ============================================================ *)
(* === ATOMIC MARKER CREATION                                 === *)
(* ============================================================ *)

let%expect_test "try_mark: first call succeeds" =
  with_test_hub (fun hub ->
    match Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
            ~trigger_id:"test-001" with
    | Ok () -> print_endline "ok"
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {| ok |}]

let%expect_test "try_mark: second call returns already_projected" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    match Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
            ~trigger_id:"test-001" with
    | Ok () -> print_endline "ok (unexpected)"
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {| error: already_projected |}]

let%expect_test "try_mark: different trigger_ids are independent" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    match Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
            ~trigger_id:"test-002" with
    | Ok () -> print_endline "ok"
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {| ok |}]

let%expect_test "try_mark: different projections are independent" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    match Cn_projection.try_mark ~hub_path:hub ~projection:"slack"
            ~trigger_id:"test-001" with
    | Ok () -> print_endline "ok"
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {| ok |}]

let%expect_test "try_mark: creates marker file on disk" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    let path = Cn_projection.marker_path ~hub_path:hub ~projection:"telegram"
                 ~trigger_id:"test-001" in
    Printf.printf "exists: %b\n" (Sys.file_exists path));
  [%expect {| exists: true |}]

(* ============================================================ *)
(* === IS_PROJECTED QUERY                                     === *)
(* ============================================================ *)

let%expect_test "is_projected: false before marking" =
  with_test_hub (fun hub ->
    Printf.printf "projected: %b\n"
      (Cn_projection.is_projected ~hub_path:hub ~projection:"telegram"
         ~trigger_id:"test-001"));
  [%expect {| projected: false |}]

let%expect_test "is_projected: true after marking" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    Printf.printf "projected: %b\n"
      (Cn_projection.is_projected ~hub_path:hub ~projection:"telegram"
         ~trigger_id:"test-001"));
  [%expect {| projected: true |}]

(* ============================================================ *)
(* === CRASH RECOVERY SIMULATION                              === *)
(* ============================================================ *)

let%expect_test "crash recovery: marker survives, second attempt skipped" =
  with_test_hub (fun hub ->
    (* First run: mark + "send" *)
    let r1 = Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
               ~trigger_id:"crash-test" in
    (* Simulate crash: marker persists, but processing restarts *)
    (* Second run: try_mark again *)
    let r2 = Cn_projection.try_mark ~hub_path:hub ~projection:"telegram"
               ~trigger_id:"crash-test" in
    Printf.printf "first: %s\n"
      (match r1 with Ok () -> "ok" | Error r -> r);
    Printf.printf "second: %s\n"
      (match r2 with Ok () -> "ok" | Error r -> r));
  [%expect {|
    first: ok
    second: already_projected |}]

(* ============================================================ *)
(* === ORCHESTRATOR INTEGRATION: CONDITIONAL REPLY             === *)
(* ============================================================ *)

let show_coord_decision d =
  match d with
  | Cn_orchestrator.Execute -> print_endline "execute"
  | Cn_orchestrator.Skip reason -> Printf.printf "skip: %s\n" reason

let%expect_test "reply: pass-A-safe when projection is idempotent" =
  show_coord_decision
    (Cn_orchestrator.classify_coordination_pass_a
       ~has_idempotent_projection:true (Cn_lib.Reply ("id", "msg")));
  [%expect {| execute |}]

let%expect_test "reply: pass-A-unsafe when projection is NOT idempotent" =
  show_coord_decision
    (Cn_orchestrator.classify_coordination_pass_a
       ~has_idempotent_projection:false (Cn_lib.Reply ("id", "msg")));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "ack: always pass-A-safe regardless of projection" =
  show_coord_decision
    (Cn_orchestrator.classify_coordination_pass_a
       ~has_idempotent_projection:false (Cn_lib.Ack "id"));
  [%expect {| execute |}]

let%expect_test "done: always pass-A-unsafe regardless of projection" =
  show_coord_decision
    (Cn_orchestrator.classify_coordination_pass_a
       ~has_idempotent_projection:true (Cn_lib.Done "id"));
  [%expect {| skip: pass_a_unsafe |}]

(* ============================================================ *)
(* === PROJECT_REPLY: FULL FLOW                               === *)
(* ============================================================ *)

let%expect_test "project_reply: first call returns Send" =
  with_test_hub (fun hub ->
    match Cn_projection.project_reply ~hub_path:hub ~projection:"telegram"
            ~trigger_id:"test-001" with
    | `Send -> print_endline "send"
    | `Already_projected -> print_endline "already_projected");
  [%expect {| send |}]

let%expect_test "project_reply: second call returns Already_projected" =
  with_test_hub (fun hub ->
    ignore (Cn_projection.project_reply ~hub_path:hub ~projection:"telegram"
              ~trigger_id:"test-001");
    match Cn_projection.project_reply ~hub_path:hub ~projection:"telegram"
            ~trigger_id:"test-001" with
    | `Send -> print_endline "send"
    | `Already_projected -> print_endline "already_projected");
  [%expect {| already_projected |}]
