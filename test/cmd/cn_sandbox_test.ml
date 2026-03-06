(** cn_sandbox_test: ppx_expect tests for path sandbox

    Tests pure path normalization, denylist, and protected file logic.
    Filesystem tests use temp directories with symlinks for
    validate_path (the only function with I/O). *)

(* === Helper === *)

let show_normalize path =
  match Cn_sandbox.normalize_path path with
  | Ok p -> Printf.printf "ok: %s\n" p
  | Error r -> Printf.printf "denied: %s\n" (Cn_sandbox.string_of_denial_reason r)

let show_denylist path =
  match Cn_sandbox.check_denylist path with
  | None -> Printf.printf "allowed: %s\n" path
  | Some prefix -> Printf.printf "denied by: %s\n" prefix

let show_access ~access path =
  match Cn_sandbox.check_access ~access path with
  | Ok p -> Printf.printf "ok: %s\n" p
  | Error r -> Printf.printf "denied: %s\n" (Cn_sandbox.string_of_denial_reason r)

(* === Pure: normalize_path === *)

let%expect_test "normalize: simple relative path" =
  show_normalize "src/lib/cn_json.ml";
  [%expect {| ok: src/lib/cn_json.ml |}]

let%expect_test "normalize: path with redundant dots" =
  show_normalize "src/./lib/../lib/cn_json.ml";
  [%expect {| ok: src/lib/cn_json.ml |}]

let%expect_test "normalize: absolute path denied" =
  show_normalize "/etc/passwd";
  [%expect {| denied: absolute_path |}]

let%expect_test "normalize: escape via .." =
  show_normalize "../../etc/passwd";
  [%expect {| denied: path_escape |}]

let%expect_test "normalize: deep escape via .." =
  show_normalize "src/../../etc/shadow";
  [%expect {| denied: path_escape |}]

let%expect_test "normalize: single .. escapes" =
  show_normalize "..";
  [%expect {| denied: path_escape |}]

let%expect_test "normalize: empty path becomes ." =
  show_normalize "";
  [%expect {| ok: . |}]

let%expect_test "normalize: just dot" =
  show_normalize ".";
  [%expect {| ok: . |}]

let%expect_test "normalize: trailing slash stripped" =
  show_normalize "docs/design/";
  [%expect {| ok: docs/design |}]

let%expect_test "normalize: .. that stays within hub" =
  show_normalize "src/lib/../cmd/cn_shell.ml";
  [%expect {| ok: src/cmd/cn_shell.ml |}]

let%expect_test "normalize: exact boundary (go up to root, stay in)" =
  show_normalize "src/..";
  [%expect {| ok: . |}]

(* === Pure: denylist === *)

let%expect_test "denylist: .cn/secrets.env denied" =
  show_denylist ".cn/secrets.env";
  [%expect {| denied by: .cn/ |}]

let%expect_test "denylist: .cn/ root denied" =
  show_denylist ".cn";
  [%expect {| denied by: .cn/ |}]

let%expect_test "denylist: .git/config denied" =
  show_denylist ".git/config";
  [%expect {| denied by: .git/ |}]

let%expect_test "denylist: state/input.md denied" =
  show_denylist "state/input.md";
  [%expect {| denied by: state/ |}]

let%expect_test "denylist: logs/output.md denied" =
  show_denylist "logs/output.md";
  [%expect {| denied by: logs/ |}]

let%expect_test "denylist: src/lib/cn_json.ml allowed" =
  show_denylist "src/lib/cn_json.ml";
  [%expect {| allowed: src/lib/cn_json.ml |}]

let%expect_test "denylist: docs/design/README.md allowed" =
  show_denylist "docs/design/README.md";
  [%expect {| allowed: docs/design/README.md |}]

let%expect_test "denylist: spec/SOUL.md allowed by denylist (not a prefix match)" =
  show_denylist "spec/SOUL.md";
  [%expect {| allowed: spec/SOUL.md |}]

let%expect_test "denylist: state_machine.ml allowed (state/ prefix != state_)" =
  show_denylist "state_machine.ml";
  [%expect {| allowed: state_machine.ml |}]

let%expect_test "denylist: .cnrc allowed (not .cn/ prefix)" =
  show_denylist ".cnrc";
  [%expect {| allowed: .cnrc |}]

let%expect_test "denylist: custom denylist" =
  (match Cn_sandbox.check_denylist ~denylist:["secret/"; "vendor/"] "secret/key.pem" with
   | Some p -> Printf.printf "denied by: %s\n" p
   | None -> print_endline "allowed");
  [%expect {| denied by: secret/ |}]

(* === Pure: check_access (denylist + protected files) === *)

let%expect_test "access: read .cn/secrets.env denied" =
  show_access ~access:Read_access ".cn/secrets.env";
  [%expect {| denied: path_denied |}]

let%expect_test "access: read src/main.ml allowed" =
  show_access ~access:Read_access "src/main.ml";
  [%expect {| ok: src/main.ml |}]

let%expect_test "access: write spec/SOUL.md denied (protected)" =
  show_access ~access:Write_access "spec/SOUL.md";
  [%expect {| denied: protected_file |}]

let%expect_test "access: write spec/USER.md denied (protected)" =
  show_access ~access:Write_access "spec/USER.md";
  [%expect {| denied: protected_file |}]

let%expect_test "access: write state/peers.md denied (denylist before protected)" =
  (* state/ is in denylist, so this hits denylist first *)
  show_access ~access:Write_access "state/peers.md";
  [%expect {| denied: path_denied |}]

let%expect_test "access: read spec/SOUL.md allowed (read, not write)" =
  show_access ~access:Read_access "spec/SOUL.md";
  [%expect {| ok: spec/SOUL.md |}]

let%expect_test "access: write docs/design/README.md allowed" =
  show_access ~access:Write_access "docs/design/README.md";
  [%expect {| ok: docs/design/README.md |}]

(* === Filesystem: validate_path with symlinks === *)

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

(** Create a minimal hub structure for testing *)
let with_test_hub f =
  let hub = mk_temp_dir "cn-sandbox-test" in
  (* Create directories *)
  let dirs = ["src"; "docs"; ".cn"; "spec"; "state"; "logs"] in
  List.iter (fun d ->
    Unix.mkdir (Filename.concat hub d) 0o755
  ) dirs;
  (* Create some files *)
  let touch path content =
    let full = Filename.concat hub path in
    let oc = open_out full in
    output_string oc content;
    close_out oc
  in
  touch "src/main.ml" "let () = ()";
  touch ".cn/secrets.env" "KEY=secret";
  touch "spec/SOUL.md" "# SOUL";
  touch "spec/USER.md" "# USER";
  touch "docs/README.md" "# Docs";
  Fun.protect ~finally:(fun () ->
    (* Recursive cleanup *)
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

let show_validate hub ~access path =
  match Cn_sandbox.validate_path ~hub_path:hub ~access path with
  | Ok p -> Printf.printf "ok: %s\n" p
  | Error r -> Printf.printf "denied: %s\n" (Cn_sandbox.string_of_denial_reason r)

let%expect_test "validate: simple read of existing file" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access "src/main.ml");
  [%expect {| ok: src/main.ml |}]

let%expect_test "validate: write to allowed path" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Write_access "docs/README.md");
  [%expect {| ok: docs/README.md |}]

let%expect_test "validate: absolute path denied" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access "/etc/passwd");
  [%expect {| denied: absolute_path |}]

let%expect_test "validate: .. escape denied" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access "../../etc/passwd");
  [%expect {| denied: path_escape |}]

let%expect_test "validate: .cn/secrets.env denied" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access ".cn/secrets.env");
  [%expect {| denied: path_denied |}]

let%expect_test "validate: write spec/SOUL.md denied (protected)" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Write_access "spec/SOUL.md");
  [%expect {| denied: protected_file |}]

let%expect_test "validate: read spec/SOUL.md allowed" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access "spec/SOUL.md");
  [%expect {| ok: spec/SOUL.md |}]

let%expect_test "validate: symlink into .cn/ denied" =
  with_test_hub (fun hub ->
    (* Create a symlink: docs/sneaky -> ../.cn/secrets.env *)
    Unix.symlink
      (Filename.concat hub ".cn/secrets.env")
      (Filename.concat hub "docs/sneaky");
    show_validate hub ~access:Read_access "docs/sneaky");
  [%expect {| denied: path_denied |}]

let%expect_test "validate: symlink escaping hub denied" =
  with_test_hub (fun hub ->
    (* Create a symlink: docs/escape -> /etc/passwd *)
    Unix.symlink "/etc/passwd" (Filename.concat hub "docs/escape");
    show_validate hub ~access:Read_access "docs/escape");
  [%expect {| denied: symlink_escape |}]

let%expect_test "validate: symlink to allowed file within hub ok" =
  with_test_hub (fun hub ->
    (* Create a symlink: docs/link -> ../src/main.ml *)
    Unix.symlink
      (Filename.concat hub "src/main.ml")
      (Filename.concat hub "docs/link");
    show_validate hub ~access:Read_access "docs/link");
  [%expect {| ok: src/main.ml |}]

let%expect_test "validate: nonexistent file uses normalized path for denylist" =
  with_test_hub (fun hub ->
    (* File doesn't exist, but path is in .cn/ *)
    show_validate hub ~access:Read_access ".cn/nonexistent.txt");
  [%expect {| denied: path_denied |}]

let%expect_test "validate: nonexistent file in allowed dir ok" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Write_access "src/new_file.ml");
  [%expect {| ok: src/new_file.ml |}]

let%expect_test "validate: normalized .. before symlink resolution" =
  with_test_hub (fun hub ->
    show_validate hub ~access:Read_access "src/../docs/README.md");
  [%expect {| ok: docs/README.md |}]
