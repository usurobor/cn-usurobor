(* Tests for peer_sync_lib using ppx_expect *)

open Peer_sync_lib

let%expect_test "parse_peers extracts names from YAML" =
  let content = {|
# Peers
```yaml
- name: pi
  hub: https://github.com/usurobor/cn-pi
  
- name: cn-agent
  hub: https://github.com/usurobor/cn-agent
```
|} in
  parse_peers content |> List.iter print_endline;
  [%expect {|
    pi
    cn-agent
  |}]

let%expect_test "parse_peers handles empty content" =
  parse_peers "" |> List.iter print_endline;
  [%expect {||}]

let%expect_test "derive_name strips cn- prefix" =
  print_endline (derive_name "/workspace/cn-sigma");
  print_endline (derive_name "/workspace/cn-pi");
  print_endline (derive_name "/workspace/agent");
  [%expect {|
    sigma
    pi
    agent
  |}]

let%expect_test "prefix detects string prefix" =
  Printf.printf "%b\n" (prefix ~pre:"- name: " "- name: foo");
  Printf.printf "%b\n" (prefix ~pre:"- name: " "other");
  Printf.printf "%b\n" (prefix ~pre:"abc" "ab");
  [%expect {|
    true
    false
    false
  |}]

let%expect_test "strip_prefix removes prefix" =
  let show = function Some s -> s | None -> "<none>" in
  print_endline (show (strip_prefix ~pre:"- name: " "- name: sigma"));
  print_endline (show (strip_prefix ~pre:"- name: " "other"));
  [%expect {|
    sigma
    <none>
  |}]

let%expect_test "non_empty filters whitespace" =
  [""; "  "; "x"; " y "]
  |> List.filter non_empty
  |> List.iter print_endline;
  [%expect {|
    x
     y
  |}]

let%expect_test "make_peer builds correct paths" =
  let join a b = a ^ "/" ^ b in
  let p1 = make_peer ~join "/workspace" "pi" in
  let p2 = make_peer ~join "/workspace" "cn-agent" in
  print_endline p1.repo_path;
  print_endline p2.repo_path;
  [%expect {|
    /workspace/cn-pi-clone
    /workspace/cn-agent
  |}]

let%expect_test "filter_branches cleans output" =
  filter_branches "  branch1\n\n  branch2  \n" |> List.iter print_endline;
  [%expect {|
    branch1
    branch2
  |}]

let%expect_test "report_result formats correctly" =
  print_endline (report_result (Fetched ("pi", [])));
  print_endline (report_result (Fetched ("pi", ["b1"; "b2"])));
  print_endline (report_result (Skipped ("pi", "not found")));
  [%expect {|
    ✓ pi (no inbound)
    ⚡ pi (2 inbound)
    · pi (not found)
  |}]

let%expect_test "collect_alerts filters only non-empty fetched" =
  let results = [
    Fetched ("a", []);
    Fetched ("b", ["x"; "y"]);
    Skipped ("c", "reason");
    Fetched ("d", ["z"]);
  ] in
  collect_alerts results |> List.iter (fun (name, branches) ->
    Printf.printf "%s: %s\n" name (String.concat ", " branches));
  [%expect {|
    b: x, y
    d: z
  |}]

let%expect_test "format_alerts handles empty" =
  format_alerts [] |> List.iter print_endline;
  [%expect {| No inbound branches. All clear. |}]

let%expect_test "format_alerts formats branches" =
  format_alerts [("pi", ["b1"; "b2"]); ("sigma", ["b3"])] |> List.iter print_endline;
  [%expect {|
    === INBOUND BRANCHES ===
    From pi:
      b1
      b2
    From sigma:
      b3
  |}]
