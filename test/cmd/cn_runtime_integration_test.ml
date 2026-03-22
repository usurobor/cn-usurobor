(** cn_runtime_integration_test: integration tests for n-pass wiring

    Tests the runtime-level integration of n-pass execution (Issue #41).
    Uses Cn_orchestrator.run_n_pass which coordinates:
    Pass 1 → repack → LLM call → Parse → Pass 2 → coordination gating

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
  Cn_shell.n_pass = "auto";
  apply_mode = "working_tree";
  exec_enabled = false;
  exec_allowlist = [];
  max_observe_ops = 10;
  max_artifact_bytes = 65536;
  max_artifact_bytes_per_op = 16384;
  max_passes = 2;
  max_total_artifact_bytes = 131072;
  max_total_ops = 32;
}

let trigger_id = "rt-int-test-001"

let show_receipt (r : Cn_shell.receipt) =
  Printf.printf "pass=%s kind=%s status=%s reason=%s\n"
    r.pass r.kind (Cn_shell.string_of_receipt_status r.status)
    (if r.reason = "" then "(none)" else r.reason)

let show_n_pass_result result =
  Printf.printf "passes_used: %d\n" result.Cn_orchestrator.passes_used;
  Printf.printf "stop_reason: %s\n"
    (Cn_orchestrator.string_of_stop_reason result.stop_reason);
  Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
  List.iter show_receipt result.all_receipts

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
(* === N-PASS INTEGRATION: run_n_pass                        === *)
(* ============================================================ *)

(* Fresh stateful mock: first call returns effect, subsequent calls return no ops *)
let make_mock_effect_then_terminal () =
  let call_count = ref 0 in
  fun _repack_content ->
    incr call_count;
    if !call_count = 1 then
      Ok "---\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-01\",\"path\":\"src/new.ml\",\"content\":\"let x = 1\"}]\n---\nI wrote the file."
    else
      Ok "---\n---\nDone."

(* Mock LLM that returns no ops (terminal) *)
let mock_llm_no_ops _repack_content =
  Ok "---\n---\nHere is what I found in the file."

(* Mock LLM that fails *)
let mock_llm_fail _repack_content =
  Error "API timeout"

let%expect_test "n-pass: observe+effect → effect → terminal (3 passes)" =
  with_test_hub (fun hub ->
    let pass_1_ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let llm_call = make_mock_effect_then_terminal () in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call
                   pass_1_ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "--- All receipts ---\n";
      List.iter show_receipt result.all_receipts);
  [%expect {|
    passes_used: 2
    --- All receipts ---
    pass=1 kind=fs_read status=ok reason=(none)
    pass=1 kind=fs_write status=skipped reason=observe_pass_requires_followup
    pass=2 kind=fs_write status=ok reason=(none) |}]

let%expect_test "single-pass: effect-only → no continuation, terminal" =
  with_test_hub (fun hub ->
    let ops = [
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let llm_call _ = failwith "should not be called for first-pass effect-only" in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
      List.iter show_receipt result.all_receipts);
  [%expect {|
    passes_used: 1
    total_receipts: 1
    pass=1 kind=fs_write status=ok reason=(none) |}]

let%expect_test "n-pass: LLM failure in Pass 2 → Error propagated" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_fail
                   ops in
    (match result with
     | Error msg -> Printf.printf "error: %s\n" msg
     | Ok _ -> print_endline "unexpected success"));
  [%expect {| error: Pass 1 LLM call failed: API timeout |}]

let%expect_test "n-pass: observe-only Pass 1 → Pass 2 with no ops" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call:mock_llm_no_ops
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts));
  [%expect {|
    passes_used: 2
    total_receipts: 1 |}]

let%expect_test "n-pass: receipts from both passes in one file" =
  with_test_hub (fun hub ->
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let llm_call = make_mock_effect_then_terminal () in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call
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
    1 fs_read ok
    1 fs_write skipped
    2 fs_write ok |}]

let%expect_test "n-pass: coordination gating — effect denied → terminal ops gated" =
  with_test_hub (fun hub ->
    let call_count = ref 0 in
    let llm_call _content =
      incr call_count;
      match !call_count with
      | 1 ->
        (* Pass 2: denied effect + coordination op *)
        Ok "---\nops: [{\"kind\":\"fs_write\",\"op_id\":\"write-bad\",\"path\":\".cn/evil.ml\",\"content\":\"bad\"}]\ndone: thread-1\n---\nDone."
      | _ ->
        (* Pass 3: terminal — LLM acknowledges denial *)
        Ok "---\ndone: thread-1\n---\nDone."
    in
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
    ] in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:auto_config ~llm_call
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok result ->
      Printf.printf "--- Pass 2 receipts ---\n";
      (* Show only pass 2 receipts *)
      List.iter (fun (r : Cn_shell.receipt) ->
        if r.pass = "2" then show_receipt r
      ) result.all_receipts;
      Printf.printf "--- Final coordination ---\n";
      List.iter (fun (op, decision) ->
        let op_str = Cn_lib.string_of_agent_op op in
        match decision with
        | Cn_orchestrator.Execute ->
          Printf.printf "%s: execute\n" op_str
        | Cn_orchestrator.Skip reason ->
          Printf.printf "%s: skip (%s)\n" op_str reason
      ) result.final_coordination_ops);
  [%expect {|
    --- Pass 2 receipts ---
    pass=2 kind=fs_write status=denied reason=path_denied
    --- Final coordination ---
    done:thread-1: skip (effects_failed) |}]

let%expect_test "n_pass=off: even with observe ops, no Pass 2" =
  with_test_hub (fun hub ->
    let off_config = { auto_config with n_pass = "off" } in
    let ops = [
      make_observe_with ~op_id:"obs-01"
        ~fields:[("path", Cn_json.String "src/main.ml")] "fs_read";
      make_effect ~op_id:"write-01"
        ~fields:[("path", Cn_json.String "src/new.ml");
                 ("content", Cn_json.String "let x = 1")] "fs_write";
    ] in
    let llm_call _ = failwith "should not be called with n_pass=off" in
    let result = Cn_orchestrator.run_n_pass ~hub_path:hub ~trigger_id
                   ~config:off_config ~llm_call
                   ops in
    match result with
    | Error msg -> Printf.printf "ERROR: %s\n" msg
    | Ok result ->
      Printf.printf "passes_used: %d\n" result.passes_used;
      Printf.printf "total_receipts: %d\n" (List.length result.all_receipts);
      List.iter show_receipt result.all_receipts);
  [%expect {|
    passes_used: 1
    total_receipts: 2
    pass=1 kind=fs_read status=ok reason=(none)
    pass=1 kind=fs_write status=ok reason=(none) |}]
