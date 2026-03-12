(** cn_output_test: ppx_expect tests for output plane separation

    Tests the pure parsing + rendering core of cn_output.ml.
    All tests are deterministic — no I/O. *)

let show_render sink parsed =
  match Cn_output.render_for_sink sink parsed with
  | Cn_output.Renderable s -> Printf.printf "Renderable: %s\n" s
  | Cn_output.Fallback (text, reason) ->
      Printf.printf "Fallback: %s (reason: %s)\n"
        text (Cn_output.string_of_render_reason reason)
  | Cn_output.Skipped -> Printf.printf "Skipped\n"
  | Cn_output.Invalid reason ->
      Printf.printf "Invalid: %s\n" (Cn_output.string_of_render_reason reason)

(* === Parsing === *)

let%expect_test "parse_output: body + legacy ops" =
  let raw = "---\nid: tg-001\nreply: tg-001|hello\n---\nThis is the body." in
  let p = Cn_output.parse_output raw in
  Printf.printf "id=%s body=%s ops=%d typed=%d receipts=%d\n"
    (match p.id with Some s -> s | None -> "none")
    (match p.body with Some s -> s | None -> "none")
    (List.length p.coordination_ops)
    (List.length p.typed_ops)
    (List.length p.ops_receipts);
  [%expect {| id=tg-001 body=This is the body. ops=1 typed=0 receipts=0 |}]

let%expect_test "parse_output: body + typed ops" =
  let raw = "---\nid: tg-002\nops: [{\"kind\":\"fs_read\",\"path\":\"x.ml\"}]\n---\nBody here." in
  let p = Cn_output.parse_output raw in
  Printf.printf "id=%s body=%s ops=%d typed=%d receipts=%d\n"
    (match p.id with Some s -> s | None -> "none")
    (match p.body with Some s -> s | None -> "none")
    (List.length p.coordination_ops)
    (List.length p.typed_ops)
    (List.length p.ops_receipts);
  [%expect {| id=tg-002 body=Body here. ops=0 typed=1 receipts=0 |}]

let%expect_test "parse_output: missing body" =
  let raw = "---\nid: tg-003\nack: tg-003\n---\n" in
  let p = Cn_output.parse_output raw in
  Printf.printf "id=%s body=%s ops=%d\n"
    (match p.id with Some s -> s | None -> "none")
    (match p.body with Some _ -> "present" | None -> "none")
    (List.length p.coordination_ops);
  [%expect {| id=tg-003 body=none ops=1 |}]

let%expect_test "parse_output: no frontmatter" =
  let raw = "Just some plain text response." in
  let p = Cn_output.parse_output raw in
  Printf.printf "id=%s body=%s ops=%d typed=%d\n"
    (match p.id with Some s -> s | None -> "none")
    (match p.body with Some s -> s | None -> "none")
    (List.length p.coordination_ops)
    (List.length p.typed_ops);
  [%expect {| id=none body=Just some plain text response. ops=0 typed=0 |}]

let%expect_test "parse_output: malformed ops produces receipts" =
  let raw = "---\nid: tg-004\nops: not-json\n---\nBody." in
  let p = Cn_output.parse_output raw in
  Printf.printf "typed=%d receipts=%d\n"
    (List.length p.typed_ops) (List.length p.ops_receipts);
  List.iter (fun r ->
    Printf.printf "  %s %s\n"
      (Cn_shell.string_of_receipt_status r.Cn_shell.status) r.Cn_shell.reason
  ) p.ops_receipts;
  [%expect {|
    typed=0 receipts=1
      denied parse_error: expected 'null' at pos 0
  |}]

let%expect_test "parse_output: ops_version extracted" =
  let raw = "---\nid: tg-005\nops_version: 3.3.0\nops: [{\"kind\":\"fs_read\",\"path\":\"x\"}]\n---\nBody." in
  let p = Cn_output.parse_output raw in
  Printf.printf "ops_version=%s\n"
    (match p.ops_version with Some s -> s | None -> "none");
  [%expect {| ops_version=3.3.0 |}]

(* === Control-plane leak detection === *)

let%expect_test "is_control_plane_like: ops: line blocked" =
  let r = Cn_output.is_control_plane_like "ops: [{\"kind\":\"fs_read\"}]" in
  Printf.printf "%s\n"
    (match r with Some reason -> Cn_output.string_of_render_reason reason | None -> "safe");
  [%expect {| control_plane_leak |}]

let%expect_test "is_control_plane_like: ops_version: blocked" =
  let r = Cn_output.is_control_plane_like "ops_version: 3.3.0" in
  Printf.printf "%s\n"
    (match r with Some reason -> Cn_output.string_of_render_reason reason | None -> "safe");
  [%expect {| control_plane_leak |}]

let%expect_test "is_control_plane_like: raw frontmatter blocked" =
  let r = Cn_output.is_control_plane_like "---\nid: foo\n---" in
  Printf.printf "%s\n"
    (match r with Some reason -> Cn_output.string_of_render_reason reason | None -> "safe");
  [%expect {| raw_frontmatter |}]

let%expect_test "is_control_plane_like: XML pseudo-tool blocked" =
  let r = Cn_output.is_control_plane_like "<observe>something</observe>" in
  Printf.printf "%s\n"
    (match r with Some reason -> Cn_output.string_of_render_reason reason | None -> "safe");
  [%expect {| xml_tool_syntax |}]

let%expect_test "is_control_plane_like: fs_read XML blocked" =
  let r = Cn_output.is_control_plane_like "<fs_read>path/to/file</fs_read>" in
  Printf.printf "%s\n"
    (match r with Some reason -> Cn_output.string_of_render_reason reason | None -> "safe");
  [%expect {| xml_tool_syntax |}]

let%expect_test "is_control_plane_like: normal prose safe" =
  let r = Cn_output.is_control_plane_like "I ran the ops and they completed." in
  Printf.printf "%s\n"
    (match r with Some _ -> "blocked" | None -> "safe");
  [%expect {| safe |}]

let%expect_test "is_control_plane_like: prose mentioning ops safe" =
  let r = Cn_output.is_control_plane_like "The operations were successful." in
  Printf.printf "%s\n"
    (match r with Some _ -> "blocked" | None -> "safe");
  [%expect {| safe |}]

(* === Rendering: HumanSurface / ConversationStore === *)

let%expect_test "render: valid body wins" =
  let p = Cn_output.parse_output "---\nid: t1\nreply: t1|fallback\n---\nHello human!" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: Hello human! |}]

let%expect_test "render: body is control-plane, reply fallback used" =
  let p = Cn_output.parse_output "---\nid: t2\nreply: t2|Here is my reply\n---\nops: [{\"kind\":\"fs_read\"}]" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: Here is my reply |}]

let%expect_test "render: body is XML, reply fallback used" =
  let p = Cn_output.parse_output "---\nid: t3\nreply: t3|Safe reply\n---\n<observe>x</observe>" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: Safe reply |}]

let%expect_test "render: no body, reply used" =
  let p = Cn_output.parse_output "---\nid: t4\nreply: t4|Reply text\n---\n" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: Reply text |}]

let%expect_test "render: no body, no reply, acknowledged fallback" =
  let p = Cn_output.parse_output "---\nid: t5\nack: t5\n---\n" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: (acknowledged) |}]

let%expect_test "render: all real candidates blocked, fallback emitted" =
  let p = Cn_output.parse_output "---\nid: t5b\nack: t5b\n---\nops: [{\"kind\":\"fs_read\"}]" in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Fallback: (acknowledged) (reason: control_plane_leak) |}]

let%expect_test "render: ConversationStore same as HumanSurface" =
  let p = Cn_output.parse_output "---\nid: t6\nreply: t6|fallback\n---\nBody for history." in
  show_render Cn_output.ConversationStore p;
  [%expect {| Renderable: Body for history. |}]

let%expect_test "render: ConversationStore blocks raw frontmatter body" =
  let p = Cn_output.parse_output "---\nid: t7\nreply: t7|clean reply\n---\n---\nid: nested\n---" in
  show_render Cn_output.ConversationStore p;
  [%expect {| Renderable: clean reply |}]

(* === Rendering: AuditFile === *)

let%expect_test "render: AuditFile returns raw output" =
  let raw = "---\nid: t8\nops: [{\"kind\":\"fs_read\"}]\n---\nBody." in
  let p = Cn_output.parse_output raw in
  show_render Cn_output.AuditFile p;
  [%expect {|
    Renderable: ---
    id: t8
    ops: [{"kind":"fs_read"}]
    ---
    Body. |}]

(* === Rendering: PeerOutbox === *)

let%expect_test "render: PeerOutbox returns Skipped" =
  let p = Cn_output.parse_output "---\nid: t9\nsend: peer|hello\n---\nBody." in
  show_render Cn_output.PeerOutbox p;
  [%expect {| Skipped |}]

(* === Body consumption rules preserved === *)

let%expect_test "parse_output: body consumption for reply" =
  let raw = "---\nid: t10\nreply: t10|notification\n---\nFull body replaces notification." in
  let p = Cn_output.parse_output raw in
  (* Body consumption: reply payload should be the body, not "notification" *)
  let reply_msg = p.Cn_output.coordination_ops |> List.find_map (fun (op : Cn_lib.agent_op) ->
    match op with Cn_lib.Reply (_, msg) -> Some msg | _ -> None) in
  Printf.printf "reply_payload=%s\n"
    (match reply_msg with Some s -> s | None -> "none");
  [%expect {| reply_payload=Full body replaces notification. |}]
