(** cn_orchestrator_test: ppx_expect tests for two-pass orchestrator

    Tests the orchestration logic from AGENT-RUNTIME v3.3.6:
    - Two-pass triggering (auto vs off)
    - Pass A: observe executes, effects deferred
    - Pass B: effects execute, observe denied
    - Coordination classification (pass-A-safe vs pass-A-unsafe)
    - Coordination gating (terminal ops gated on effect failure)
    - Receipt pass tagging
    - Pass B repacking (deterministic output) *)

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
  Cn_shell.two_pass = "auto";
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

let off_config = { auto_config with two_pass = "off" }
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
(* === TWO-PASS TRIGGERING                                    === *)
(* ============================================================ *)

let%expect_test "auto + observe ops → needs_pass_b=true" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    Printf.printf "receipt_count: %d\n" (List.length result.receipts);
    List.iter show_receipt result.receipts);
  [%expect {|
    needs_pass_b: true
    receipt_count: 1
    pass=A kind=fs_read status=ok reason=(none) |}]

let%expect_test "auto + effect-only → needs_pass_b=false (single pass)" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write"
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    List.iter show_receipt result.receipts);
  [%expect {|
    needs_pass_b: false
    pass=A kind=fs_write status=ok reason=(none) |}]

let%expect_test "auto + mixed observe+effect → effects deferred" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:auto_config ops in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    List.iter show_receipt result.receipts);
  [%expect {|
    needs_pass_b: true
    pass=A kind=fs_read status=ok reason=(none)
    pass=A kind=fs_write status=skipped reason=observe_pass_requires_followup |}]

let%expect_test "off + mixed → all execute, single pass" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:off_config ops in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    List.iter show_receipt result.receipts);
  [%expect {|
    needs_pass_b: false
    pass=A kind=fs_read status=ok reason=(none)
    pass=A kind=fs_write status=ok reason=(none) |}]

let%expect_test "off + observe-only → execute, no pass B" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:off_config ops in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    List.iter show_receipt result.receipts);
  [%expect {|
    needs_pass_b: false
    pass=A kind=fs_read status=ok reason=(none) |}]

(* ============================================================ *)
(* === PASS B EXECUTION                                       === *)
(* ============================================================ *)

let%expect_test "pass B: effects execute, observe denied max_passes_exceeded" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_b ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {|
    pass=B kind=fs_read status=denied reason=max_passes_exceeded
    pass=B kind=fs_write status=ok reason=(none) |}]

let%expect_test "pass B: effect-only all execute" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_b ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {| pass=B kind=fs_write status=ok reason=(none) |}]

let%expect_test "pass B: denied effects still receipted" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String ".cn/evil.ml");
                 ("content", Cn_json.String "bad")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_b ~hub_path:hub ~trigger_id ~config:auto_config ops in
    List.iter show_receipt result);
  [%expect {| pass=B kind=fs_write status=denied reason=path_denied |}]

(* ============================================================ *)
(* === RECEIPT PASS TAGGING                                   === *)
(* ============================================================ *)

let%expect_test "pass A receipts all tagged 'A'" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id ~config:auto_config ops in
    let all_a = List.for_all (fun (r : Cn_shell.receipt) -> r.pass = "A") result.receipts in
    Printf.printf "all_pass_A: %b\n" all_a);
  [%expect {| all_pass_A: true |}]

let%expect_test "pass B receipts all tagged 'B'" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_pass_b ~hub_path:hub ~trigger_id ~config:auto_config ops in
    let all_b = List.for_all (fun (r : Cn_shell.receipt) -> r.pass = "B") result in
    Printf.printf "all_pass_B: %b\n" all_b);
  [%expect {| all_pass_B: true |}]

(* ============================================================ *)
(* === COORDINATION CLASSIFICATION                            === *)
(* ============================================================ *)

let show_coord_decision d =
  match d with
  | Cn_orchestrator.Execute -> print_endline "execute"
  | Cn_orchestrator.Skip reason -> Printf.printf "skip: %s\n" reason

let%expect_test "pass-A-safe: ack" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Ack "test"));
  [%expect {| execute |}]

let%expect_test "pass-A-safe: surface" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Surface "mca"));
  [%expect {| execute |}]

let%expect_test "pass-A-safe: reply" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Reply ("id", "msg")));
  [%expect {| execute |}]

let%expect_test "pass-A-unsafe: done" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Done "id"));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "pass-A-unsafe: fail" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Fail ("id", "reason")));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "pass-A-unsafe: send" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Send ("peer", "msg", None)));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "pass-A-unsafe: delegate" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Delegate ("id", "peer")));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "pass-A-unsafe: defer" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Defer ("id", None)));
  [%expect {| skip: pass_a_unsafe |}]

let%expect_test "pass-A-unsafe: delete" =
  show_coord_decision (Cn_orchestrator.classify_coordination_pass_a (Cn_lib.Delete "id"));
  [%expect {| skip: pass_a_unsafe |}]

(* ============================================================ *)
(* === COORDINATION GATING                                    === *)
(* ============================================================ *)

let%expect_test "gating: terminal ops blocked when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "B"; op_id = Some "write-01"; kind = "fs_write";
      status = Error_status; reason = "patch_failed";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| skip: effects_failed |}]

let%expect_test "gating: terminal ops allowed when effects succeeded" =
  let effect_receipts = [
    { Cn_shell.pass = "B"; op_id = Some "write-01"; kind = "fs_write";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| execute |}]

let%expect_test "gating: reply allowed even when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "B"; op_id = Some "write-01"; kind = "fs_write";
      status = Error_status; reason = "patch_failed";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Reply ("id", "msg")));
  [%expect {| execute |}]

let%expect_test "gating: ack allowed even when effects failed" =
  let effect_receipts = [
    { Cn_shell.pass = "B"; op_id = Some "write-01"; kind = "fs_write";
      status = Denied; reason = "path_denied";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Ack "id"));
  [%expect {| execute |}]

let%expect_test "gating: send blocked when effects denied" =
  let effect_receipts = [
    { Cn_shell.pass = "B"; op_id = Some "write-01"; kind = "fs_write";
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
    { Cn_shell.pass = "A"; op_id = Some "write-01"; kind = "fs_write";
      status = Skipped; reason = "observe_pass_requires_followup";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  show_coord_decision (Cn_orchestrator.gate_coordination ~effect_receipts (Cn_lib.Done "id"));
  [%expect {| execute |}]

(* ============================================================ *)
(* === PASS B REPACKING                                       === *)
(* ============================================================ *)

let%expect_test "repack_for_pass_b: includes receipts summary" =
  with_test_hub (fun hub ->
    let receipts = [
      { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = "2026-01-01T00:00:00Z"; end_time = "2026-01-01T00:00:01Z";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:abc"; size = 42 }] }
    ] in
    let content = Cn_orchestrator.repack_for_pass_b ~hub_path:hub
                    ~trigger_id ~config:auto_config ~pass_a_receipts:receipts in
    (* Should contain receipts section *)
    let has_receipts = String.length content > 0
                       && Cn_orchestrator.contains_sub content "Receipt" in
    Printf.printf "has_receipts_section: %b\n" has_receipts;
    Printf.printf "non_empty: %b\n" (String.length content > 0));
  [%expect {|
    has_receipts_section: true
    non_empty: true |}]

let%expect_test "repack_for_pass_b: includes artifact excerpts" =
  with_test_hub (fun hub ->
    (* Write an artifact file *)
    let art_dir = Filename.concat hub "state/artifacts/orch-test-001" in
    Cn_ffi.Fs.ensure_dir art_dir;
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-01.txt") "file content here";
    let receipts = [
      { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:abc"; size = 17 }] }
    ] in
    let content = Cn_orchestrator.repack_for_pass_b ~hub_path:hub
                    ~trigger_id ~config:auto_config ~pass_a_receipts:receipts in
    let has_artifact = Cn_orchestrator.contains_sub content "file content here" in
    Printf.printf "has_artifact_content: %b\n" has_artifact);
  [%expect {| has_artifact_content: true |}]

let%expect_test "repack_for_pass_b: deterministic ordering" =
  with_test_hub (fun hub ->
    let art_dir = Filename.concat hub "state/artifacts/orch-test-001" in
    Cn_ffi.Fs.ensure_dir art_dir;
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-01.txt") "first";
    Cn_ffi.Fs.write (Filename.concat art_dir "obs-02.txt") "second";
    let receipts = [
      { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-01.txt";
                       hash = "sha256:aaa"; size = 5 }] };
      { Cn_shell.pass = "A"; op_id = Some "obs-02"; kind = "fs_read";
        status = Ok_status; reason = "";
        start_time = ""; end_time = "";
        artifacts = [{ path = "state/artifacts/orch-test-001/obs-02.txt";
                       hash = "sha256:bbb"; size = 6 }] };
    ] in
    let c1 = Cn_orchestrator.repack_for_pass_b ~hub_path:hub
               ~trigger_id ~config:auto_config ~pass_a_receipts:receipts in
    let c2 = Cn_orchestrator.repack_for_pass_b ~hub_path:hub
               ~trigger_id ~config:auto_config ~pass_a_receipts:receipts in
    Printf.printf "deterministic: %b\n" (c1 = c2));
  [%expect {| deterministic: true |}]

(* ============================================================ *)
(* === RECEIPT PERSISTENCE (pass A → pass B append)           === *)
(* ============================================================ *)

let%expect_test "full two-pass: receipts accumulate in one file" =
  with_test_hub (fun hub ->
    (* Pass A *)
    let pass_a_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let pass_a = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id
                   ~config:auto_config pass_a_ops in
    assert pass_a.needs_pass_b;

    (* Pass B *)
    let pass_b_ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let _pass_b = Cn_orchestrator.run_pass_b ~hub_path:hub ~trigger_id
                    ~config:auto_config pass_b_ops in

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
    A fs_read ok
    A fs_write skipped
    B fs_write ok |}]

(* ============================================================ *)
(* === EMPTY MANIFEST                                         === *)
(* ============================================================ *)

let%expect_test "empty ops list → single pass, no receipts" =
  with_test_hub (fun hub ->
    let result = Cn_orchestrator.run_pass_a ~hub_path:hub ~trigger_id
                   ~config:auto_config [] in
    Printf.printf "needs_pass_b: %b\n" result.needs_pass_b;
    Printf.printf "receipt_count: %d\n" (List.length result.receipts));
  [%expect {|
    needs_pass_b: false
    receipt_count: 0 |}]

(* ============================================================ *)
(* === DENIAL RECEIPTS FROM PARSER PASS THROUGH                === *)
(* ============================================================ *)

(* ============================================================ *)
(* === ANTI-CONFABULATION SIGNALS (#49)                      === *)
(* ============================================================ *)

let%expect_test "receipts_summary: ok with artifacts has no signal tag" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = "";
      artifacts = [{ path = "state/artifacts/t/obs-01.txt";
                     hash = "sha256:abc"; size = 42 }] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
  let has_empty = Cn_orchestrator.contains_sub summary "EMPTY_RESULT" in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_failed = Cn_orchestrator.contains_sub summary "FAILED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "empty=%b not_exec=%b failed=%b warning=%b\n"
    has_empty has_not_exec has_failed has_warning;
  [%expect {| empty=false not_exec=false failed=false warning=false |}]

let%expect_test "receipts_summary: ok with zero artifacts → EMPTY_RESULT" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
  let has_empty = Cn_orchestrator.contains_sub summary "EMPTY_RESULT" in
  Printf.printf "has_empty_result: %b\n" has_empty;
  [%expect {| has_empty_result: true |}]

let%expect_test "receipts_summary: denied → NOT_EXECUTED + WARNING" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "exec-01"; kind = "exec";
      status = Denied; reason = "not_in_allowlist";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  let has_reason = Cn_orchestrator.contains_sub summary "reason: not_in_allowlist" in
  Printf.printf "not_exec=%b warning=%b reason=%b\n"
    has_not_exec has_warning has_reason;
  [%expect {| not_exec=true warning=true reason=true |}]

let%expect_test "receipts_summary: error → FAILED + WARNING" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
      status = Error_status; reason = "file_not_found";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
  let has_failed = Cn_orchestrator.contains_sub summary "FAILED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "failed=%b warning=%b\n" has_failed has_warning;
  [%expect {| failed=true warning=true |}]

let%expect_test "receipts_summary: skipped → NOT_EXECUTED, no warning" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "write-01"; kind = "fs_write";
      status = Skipped; reason = "observe_pass_requires_followup";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
  let has_not_exec = Cn_orchestrator.contains_sub summary "NOT_EXECUTED" in
  let has_warning = Cn_orchestrator.contains_sub summary "WARNING" in
  Printf.printf "not_exec=%b warning=%b\n" has_not_exec has_warning;
  [%expect {| not_exec=true warning=false |}]

let%expect_test "receipts_summary: mixed ok+denied → WARNING present" =
  let receipts = [
    { Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = "";
      artifacts = [{ path = "state/artifacts/t/obs-01.txt";
                     hash = "sha256:abc"; size = 42 }] };
    { Cn_shell.pass = "A"; op_id = Some "exec-01"; kind = "exec";
      status = Denied; reason = "exec_disabled";
      start_time = ""; end_time = ""; artifacts = [] }
  ] in
  let summary = Cn_orchestrator.receipts_summary receipts in
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
    Cn_orchestrator.write_denial_receipts ~hub_path:hub ~trigger_id ~pass:"A" [denial];
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
  [%expect {| pass=A status=denied |}]

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
    stop_reason: no_ops
    total_receipts: 1
    pass=1 kind=fs_write status=ok reason=(none) |}]

let%expect_test "n_pass: observe → LLM → effect (two passes)" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read"
    ] in
    (* Pass 2 LLM returns an effect op *)
    let pass_2_output =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/out.ml\",\"content\":\"let y = 2\"}]\n---\n\nDone." in
    let call_count = ref 0 in
    let llm_call _repack =
      incr call_count;
      Ok pass_2_output
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
    passes_used: 2
    stop_reason: no_ops
    llm_calls: 1
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
    (* Pass 2 LLM returns effect-only *)
    let pass_2_output =
      "---\nid: orch-test-001\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-02\",\"path\":\"src/out.ml\",\"content\":\"let y = 2\"}]\n---\n\nDone." in
    let llm_call _ = Ok pass_2_output in
    match Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
            ~config:n_pass_config ~llm_call ops with
    | Error msg -> Printf.printf "error: %s\n" msg
    | Ok result ->
      let passes = List.sort_uniq String.compare
        (List.map (fun (r : Cn_shell.receipt) -> r.pass) result.all_receipts) in
      Printf.printf "pass_labels: %s\n" (String.concat ", " passes));
  [%expect {| pass_labels: 1, 2 |}]

let%expect_test "n_pass: backward compat — max_passes=2 matches two-pass" =
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
