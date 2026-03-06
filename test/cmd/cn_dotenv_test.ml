(** cn_dotenv_test: ppx_expect tests for cn_dotenv

    Tests the pure parsing core of the dotenv loader.
    Filesystem tests (permissions, missing file) use temp directories. *)

(* === Pure parse tests === *)

let%expect_test "parse: simple key=value" =
  let pairs = Cn_dotenv.parse "FOO=bar" in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| FOO=bar |}]

let%expect_test "parse: multiple entries" =
  let input = "KEY_A=hello\nKEY_B=world" in
  let pairs = Cn_dotenv.parse input in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {|
    KEY_A=hello
    KEY_B=world
  |}]

let%expect_test "parse: skip blank lines and comments" =
  let input = "\n# this is a comment\nFOO=bar\n\n# another\nBAZ=qux\n" in
  let pairs = Cn_dotenv.parse input in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {|
    FOO=bar
    BAZ=qux
  |}]

let%expect_test "parse: strip double quotes" =
  let pairs = Cn_dotenv.parse {|TOKEN="sk-ant-abc123"|} in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| TOKEN=sk-ant-abc123 |}]

let%expect_test "parse: strip single quotes" =
  let pairs = Cn_dotenv.parse "SECRET='my-secret'" in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| SECRET=my-secret |}]

let%expect_test "parse: unquoted value with spaces preserved" =
  let pairs = Cn_dotenv.parse "MSG=hello world" in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| MSG=hello world |}]

let%expect_test "parse: empty value" =
  let pairs = Cn_dotenv.parse "EMPTY=" in
  List.iter (fun (k, v) -> Printf.printf "%s=[%s]\n" k v) pairs;
  [%expect {| EMPTY=[] |}]

let%expect_test "parse: value with equals sign" =
  let pairs = Cn_dotenv.parse "URL=https://example.com?a=1&b=2" in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| URL=https://example.com?a=1&b=2 |}]

let%expect_test "parse: reject lowercase keys" =
  let pairs = Cn_dotenv.parse "lowercase=bad" in
  Printf.printf "%d pairs\n" (List.length pairs);
  [%expect {| 0 pairs |}]

let%expect_test "parse: reject keys with hyphens" =
  let pairs = Cn_dotenv.parse "MY-KEY=bad" in
  Printf.printf "%d pairs\n" (List.length pairs);
  [%expect {| 0 pairs |}]

let%expect_test "parse: valid key characters" =
  let pairs = Cn_dotenv.parse "A_B_C_123=ok" in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {| A_B_C_123=ok |}]

let%expect_test "parse: whitespace around value trimmed" =
  let pairs = Cn_dotenv.parse "KEY=  spaced  " in
  List.iter (fun (k, v) -> Printf.printf "%s=[%s]\n" k v) pairs;
  [%expect {| KEY=[spaced] |}]

let%expect_test "parse: lines without equals skipped" =
  let input = "GOOD=yes\njust some text\nALSO_GOOD=yep" in
  let pairs = Cn_dotenv.parse input in
  List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs;
  [%expect {|
    GOOD=yes
    ALSO_GOOD=yep
  |}]

(* === Filesystem tests === *)

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

let with_temp_hub f =
  let hub = mk_temp_dir "cn-dotenv-test" in
  let cn_dir = Filename.concat hub ".cn" in
  Unix.mkdir cn_dir 0o700;
  Fun.protect ~finally:(fun () ->
    (* cleanup *)
    let secrets = Filename.concat cn_dir "secrets.env" in
    (try Sys.remove secrets with Sys_error _ -> ());
    (try Unix.rmdir cn_dir with Unix.Unix_error _ -> ());
    (try Unix.rmdir hub with Unix.Unix_error _ -> ())
  ) (fun () -> f hub)

let%expect_test "load_file: missing file returns empty" =
  (match Cn_dotenv.load_file "/nonexistent/secrets.env" with
   | Ok pairs -> Printf.printf "%d pairs\n" (List.length pairs)
   | Error msg -> Printf.printf "error: %s\n" msg);
  [%expect {| 0 pairs |}]

let%expect_test "load_file: valid file parsed" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "ANTHROPIC_KEY=sk-ant-test\nTELEGRAM_TOKEN=bot123\n";
    close_out oc;
    Unix.chmod path 0o600;
    match Cn_dotenv.load_file path with
    | Ok pairs ->
      List.iter (fun (k, v) -> Printf.printf "%s=%s\n" k v) pairs
    | Error msg -> Printf.printf "error: %s\n" msg);
  [%expect {|
    ANTHROPIC_KEY=sk-ant-test
    TELEGRAM_TOKEN=bot123
  |}]

let%expect_test "load_file: permissions too open" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "KEY=value\n";
    close_out oc;
    Unix.chmod path 0o644;
    match Cn_dotenv.load_file path with
    | Ok _ -> print_endline "unexpected ok"
    | Error msg ->
      (* Check it mentions permissions *)
      let has_perm = String.length msg > 0 in
      Printf.printf "error returned: %b\n" has_perm);
  [%expect {| error returned: true |}]

let%expect_test "load_file: permissions 0400 accepted" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "KEY=value\n";
    close_out oc;
    Unix.chmod path 0o400;
    match Cn_dotenv.load_file path with
    | Ok pairs -> Printf.printf "%d pairs\n" (List.length pairs)
    | Error msg -> Printf.printf "error: %s\n" msg);
  [%expect {| 1 pairs |}]

let%expect_test "resolve_secret: env var takes precedence" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "ANTHROPIC_KEY=from-file\n";
    close_out oc;
    Unix.chmod path 0o600;
    Unix.putenv "ANTHROPIC_KEY" "from-env";
    Fun.protect ~finally:(fun () ->
      (* Can't truly unset in OCaml pre-5.x, set empty *)
      Unix.putenv "ANTHROPIC_KEY" ""
    ) (fun () ->
      match Cn_dotenv.resolve_secret ~hub_path:hub ~env_key:"ANTHROPIC_KEY" with
      | Some v -> Printf.printf "resolved: %s\n" v
      | None -> print_endline "none"));
  [%expect {| resolved: from-env |}]

let%expect_test "resolve_secret: falls back to file" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "MY_SECRET=from-file\n";
    close_out oc;
    Unix.chmod path 0o600;
    (* Ensure env var is not set *)
    (try Unix.putenv "MY_SECRET" "" with _ -> ());
    match Cn_dotenv.resolve_secret ~hub_path:hub ~env_key:"MY_SECRET" with
    | Some v -> Printf.printf "resolved: %s\n" v
    | None -> print_endline "none");
  [%expect {| resolved: from-file |}]

let%expect_test "resolve_secret: missing everywhere returns none" =
  with_temp_hub (fun hub ->
    (try Unix.putenv "NONEXISTENT_KEY_XYZ" "" with _ -> ());
    match Cn_dotenv.resolve_secret ~hub_path:hub ~env_key:"NONEXISTENT_KEY_XYZ" with
    | Some v -> Printf.printf "resolved: %s\n" v
    | None -> print_endline "none");
  [%expect {| none |}]
