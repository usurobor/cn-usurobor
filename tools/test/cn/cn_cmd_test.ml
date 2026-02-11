(** cn_cmd_test: ppx_expect tests for cn_cmd module functions

    Tests pure or near-pure functions from the cn_cmd modules:
    - Cn_mail.parse_rejected_branch (string parsing)

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
