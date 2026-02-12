(** cn_cmd_test: ppx_expect tests for cn_cmd module functions

    Tests pure or near-pure functions from the cn_cmd modules:
    - Cn_mail.parse_rejected_branch (string parsing)
    - Cn_agent.version_to_tuple (version string parsing)
    - Cn_agent.is_newer_version (semver comparison)
    - Cn_agent.auto_update_enabled (recursion guard + kill switch)

    Note: Most cn_cmd functions do I/O (Cn_ffi.Fs, git). Those need
    integration tests with temp directories. This file covers the
    pure subset that can be tested with ppx_expect. *)

(* === Cn_mail: parse_rejected_branch === *)

let%expect_test "parse_rejected_branch: valid rejection notice" =
  let content = "Branch `pi/review-request` rejected and deleted." in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| Some pi/review-request |}]

let%expect_test "parse_rejected_branch: simple branch name" =
  let content = "Branch `fix-bug` rejected and deleted." in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| Some fix-bug |}]

let%expect_test "parse_rejected_branch: not a rejection notice" =
  let content = "Something else `branch` here" in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: empty string" =
  (match Cn_mail.parse_rejected_branch "" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: too short" =
  (match Cn_mail.parse_rejected_branch "Branch" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: no closing backtick" =
  (match Cn_mail.parse_rejected_branch "Branch `foo" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: empty branch name" =
  (match Cn_mail.parse_rejected_branch "Branch `` rejected" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]


(* === Cn_agent: version_to_tuple === *)

let show_tuple v =
  match Cn_agent.version_to_tuple v with
  | Some (a, b, c) -> Printf.printf "Some (%d, %d, %d)\n" a b c
  | None -> print_endline "None"

let%expect_test "version_to_tuple: plain semver" =
  show_tuple "2.4.3";
  [%expect {| Some (2, 4, 3) |}]

let%expect_test "version_to_tuple: v-prefix" =
  show_tuple "v2.4.3";
  [%expect {| Some (2, 4, 3) |}]

let%expect_test "version_to_tuple: zero version" =
  show_tuple "0.0.0";
  [%expect {| Some (0, 0, 0) |}]

let%expect_test "version_to_tuple: two segments" =
  show_tuple "2.4";
  [%expect {| None |}]

let%expect_test "version_to_tuple: four segments" =
  show_tuple "2.4.3.1";
  [%expect {| None |}]

let%expect_test "version_to_tuple: non-numeric" =
  show_tuple "2.4.beta";
  [%expect {| None |}]

let%expect_test "version_to_tuple: empty string" =
  show_tuple "";
  [%expect {| None |}]

let%expect_test "version_to_tuple: just v" =
  show_tuple "v";
  [%expect {| None |}]


(* === Cn_agent: is_newer_version === *)

let show_newer remote local =
  Printf.printf "%s vs %s → %b\n" remote local
    (Cn_agent.is_newer_version remote local)

let%expect_test "is_newer_version: patch bump" =
  show_newer "2.4.3" "2.4.2";
  [%expect {| 2.4.3 vs 2.4.2 → true |}]

let%expect_test "is_newer_version: minor bump" =
  show_newer "2.5.0" "2.4.9";
  [%expect {| 2.5.0 vs 2.4.9 → true |}]

let%expect_test "is_newer_version: major bump" =
  show_newer "3.0.0" "2.99.99";
  [%expect {| 3.0.0 vs 2.99.99 → true |}]

let%expect_test "is_newer_version: same version" =
  show_newer "2.4.3" "2.4.3";
  [%expect {| 2.4.3 vs 2.4.3 → false |}]

let%expect_test "is_newer_version: older remote" =
  show_newer "2.4.2" "2.4.3";
  [%expect {| 2.4.2 vs 2.4.3 → false |}]

let%expect_test "is_newer_version: v-prefix mixed" =
  show_newer "v2.5.0" "2.4.0";
  [%expect {| v2.5.0 vs 2.4.0 → true |}]

let%expect_test "is_newer_version: both v-prefix" =
  show_newer "v3.0.0" "v2.0.0";
  [%expect {| v3.0.0 vs v2.0.0 → true |}]

let%expect_test "is_newer_version: garbage remote" =
  show_newer "garbage" "2.4.3";
  [%expect {| garbage vs 2.4.3 → false |}]

let%expect_test "is_newer_version: garbage local" =
  show_newer "2.5.0" "garbage";
  [%expect {| 2.5.0 vs garbage → false |}]

let%expect_test "is_newer_version: both garbage" =
  show_newer "abc" "def";
  [%expect {| abc vs def → false |}]


(* === Cn_agent: auto_update_enabled (recursion guard) ===

   Tests ordered carefully: CN_UPDATE_RUNNING is set last because
   OCaml has no Unix.unsetenv — once set, it persists. *)

let%expect_test "auto_update_enabled: default is true" =
  (* Neither CN_UPDATE_RUNNING nor CN_AUTO_UPDATE=0 set in test env *)
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  [%expect {| true |}]

let%expect_test "auto_update_enabled: CN_AUTO_UPDATE=0 disables" =
  Unix.putenv "CN_AUTO_UPDATE" "0";
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  (* Clean up so subsequent tests aren't affected *)
  Unix.putenv "CN_AUTO_UPDATE" "1";
  [%expect {| false |}]

let%expect_test "auto_update_enabled: CN_UPDATE_RUNNING blocks re-exec loop" =
  (* This test MUST be last — putenv cannot be undone without unsetenv.
     This is the critical guard that prevents the infinite loop from
     MCA: self-update-recursion. *)
  Unix.putenv "CN_UPDATE_RUNNING" "1";
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  [%expect {| false |}]
