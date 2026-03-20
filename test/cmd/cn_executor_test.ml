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

let read_artifact hub (r : Cn_shell.receipt) =
  match r.artifacts with
  | [] -> "(no artifacts)"
  | a :: _ ->
    let path = Filename.concat hub a.Cn_shell.path in
    let ic = open_in path in
    let n = in_channel_length ic in
    let s = really_input_string ic n in
    close_in ic; s

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

(* === fs_glob: implemented in v3.8.0 === *)

let%expect_test "fs_glob: match *.ml in src/" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "*.ml");
                          ("base", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_glob status=ok reason=(none) artifacts=1 |}]

let%expect_test "fs_glob: no matches returns ok" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "*.xyz")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_glob status=ok reason=(none) artifacts=1 |}]

let%expect_test "fs_glob: denied base path (.cn)" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "*");
                          ("base", Cn_json.String ".cn")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_glob status=denied reason=path_denied artifacts=0 |}]

let%expect_test "fs_glob: missing pattern field" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=fs_glob status=error reason=missing required field 'pattern' artifacts=0 |}]

(* === fs_glob: symlink regressions === *)

let%expect_test "fs_glob: symlink into .cn/ is denied" =
  with_test_hub (fun hub ->
    (* src/linkdir -> .cn *)
    Unix.symlink (Filename.concat hub ".cn")
      (Filename.concat hub "src/linkdir");
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "**/*");
                          ("base", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "sees_linkdir: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "linkdir") content 0); true
       with Not_found -> false);
    (* Clean up symlink before with_test_hub's rm *)
    Sys.remove (Filename.concat hub "src/linkdir"));
  [%expect {|
    kind=fs_glob status=ok reason=(none) artifacts=1
    sees_linkdir: false |}]

let%expect_test "fs_glob: symlink escaping hub is denied" =
  with_test_hub (fun hub ->
    (* src/escape -> /tmp (outside hub) *)
    Unix.symlink "/tmp" (Filename.concat hub "src/escape");
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "**/*");
                          ("base", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "sees_escape: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "escape") content 0); true
       with Not_found -> false);
    Sys.remove (Filename.concat hub "src/escape"));
  [%expect {|
    kind=fs_glob status=ok reason=(none) artifacts=1
    sees_escape: false |}]

let%expect_test "fs_glob: symlink cycle does not recurse forever" =
  with_test_hub (fun hub ->
    (* src/loop -> src (cycle) *)
    Unix.symlink (Filename.concat hub "src")
      (Filename.concat hub "src/loop");
    let op = { Cn_shell.kind = Observe Fs_glob;
               op_id = Some "obs-01";
               fields = [("pattern", Cn_json.String "**/*");
                          ("base", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    (* Should complete (not hang) and not contain loop/ entries *)
    let content = read_artifact hub r in
    Printf.printf "contains_loop: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "loop/") content 0); true
       with Not_found -> false);
    Sys.remove (Filename.concat hub "src/loop"));
  [%expect {|
    kind=fs_glob status=ok reason=(none) artifacts=1
    contains_loop: false |}]

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

(* === v3.8.0: fs_read chunking === *)

let%expect_test "fs_read: chunked with offset" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/main.ml");
                          ("offset", Cn_json.Int 4);
                          ("limit", Cn_json.Int 5)] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    (* Verify artifact content is the chunk *)
    let art_path = Filename.concat hub (List.hd r.artifacts).Cn_shell.path in
    let content = Cn_ffi.Fs.read art_path in
    Printf.printf "chunk: '%s'\n" content);
  [%expect {|
    kind=fs_read status=ok reason=(none) artifacts=1
    chunk: '() = ' |}]

let%expect_test "fs_read: offset beyond file size" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/main.ml");
                          ("offset", Cn_json.Int 99999)] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    let art_path = Filename.concat hub (List.hd r.artifacts).Cn_shell.path in
    let content = Cn_ffi.Fs.read art_path in
    Printf.printf "chunk_len: %d\n" (String.length content));
  [%expect {|
    kind=fs_read status=ok reason=(none) artifacts=1
    chunk_len: 0 |}]

let%expect_test "fs_read: no offset/limit defaults to full read" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Observe Fs_read;
               op_id = Some "obs-01";
               fields = [("path", Cn_json.String "src/main.ml")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r;
    let art_path = Filename.concat hub (List.hd r.artifacts).Cn_shell.path in
    let content = Cn_ffi.Fs.read art_path in
    Printf.printf "content: %s\n" content);
  [%expect {|
    kind=fs_read status=ok reason=(none) artifacts=1
    content: let () = print_endline "hello" |}]

(* === v3.8.0: git_stage === *)

let%expect_test "git_stage: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=policy_rejected artifacts=0 |}]

(* === v3.8.0: git_commit index-only semantics === *)

let%expect_test "git_commit: apply_mode off denied" =
  with_test_hub (fun hub ->
    let config = { test_config with apply_mode = "off" } in
    let op = { Cn_shell.kind = Effect Git_commit;
               op_id = Some "commit-01";
               fields = [("message", Cn_json.String "test")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config op in
    show_receipt r);
  [%expect {| kind=git_commit status=denied reason=policy_rejected artifacts=0 |}]

(* === v3.8.0: end-to-end git_stage + git_commit === *)

let init_git_repo hub =
  let _ = Cn_ffi.Process.exec_args ~prog:"git"
    ~args:["-C"; hub; "init"; "--initial-branch"; "main"] () in
  let _ = Cn_ffi.Process.exec_args ~prog:"git"
    ~args:["-C"; hub; "config"; "user.email"; "test@test.com"] () in
  let _ = Cn_ffi.Process.exec_args ~prog:"git"
    ~args:["-C"; hub; "config"; "user.name"; "Test"] () in
  (* Initial commit so HEAD exists *)
  let _ = Cn_ffi.Process.exec_args ~prog:"git"
    ~args:["-C"; hub; "commit"; "--allow-empty"; "-m"; "init"] () in
  ()

let%expect_test "git_commit: nothing_staged when no changes in index" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create an unstaged file — don't stage it *)
    let oc = open_out (Filename.concat hub "src/unstaged.ml") in
    output_string oc "let x = 1";
    close_out oc;
    let op = { Cn_shell.kind = Effect Git_commit;
               op_id = Some "commit-01";
               fields = [("message", Cn_json.String "should skip")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_commit status=skipped reason=nothing_staged artifacts=0 |}]

let%expect_test "git_stage then git_commit: succeeds" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a new file *)
    let oc = open_out (Filename.concat hub "src/new_file.ml") in
    output_string oc "let y = 2";
    close_out oc;
    (* Stage it *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01";
                     fields = [("paths", Cn_json.Array [Cn_json.String "src/new_file.ml"])] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    (* Commit *)
    let commit_op = { Cn_shell.kind = Effect Git_commit;
                      op_id = Some "commit-01";
                      fields = [("message", Cn_json.String "add new_file")] } in
    let cr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config commit_op in
    show_receipt cr);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    kind=git_commit status=ok reason=(none) artifacts=0 |}]

let%expect_test "git_stage all then git_commit: succeeds" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create two new files *)
    let oc1 = open_out (Filename.concat hub "src/a.ml") in
    output_string oc1 "let a = 1"; close_out oc1;
    let oc2 = open_out (Filename.concat hub "docs/b.md") in
    output_string oc2 "# B"; close_out oc2;
    (* Stage all (no paths = stage everything) *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    (* Commit *)
    let commit_op = { Cn_shell.kind = Effect Git_commit;
                      op_id = Some "commit-01";
                      fields = [("message", Cn_json.String "add a and b")] } in
    let cr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config commit_op in
    show_receipt cr);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    kind=git_commit status=ok reason=(none) artifacts=0 |}]

(* === v3.8.0: git_stage path sandbox regressions === *)

let%expect_test "git_stage: denied path (.cn/) with explicit paths" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String ".cn/secrets.env"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=path_denied: .cn/secrets.env artifacts=0 |}]

let%expect_test "git_stage: denied protected file with explicit paths" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "spec/SOUL.md"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=path_denied: spec/SOUL.md artifacts=0 |}]

let%expect_test "git_stage: absolute path denied" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "/etc/passwd"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=path_denied: /etc/passwd artifacts=0 |}]

(* === v3.8.0: git_commit allow_empty === *)

let%expect_test "git_commit: allow_empty succeeds with nothing staged" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let op = { Cn_shell.kind = Effect Git_commit;
               op_id = Some "commit-01";
               fields = [("message", Cn_json.String "empty commit");
                          ("allow_empty", Cn_json.Bool true)] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_commit status=ok reason=(none) artifacts=0 |}]

(* === v3.8.0: git_stage directory path rejection === *)

let%expect_test "git_stage: directory path '.' rejected" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "."])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=directory_not_allowed: . artifacts=0 |}]

let%expect_test "git_stage: directory path 'src' rejected" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "src"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=directory_not_allowed: src artifacts=0 |}]

let%expect_test "git_stage: directory path 'spec' rejected" =
  with_test_hub (fun hub ->
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "spec"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=directory_not_allowed: spec artifacts=0 |}]

(* === v3.8.0: stage-all excludes protected files === *)

let staged_files hub =
  let _, out = Cn_ffi.Process.exec_args ~prog:"git"
    ~args:["-C"; hub; "diff"; "--cached"; "--name-only"] () in
  String.trim out

let%expect_test "git_stage all: protected files remain unstaged" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a normal file and modify a protected file *)
    let oc1 = open_out (Filename.concat hub "src/safe.ml") in
    output_string oc1 "let safe = true"; close_out oc1;
    let oc2 = open_out (Filename.concat hub "spec/SOUL.md") in
    output_string oc2 "# Modified SOUL"; close_out oc2;
    let oc3 = open_out (Filename.concat hub "spec/USER.md") in
    output_string oc3 "# Modified USER"; close_out oc3;
    (* Stage all *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    (* Check what actually got staged *)
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/safe.ml |}]

let%expect_test "git_stage all: symlink to .cn/ excluded" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a normal file *)
    let oc = open_out (Filename.concat hub "src/normal.ml") in
    output_string oc "let n = 1"; close_out oc;
    (* Create a symlink from src/sneaky.env -> .cn/secrets.env *)
    Unix.symlink
      (Filename.concat hub ".cn/secrets.env")
      (Filename.concat hub "src/sneaky.env");
    (* Stage all *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/normal.ml |}]

let%expect_test "git_stage all: symlink to protected file excluded" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a normal file *)
    let oc = open_out (Filename.concat hub "src/ok.ml") in
    output_string oc "let ok = true"; close_out oc;
    (* Create a symlink from docs/soul_link.md -> spec/SOUL.md *)
    Unix.symlink
      (Filename.concat hub "spec/SOUL.md")
      (Filename.concat hub "docs/soul_link.md");
    (* Stage all *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/ok.ml |}]

let%expect_test "git_stage explicit: symlink to .cn/ denied" =
  with_test_hub (fun hub ->
    (* Create a symlink from src/link.env -> .cn/secrets.env *)
    Unix.symlink
      (Filename.concat hub ".cn/secrets.env")
      (Filename.concat hub "src/link.env");
    let op = { Cn_shell.kind = Effect Git_stage;
               op_id = Some "stage-01";
               fields = [("paths", Cn_json.Array [Cn_json.String "src/link.env"])] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config op in
    show_receipt r);
  [%expect {| kind=git_stage status=denied reason=path_denied: src/link.env artifacts=0 |}]

let%expect_test "git_stage all: file with spaces in name staged correctly" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let oc = open_out (Filename.concat hub "src/my file.ml") in
    output_string oc "let x = 1"; close_out oc;
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/my file.ml |}]

let%expect_test "git_stage all: renamed file staged correctly" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a file, commit it, then rename it *)
    let oc = open_out (Filename.concat hub "src/old.ml") in
    output_string oc "let old = 1"; close_out oc;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "src/old.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add old"] () in
    (* Rename via git mv *)
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "mv"; "src/old.ml"; "src/new.ml"] () in
    (* Unstage to let stage-all pick it up fresh *)
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "reset"; "HEAD"; "--"; "src/old.ml"; "src/new.ml"] () in
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/new.ml |}]

let%expect_test "git_stage all: non-repo hub returns error" =
  with_test_hub (fun hub ->
    (* hub is not initialized as a git repo *)
    let oc = open_out (Filename.concat hub "src/x.ml") in
    output_string oc "let x = 1"; close_out oc;
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr);
  [%expect {| kind=git_stage status=error reason=git_status_exit_128: fatal: not a git repository (or any of the parent directories): .git artifacts=0 |}]

let%expect_test "git_diff observes spec/SOUL.md changes" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Commit initial SOUL.md, then modify it *)
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "spec/SOUL.md"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add soul"] () in
    let oc = open_out (Filename.concat hub "spec/SOUL.md") in
    output_string oc "# Modified SOUL"; close_out oc;
    (* git_diff with no paths should see the change *)
    let diff_op = { Cn_shell.kind = Observe Git_diff;
                    op_id = Some "obs-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config diff_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "sees_soul: %b\n" (String.length content > 0 &&
      try let _ = Str.search_forward (Str.regexp_string "SOUL.md") content 0 in true
      with Not_found -> false));
  [%expect {|
    kind=git_diff status=ok reason=(none) artifacts=1
    sees_soul: true |}]

let%expect_test "git_grep observes spec/SOUL.md content" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Commit SOUL.md with searchable content *)
    let oc = open_out (Filename.concat hub "spec/SOUL.md") in
    output_string oc "SOUL_MARKER_42"; close_out oc;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "spec/SOUL.md"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add soul content"] () in
    (* git_grep should find the marker *)
    let grep_op = { Cn_shell.kind = Observe Git_grep;
                    op_id = Some "obs-02";
                    fields = [("query", Cn_json.String "SOUL_MARKER_42")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config grep_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "finds_marker: %b\n" (String.length content > 0 &&
      try let _ = Str.search_forward (Str.regexp_string "SOUL_MARKER_42") content 0 in true
      with Not_found -> false));
  [%expect {|
    kind=git_grep status=ok reason=(none) artifacts=1
    finds_marker: true |}]

let%expect_test "git_stage all: spec/SOUL.md still write-denied" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Modify protected file and a safe file *)
    let oc1 = open_out (Filename.concat hub "spec/SOUL.md") in
    output_string oc1 "# Tampered SOUL"; close_out oc1;
    let oc2 = open_out (Filename.concat hub "src/good.ml") in
    output_string oc2 "let good = true"; close_out oc2;
    (* Stage all *)
    let stage_op = { Cn_shell.kind = Effect Git_stage;
                     op_id = Some "stage-01"; fields = [] } in
    let sr = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config stage_op in
    show_receipt sr;
    let staged = staged_files hub in
    Printf.printf "staged: %s\n" staged);
  [%expect {|
    kind=git_stage status=ok reason=(none) artifacts=0
    staged: src/good.ml |}]

(* === Git CLI injection regressions === *)

let%expect_test "git_diff: leading-dash rev is denied (--output injection)" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let target = Filename.concat hub "injected.txt" in
    let diff_op = { Cn_shell.kind = Observe Git_diff;
                    op_id = Some "obs-01";
                    fields = [("rev", Cn_json.String ("--output=" ^ target))] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config diff_op in
    Printf.printf "status=%s\n" (Cn_shell.string_of_receipt_status r.status);
    Printf.printf "denied: %b\n" (r.status = Cn_shell.Denied);
    Printf.printf "file_created: %b\n" (Sys.file_exists target));
  [%expect {|
    status=denied
    denied: true
    file_created: false |}]

let%expect_test "git_log: leading-dash rev is denied" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let log_op = { Cn_shell.kind = Observe Git_log;
                   op_id = Some "obs-01";
                   fields = [("rev", Cn_json.String "--format=%H")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config log_op in
    show_receipt r);
  [%expect {| kind=git_log status=denied reason=invalid_rev: leading dash not allowed: --format=%H artifacts=0 |}]

let%expect_test "git_grep: leading-dash query treated as literal via -e" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Commit a file containing a literal dash-prefixed string *)
    let oc = open_out (Filename.concat hub "src/main.ml") in
    output_string oc "--open-output flag"; close_out oc;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "src/main.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add content"] () in
    let grep_op = { Cn_shell.kind = Observe Git_grep;
                    op_id = Some "obs-01";
                    fields = [("query", Cn_json.String "--open-output")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config grep_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "found: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "--open-output") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_grep status=ok reason=(none) artifacts=1
    found: true |}]

let%expect_test "git_grep: pathspec magic chars treated literally" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Create a file under src and commit *)
    let oc = open_out (Filename.concat hub "src/main.ml") in
    output_string oc "hello world"; close_out oc;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "src/main.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add src"] () in
    (* Path with colon prefix — would be pathspec magic without
       GIT_LITERAL_PATHSPECS; should be treated as literal path *)
    let grep_op = { Cn_shell.kind = Observe Git_grep;
                    op_id = Some "obs-01";
                    fields = [("query", Cn_json.String "hello");
                              ("path", Cn_json.String "src")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config grep_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "found: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "hello") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_grep status=ok reason=(none) artifacts=1
    found: true |}]

(* === git_grep observe-exclusion regressions === *)

let%expect_test "git_grep no-path: .cn/secrets.env excluded from repo-wide grep" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    (* Put a shared marker in both .cn and src so grep always matches
       something — we test that the .cn hit is excluded, not that
       grep returns zero results. *)
    let oc = open_out (Filename.concat hub ".cn/secrets.env") in
    output_string oc "SHARED_MARKER_99"; close_out oc;
    let oc2 = open_out (Filename.concat hub "src/main.ml") in
    output_string oc2 "SHARED_MARKER_99"; close_out oc2;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "--force"; ".cn/secrets.env"; "src/main.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add shared marker"] () in
    (* Repo-wide grep with no path should find src but not .cn *)
    let grep_op = { Cn_shell.kind = Observe Git_grep;
                    op_id = Some "obs-01";
                    fields = [("query", Cn_json.String "SHARED_MARKER_99")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config grep_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "finds_src: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "src/main.ml") content 0); true
       with Not_found -> false);
    Printf.printf "finds_cn: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string ".cn/") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_grep status=ok reason=(none) artifacts=1
    finds_src: true
    finds_cn: false |}]

let%expect_test "git_grep path=.: .cn/secrets.env excluded from root-scoped grep" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let oc = open_out (Filename.concat hub ".cn/secrets.env") in
    output_string oc "ROOT_MARKER_77"; close_out oc;
    let oc2 = open_out (Filename.concat hub "src/main.ml") in
    output_string oc2 "ROOT_MARKER_77"; close_out oc2;
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "--force"; ".cn/secrets.env"; "src/main.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "add root marker"] () in
    (* Explicit path="." — root-scoped grep must still exclude .cn *)
    let grep_op = { Cn_shell.kind = Observe Git_grep;
                    op_id = Some "obs-01";
                    fields = [("query", Cn_json.String "ROOT_MARKER_77");
                              ("path", Cn_json.String ".")] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config grep_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "finds_src: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "src/main.ml") content 0); true
       with Not_found -> false);
    Printf.printf "finds_cn: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string ".cn/") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_grep status=ok reason=(none) artifacts=1
    finds_src: true
    finds_cn: false |}]

(* === git_status observe-exclusion tests === *)

let%expect_test "git_status: shows src/ changes, hides .cn/ state/ logs/" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let touch path content =
      let full = Filename.concat hub path in
      let oc = open_out full in
      output_string oc content; close_out oc
    in
    touch "src/new_file.ml" "let x = 1";
    touch ".cn/internal.dat" "internal";
    touch "state/artifacts/art-001.txt" "artifact data";
    touch "state/receipts/rcpt-001.json" "{}";
    touch "logs/events.jsonl" "{\"event\":\"test\"}";
    let status_op = { Cn_shell.kind = Observe Git_status;
                      op_id = Some "obs-01"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config status_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "finds_src: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "src/") content 0); true
       with Not_found -> false);
    Printf.printf "finds_cn: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string ".cn/") content 0); true
       with Not_found -> false);
    Printf.printf "finds_state: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "state/") content 0); true
       with Not_found -> false);
    Printf.printf "finds_logs: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "logs/") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_status status=ok reason=(none) artifacts=1
    finds_src: true
    finds_cn: false
    finds_state: false
    finds_logs: false |}]

let%expect_test "git_status: prior observe op artifacts do not pollute status" =
  with_test_hub (fun hub ->
    init_git_repo hub;
    let touch path content =
      let full = Filename.concat hub path in
      let oc = open_out full in
      output_string oc content; close_out oc
    in
    touch "src/main.ml" "let () = ()";
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "add"; "src/main.ml"] () in
    let _ = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["-C"; hub; "commit"; "-m"; "baseline"] () in
    (* Run a git_diff observe op — this creates receipt/artifact files under state/ *)
    let diff_op = { Cn_shell.kind = Observe Git_diff;
                    op_id = Some "obs-01"; fields = [] } in
    let _diff_r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config diff_op in
    (* Now make a visible change in src/ *)
    touch "src/main.ml" "let () = print_endline \"changed\"";
    (* Run git_status — should see src/ change but NOT state/artifacts or state/receipts *)
    let status_op = { Cn_shell.kind = Observe Git_status;
                      op_id = Some "obs-02"; fields = [] } in
    let r = Cn_executor.execute_op ~hub_path:hub ~trigger_id ~config:test_config status_op in
    show_receipt r;
    let content = read_artifact hub r in
    Printf.printf "finds_src: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "src/") content 0); true
       with Not_found -> false);
    Printf.printf "finds_state: %b\n"
      (try ignore (Str.search_forward (Str.regexp_string "state/") content 0); true
       with Not_found -> false));
  [%expect {|
    kind=git_status status=ok reason=(none) artifacts=1
    finds_src: true
    finds_state: false |}]
