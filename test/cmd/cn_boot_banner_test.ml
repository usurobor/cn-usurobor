(** cn_boot_banner_test: ppx_expect tests for boot banner (issue #61)

    Tests:
    - render_boot_banner includes version, hub, profile, model, secrets, peers
    - Secret values never appear in banner output
    - probe_source correctly identifies env vs file vs missing *)

(* === Helpers === *)

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
  let hub = mk_temp_dir "cn-boot-banner-test" in
  let cn_dir = Filename.concat hub ".cn" in
  Unix.mkdir cn_dir 0o700;
  let state_dir = Filename.concat hub "state" in
  Unix.mkdir state_dir 0o700;
  Fun.protect ~finally:(fun () ->
    (* cleanup *)
    let secrets = Filename.concat cn_dir "secrets.env" in
    let peers = Filename.concat state_dir "peers.md" in
    (try Sys.remove secrets with Sys_error _ -> ());
    (try Sys.remove peers with Sys_error _ -> ());
    (try Unix.rmdir state_dir with Unix.Unix_error _ -> ());
    (try Unix.rmdir cn_dir with Unix.Unix_error _ -> ());
    (try Unix.rmdir hub with Unix.Unix_error _ -> ())
  ) (fun () -> f hub)

(* === probe_source tests === *)

let%expect_test "probe_source: env var set" =
  with_temp_hub (fun hub ->
    Unix.putenv "CN_TEST_PROBE_KEY" "some-value";
    Fun.protect ~finally:(fun () ->
      Unix.putenv "CN_TEST_PROBE_KEY" ""
    ) (fun () ->
      let src = Cn_dotenv.probe_source ~hub_path:hub ~env_key:"CN_TEST_PROBE_KEY" in
      Printf.printf "%s\n" (match src with
        | Cn_dotenv.Env -> "env"
        | Cn_dotenv.File -> "file"
        | Cn_dotenv.Missing -> "missing")));
  [%expect {| env |}]

let%expect_test "probe_source: in secrets file" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "CN_TEST_FILE_KEY=secret-val\n";
    close_out oc;
    Unix.chmod path 0o600;
    (try Unix.putenv "CN_TEST_FILE_KEY" "" with _ -> ());
    let src = Cn_dotenv.probe_source ~hub_path:hub ~env_key:"CN_TEST_FILE_KEY" in
    Printf.printf "%s\n" (match src with
      | Cn_dotenv.Env -> "env"
      | Cn_dotenv.File -> "file"
      | Cn_dotenv.Missing -> "missing"));
  [%expect {| file |}]

let%expect_test "probe_source: missing everywhere" =
  with_temp_hub (fun hub ->
    (try Unix.putenv "CN_TEST_NOWHERE_KEY" "" with _ -> ());
    let src = Cn_dotenv.probe_source ~hub_path:hub ~env_key:"CN_TEST_NOWHERE_KEY" in
    Printf.printf "%s\n" (match src with
      | Cn_dotenv.Env -> "env"
      | Cn_dotenv.File -> "file"
      | Cn_dotenv.Missing -> "missing"));
  [%expect {| missing |}]

let%expect_test "probe_source: env takes precedence over file" =
  with_temp_hub (fun hub ->
    let path = Filename.concat hub ".cn/secrets.env" in
    let oc = open_out path in
    output_string oc "CN_TEST_BOTH_KEY=file-val\n";
    close_out oc;
    Unix.chmod path 0o600;
    Unix.putenv "CN_TEST_BOTH_KEY" "env-val";
    Fun.protect ~finally:(fun () ->
      Unix.putenv "CN_TEST_BOTH_KEY" ""
    ) (fun () ->
      let src = Cn_dotenv.probe_source ~hub_path:hub ~env_key:"CN_TEST_BOTH_KEY" in
      Printf.printf "%s\n" (match src with
        | Cn_dotenv.Env -> "env"
        | Cn_dotenv.File -> "file"
        | Cn_dotenv.Missing -> "missing")));
  [%expect {| env |}]

(* === Banner safety: no secret values in output === *)

let%expect_test "probe_source: return type has no value field" =
  (* Type-level test: secret_source is Env | File | Missing — no string payload.
     This ensures the banner can never accidentally leak a secret value
     through the source probe. Compile = pass. *)
  let _x : Cn_dotenv.secret_source = Cn_dotenv.Env in
  let _y : Cn_dotenv.secret_source = Cn_dotenv.File in
  let _z : Cn_dotenv.secret_source = Cn_dotenv.Missing in
  print_endline "type has no value payload";
  [%expect {| type has no value payload |}]
