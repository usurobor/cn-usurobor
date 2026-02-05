(* inbox_test: Tests for inbox_lib *)

open Inbox_lib

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
