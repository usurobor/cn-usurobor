(** cn_protocol_test: ppx_expect tests for cn_protocol FSMs *)

open Cn_protocol

(* === Helpers === *)

let show_thread s e =
  match thread_transition s e with
  | Ok s' -> Printf.printf "%s + %s → %s\n"
      (string_of_thread_state s) (string_of_thread_event e) (string_of_thread_state s')
  | Error msg -> Printf.printf "ERROR: %s\n" msg

let show_actor s e =
  match actor_transition s e with
  | Ok s' -> Printf.printf "%s → %s\n"
      (string_of_actor_state s) (string_of_actor_state s')
  | Error msg -> Printf.printf "ERROR: %s\n" msg

let show_sender s e =
  match sender_transition s e with
  | Ok s' -> Printf.printf "%s → %s\n"
      (string_of_sender_state s) (string_of_sender_state s')
  | Error msg -> Printf.printf "ERROR: %s\n" msg

let show_receiver s e =
  match receiver_transition s e with
  | Ok s' -> Printf.printf "%s → %s\n"
      (string_of_receiver_state s) (string_of_receiver_state s')
  | Error msg -> Printf.printf "ERROR: %s\n" msg


(* ============================================================
   FSM 1: Thread Lifecycle
   ============================================================ *)

(* --- Happy path: inbox → queue → active → doing → archived --- *)

let%expect_test "thread: full lifecycle received → archived" =
  show_thread Received Enqueue;
  show_thread Queued Feed;
  show_thread Active Claim;
  show_thread Doing Complete;
  [%expect {|
    received + enqueue → queued
    queued + feed → active
    active + claim → doing
    doing + complete → archived
  |}]

(* --- Active can go to any GTD outcome --- *)

let%expect_test "thread: active fan-out" =
  [Claim; Complete; Defer; Delegate; Discard]
  |> List.iter (show_thread Active);
  [%expect {|
    active + claim → doing
    active + complete → archived
    active + defer → deferred
    active + delegate → delegated
    active + discard → deleted
  |}]

(* --- Received can be directly triaged (human shortcut) --- *)

let%expect_test "thread: received direct triage" =
  [Claim; Defer; Delegate; Discard; Complete]
  |> List.iter (show_thread Received);
  [%expect {|
    received + claim → doing
    received + defer → deferred
    received + delegate → delegated
    received + discard → deleted
    received + complete → archived
  |}]

(* --- Doing lifecycle --- *)

let%expect_test "thread: doing outcomes" =
  show_thread Doing Complete;
  show_thread Doing Defer;
  [%expect {|
    doing + complete → archived
    doing + defer → deferred
  |}]

(* --- Deferred lifecycle --- *)

let%expect_test "thread: deferred resurface and discard" =
  show_thread Deferred Resurface;
  show_thread Deferred Discard;
  [%expect {|
    deferred + resurface → queued
    deferred + discard → deleted
  |}]

(* --- Terminal idempotency --- *)

let%expect_test "thread: archived is idempotent" =
  [Enqueue; Feed; Claim; Complete; Defer; Delegate; Discard; Resurface]
  |> List.iter (fun e ->
    match thread_transition Archived e with
    | Ok Archived -> ()
    | Ok other -> Printf.printf "FAIL: archived + %s → %s\n"
        (string_of_thread_event e) (string_of_thread_state other)
    | Error msg -> Printf.printf "FAIL: %s\n" msg);
  print_endline "all archived transitions → archived";
  [%expect {| all archived transitions → archived |}]

let%expect_test "thread: deleted is idempotent" =
  [Enqueue; Feed; Claim; Complete; Defer; Delegate; Discard; Resurface]
  |> List.iter (fun e ->
    match thread_transition Deleted e with
    | Ok Deleted -> ()
    | Ok other -> Printf.printf "FAIL: deleted + %s → %s\n"
        (string_of_thread_event e) (string_of_thread_state other)
    | Error msg -> Printf.printf "FAIL: %s\n" msg);
  print_endline "all deleted transitions → deleted";
  [%expect {| all deleted transitions → deleted |}]

(* --- Invalid transitions (the bug P1 fixes) --- *)

let%expect_test "thread: doing + claim is invalid" =
  show_thread Doing Claim;
  [%expect {| ERROR: invalid transition: doing + claim |}]

let%expect_test "thread: queued + complete is invalid" =
  show_thread Queued Complete;
  [%expect {| ERROR: invalid transition: queued + complete |}]

let%expect_test "thread: delegated + claim is invalid" =
  show_thread Delegated Claim;
  [%expect {| ERROR: invalid transition: delegated + claim |}]

(* --- String round-trip --- *)

let%expect_test "thread: state string round-trip" =
  [Received; Queued; Active; Doing; Deferred; Delegated; Archived; Deleted]
  |> List.iter (fun s ->
    let str = string_of_thread_state s in
    match thread_state_of_string str with
    | Some s' when s = s' -> ()
    | Some s' -> Printf.printf "MISMATCH: %s → %s\n" str (string_of_thread_state s')
    | None -> Printf.printf "MISSING: %s\n" str);
  print_endline "all round-trips ok";
  [%expect {| all round-trips ok |}]

let%expect_test "thread: state_of_string unknown" =
  (match thread_state_of_string "bogus" with
   | None -> print_endline "None"
   | Some s -> Printf.printf "UNEXPECTED: %s\n" (string_of_thread_state s));
  [%expect {| None |}]

(* --- Path-based state derivation --- *)

let%expect_test "thread: state_of_path" =
  ["state/queue/foo.md"; "threads/doing/bar.md"; "threads/deferred/baz.md";
   "threads/mail/inbox/x.md"; "threads/mail/outbox/y.md";
   "threads/archived/z.md"; "threads/mail/sent/w.md";
   "some/random/path.md"]
  |> List.iter (fun p ->
    match thread_state_of_path p with
    | Some s -> Printf.printf "%s → %s\n" p (string_of_thread_state s)
    | None -> Printf.printf "%s → None\n" p);
  [%expect {|
    state/queue/foo.md → queued
    threads/doing/bar.md → doing
    threads/deferred/baz.md → deferred
    threads/mail/inbox/x.md → received
    threads/mail/outbox/y.md → delegated
    threads/archived/z.md → archived
    threads/mail/sent/w.md → delegated
    some/random/path.md → None
  |}]

(* --- Meta-based state derivation (frontmatter > directory) --- *)

let%expect_test "thread: state_of_meta prefers frontmatter" =
  let meta = [("from", "pi"); ("state", "doing")] in
  let s = thread_state_of_meta meta "threads/mail/inbox/foo.md" in
  Printf.printf "%s\n" (string_of_thread_state s);
  [%expect {| doing |}]

let%expect_test "thread: state_of_meta falls back to path" =
  let s = thread_state_of_meta [] "threads/doing/foo.md" in
  Printf.printf "%s\n" (string_of_thread_state s);
  [%expect {| doing |}]

let%expect_test "thread: state_of_meta defaults to received" =
  let s = thread_state_of_meta [] "some/unknown/path.md" in
  Printf.printf "%s\n" (string_of_thread_state s);
  [%expect {| received |}]

(* --- dir_of_thread_state --- *)

let%expect_test "thread: dir_of_thread_state" =
  [Received; Queued; Active; Doing; Deferred; Delegated; Archived; Deleted]
  |> List.iter (fun s ->
    Printf.printf "%s → %s\n" (string_of_thread_state s) (dir_of_thread_state s));
  [%expect {|
    received → threads/mail/inbox
    queued → state/queue
    active → state
    doing → threads/doing
    deferred → threads/deferred
    delegated → threads/mail/outbox
    archived → threads/archived
    deleted →
  |}]


(* ============================================================
   FSM 2: Actor Loop
   ============================================================ *)

(* --- Happy path: idle → input_ready → processing → output_ready → idle --- *)

let%expect_test "actor: full cycle" =
  show_actor Idle Queue_pop;
  show_actor InputReady Wake;
  show_actor Processing Output_received;
  show_actor OutputReady Archive_complete;
  [%expect {|
    idle → input_ready
    input_ready → processing
    processing → output_ready
    output_ready → idle
  |}]

(* --- Idle stays idle on empty queue --- *)

let%expect_test "actor: idle + queue_empty stays idle" =
  show_actor Idle Queue_empty;
  [%expect {| idle → idle |}]

(* --- Archive failure is retryable --- *)

let%expect_test "actor: output_ready + archive_fail stays output_ready" =
  show_actor OutputReady Archive_fail;
  [%expect {| output_ready → output_ready |}]

(* --- Invalid transitions --- *)

let%expect_test "actor: processing + queue_pop is invalid" =
  show_actor Processing Queue_pop;
  [%expect {| ERROR: invalid actor transition: processing + queue_pop |}]

let%expect_test "actor: idle + wake is invalid" =
  show_actor Idle Wake;
  [%expect {| ERROR: invalid actor transition: idle + wake |}]

(* --- State derivation from filesystem --- *)

let%expect_test "actor: derive_state" =
  [(false, false); (true, false); (true, true); (false, true)]
  |> List.iter (fun (inp, outp) ->
    let s = actor_derive_state ~input_exists:inp ~output_exists:outp in
    Printf.printf "input=%b output=%b → %s\n" inp outp (string_of_actor_state s));
  [%expect {|
    input=false output=false → idle
    input=true output=false → processing
    input=true output=true → output_ready
    input=false output=true → idle
  |}]


(* ============================================================
   FSM 3: Transport Sender
   ============================================================ *)

(* --- Happy path: pending → branch → pushing → pushed → delivered --- *)

let%expect_test "sender: happy path" =
  show_sender S_Pending SE_CreateBranch;
  show_sender S_BranchCreated SE_Push;
  show_sender S_Pushing SE_PushOk;
  show_sender S_Pushed SE_Cleanup;
  [%expect {|
    pending → branch_created
    branch_created → pushing
    pushing → pushed
    pushed → delivered
  |}]

(* --- Push failure + retry --- *)

let%expect_test "sender: push failure and retry" =
  show_sender S_Pushing SE_PushFail;
  show_sender S_Failed SE_Retry;
  [%expect {|
    pushing → failed
    failed → pending
  |}]

(* --- Failed can also be cleaned up (give up) --- *)

let%expect_test "sender: failed cleanup" =
  show_sender S_Failed SE_Cleanup;
  [%expect {| failed → delivered |}]

(* --- Delivered is idempotent --- *)

let%expect_test "sender: delivered is idempotent" =
  [SE_CreateBranch; SE_Push; SE_PushOk; SE_PushFail; SE_Retry; SE_Cleanup]
  |> List.iter (fun e ->
    match sender_transition S_Delivered e with
    | Ok S_Delivered -> ()
    | Ok other -> Printf.printf "FAIL: → %s\n" (string_of_sender_state other)
    | Error msg -> Printf.printf "FAIL: %s\n" msg);
  print_endline "all delivered transitions → delivered";
  [%expect {| all delivered transitions → delivered |}]

(* --- Invalid transitions --- *)

let%expect_test "sender: pending + push is invalid" =
  show_sender S_Pending SE_Push;
  [%expect {| ERROR: invalid sender transition from pending |}]

let%expect_test "sender: pushed + push is invalid" =
  show_sender S_Pushed SE_Push;
  [%expect {| ERROR: invalid sender transition from pushed |}]


(* ============================================================
   FSM 4: Transport Receiver
   ============================================================ *)

(* --- Happy path: fetched → materializing → materialized → cleaned --- *)

let%expect_test "receiver: happy path (new branch)" =
  show_receiver R_Fetched RE_IsNew;
  show_receiver R_Materializing RE_WriteOk;
  show_receiver R_Materialized RE_DeleteBranch;
  [%expect {|
    fetched → materializing
    materializing → materialized
    materialized → cleaned
  |}]

(* --- Duplicate path --- *)

let%expect_test "receiver: duplicate skip" =
  show_receiver R_Fetched RE_IsDuplicate;
  show_receiver R_Skipped RE_DeleteBranch;
  [%expect {|
    fetched → skipped
    skipped → cleaned
  |}]

(* --- Orphan path --- *)

let%expect_test "receiver: orphan reject" =
  show_receiver R_Fetched RE_IsOrphan;
  show_receiver R_Rejected RE_DeleteBranch;
  [%expect {|
    fetched → rejected
    rejected → cleaned
  |}]

(* --- Write failure retries --- *)

let%expect_test "receiver: write failure returns to fetched" =
  show_receiver R_Materializing RE_WriteFail;
  [%expect {| materializing → fetched |}]

(* --- Cleaned is idempotent --- *)

let%expect_test "receiver: cleaned is idempotent" =
  [RE_IsNew; RE_IsDuplicate; RE_IsOrphan; RE_WriteOk; RE_WriteFail; RE_DeleteBranch]
  |> List.iter (fun e ->
    match receiver_transition R_Cleaned e with
    | Ok R_Cleaned -> ()
    | Ok other -> Printf.printf "FAIL: → %s\n" (string_of_receiver_state other)
    | Error msg -> Printf.printf "FAIL: %s\n" msg);
  print_endline "all cleaned transitions → cleaned";
  [%expect {| all cleaned transitions → cleaned |}]

(* --- Invalid transitions --- *)

let%expect_test "receiver: materialized + write_ok is invalid" =
  show_receiver R_Materialized RE_WriteOk;
  [%expect {| ERROR: invalid receiver transition from materialized |}]

let%expect_test "receiver: skipped + write_ok is invalid" =
  show_receiver R_Skipped RE_WriteOk;
  [%expect {| ERROR: invalid receiver transition from skipped |}]
