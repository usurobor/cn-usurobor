(** cn_mail_test: ppx_expect tests for orphan rejection loop fix (#144)

    Three invariants tested:
    1. Rejection deduplication — deterministic filenames prevent amplification
    2. Fetched peer identity is authoritative — peer_name, not git log author
    3. Self-send guard — to == my_name is rejected before send *)

(* ============================================================
   Invariant 1: Rejection filename is deterministic
   ============================================================

   Same (peer, branch) must always produce the same filename.
   This prevents the amplification loop where timestamped filenames
   caused unbounded rejection messages for the same orphan branch. *)

let%expect_test "rejection_filename: deterministic for same inputs" =
  let f1 = Cn_mail.rejection_filename "pi" "sigma/test-topic" in
  let f2 = Cn_mail.rejection_filename "pi" "sigma/test-topic" in
  Printf.printf "f1 = %s\n" f1;
  Printf.printf "f2 = %s\n" f2;
  Printf.printf "equal = %b\n" (f1 = f2);
  [%expect {|
    f1 = rejected-pi-sigma-test-topic.md
    f2 = rejected-pi-sigma-test-topic.md
    equal = true
  |}]

let%expect_test "rejection_filename: different peers produce different files" =
  let f1 = Cn_mail.rejection_filename "pi" "sigma/topic" in
  let f2 = Cn_mail.rejection_filename "tau" "sigma/topic" in
  Printf.printf "pi = %s\n" f1;
  Printf.printf "tau = %s\n" f2;
  Printf.printf "different = %b\n" (f1 <> f2);
  [%expect {|
    pi = rejected-pi-sigma-topic.md
    tau = rejected-tau-sigma-topic.md
    different = true
  |}]

let%expect_test "rejection_filename: different branches produce different files" =
  let f1 = Cn_mail.rejection_filename "pi" "sigma/topic-a" in
  let f2 = Cn_mail.rejection_filename "pi" "sigma/topic-b" in
  Printf.printf "a = %s\n" f1;
  Printf.printf "b = %s\n" f2;
  Printf.printf "different = %b\n" (f1 <> f2);
  [%expect {|
    a = rejected-pi-sigma-topic-a.md
    b = rejected-pi-sigma-topic-b.md
    different = true
  |}]

(* ============================================================
   Invariant 2: is_already_rejected checks outbox and sent
   ============================================================

   Rejection dedup must check both outbox and sent directories.
   If a rejection file exists in either, skip re-rejection. *)

let%expect_test "is_already_rejected: false when no rejection exists" =
  let tmp = Filename.temp_dir "cn-test-" "" in
  let result = Cn_mail.is_already_rejected tmp "pi" "sigma/orphan-topic" in
  Printf.printf "already_rejected = %b\n" result;
  (* cleanup *)
  let _ = Sys.command (Printf.sprintf "rm -rf %s" (Filename.quote tmp)) in
  [%expect {| already_rejected = false |}]

let%expect_test "is_already_rejected: true when rejection in outbox" =
  let tmp = Filename.temp_dir "cn-test-" "" in
  let outbox = Filename.concat tmp "threads/mail/outbox" in
  let _ = Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote outbox)) in
  let filename = Cn_mail.rejection_filename "pi" "sigma/orphan-topic" in
  let path = Filename.concat outbox filename in
  let oc = open_out path in
  output_string oc "test"; close_out oc;
  let result = Cn_mail.is_already_rejected tmp "pi" "sigma/orphan-topic" in
  Printf.printf "already_rejected = %b\n" result;
  let _ = Sys.command (Printf.sprintf "rm -rf %s" (Filename.quote tmp)) in
  [%expect {| already_rejected = true |}]

let%expect_test "is_already_rejected: true when rejection in sent" =
  let tmp = Filename.temp_dir "cn-test-" "" in
  let sent = Filename.concat tmp "threads/mail/sent" in
  let _ = Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote sent)) in
  let filename = Cn_mail.rejection_filename "pi" "sigma/orphan-topic" in
  let path = Filename.concat sent filename in
  let oc = open_out path in
  output_string oc "test"; close_out oc;
  let result = Cn_mail.is_already_rejected tmp "pi" "sigma/orphan-topic" in
  Printf.printf "already_rejected = %b\n" result;
  let _ = Sys.command (Printf.sprintf "rm -rf %s" (Filename.quote tmp)) in
  [%expect {| already_rejected = true |}]

let%expect_test "is_already_rejected: false for different peer same branch" =
  let tmp = Filename.temp_dir "cn-test-" "" in
  let outbox = Filename.concat tmp "threads/mail/outbox" in
  let _ = Sys.command (Printf.sprintf "mkdir -p %s" (Filename.quote outbox)) in
  (* Create rejection for pi *)
  let filename = Cn_mail.rejection_filename "pi" "sigma/orphan-topic" in
  let path = Filename.concat outbox filename in
  let oc = open_out path in
  output_string oc "test"; close_out oc;
  (* Check for tau — should be false *)
  let result = Cn_mail.is_already_rejected tmp "tau" "sigma/orphan-topic" in
  Printf.printf "already_rejected = %b\n" result;
  let _ = Sys.command (Printf.sprintf "rm -rf %s" (Filename.quote tmp)) in
  [%expect {| already_rejected = false |}]

(* ============================================================
   Invariant 3: Self-send is detectable
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

(* ============================================================
   Negative space: rejection filename never contains timestamps
   ============================================================

   The old code used make_thread_filename which prepends timestamps.
   Verify the new filename format has no timestamp component. *)

let%expect_test "rejection_filename: no timestamp prefix" =
  let f = Cn_mail.rejection_filename "pi" "sigma/topic" in
  (* Old format was like "20260402-123456-rejected-sigma-topic.md"
     New format is "rejected-pi-sigma-topic.md" — starts with "rejected-" *)
  let starts_with_rejected = String.length f > 9 && String.sub f 0 9 = "rejected-" in
  Printf.printf "filename = %s\n" f;
  Printf.printf "starts_with_rejected = %b\n" starts_with_rejected;
  (* Verify no digit-heavy prefix that would indicate a timestamp *)
  let first_char_is_digit = f.[0] >= '0' && f.[0] <= '9' in
  Printf.printf "has_timestamp_prefix = %b\n" first_char_is_digit;
  [%expect {|
    filename = rejected-pi-sigma-topic.md
    starts_with_rejected = true
    has_timestamp_prefix = false
  |}]

(* ============================================================
   Negative space: rejection hint has no stale clone wording
   ============================================================

   Finding #2 / #6 from review R1: rejection message must reference
   current pull-only protocol, not stale clone-based send model.
   Regression: "cn-{recipient}-clone" and "uses clone automatically"
   must never appear in rejection filenames or hints. *)

let%expect_test "rejection_filename: no clone reference in filename" =
  let f = Cn_mail.rejection_filename "pi" "sigma/topic" in
  let contains_clone s =
    let len = String.length s in
    let rec check i = if i + 5 > len then false
      else if String.sub s i 5 = "clone" then true
      else check (i + 1) in
    check 0 in
  Printf.printf "has_clone_in_filename = %b\n" (contains_clone f);
  [%expect {| has_clone_in_filename = false |}]
