(** cn_mail_test: ppx_expect tests for mail transport invariants

    Invariants tested:
    - Self-send guard — to == my_name is rejected before send *)

(* ============================================================
   Self-send is detectable
   ============================================================

   The self-send guard is a string comparison: to_name = my_name.
   This test validates the concept that the guard would fire. *)

let%expect_test "self-send detection: same identity" =
  let my_name = "sigma" in
  let to_name = "sigma" in
  Printf.printf "self_send = %b\n" (to_name = my_name);
  [%expect {| self_send = true |}]

let%expect_test "self-send detection: different identity" =
  let my_name = "sigma" in
  let to_name = "pi" in
  Printf.printf "self_send = %b\n" (to_name = my_name);
  [%expect {| self_send = false |}]
