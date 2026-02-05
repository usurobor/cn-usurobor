(* inbox_test: Tests for inbox_lib *)

open Inbox_lib

(* === GTD Triage === *)

let%expect_test "triage_of_string with payloads" =
  ["delete:stale branch"; 
   "d:duplicate"; 
   "defer:blocked on design";
   "f:waiting for review";
   "delegate:pi";
   "g:omega";
   "do:merge";
   "o:merge";
   "do:reply:response-thread";
   "do:custom:update docs first"]
  |> List.iter (fun s ->
    match triage_of_string s with
    | Some t -> print_endline (string_of_triage t)
    | None -> print_endline "NONE");
  [%expect {|
    delete:stale branch
    delete:duplicate
    defer:blocked on design
    defer:waiting for review
    delegate:pi
    delegate:omega
    do:merge
    do:merge
    do:reply:response-thread
    do:custom:update docs first
  |}]

let%expect_test "triage_of_string invalid" =
  ["delete"; "defer"; "delegate"; "do"; ""; "invalid"]
  |> List.iter (fun s ->
    match triage_of_string s with
    | Some t -> print_endline (string_of_triage t)
    | None -> print_endline "NONE");
  [%expect {|
    NONE
    NONE
    NONE
    NONE
    NONE
    NONE
  |}]

let%expect_test "triage roundtrip" =
  let examples = [
    Delete "stale";
    Defer "blocked on X";
    Delegate "pi";
    Do Merge;
    Do (Reply "my-response");
    Do (Custom "manual fix needed")
  ] in
  examples |> List.iter (fun t ->
    let s = string_of_triage t in
    match triage_of_string s with
    | Some t' when t = t' -> print_endline "OK"
    | Some t' -> print_endline (Printf.sprintf "MISMATCH: %s" (string_of_triage t'))
    | None -> print_endline "FAIL");
  [%expect {|
    OK
    OK
    OK
    OK
    OK
    OK
  |}]

let%expect_test "triage descriptions" =
  let examples = [
    Delete "stale";
    Defer "blocked on X";
    Delegate "pi";
    Do Merge;
    Do (Reply "response");
    Do (Custom "update docs")
  ] in
  examples |> List.iter (fun t -> print_endline (triage_description t));
  [%expect {|
    Remove branch (stale)
    Defer (blocked on X)
    Delegate to pi
    Merge branch
    Reply with branch response
    Action: update docs
  |}]

let%expect_test "triage_kind" =
  let examples = [
    Delete "x";
    Defer "y";
    Delegate "z";
    Do Merge
  ] in
  examples |> List.iter (fun t -> print_endline (triage_kind t));
  [%expect {|
    delete
    defer
    delegate
    do
  |}]

(* === Triage Log === *)

let%expect_test "format_log_entry" =
  let entry = {
    timestamp = "2026-02-05T17:20:00Z";
    branch = "review-request";
    peer = "pi";
    decision = Do Merge;
    actor = "sigma"
  } in
  print_endline (format_log_entry entry);
  [%expect {| - 2026-02-05T17:20:00Z | sigma | pi/review-request | do:merge |}]

let%expect_test "format_log_entry_human" =
  let entries = [
    { timestamp = "2026-02-05T17:20:00Z"; branch = "review"; peer = "pi"; 
      decision = Delete "stale"; actor = "sigma" };
    { timestamp = "2026-02-05T17:21:00Z"; branch = "urgent"; peer = "omega"; 
      decision = Defer "blocked on X"; actor = "sigma" };
    { timestamp = "2026-02-05T17:22:00Z"; branch = "task"; peer = "pi"; 
      decision = Delegate "tau"; actor = "sigma" };
    { timestamp = "2026-02-05T17:23:00Z"; branch = "feature"; peer = "pi"; 
      decision = Do Merge; actor = "sigma" };
  ] in
  entries |> List.iter (fun e -> print_endline (format_log_entry_human e));
  [%expect {|
    [2026-02-05T17:20:00Z] sigma triaged pi/review → Remove branch (stale)
    [2026-02-05T17:21:00Z] sigma triaged omega/urgent → Defer (blocked on X)
    [2026-02-05T17:22:00Z] sigma triaged pi/task → Delegate to tau
    [2026-02-05T17:23:00Z] sigma triaged pi/feature → Merge branch
  |}]

let%expect_test "format_log_row" =
  let entry = {
    timestamp = "2026-02-05T17:20:00Z";
    branch = "review-request";
    peer = "pi";
    decision = Delete "duplicate";
    actor = "sigma"
  } in
  print_endline (format_log_row entry);
  [%expect {| | 2026-02-05T17:20:00Z | sigma | pi/review-request | `delete:duplicate` | |}]

(* === Action parsing === *)

let%expect_test "action_of_string valid" =
  ["check"; "process"; "flush"]
  |> List.iter (fun s ->
    match action_of_string s with
    | Some a -> print_endline (string_of_action a)
    | None -> print_endline "NONE");
  [%expect {|
    check
    process
    flush
  |}]

let%expect_test "action_of_string invalid" =
  ["chekc"; "PROCESS"; "sync"; ""]
  |> List.iter (fun s ->
    match action_of_string s with
    | Some a -> print_endline (string_of_action a)
    | None -> print_endline "NONE");
  [%expect {|
    NONE
    NONE
    NONE
    NONE
  |}]

let%expect_test "action roundtrip" =
  all_actions
  |> List.iter (fun a ->
    let s = string_of_action a in
    match action_of_string s with
    | Some a' when a = a' -> print_endline "OK"
    | _ -> print_endline "FAIL");
  [%expect {|
    OK
    OK
    OK
  |}]

(* === String helpers === *)

let%expect_test "prefix matching" =
  [("hello", "hel", true);
   ("hello", "hello", true);
   ("hello", "hellox", false);
   ("", "x", false)]
  |> List.iter (fun (s, pre, expected) ->
    let result = prefix ~pre s in
    print_endline (if result = expected then "OK" else "FAIL"));
  [%expect {|
    OK
    OK
    OK
    OK
  |}]

let%expect_test "strip_prefix" =
  [("- name: sigma", "- name: ", Some "sigma");
   ("other line", "- name: ", None);
   ("- name: ", "- name: ", Some "")]
  |> List.iter (fun (s, pre, expected) ->
    let result = strip_prefix ~pre s in
    match result, expected with
    | Some r, Some e when r = e -> print_endline "OK"
    | None, None -> print_endline "OK"
    | _ -> print_endline "FAIL");
  [%expect {|
    OK
    OK
    OK
  |}]

(* === Peer parsing === *)

let%expect_test "parse_peers" =
  let content = {|# Peers
- name: pi
- name: cn-agent
other line
- name: omega|} in
  parse_peers content |> List.iter print_endline;
  [%expect {|
    pi
    cn-agent
    omega
  |}]

let%expect_test "derive_name" =
  [("/path/to/cn-sigma", "sigma");
   ("./cn-pi", "pi");
   ("cn-agent", "agent");
   ("my-hub", "my-hub")]
  |> List.iter (fun (path, expected) ->
    let result = derive_name path in
    print_endline (if result = expected then "OK" else Printf.sprintf "FAIL: got %s" result));
  [%expect {|
    OK
    OK
    OK
    OK
  |}]

(* === Results === *)

let%expect_test "report_result" =
  [Fetched ("pi", []);
   Fetched ("omega", ["omega/feature-1"; "omega/bugfix"]);
   Skipped ("missing", "not found")]
  |> List.iter (fun r -> print_endline (report_result r));
  [%expect {|
    ✓ pi (no inbound)
    ⚡ omega (2 inbound)
    · missing (not found)
  |}]

let%expect_test "collect_alerts empty" =
  let results = [Fetched ("pi", []); Skipped ("x", "reason")] in
  let alerts = collect_alerts results in
  print_endline (Printf.sprintf "alerts: %d" (List.length alerts));
  [%expect {| alerts: 0 |}]

let%expect_test "collect_alerts with branches" =
  let results = [
    Fetched ("pi", ["sigma/feature"]);
    Fetched ("omega", []);
    Fetched ("tau", ["sigma/fix-1"; "sigma/fix-2"])
  ] in
  let alerts = collect_alerts results in
  alerts |> List.iter (fun (peer, branches) ->
    print_endline (Printf.sprintf "%s: %d" peer (List.length branches)));
  [%expect {|
    pi: 1
    tau: 2
  |}]

let%expect_test "format_alerts none" =
  format_alerts [] |> List.iter print_endline;
  [%expect {| No inbound branches. All clear. |}]

let%expect_test "format_alerts some" =
  let alerts = [("pi", ["sigma/feature"; "sigma/fix"]); ("tau", ["sigma/doc"])] in
  format_alerts alerts |> List.iter print_endline;
  [%expect {|
    === INBOUND BRANCHES ===
    From pi:
      sigma/feature
      sigma/fix
    From tau:
      sigma/doc
  |}]
