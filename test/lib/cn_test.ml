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

(* === Extract Body === *)

let%expect_test "extract_body with frontmatter and body" =
  let content = {|---
reply: thread-1|hello
---

Here is my detailed response.

It spans multiple lines.|} in
  (match extract_body content with
   | Some b -> print_endline b
   | None -> print_endline "NONE");
  [%expect {|
    Here is my detailed response.

    It spans multiple lines.
  |}]

let%expect_test "extract_body with frontmatter, no body" =
  let content = {|---
ack: thread-1
---|} in
  (match extract_body content with
   | Some b -> print_endline b
   | None -> print_endline "NONE");
  [%expect {| NONE |}]

let%expect_test "extract_body with frontmatter, blank lines only" =
  let content = "---\nack: thread-1\n---\n\n   \n" in
  (match extract_body content with
   | Some b -> print_endline b
   | None -> print_endline "NONE");
  [%expect {| NONE |}]

let%expect_test "extract_body no frontmatter" =
  let content = "Just plain text content" in
  (match extract_body content with
   | Some b -> print_endline b
   | None -> print_endline "NONE");
  [%expect {| Just plain text content |}]

let%expect_test "extract_body empty string" =
  (match extract_body "" with
   | Some b -> print_endline b
   | None -> print_endline "NONE");
  [%expect {| NONE |}]

(* === Resolve Payload === *)

let%expect_test "resolve_payload reply with body" =
  let op = Reply ("t1", "short notification") in
  let resolved = resolve_payload (Some "Full detailed reply body") op in
  print_endline (string_of_agent_op resolved);
  (match resolved with Reply (_, msg) -> print_endline msg | _ -> ());
  [%expect {|
    reply:t1
    Full detailed reply body
  |}]

let%expect_test "resolve_payload reply without body" =
  let op = Reply ("t1", "frontmatter message") in
  let resolved = resolve_payload None op in
  (match resolved with Reply (_, msg) -> print_endline msg | _ -> ());
  [%expect {| frontmatter message |}]

let%expect_test "resolve_payload send with body" =
  let op = Send ("pi", "notification", None) in
  let resolved = resolve_payload (Some "Full letter body") op in
  print_endline (string_of_agent_op resolved);
  (match resolved with Send (_, _, Some b) -> print_endline b | _ -> print_endline "NO BODY");
  [%expect {|
    send:pi
    Full letter body
  |}]

let%expect_test "resolve_payload send without body" =
  let op = Send ("pi", "notification", Some "existing body") in
  let resolved = resolve_payload None op in
  (match resolved with Send (_, _, Some b) -> print_endline b | _ -> print_endline "NO BODY");
  [%expect {| existing body |}]

let%expect_test "resolve_payload send explicit body wins over markdown body" =
  let op = Send ("pi", "notification", Some "explicit body") in
  let resolved = resolve_payload (Some "markdown body") op in
  (match resolved with Send (_, _, Some b) -> print_endline b | _ -> print_endline "NO BODY");
  [%expect {| explicit body |}]

let%expect_test "resolve_payload non-reply/send ops unchanged" =
  let ops = [Ack "t1"; Done "t1"; Surface "mca-desc"; Defer ("t1", None)] in
  ops |> List.iter (fun op ->
    let resolved = resolve_payload (Some "body text") op in
    print_endline (string_of_agent_op resolved));
  [%expect {|
    ack:t1
    done:t1
    surface:mca-desc
    defer:t1
  |}]
