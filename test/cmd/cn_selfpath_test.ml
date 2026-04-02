(** cn_selfpath_test: ppx_expect tests for hardcoded path removal (#146)

    Three invariants tested:
    1. bin_path resolution chain — $CN_BIN > /proc/self/exe > readlink exe > Sys.executable_name
    2. repo resolution chain — $CN_REPO > cn.json build-time value
    3. No hardcoded literals remain in resolved values *)

(* Helper: save, set, run, restore an env var.
   OCaml stdlib has no unsetenv — empty string is treated as unset
   by our resolution functions (String.length > 0 guard). *)
let with_env var value f =
  let saved = Sys.getenv_opt var in
  Unix.putenv var value;
  let result = f () in
  (match saved with
   | Some v -> Unix.putenv var v
   | None -> Unix.putenv var "");
  result

(* ============================================================
   Invariant 1: resolve_bin_path respects $CN_BIN override
   ============================================================ *)

let%expect_test "resolve_bin_path: CN_BIN override takes precedence" =
  with_env "CN_BIN" "/custom/path/cn" (fun () ->
    let result = Cn_agent.resolve_bin_path () in
    Printf.printf "bin_path = %s\n" result);
  [%expect {| bin_path = /custom/path/cn |}]

let%expect_test "resolve_bin_path: without CN_BIN returns non-empty string" =
  with_env "CN_BIN" "" (fun () ->
    let result = Cn_agent.resolve_bin_path () in
    Printf.printf "non_empty = %b\n" (String.length result > 0));
  [%expect {| non_empty = true |}]

(* ============================================================
   Invariant 2: resolve_repo respects $CN_REPO override
   ============================================================ *)

let%expect_test "resolve_repo: CN_REPO override takes precedence" =
  with_env "CN_REPO" "other-org/other-repo" (fun () ->
    let result = Cn_agent.resolve_repo () in
    Printf.printf "repo = %s\n" result);
  [%expect {| repo = other-org/other-repo |}]

let%expect_test "resolve_repo: without CN_REPO returns cn.json value" =
  with_env "CN_REPO" "" (fun () ->
    let result = Cn_agent.resolve_repo () in
    Printf.printf "matches_cnos_repo = %b\n" (result = Cn_lib.cnos_repo));
  [%expect {| matches_cnos_repo = true |}]

(* ============================================================
   Invariant 3: cn_lib.cnos_repo is derived from build-time metadata
   ============================================================ *)

let%expect_test "cnos_repo: build-time value is owner/repo format" =
  let repo = Cn_lib.cnos_repo in
  let has_slash = String.contains repo '/' in
  let non_empty = String.length repo > 0 in
  let no_dot_git = not (Filename.check_suffix repo ".git") in
  Printf.printf "has_slash = %b\n" has_slash;
  Printf.printf "non_empty = %b\n" non_empty;
  Printf.printf "no_dot_git = %b\n" no_dot_git;
  [%expect {|
    has_slash = true
    non_empty = true
    no_dot_git = true
  |}]

(* ============================================================
   Invariant 4: cn_deps derives source from cnos_repo
   ============================================================ *)

let%expect_test "default_first_party_source: derived from cnos_repo" =
  let source = Cn_deps.default_first_party_source in
  let expected = Printf.sprintf "https://github.com/%s.git" Cn_lib.cnos_repo in
  Printf.printf "matches = %b\n" (source = expected);
  [%expect {| matches = true |}]

(* ============================================================
   Negative space: no /usr/local/bin/cn literal in resolved bin_path
   ============================================================ *)

let%expect_test "bin_path: not hardcoded to /usr/local/bin/cn" =
  with_env "CN_BIN" "/test/override/cn" (fun () ->
    let result = Cn_agent.resolve_bin_path () in
    Printf.printf "is_override = %b\n" (result = "/test/override/cn");
    Printf.printf "is_not_usr_local = %b\n" (result <> "/usr/local/bin/cn"));
  [%expect {|
    is_override = true
    is_not_usr_local = true
  |}]
