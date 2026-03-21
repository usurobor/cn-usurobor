(** cn_runtime_integration_test: integration tests for two-pass wiring

    Tests the runtime-level integration of two-pass execution (Issue #41).
    Uses Cn_orchestrator.run_two_pass which coordinates:
    Pass A → repack → LLM call → Parse → Pass B → coordination gating

    The LLM call is injected as a function parameter for testability. *)

(* === Temp hub setup (shared with cn_orchestrator_test) === *)

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
  let hub = mk_temp_dir "cn-rt-int-test" in
  let dirs = ["src"; "docs"; ".cn"; "spec"; "state"; "logs";
              "state/artifacts"; "state/receipts"; "logs/input"; "logs/output"] in
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

let trigger_id = "rt-int-test-001"

let show_receipt (r : Cn_shell.receipt) =
  Printf.printf "pass=%s kind=%s status=%s reason=%s\n"
    r.pass r.kind (Cn_shell.string_of_receipt_status r.status)
    (if r.reason = "" then "(none)" else r.reason)

(* === Typed op helpers === *)

let make_observe_with ~op_id ~fields kind_str =
  let kind = match Cn_shell.op_kind_of_string kind_str with
    | Some k -> k | None -> failwith "bad kind" in
  { Cn_shell.kind; op_id = Some op_id; fields }

let make_effect ~op_id ~fields kind_str =
  let kind = match Cn_shell.op_kind_of_string kind_str with
    | Some k -> k | None -> failwith "bad kind" in
  { Cn_shell.kind; op_id = Some op_id; fields }

(* ============================================================ *)
(* === TWO-PASS INTEGRATION: run_two_pass                    === *)
(* ============================================================ *)

(* Mock LLM that returns a Pass B output with an fs_write effect *)
let mock_llm_pass_b_write _repack_content =
  Ok "---\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/new.ml\",\"content\":\"let x = 1\"}]\n---\nI wrote the file."

(* Mock LLM that returns a Pass B output with no ops *)
let mock_llm_pass_b_no_ops _repack_content =
  Ok "---\n---\nHere is what I found in the file."

(* Mock LLM that fails *)
let mock_llm_fail _repack_content =
  Error "API timeout"

let%expect_test "two-pass: observe+effect → Pass B invoked, both passes receipted" =
  with_test_hub (fun hub ->
    let pass_a_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_pass_b_write
                   pass_a_ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok { pass_a_receipts; pass_b_receipts; pass_b_coordination_ops = _; pass_b_output = _; used_two_pass } ->
      Printf.printf "used_two_pass: %b\n" used_two_pass;
      Printf.printf "--- Pass A ---\n";
      List.iter show_receipt pass_a_receipts;
      Printf.printf "--- Pass B ---\n";
      List.iter show_receipt pass_b_receipts);
  [%expect {|
    used_two_pass: true
    --- Pass A ---
    pass=A kind=fs_read status=ok reason=(none)
    pass=A kind=fs_write status=skipped reason=observe_pass_requires_followup
    --- Pass B ---
    pass=B kind=fs_write status=ok reason=(none) |}]

let%expect_test "single-pass: effect-only → no Pass B, normal flow" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_pass_b_write
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok { pass_a_receipts; pass_b_receipts; used_two_pass; _ } ->
      Printf.printf "used_two_pass: %b\n" used_two_pass;
      Printf.printf "pass_a_count: %d\n" (List.length pass_a_receipts);
      Printf.printf "pass_b_count: %d\n" (List.length pass_b_receipts);
      List.iter show_receipt pass_a_receipts);
  [%expect {|
    used_two_pass: false
    pass_a_count: 1
    pass_b_count: 0
    pass=A kind=fs_write status=ok reason=(none) |}]

let%expect_test "two-pass: LLM failure in Pass B → Error propagated" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_fail
                   ops in
    (match result with
     | Error msg -> Printf.printf "error: %s\n" msg
     | Ok _ -> print_endline "unexpected success"));
  [%expect {| error: Pass B LLM call failed: API timeout |}]

let%expect_test "two-pass: observe-only Pass A → Pass B with no ops" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_pass_b_no_ops
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok { pass_a_receipts; pass_b_receipts; used_two_pass; _ } ->
      Printf.printf "used_two_pass: %b\n" used_two_pass;
      Printf.printf "pass_a_count: %d\n" (List.length pass_a_receipts);
      Printf.printf "pass_b_count: %d\n" (List.length pass_b_receipts));
  [%expect {|
    used_two_pass: true
    pass_a_count: 1
    pass_b_count: 0 |}]

let%expect_test "two-pass: receipts from both passes in one file" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_pass_b_write
                   ops in
    (match result with
     | Error msg -> Printf.printf "ERROR: %s\n" msg
     | Ok _ -> ());
    (* Verify receipt file contains both passes *)
    let path = Filename.concat hub "state/receipts/rt-int-test-001.json" in
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

let%expect_test "two-pass: coordination gating — Pass B effect denied → terminal ops gated" =
  with_test_hub (fun hub ->
    (* Mock LLM returns a write to a denied path + terminal coord op *)
    let mock_llm_denied _content =
      Ok "---\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-bad\",\"path\":\".cn/evil.ml\",\"content\":\"bad\"}]\ndone: thread-1\n---\nDone."
    in
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_denied
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok { pass_b_receipts; pass_b_coordination_ops; _ } ->
      Printf.printf "--- Pass B receipts ---\n";
      List.iter show_receipt pass_b_receipts;
      Printf.printf "--- Pass B coordination ---\n";
      List.iter (fun (op, decision) ->
        let op_str = Cn_lib.string_of_agent_op op in
        match decision with
        | Cn_orchestrator.Execute ->
          Printf.printf "%s: execute\n" op_str
        | Cn_orchestrator.Skip reason ->
          Printf.printf "%s: skip (%s)\n" op_str reason
      ) pass_b_coordination_ops);
  [%expect {|
    --- Pass B receipts ---
    pass=B kind=fs_write status=denied reason=path_denied
    --- Pass B coordination ---
    done:thread-1: skip (effects_failed) |}]

let%expect_test "two-pass=off: even with observe ops, no Pass B" =
  with_test_hub (fun hub ->
    let off_config = { auto_config with two_pass = "off" } in
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let result = Cn_orchestrator.run_two_pass ~hub_path:hub ~trigger_id
                   ~config:off_config ~llm_call:mock_llm_pass_b_write
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok { pass_a_receipts; pass_b_receipts; used_two_pass; _ } ->
      Printf.printf "used_two_pass: %b\n" used_two_pass;
      Printf.printf "pass_a_count: %d\n" (List.length pass_a_receipts);
      Printf.printf "pass_b_count: %d\n" (List.length pass_b_receipts);
      List.iter show_receipt pass_a_receipts);
  [%expect {|
    used_two_pass: false
    pass_a_count: 2
    pass_b_count: 0
    pass=A kind=fs_read status=ok reason=(none)
    pass=A kind=fs_write status=ok reason=(none) |}]
