(** cn_orchestrator_test: ppx_expect tests for N-pass orchestrator

    Tests the orchestration logic from AGENT-RUNTIME v3.3.6:
    - N-pass triggering (auto vs off)
    - Observe pass: observe executes, effects deferred
    - Effect pass: effects execute, observe denied
    - Coordination classification (pass-safe vs pass-unsafe)
    - Coordination gating (terminal ops gated on effect failure)
    - Receipt pass tagging
    - Next-pass repacking (deterministic output) *)

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
  let hub = mk_temp_dir "cn-orch-test" in
  let dirs = ["src"; "docs"; ".cn"; "spec"; "state"; "logs";
              "state/artifacts"; "state/receipts"] in
  List.iter (fun d ->
    Cn_ffi.Fs.ensure_dir (Filename.concat hub d)
  ) dirs;
  let touch path content =
    let full = Filename.concat hub path in
    Cn_ffi.Fs.ensure_dir (Filename.dirname full);
    let oc = open_out full in
    output_string oc content;
    close_out oc
  in
  touch "src/main.ml" "let () = print_endline \"hello\"";
  touch "docs/README.md" "# Docs";
  touch "spec/SOUL.md" "# SOUL";
  touch "spec/USER.md" "# USER";
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

let auto_config = {
  Cn_shell.n_pass = "auto";
  apply_mode = "working_tree";
  exec_enabled = false;
  exec_allowlist = [];
  max_observe_ops = 10;
  max_artifact_bytes = 65536;
  max_artifact_bytes_per_op = 16384;
  max_passes = 5;
  max_total_artifact_bytes = 131072;
  max_total_ops = 32;
}

let off_config = { auto_config with n_pass = "off" }
let trigger_id = "orch-test-001"

let show_receipt (r : Cn_shell.receipt) =
  Printf.printf "pass=%s kind=%s status=%s reason=%s\n"
    r.pass r.kind (Cn_shell.string_of_receipt_status r.status)
    (if r.reason = "" then "(none)" else r.reason)

(* === Helper: make typed ops === *)

let make_observe kind_str =
  let kind = match Cn_shell.op_kind_of_string kind_str with
    | Some k -> k | None -> failwith "bad kind" in
  { Cn_shell.kind; op_id = None; fields = [] }

let make_observe_with ~op_id ~fields kind_str =
  let kind = match Cn_shell.op_kind_of_string kind_str with
    | Some k -> k | None -> failwith "bad kind" in
  { Cn_shell.kind; op_id = Some op_id; fields }

let make_effect ~op_id ~fields kind_str =
  let kind = match Cn_shell.op_kind_of_string kind_str with
    | Some k -> k | None -> failwith "bad kind" in
  { Cn_shell.kind; op_id = Some op_id; fields }

(* ============================================================ *)
(* === N-PASS TRIGGERING                                      === *)
(* ============================================================ *)

let%expect_test "auto + observe ops → effects_deferred=true" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    Printf.printf "receipt_count: %d\n" (List.length receipts);
    List.iter show_receipt receipts);
  [%expect {|
    effects_deferred: true
    receipt_count: 1
    pass=1 kind=fs_read status=ok reason=(none) |}]

let%expect_test "auto + effect-only → effects_deferred=false (single pass)" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write"
    ] in
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    List.iter show_receipt receipts);
  [%expect {|
    effects_deferred: false
    pass=1 kind=fs_write status=ok reason=(none) |}]

let%expect_test "auto + mixed observe+effect → effects deferred" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    List.iter show_receipt receipts);
  [%expect {|
    effects_deferred: true
    pass=1 kind=fs_read status=ok reason=(none)
    pass=1 kind=fs_write status=skipped reason=observe_pass_requires_followup |}]

let%expect_test "off + mixed → all execute, single pass" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:off_config ops in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    List.iter show_receipt receipts);
  [%expect {|
    effects_deferred: false
    pass=1 kind=fs_read status=ok reason=(none)
    pass=1 kind=fs_write status=ok reason=(none) |}]

let%expect_test "off + observe-only → execute, no continuation" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:off_config ops in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    List.iter show_receipt receipts);
  [%expect {|
    effects_deferred: false
    pass=1 kind=fs_read status=ok reason=(none) |}]

(* ============================================================ *)
(* === EFFECT PASS EXECUTION                                  === *)
(* ============================================================ *)

let%expect_test "effect pass: effects execute, observe denied max_passes_exceeded" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_effect_pass ~pass_label:"2" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {|
    pass=2 kind=fs_read status=denied reason=max_passes_exceeded
    pass=2 kind=fs_write status=ok reason=(none) |}]

let%expect_test "effect pass: effect-only all execute" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_effect_pass ~pass_label:"2" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {| pass=2 kind=fs_write status=ok reason=(none) |}]

let%expect_test "effect pass: denied effects still receipted" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String ".cn/evil.ml");
                 ("content", Cn_json.String "bad")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_effect_pass ~pass_label:"2" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {| pass=2 kind=fs_write status=denied reason=path_denied |}]

(* ============================================================ *)
(* === RECEIPT PASS TAGGING                                   === *)
(* ============================================================ *)

let%expect_test "observe pass receipts all tagged '1'" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x")] "fs_write";
    ] in
    let (receipts, _effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    let all_1 = List.for_all (fun (r : Cn_shell.receipt) -> r.pass = "1") receipts in
    Printf.printf "all_pass_1: %b\n" all_1);
  [%expect {| all_pass_1: true |}]

let%expect_test "effect pass receipts all tagged '2'" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_effect_pass ~pass_label:"2" ~hub_path:hub ~trigger_id ~config:auto_config ops in
    let all_2 = List.for_all (fun (r : Cn_shell.receipt) -> r.pass = "2") result in
    Printf.printf "all_pass_2: %b\n" all_2);
  [%expect {| all_pass_2: true |}]

(* ============================================================ *)
(* === COORDINATION CLASSIFICATION                            === *)
(* ============================================================ *)

let show_coord_decision d =
  match d with
  | Cn_orchestrator.Execute -> print_endline "execute"
  | Cn_orchestrator.Skip reason -> Printf.printf "skip: %s\n" reason

let%expect_test "pass-safe: ack" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Ack "test"));
  [%expect {| execute |}]

let%expect_test "pass-safe: surface" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Surface "mca"));
  [%expect {| execute |}]

let%expect_test "pass-safe: reply" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Reply ("id", "msg")));
  [%expect {| execute |}]

let%expect_test "pass-unsafe: done" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Done "id"));
  [%expect {| skip: pass_unsafe |}]

let%expect_test "pass-unsafe: fail" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Fail ("id", "reason")));
  [%expect {| skip: pass_unsafe |}]

let%expect_test "pass-unsafe: send" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Send ("peer", "msg", None)));
  [%expect {| skip: pass_unsafe |}]

let%expect_test "pass-unsafe: delegate" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Delegate ("id", "peer")));
  [%expect {| skip: pass_unsafe |}]

let%expect_test "pass-unsafe: defer" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Defer ("id", None)));
  [%expect {| skip: pass_unsafe |}]

let%expect_test "pass-unsafe: delete" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_safe (Cn_lib.Delete "id"));
  [%expect {| skip: pass_unsafe |}]

(* ============================================================ *)
(* === COORDINATION GATING                                    === *)
(* ============================================================ *)

let%expect_test "gating: terminal ops blocked when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "2"; op_id = Some "write-01"; kind = "fs_write";
      status = Error_status; reason = "patch_failed";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| skip: effects_failed |}]

let%expect_test "gating: terminal ops allowed when effects succeeded" =
  let effect_receipts = [
    { Cn_shell.pass = "2"; op_id = Some "write-01"; kind = "fs_write";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| execute |}]

let%expect_test "gating: reply allowed even when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "2"; op_id = Some "write-01"; kind = "fs_write";
      status = Error_status; reason = "patch_failed";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Reply ("id", "msg")));
  [%expect {| execute |}]

let%expect_test "gating: ack allowed even when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "2"; op_id = Some "write-01"; kind = "fs_write";
      status = Denied; reason = "path_denied";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Ack "id"));
  [%expect {| execute |}]

let%expect_test "gating: send blocked when effects denied" =
  let effect_receipts = [
    { Cn_shell.pass = "2"; op_id = Some "write-01"; kind = "fs_write";
      status = Denied; reason = "path_denied";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Send ("peer", "msg", None)));
  [%expect {| skip: effects_failed |}]

let%expect_test "gating: no effect receipts → terminal ops allowed" =
  let effect_receipts = [] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| execute |}]

let%expect_test "gating: skipped effects (deferred) don't block" =
  let effect_receipts = [
    { Cn_shell.pass = "1"; op_id = Some "write-01"; kind = "fs_write";
      status = Skipped; reason = "observe_pass_requires_followup";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| execute |}]

(* ============================================================ *)
(* === NEXT-PASS REPACKING                                    === *)
(* ============================================================ *)

let%expect_test "repack_for_next_pass: includes receipts summary" =
  with_test_hub (fun hub ->
    let receipts = [
      { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = "2026-01-01T00:00:00Z"; end_time = "2026-01-01T00:00:01Z";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:abc"; size = 42 }] }
    ] in
    let content = Cn_orchestrator.repack_for_next_pass ~hub_path:hub
                    ~trigger_id ~config:auto_config ~pass_label:"1" ~pass_receipts:receipts in
    (* Should contain receipts section *)
    let has_receipts = String.length content > 0
                       && Cn_orchestrator.contains_sub content "Receipt" in
    Printf.printf "has_receipts_section: %b\n" has_receipts;
    Printf.printf "non_empty: %b\n" (String.length content > 0));
  [%expect {|
    has_receipts_section: true
    non_empty: true |}]

let%expect_test "repack_for_next_pass: includes artifact excerpts" =
  with_test_hub (fun hub ->
    (* Write an artifact file *)
    let art_dir = Filename.concat hub "state/artifacts/orch-test-001" in
    Cn_ffi.Fs.ensure_dir art_dir;
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-01.txt") "file content here";
    let receipts = [
      { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:abc"; size = 17 }] }
    ] in
    let content = Cn_orchestrator.repack_for_next_pass ~hub_path:hub
                    ~trigger_id ~config:auto_config ~pass_label:"1" ~pass_receipts:receipts in
    let has_artifact = Cn_orchestrator.contains_sub content "file content here" in
    Printf.printf "has_artifact_content: %b\n" has_artifact);
  [%expect {| has_artifact_content: true |}]

let%expect_test "repack_for_next_pass: deterministic ordering" =
  with_test_hub (fun hub ->
    let art_dir = Filename.concat hub "state/artifacts/orch-test-001" in
    Cn_ffi.Fs.ensure_dir art_dir;
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-01.txt") "first";
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-02.txt") "second";
    let receipts = [
      { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:aaa"; size = 5 }] };
      { Cn_shell.pass = "1"; op_id = Some "obs-02"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-02.txt";
                       hash = "sha256:bbb"; size = 6 }] };
    ] in
    let c1 = Cn_orchestrator.repack_for_next_pass ~hub_path:hub
               ~trigger_id ~config:auto_config ~pass_label:"1" ~pass_receipts:receipts in
    let c2 = Cn_orchestrator.repack_for_next_pass ~hub_path:hub
               ~trigger_id ~config:auto_config ~pass_label:"1" ~pass_receipts:receipts in
    Printf.printf "deterministic: %b\n" (c1 = c2));
  [%expect {| deterministic: true |}]

(* ============================================================ *)
(* === RECEIPT PERSISTENCE (pass 1 → pass 2 append)           === *)
(* ============================================================ *)

let%expect_test "full N-pass: receipts accumulate in one file" =
  with_test_hub (fun hub ->
    (* Pass 1 (observe) *)
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let (receipts_1, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id
                   ~config:auto_config pass_1_ops in
    assert effects_deferred;
    ignore receipts_1;

    (* Pass 2 (effect) *)
    let pass_2_ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let _pass_2 = Cn_orchestrator.run_effect_pass ~pass_label:"2" ~hub_path:hub ~trigger_id
                    ~config:auto_config pass_2_ops in

    (* Read receipts file *)
    let path = Filename.concat hub "state/receipts/orch-test-001.json" in
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Ok obj ->
      (match Cn_json.get_list "receipts" obj with
       | Some rs ->
         Printf.printf "total_receipts: %d\n" (List.length rs);
         List.iter (fun r ->
           match Cn_json.get_string "pass" r, Cn_json.get_string "kind" r,
                 Cn_json.get_string "status" r with
           | Some p, Some k, Some s -> Printf.printf "%s %s %s\n" p k s
           | _ -> print_endline "malformed"
         ) rs
       | None -> print_endline "no receipts")
    | Error msg -> Printf.printf "parse error: %s\n" msg);
  [%expect {|
    total_receipts: 3
    1 fs_read ok
    1 fs_write skipped
    2 fs_write ok |}]

(* ============================================================ *)
(* === EMPTY MANIFEST                                         === *)
(* ============================================================ *)

let%expect_test "empty ops list → single pass, no receipts" =
  with_test_hub (fun hub ->
    let (receipts, effects_deferred) = Cn_orchestrator.run_pass ~pass_label:"1" ~hub_path:hub ~trigger_id
                   ~config:auto_config [] in
    Printf.printf "effects_deferred: %b\n" effects_deferred;
    Printf.printf "receipt_count: %d\n" (List.length receipts));
  [%expect {|
    effects_deferred: false
    receipt_count: 0 |}]

(* ============================================================ *)
(* === DENIAL RECEIPTS FROM PARSER PASS THROUGH                === *)
(* ============================================================ *)

(* ============================================================ *)
(* === ANTI-CONFABULATION SIGNALS (#49)                      === *)
(* ============================================================ *)

let%expect_test "receipts_summary: ok with artifacts has no signal tag" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = "";
      artifacts = [{ path = "state/artifacts/t/obs-01.txt";
                     hash = "sha256:abc"; size = 42 }] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_empty = Cn_orchestrator.contains_sub summary "EMPTY_RESULT" in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_failed = Cn_orchestrator.contains_sub summary "FAILED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "empty=%b not_exec=%b failed=%b warning=%b\n"
    has_empty has_not_exec has_failed has_warning;
  [%expect {| empty=false not_exec=false failed=false warning=false |}]

let%expect_test "receipts_summary: ok with zero artifacts → EMPTY_RESULT" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_empty = Cn_orchestrator.contains_sub summary "EMPTY_RESULT" in
  Printf.printf "has_empty_result: %b\n" has_empty;
  [%expect {| has_empty_result: true |}]

let%expect_test "receipts_summary: denied → NOT_EXECUTED + WARNING" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "exec-01"; kind = "exec";
      status = Denied; reason = "not_in_allowlist";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  let has_reason = Cn_orchestrator.contains_sub summary "reason: not_in_allowlist" in
  Printf.printf "not_exec=%b warning=%b reason=%b\n"
    has_not_exec has_warning has_reason;
  [%expect {| not_exec=true warning=true reason=true |}]

let%expect_test "receipts_summary: error → FAILED + WARNING" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
      status = Error_status; reason = "file_not_found";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_failed = Cn_orchestrator.contains_sub summary "FAILED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "failed=%b warning=%b\n" has_failed has_warning;
  [%expect {| failed=true warning=true |}]

let%expect_test "receipts_summary: skipped → NOT_EXECUTED, no warning" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "write-01"; kind = "fs_write";
      status = Skipped; reason = "observe_pass_requires_followup";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "not_exec=%b warning=%b\n" has_not_exec has_warning;
  [%expect {| not_exec=true warning=false |}]

let%expect_test "receipts_summary: mixed ok+denied → WARNING present" =
  let receipts = [
    { Cn_shell.pass = "1"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = "";
      artifacts = [{ path = "state/artifacts/t/obs-01.txt";
                     hash = "sha256:abc"; size = 42 }] };
    { Cn_shell.pass = "1"; op_id = Some "exec-01"; kind = "exec";
      status = Denied; reason = "exec_disabled";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary ~pass_label:"1" receipts in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  let has_fabricate = Cn_orchestrator.contains_sub summary "fabricate" in
  Printf.printf "warning=%b fabricate=%b\n" has_warning has_fabricate;
  [%expect {| warning=true fabricate=true |}]

(* ============================================================ *)
(* === DENIAL RECEIPTS FROM PARSER PASS THROUGH                === *)
(* ============================================================ *)

let%expect_test "parser denial receipts get pass-tagged and written" =
  with_test_hub (fun hub ->
    let denial = Cn_shell.make_receipt ~pass:"" ~op_id:None ~kind:"frobnicate"
                   ~status:Denied ~reason:"unknown_op_kind" in
    Cn_orchestrator.write_denial_receipts ~hub_path:hub ~trigger_id ~pass:"1" [denial];
    let path = Filename.concat hub "state/receipts/orch-test-001.json" in
    let content = Cn_ffi.Fs.read path in
    match Cn_json.parse content with
    | Ok obj ->
      (match Cn_json.get_list "receipts" obj with
       | Some [r] ->
         (match Cn_json.get_string "pass" r, Cn_json.get_string "status" r with
          | Some p, Some s -> Printf.printf "pass=%s status=%s\n" p s
          | _ -> print_endline "malformed")
       | _ -> print_endline "wrong count")
    | Error msg -> Printf.printf "parse error: %s\n" msg);
  [%expect {| pass=1 status=denied |}]

(* ============================================================ *)
(* === N-PASS BIND LOOP (run_n_pass)                          === *)
(* ============================================================ *)

let n_pass_config = { auto_config with max_passes = 5 }
let n_pass_config_2 = { auto_config with max_passes = 2 }
let n_pass_config_1 = { auto_config with max_passes = 1 }

let show_n_pass_result result =
  Printf.printf "passes_used: %d\n" result.Cn_orchestrator.passes_used;
  Printf.printf "stop_reason: %s\n"
    (Cn_orchestrator.string_of_stop_reason result.stop_reason);
  Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
  List.iter show_receipt result.all_receipts

let%expect_test "n_pass: effect-only → single pass, no continuation" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write"
    ] in
    let llm_call _ = failwith "should not be called" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result -> show_n_pass_result result);
  [%expect {|
    passes_used: 1
    stop_reason: effect_only
    total_receipts: 1
    pass=1 kind=fs_write status=ok reason=(none) |}]

let%expect_test "n_pass: observe → effect → terminal (3 passes)" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    (* Pass 2 LLM returns an effect op *)
    let pass_2_output =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/out.ml\",\"content\":\"let y = 2\"}]\n---\n\nDone." in
    (* Pass 3 LLM returns no ops — terminal *)
    let pass_3_terminal =
      "---\nid: orch-test-001\n---\n\nAll done." in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      match !call_count with
      | 1 -> Ok pass_2_output
      | _ -> Ok pass_3_terminal
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "llm_calls: %d\n" !call_count;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts));
  [%expect {|
    passes_used: 3
    stop_reason: no_ops
    llm_calls: 2
    total_receipts: 2 |}]

let%expect_test "n_pass: max_passes=1 → all ops in single pass" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let llm_call _ = failwith "should not be called" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config_1 ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason));
  [%expect {|
    passes_used: 1
    stop_reason: max_passes_reached |}]

let%expect_test "n_pass: no-ops from LLM → terminal after 2 passes" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    (* Pass 2 LLM returns no typed ops *)
    let no_ops_output = "---\nid: orch-test-001\n---\n\nAll done, no more ops." in
    let llm_call _repack = Ok no_ops_output in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "has_final_output: %b\n" (result.final_output <> None));
  [%expect {|
    passes_used: 2
    stop_reason: no_ops
    has_final_output: true |}]

let%expect_test "n_pass: budget exhaustion stops loop" =
  with_test_hub (fun hub ->
    let ops = List.init 33 (fun i ->
      make_observe_with ~op_id:(Printf.sprintf "obs-%02d" (i + 1))
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ) in
    let budget_config = { auto_config with max_passes = 10; max_total_ops = 32 } in
    let llm_call _ = failwith "should not be called (budget exceeded)" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:budget_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason));
  [%expect {|
    passes_used: 1
    stop_reason: budget_exhausted |}]

let%expect_test "n_pass: LLM error propagates" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let llm_call _ = Error "API rate limit" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok _ -> print_endline "unexpected ok");
  [%expect {| error: Pass 1 LLM call failed: API rate limit |}]

let%expect_test "n_pass: pass labels are numeric (1, 2, ...)" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let call_count = ref 0 in
    let llm_call _ =
      incr call_count;
      match !call_count with
      | 1 ->
        (* Pass 2: effect-only *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-02\",\"path\":\"src/out.ml\",\"content\":\"let y = 2\"}]\n---\n\nDone."
      | _ ->
        (* Pass 3: terminal *)
        Ok "---\nid: orch-test-001\n---\n\nAll done."
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      let passes = List.sort_uniq String.compare
        (List.map (fun (r : Cn_shell.receipt) -> r.pass) result.all_receipts) in
      Printf.printf "pass_labels: %s\n" (String.concat ", " passes));
  [%expect {| pass_labels: 1, 2 |}]

(* ============================================================ *)
(* === 3+ PASS CHAIN (observe → observe → effect → terminal) === *)
(* ============================================================ *)

let%expect_test "n_pass: 4-pass chain (observe → observe → effect → terminal)" =
  with_test_hub (fun hub ->
    (* Pass 1: observe-only (fs_read) → continuation *)
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    (* Pass 2 LLM returns another observe (e.g. read a second file) *)
    let pass_2_observe =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-02\",\"path\":\"docs/README.md\"}]\n---\n\nLet me also check README." in
    (* Pass 3 LLM returns an effect (write based on both reads) *)
    let pass_3_effect =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/out.ml\",\"content\":\"let combined = 1\"}]\n---\n\nWrote combined output." in
    (* Pass 4 LLM returns no ops — terminal *)
    let pass_4_terminal =
      "---\nid: orch-test-001\n---\n\nAll done." in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      match !call_count with
      | 1 -> Ok pass_2_observe
      | 2 -> Ok pass_3_effect
      | _ -> Ok pass_4_terminal
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call pass_1_ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "llm_calls: %d\n" !call_count;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
      let passes = List.sort_uniq String.compare
        (List.map (fun (r : Cn_shell.receipt) -> r.pass) result.all_receipts) in
      Printf.printf "pass_labels: %s\n" (String.concat ", " passes));
  [%expect {|
    passes_used: 4
    stop_reason: no_ops
    llm_calls: 3
    total_receipts: 3
    pass_labels: 1, 2, 3 |}]

let%expect_test "n_pass: 3-pass chain hits max_passes=3 with more observe" =
  with_test_hub (fun hub ->
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let pass_2_observe =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-02\",\"path\":\"docs/README.md\"}]\n---\n\nChecking more." in
    let pass_3_observe =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-03\",\"path\":\"spec/SOUL.md\"}]\n---\n\nStill looking." in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      match !call_count with
      | 1 -> Ok pass_2_observe
      | 2 -> Ok pass_3_observe
      | _ -> Error "unexpected call"
    in
    let config_3 = { n_pass_config with max_passes = 3 } in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:config_3 ~llm_call pass_1_ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason));
  [%expect {|
    passes_used: 3
    stop_reason: max_passes_reached |}]

(* ============================================================ *)
(* === MISPLACED OPS CORRECTION (Issue #51)                   === *)
(* ============================================================ *)

let correction_msg = "Re-emit your ops in frontmatter."

let%expect_test "correction: typed ops recovered → ops execute normally" =
  with_test_hub (fun hub ->
    let corrected_output =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-01\",\"path\":\"src/main.ml\"}]\n---\n\nHere are the results." in
    let terminal_output =
      "---\nid: orch-test-001\n---\n\nAll done." in
    let call_count = ref 0 in
    let llm_call _ =
      incr call_count;
      match !call_count with
      | 1 -> Ok corrected_output
      | _ -> Ok terminal_output
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call
            ~correction_message:correction_msg [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "llm_calls: %d\n" !call_count;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts));
  [%expect {|
    passes_used: 3
    stop_reason: no_ops
    llm_calls: 2
    total_receipts: 1 |}]

let%expect_test "correction: coordination ops recovered → terminal with output" =
  with_test_hub (fun hub ->
    let corrected_output =
      "---\nid: orch-test-001\nreply: orch-test-001|Here is my reply\ndone: orch-test-001\n---\n\nCompleted." in
    let llm_call _ = Ok corrected_output in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call
            ~correction_message:correction_msg [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "has_final_output: %b\n" (result.final_output <> None);
      Printf.printf "coord_ops: %d\n" (List.length result.final_coordination_ops));
  [%expect {|
    passes_used: 1
    stop_reason: no_ops
    has_final_output: true
    coord_ops: 2 |}]

let%expect_test "correction: still misplaced → Misplaced_ops stop reason" =
  with_test_hub (fun hub ->
    let still_broken =
      "---\nid: orch-test-001\n---\nops: [{\"kind\":\"fs_read\",\"path\":\"x\"}]\nStill broken." in
    let llm_call _ = Ok still_broken in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call
            ~correction_message:correction_msg [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "has_final_output: %b\n" (result.final_output <> None));
  [%expect {|
    passes_used: 1
    stop_reason: misplaced_ops
    has_final_output: true |}]

let%expect_test "correction: consumes max_passes budget" =
  with_test_hub (fun hub ->
    (* max_passes=2: correction is pass 0, recovered ops execute as pass 1,
       then pass_index+1 >= max_passes → loop stops. The recovered ops
       get one execution pass but no further continuation. *)
    let corrected_output =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-01\",\"path\":\"src/main.ml\"}]\n---\n\nResults." in
    let llm_call _ = Ok corrected_output in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config_2 ~llm_call
            ~correction_message:correction_msg [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts));
  [%expect {|
    passes_used: 2
    stop_reason: max_passes_reached
    total_receipts: 1 |}]

let%expect_test "correction: LLM error → Error propagated" =
  with_test_hub (fun hub ->
    let llm_call _ = Error "API timeout" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call
            ~correction_message:correction_msg [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok _ -> print_endline "unexpected ok");
  [%expect {| error: Correction pass LLM call failed: API timeout |}]

let%expect_test "no correction_message + empty ops → empty terminal" =
  with_test_hub (fun hub ->
    let llm_call _ = failwith "should not be called" in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call [] with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason));
  [%expect {|
    passes_used: 0
    stop_reason: no_ops |}]

let%expect_test "n_pass: observe → effect → verify (effect continues)" =
  with_test_hub (fun hub ->
    (* Pass 1: observe — read a file *)
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      match !call_count with
      | 1 ->
        (* Pass 2: effect — write a file *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/out.ml\",\"content\":\"let x = 1\"}]\n---\n\nWriting."
      | 2 ->
        (* Pass 3: observe — verify the write *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-02\",\"path\":\"src/out.ml\"}]\n---\n\nVerifying."
      | 3 ->
        (* Pass 4: terminal — confirmed *)
        Ok "---\nid: orch-test-001\n---\n\nVerified and done."
      | _ -> Error "unexpected call"
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call pass_1_ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "llm_calls: %d\n" !call_count;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
      let pass_kinds = List.map (fun (r : Cn_shell.receipt) ->
        Printf.sprintf "%s:%s" r.pass r.kind
      ) result.all_receipts in
      Printf.printf "receipt_trail: %s\n" (String.concat " → " pass_kinds));
  [%expect {|
    passes_used: 4
    stop_reason: no_ops
    llm_calls: 3
    total_receipts: 3
    receipt_trail: 1:fs_read → 2:fs_write → 3:fs_read |}]

let%expect_test "n_pass: effect → observe → effect (full generic chain)" =
  with_test_hub (fun hub ->
    (* Pass 1: observe — triggers continuation *)
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      match !call_count with
      | 1 ->
        (* Pass 2: effect *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/a.ml\",\"content\":\"a\"}]\n---\n\nWrote a."
      | 2 ->
        (* Pass 3: observe (verify) *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_read\",\"op_id\":\"obs-02\",\"path\":\"src/a.ml\"}]\n---\n\nVerifying a."
      | 3 ->
        (* Pass 4: effect (fix based on verify) *)
        Ok "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-02\",\"path\":\"src/a.ml\",\"content\":\"a_fixed\"}]\n---\n\nFixed a."
      | 4 ->
        (* Pass 5: terminal *)
        Ok "---\nid: orch-test-001\n---\n\nDone."
      | _ -> Error "unexpected call"
    in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call pass_1_ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "llm_calls: %d\n" !call_count;
      let pass_kinds = List.map (fun (r : Cn_shell.receipt) ->
        Printf.sprintf "%s:%s" r.pass r.kind
      ) result.all_receipts in
      Printf.printf "receipt_trail: %s\n" (String.concat " → " pass_kinds));
  [%expect {|
    passes_used: 5
    stop_reason: no_ops
    llm_calls: 4
    receipt_trail: 1:fs_read → 2:fs_write → 3:fs_read → 4:fs_write |}]

let%expect_test "n_pass: backward compat — max_passes=2 matches N-pass" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let pass_2_output = "---\nid: orch-test-001\n---\n\nFinal response." in
    let llm_call _ = Ok pass_2_output in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config_2 ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "stop_reason: %s\n"
        (Cn_orchestrator.string_of_stop_reason result.stop_reason);
      Printf.printf "has_final_output: %b\n" (result.final_output <> None));
  [%expect {|
    passes_used: 2
    stop_reason: no_ops
    has_final_output: true |}]
