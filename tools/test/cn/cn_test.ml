(** cn_test: ppx_expect tests for cn_lib pure functions *)

open Cn_lib

(* === Command Parsing === *)

let%expect_test "parse_command basic" =
  ["help"; "status"; "doctor"; "sync"; "next"; "process"]
  |> List.iter (fun s ->
    match parse_command [s] with
    | Some c -> print_endline (string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    help
    status
    doctor
    sync
    next
    in
  |}]

let%expect_test "parse_command inbox subcommands" =
  [["inbox"]; ["inbox"; "check"]; ["inbox"; "process"]; ["inbox"; "flush"]]
  |> List.iter (fun args ->
    match parse_command args with
    | Some c -> print_endline (string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    inbox check
    inbox check
    inbox process
    inbox flush
  |}]

let%expect_test "parse_command aliases" =
  ["i"; "o"; "s"; "d"]
  |> List.iter (fun s ->
    match parse_command [s] with
    | Some c -> print_endline (string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    inbox check
    outbox check
    status
    doctor
  |}]

let%expect_test "parse_command gtd verbs" =
  [["delete"; "foo"]; ["defer"; "foo"]; ["defer"; "foo"; "tomorrow"]; 
   ["delegate"; "foo"; "pi"]; ["do"; "foo"]; ["done"; "foo"]]
  |> List.iter (fun args ->
    match parse_command args with
    | Some c -> print_endline (string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    delete foo
    defer foo
    defer foo
    delegate foo pi
    do foo
    done foo
  |}]

let%expect_test "parse_command unknown" =
  match parse_command ["unknown_cmd"] with
  | Some _ -> print_endline "FOUND"
  | None -> print_endline "NONE";
  [%expect {| NONE |}]

(* === Flags Parsing === *)

let%expect_test "parse_flags" =
  let flags, args = parse_flags ["--json"; "status"; "-q"] in
  Printf.printf "json=%b quiet=%b verbose=%b dry_run=%b\n" 
    flags.json flags.quiet flags.verbose flags.dry_run;
  print_endline (String.concat " " args);
  [%expect {|
    json=true quiet=true verbose=false dry_run=false
    status
  |}]

(* === Hub Name Derivation === *)

let%expect_test "derive_name" =
  ["/home/user/cn-sigma"; "/home/user/cn-pi"; "/home/user/myagent"; "/cn-test"]
  |> List.iter (fun path ->
    print_endline (derive_name path));
  [%expect {|
    sigma
    pi
    myagent
    test
  |}]

(* === Frontmatter Parsing === *)

let%expect_test "parse_frontmatter" =
  let content = {|---
from: pi
branch: pi/thread
received: 2026-02-06
---

# Content here|} in
  let meta = parse_frontmatter content in
  meta |> List.iter (fun (k, v) -> Printf.printf "%s: %s\n" k v);
  [%expect {|
    from: pi
    branch: pi/thread
    received: 2026-02-06
  |}]

let%expect_test "parse_frontmatter empty" =
  let content = "# No frontmatter" in
  let meta = parse_frontmatter content in
  Printf.printf "count: %d\n" (List.length meta);
  [%expect {| count: 0 |}]

(* === Peers Parsing === *)

let%expect_test "parse_peers_md" =
  let content = {|# Peers

- name: pi
  hub: git@github.com:user/cn-pi.git
  clone: /home/user/cn-pi-clone

- name: omega
  hub: git@github.com:user/cn-omega.git
  kind: template|} in
  let peers = parse_peers_md content in
  peers |> List.iter (fun p ->
    Printf.printf "%s hub=%s clone=%s kind=%s\n" 
      p.name 
      (Option.value p.hub ~default:"none")
      (Option.value p.clone ~default:"none")
      (Option.value p.kind ~default:"none"));
  [%expect {|
    pi hub=git@github.com:user/cn-pi.git clone=/home/user/cn-pi-clone kind=none
    omega hub=git@github.com:user/cn-omega.git clone=none kind=template
  |}]

(* === Cadence Detection === *)

let%expect_test "cadence_of_path" =
  ["threads/inbox/foo.md"; "threads/daily/20260206.md"; 
   "threads/doing/bar.md"; "threads/archived/old.md"; "random/path.md"]
  |> List.iter (fun path ->
    print_endline (string_of_cadence (cadence_of_path path)));
  [%expect {|
    inbox
    daily
    doing
    unknown
    unknown
  |}]

(* === Frontmatter Update === *)

let%expect_test "update_frontmatter" =
  let content = {|---
from: pi
---

# Content|} in
  let updated = update_frontmatter content [("to", "sigma"); ("sent", "2026-02-06")] in
  print_endline updated;
  [%expect {|
    ---
    sent: 2026-02-06
    to: sigma
    from: pi
    ---
    
    # Content
  |}]

let%expect_test "update_frontmatter no existing" =
  let content = "# Just content" in
  let updated = update_frontmatter content [("created", "2026-02-06")] in
  print_endline updated;
  [%expect {|
    ---
    created: 2026-02-06
    ---
    # Just content
  |}]
