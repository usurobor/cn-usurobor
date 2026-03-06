(** cn_executor_test: ppx_expect tests for typed op executor

    Tests pure helpers (scrub_env, field extraction) and filesystem
    ops (fs_read, fs_list, fs_write) using temp hub directories.
    Git ops tested only for argument construction; exec tested
    for allowlist enforcement. *)

(* === Temp hub setup (shared with cn_sandbox_test) === *)

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
  let hub = mk_temp_dir "cn-executor-test" in
  let dirs = ["src"; "docs"; ".cn"; "spec"; "state"; "logs";
              "state/artifacts"; "state/receipts"] in
  List.iter (fun d ->
    Cn_ffi.Fs.ensure_dir (Filename.concat hub d)
  ) dirs;
  let touch path content =
    let full = Filename.concat hub path in
    let oc = open_out full in
    output_string oc content;
    close_out oc
  in
  touch "src/main.ml" "let () = print_endline \"hello\"";
  touch "docs/README.md" "# Docs";
  touch "spec/SOUL.md" "# SOUL";
  touch "spec/USER.md" "# USER";
  touch ".cn/secrets.env" "KEY=secret";
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

let test_config = {
  Cn_shell.two_pass = "auto";
  apply_mode = "working_tree";
  exec_enabled = false;
  exec_allowlist = [];
  max_observe_ops = 10;
  max_artifact_bytes = 65536;
  max_artifact_bytes_per_op = 16384;
}

let trigger_id = "test-001"

let show_receipt (r : Cn_shell.receipt) =
  Printf.printf "kind=%s status=%s reason=%s artifacts=%d\n"
    r.kind (Cn_shell.string_of_receipt_status r.status)
    (if r.reason = "" then "(none)" else r.reason)
    (List.length r.artifacts)

(* === Pure: scrub_env === *)

let%expect_test "scrub_env: drops _KEY, _TOKEN, _SECRET vars" =
  (* We can't control Unix.environment() directly, but we can test
     the is_secret logic by examining the scrub_env output.
     Since we're in a test env, just verify known patterns are filtered. *)
  let env = Cn_executor.scrub_env ~extra_keys:["CUSTOM_VAR"] in
  (* Check that no *_KEY, *_TOKEN, *_SECRET vars remain *)
  let has_secret = List.exists (fun (k, _) ->
    let ends_with ~suffix s =
      let sl = String.length suffix and kl = String.length s in
      kl >= sl && String.sub s (kl - sl) sl = suffix
    in
    ends_with ~suffix:"_KEY" k
    || ends_with ~suffix:"_TOKEN" k
    || ends_with ~suffix:"_SECRET" k
    || k = "CUSTOM_VAR"
  ) env in
  Printf.printf "has_secret_vars: %b\n" has_secret;
  [%expect {| has_secret_vars: false |}]

(* === Field extraction === *)

let%expect_test "get_field_string: present" =
  let op = { Cn_shell.kind = Observe Fs_read;
             op_id = Some "obs-01";
             fields = [("path", Cn_json.String "src/main.ml")] } in
  (match Cn_executor.get_field_string "path" op with
   | Some s -> Printf.printf "ok: %s\n" s
   | None -> print_endline "none");
  [%expect {| ok: src/main.ml |}]

let%expect_test "get_field_string: missing" =
  let op = { Cn_shell.kind = Observe Fs_read;
             op_id = Some "obs-01"; fields = [] } in
  (match Cn_executor.get_field_string "path" op with
   | Some s -> Printf.printf "ok: %s\n" s
   | None -> print_endline "none");
  [%expect {| none |}]

let%expect_test "get_field_int: present" =
  let op = { Cn_shell.kind = Observe Git_log;
             op_id = Some "obs-01";
             fields = [("max", Cn_json.Int 5)] } in
  (match Cn_executor.get_field_int "max" op with
   | Some i -> Printf.printf "ok: %d\n" i
   | None -> print_endline "none");
  [%expect {| ok: 5 |}]

let%expect_test "require_field_string: missing returns error" =
  let op = { Cn_shell.kind = Observe Fs_read;
             op_id = Some "obs-01"; fields = [] } in
  (match Cn_executor.require_field_string "path" op with
   | Ok s -> Printf.printf "ok: %s\n" s
   | Error msg -> Printf.printf "error: %s\n" msg);
  [%expect {| error: missing required field 'path' |}]

(* === Filesystem: fs_read === *)

let%expect_test "fs_read: read existing file" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/main.ml")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_read status=ok reason=(none) artifacts=1 |}]

let%expect_test "fs_read: nonexistent file" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/nope.ml")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_read status=error reason=file_not_found artifacts=0 |}]

let%expect_test "fs_read: denied path (.cn/)" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String ".cn/secrets.env")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_read status=denied reason=path_denied artifacts=0 |}]

let%expect_test "fs_read: absolute path denied" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "/etc/passwd")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_read status=denied reason=absolute_path artifacts=0 |}]

let%expect_test "fs_read: missing path field" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_read status=error reason=missing required field 'path' artifacts=0 |}]

(* === Filesystem: fs_list === *)

let%expect_test "fs_list: list directory" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_list;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_list status=ok reason=(none) artifacts=1 |}]

let%expect_test "fs_list: nonexistent directory" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_list;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "nope")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_list status=error reason=directory_not_found artifacts=0 |}]

let%expect_test "fs_list: denied path" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_list;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String ".cn")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_list status=denied reason=path_denied artifacts=0 |}]

(* === Filesystem: fs_write === *)

let%expect_test "fs_write: write new file" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Fs_write;
               op_id = Some "write-01";
               fields = [("path", Cn_json.String "src/new.ml");
                          ("content", Cn_json.String "let x = 1")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    (* Verify the file was actually written *)
    let content = Cn_ffi.Fs.read (Filename.concat hub "src/new.ml") in
    Printf.printf "content: %s\n" content);
  [%expect {|
    kind=fs_write status=ok reason=(none) artifacts=0
    content: let x = 1 |}]

let%expect_test "fs_write: denied path (.cn/)" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Fs_write;
               op_id = Some "write-01";
               fields = [("path", Cn_json.String ".cn/evil.ml");
                          ("content", Cn_json.String "bad")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_write status=denied reason=path_denied artifacts=0 |}]

let%expect_test "fs_write: protected file denied" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Fs_write;
               op_id = Some "write-01";
               fields = [("path", Cn_json.String "spec/SOUL.md");
                          ("content", Cn_json.String "overwritten")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_write status=denied reason=protected_file artifacts=0 |}]

let%expect_test "fs_write: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Fs_write;
               op_id = Some "write-01";
               fields = [("path", Cn_json.String "src/new.ml");
                          ("content", Cn_json.String "let x = 1")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=fs_write status=denied reason=policy_rejected artifacts=0 |}]

let%expect_test "fs_write: missing fields" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Fs_write;
               op_id = Some "write-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_write status=error reason=missing required field 'path' artifacts=0 |}]

(* === Effect: git_branch (apply_mode off) === *)

let%expect_test "git_branch: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Git_branch;
               op_id = Some "branch-01";
               fields = [("name", Cn_json.String "feature/x")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=git_branch status=denied reason=policy_rejected artifacts=0 |}]

let%expect_test "git_commit: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Git_commit;
               op_id = Some "commit-01";
               fields = [("message", Cn_json.String "test")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=git_commit status=denied reason=policy_rejected artifacts=0 |}]

(* === Effect: exec (policy checks) === *)

let%expect_test "exec: exec_enabled false denied" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Exec;
               op_id = Some "exec-01";
               fields = [("argv", Cn_json.Array [Cn_json.String "echo"; Cn_json.String "hi"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=exec status=denied reason=policy_rejected artifacts=0 |}]

let%expect_test "exec: not on allowlist denied" =
  with_test_hub (fun hub ->
    let config = { test_config with exec_enabled = true; exec_allowlist = ["/usr/bin/ls"] } in
    let op = { Cn_shell.kind = Effect Exec;
               op_id = Some "exec-01";
               fields = [("argv", Cn_json.Array [Cn_json.String "echo"; Cn_json.String "hi"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=exec status=denied reason=policy_rejected artifacts=0 |}]

let%expect_test "exec: empty argv" =
  with_test_hub (fun hub ->
    let config = { test_config with exec_enabled = true; exec_allowlist = [] } in
    let op = { Cn_shell.kind = Effect Exec;
               op_id = Some "exec-01";
               fields = [("argv", Cn_json.Array [])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=exec status=error reason=empty_argv artifacts=0 |}]

let%expect_test "exec: missing argv field" =
  with_test_hub (fun hub ->
    let config = { test_config with exec_enabled = true } in
    let op = { Cn_shell.kind = Effect Exec;
               op_id = Some "exec-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=exec status=error reason=missing required field 'argv' artifacts=0 |}]

(* === fs_glob: not yet implemented === *)

let%expect_test "fs_glob: not yet implemented" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "**/*.ml")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_glob status=error reason=not_yet_implemented artifacts=0 |}]

(* === Artifact: write_artifact with SHA-256 === *)

let%expect_test "write_artifact: writes file and returns record" =
  with_test_hub (fun hub ->
    let content = "test artifact content" in
    let a = Cn_executor.write_artifact ~hub_path:hub ~trigger_id
              ~op_id:"obs-01" ~ext:"txt" ~content ~max_bytes:65536 in
    Printf.printf "path: %s\n" a.Cn_shell.path;
    Printf.printf "hash: %s\n" a.hash;
    Printf.printf "size: %d\n" a.size;
    (* Verify file exists *)
    let full = Filename.concat hub a.path in
    Printf.printf "exists: %b\n" (Sys.file_exists full));
  [%expect {|
    path: state/artifacts/test-001/obs-01.txt
    hash: sha256:2362660f9e876799563237b854032040dd853aee58f6d135884c5f3f63712183
    size: 21
    exists: true |}]

let%expect_test "write_artifact: caps at max_bytes" =
  with_test_hub (fun hub ->
    let content = String.make 100 'x' in
    let a = Cn_executor.write_artifact ~hub_path:hub ~trigger_id
              ~op_id:"obs-02" ~ext:"txt" ~content ~max_bytes:50 in
    Printf.printf "size: %d\n" a.Cn_shell.size;
    let full = Filename.concat hub a.path in
    let on_disk = Cn_ffi.Fs.read full in
    Printf.printf "on_disk_len: %d\n" (String.length on_disk));
  [%expect {|
    size: 50
    on_disk_len: 50 |}]

(* === Receipt I/O === *)

let%expect_test "write_receipts: creates receipt file" =
  with_test_hub (fun hub ->
    let receipt = {
      Cn_shell.pass = ""; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = "2026-01-01T00:00:00Z"; end_time = "2026-01-01T00:00:01Z";
      artifacts = []
    } in
    Cn_executor.write_receipts ~hub_path:hub ~trigger_id ~pass:"A" [receipt];
    let path = Filename.concat hub "state/receipts/test-001.json" in
    Printf.printf "exists: %b\n" (Sys.file_exists path);
    (* Verify it parses back *)
    let content = Cn_ffi.Fs.read path in
    match Cn_json.parse content with
    | Ok obj ->
      (match Cn_json.get_string "schema" obj with
       | Some s -> Printf.printf "schema: %s\n" s
       | None -> print_endline "no schema");
      (match Cn_json.get_list "receipts" obj with
       | Some rs -> Printf.printf "receipt_count: %d\n" (List.length rs)
       | None -> print_endline "no receipts")
    | Error msg -> Printf.printf "parse error: %s\n" msg);
  [%expect {|
    exists: true
    schema: cn.receipts.v1
    receipt_count: 1 |}]

let%expect_test "write_receipts: appends to existing" =
  with_test_hub (fun hub ->
    let r1 = {
      Cn_shell.pass = ""; op_id = Some "obs-01"; kind = "fs_read";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = []
    } in
    let r2 = {
      Cn_shell.pass = ""; op_id = Some "write-01"; kind = "fs_write";
      status = Ok_status; reason = "";
      start_time = ""; end_time = ""; artifacts = []
    } in
    Cn_executor.write_receipts ~hub_path:hub ~trigger_id ~pass:"A" [r1];
    Cn_executor.write_receipts ~hub_path:hub ~trigger_id ~pass:"B" [r2];
    let path = Filename.concat hub "state/receipts/test-001.json" in
    let content = Cn_ffi.Fs.read path in
    match Cn_json.parse content with
    | Ok obj ->
      (match Cn_json.get_list "receipts" obj with
       | Some rs -> Printf.printf "receipt_count: %d\n" (List.length rs)
       | None -> print_endline "no receipts")
    | Error msg -> Printf.printf "parse error: %s\n" msg);
  [%expect {| receipt_count: 2 |}]

let%expect_test "read_receipts: missing file returns empty" =
  with_test_hub (fun hub ->
    let rs = Cn_executor.read_receipts ~hub_path:hub ~trigger_id:"nonexistent" in
    Printf.printf "count: %d\n" (List.length rs));
  [%expect {| count: 0 |}]

(* === fs_patch: apply_mode off === *)

let%expect_test "fs_patch: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Fs_patch;
               op_id = Some "patch-01";
               fields = [("path", Cn_json.String "src/main.ml");
                          ("unified_diff", Cn_json.String "--- a\n+++ b")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=fs_patch status=denied reason=policy_rejected artifacts=0 |}]

(* === Dispatch: pass field left blank === *)

let%expect_test "execute_op: pass field is blank (orchestrator fills)" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/main.ml")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    Printf.printf "pass: '%s'\n" r.Cn_shell.pass);
  [%expect {| pass: '' |}]
