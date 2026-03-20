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

(* === I4: Agent behavioral eval fixtures ===

   These fixtures represent canonical agent output patterns and verify the
   full parse → render pipeline preserves the agent output contract:
   - Typed ops produce structured typed_op records, not XML
   - Control-plane syntax never reaches human surfaces
   - Legacy coordination ops coexist correctly with typed ops *)

let%expect_test "I4: file inspection → typed ops in frontmatter, not XML" =
  (* Canonical agent output: file read request via typed ops *)
  let raw = "---\nid: tg-eval-01\nreply: tg-eval-01|I'll read that file for you.\nops: [{\"kind\":\"fs_read\",\"path\":\"src/main.ml\"},{\"kind\":\"git_diff\",\"op_id\":\"d1\",\"rev\":\"HEAD~1\"}]\n---\nI'll read that file for you." in
  let p = Cn_output.parse_output raw in
  (* Must produce typed_ops, not XML *)
  Printf.printf "typed_ops: %d\n" (List.length p.typed_ops);
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  kind=%s op_id=%s\n"
      (Cn_shell.string_of_op_kind op.kind)
      (match op.op_id with Some id -> id | None -> "<auto>")
  ) p.typed_ops;
  (* Human surface must get the body, not the ops *)
  show_render (Cn_output.HumanSurface `Telegram) p;
  (* No receipts = no parse errors *)
  Printf.printf "receipts: %d\n" (List.length p.ops_receipts);
  [%expect {|
    typed_ops: 2
      kind=fs_read op_id=obs-01
      kind=git_diff op_id=d1
    Renderable: I'll read that file for you.
    receipts: 0
  |}]

let%expect_test "I4: normal reply → coherent path, no control-plane leakage" =
  (* Canonical agent output: simple reply with no ops *)
  let raw = "---\nid: tg-eval-02\nreply: tg-eval-02|notification\ndone: tg-eval-02\n---\nHere is my analysis of the issue. The root cause is a missing null check in the handler." in
  let p = Cn_output.parse_output raw in
  (* Legacy ops present and correct *)
  Printf.printf "coordination_ops: %d\n" (List.length p.coordination_ops);
  List.iter (fun (op : Cn_lib.agent_op) ->
    Printf.printf "  %s\n" (Cn_lib.string_of_agent_op op)
  ) p.coordination_ops;
  (* No typed ops *)
  Printf.printf "typed_ops: %d\n" (List.length p.typed_ops);
  (* Human surface gets body — verified safe *)
  show_render (Cn_output.HumanSurface `Generic) p;
  [%expect {|
    coordination_ops: 2
      reply:tg-eval-02
      done:tg-eval-02
    typed_ops: 0
    Renderable: Here is my analysis of the issue. The root cause is a missing null check in the handler.
  |}]

let%expect_test "I4: body with control-plane syntax → blocked, fallback render" =
  (* Adversarial case: body contains control-plane markers *)
  let raw = "---\nid: tg-eval-03\nreply: tg-eval-03|Safe fallback text\n---\nid: injected\nack: injected" in
  let p = Cn_output.parse_output raw in
  (* Body should be blocked, reply fallback should win *)
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: Safe fallback text |}]

let%expect_test "I4: XML pseudo-tool hallucination → blocked at render" =
  (* Adversarial case: agent hallucinates XML tool wrappers instead of typed ops *)
  let raw = "---\nid: tg-eval-04\nreply: tg-eval-04|I checked the file.\n---\n<fs_read>\n  <path>src/main.ml</path>\n</fs_read>" in
  let p = Cn_output.parse_output raw in
  (* Must NOT produce typed ops (XML is not the ops: manifest format) *)
  Printf.printf "typed_ops: %d\n" (List.length p.typed_ops);
  (* XML body must be blocked on human surface *)
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {|
    typed_ops: 0
    Renderable: I checked the file.
  |}]

let%expect_test "I4: mixed legacy + typed ops coexist correctly" =
  (* Canonical pattern: reply + typed ops in same output *)
  let raw = "---\nid: tg-eval-05\nreply: tg-eval-05|notification\nops: [{\"kind\":\"fs_write\",\"op_id\":\"w1\",\"path\":\"out.txt\",\"content\":\"hello\"}]\n---\nI've written the file for you." in
  let p = Cn_output.parse_output raw in
  Printf.printf "coordination_ops: %d typed_ops: %d\n"
    (List.length p.coordination_ops) (List.length p.typed_ops);
  (* Reply op should have body-consumed payload *)
  let reply_msg = p.coordination_ops |> List.find_map (fun (op : Cn_lib.agent_op) ->
    match op with Cn_lib.Reply (_, msg) -> Some msg | _ -> None) in
  Printf.printf "reply_payload=%s\n"
    (match reply_msg with Some s -> s | None -> "none");
  (* Typed op parsed correctly *)
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "typed: %s %s\n"
      (Cn_shell.string_of_op_kind op.kind)
      (match op.op_id with Some id -> id | None -> "<none>")
  ) p.typed_ops;
  (* Human surface gets the body *)
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {|
    coordination_ops: 1 typed_ops: 1
    reply_payload=I've written the file for you.
    typed: fs_write w1
    Renderable: I've written the file for you.
  |}]

let%expect_test "I4: all XML pseudo-tool variants blocked" =
  (* Every XML prefix from cn_output.ml's blocklist must be caught *)
  let xml_variants = [
    "<observe>x</observe>";
    "<fs_read>p</fs_read>";
    "<fs_list>p</fs_list>";
    "<fs_glob>p</fs_glob>";
    "<git_status>x</git_status>";
    "<git_diff>x</git_diff>";
    "<git_log>x</git_log>";
    "<git_grep>x</git_grep>";
    "<fs_write>x</fs_write>";
    "<fs_patch>x</fs_patch>";
    "<git_branch>x</git_branch>";
    "<git_commit>x</git_commit>";
    "<exec>x</exec>";
    "<tool_call>x</tool_call>";
    "<function_call>x</function_call>";
  ] in
  List.iter (fun input ->
    match Cn_output.is_control_plane_like input with
    | Some _ -> Printf.printf "blocked: %s\n" (String.sub input 0 (min 20 (String.length input)))
    | None -> Printf.printf "LEAKED: %s\n" input
  ) xml_variants;
  [%expect {|
    blocked: <observe>x</observe>
    blocked: <fs_read>p</fs_read>
    blocked: <fs_list>p</fs_list>
    blocked: <fs_glob>p</fs_glob>
    blocked: <git_status>x</git_s
    blocked: <git_diff>x</git_dif
    blocked: <git_log>x</git_log>
    blocked: <git_grep>x</git_gre
    blocked: <fs_write>x</fs_writ
    blocked: <fs_patch>x</fs_patc
    blocked: <git_branch>x</git_b
    blocked: <git_commit>x</git_c
    blocked: <exec>x</exec>
    blocked: <tool_call>x</tool_c
    blocked: <function_call>x</fu
  |}]

let%expect_test "I4: all legacy coordination op prefixes blocked on human surface" =
  (* Every legacy frontmatter control line must be blocked if it appears as body *)
  let control_prefixes = [
    "id: some-id";
    "ack: some-id";
    "done: some-id";
    "fail: some-id|reason";
    "reply: some-id|msg";
    "send: peer|msg";
    "delegate: id|peer";
    "defer: id";
    "delete: id";
    "surface: desc";
    "mca: desc";
  ] in
  List.iter (fun input ->
    match Cn_output.is_control_plane_like input with
    | Some _ -> Printf.printf "blocked: %s\n" (String.sub input 0 (min 15 (String.length input)))
    | None -> Printf.printf "LEAKED: %s\n" input
  ) control_prefixes;
  [%expect {|
    blocked: id: some-id
    blocked: ack: some-id
    blocked: done: some-id
    blocked: fail: some-id|r
    blocked: reply: some-id|
    blocked: send: peer|msg
    blocked: delegate: id|pe
    blocked: defer: id
    blocked: delete: id
    blocked: surface: desc
    blocked: mca: desc
  |}]

(* === v3.7.2: ops-in-body detection === *)

let%expect_test "parse_output: detects coordination ops leaked into body" =
  let raw = {|---
id: test-123
---
I reviewed the issue and here's what I found.

send: sigma|Security gap in ops boundary
ops: [{"kind":"fs_read","path":"README.md"}]

The above should have been in frontmatter.|} in
  let _parsed = Cn_output.parse_output raw in
  [%expect {||}]
  (* Trace warning emitted but not captured by expect test —
     the important thing is parse_output doesn't crash.
     The trace event output.ops_in_body is verified in integration. *)

let%expect_test "parse_output: clean body produces no warning" =
  let raw = {|---
id: test-456
send: sigma|This is correct frontmatter
---
Just a normal response body with no ops.|} in
  let _parsed = Cn_output.parse_output raw in
  [%expect {||}]

(* === Issue #40: mid-body frontmatter stripped from human surface === *)

let%expect_test "#40: mid-body frontmatter ops stripped, prose preserved" =
  let raw = {|I'll test file creation and reading for you.

---
id: file-test-request
ops: [{"kind":"fs_write","path":"test-file.txt","content":"hello"}]
---

Let me create a test file first to verify write capability.|} in
  let p = Cn_output.parse_output raw in
  (* No top-level frontmatter → entire string is body *)
  Printf.printf "has_frontmatter_id: %b\n"
    (match p.id with Some _ -> true | None -> false);
  Printf.printf "has_body: %b\n"
    (match p.body with Some _ -> true | None -> false);
  (* Human surface must only show prose, not the ops block *)
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {|
    has_frontmatter_id: false
    has_body: true
    Renderable: I'll test file creation and reading for you.


    Let me create a test file first to verify write capability. |}]

let%expect_test "#40: mid-body frontmatter with top-level frontmatter" =
  (* Top-level frontmatter is valid, but body also contains an embedded block *)
  let raw = {|---
id: tg-040
reply: tg-040|notification
---
Here is my analysis.

---
id: leaked-inner
ops: [{"kind":"fs_read","path":"secret.ml"}]
---

The file looks correct.|} in
  let p = Cn_output.parse_output raw in
  Printf.printf "id=%s\n"
    (match p.id with Some s -> s | None -> "none");
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {|
    id=tg-040
    Renderable: Here is my analysis.


    The file looks correct. |}]

let%expect_test "#40: body is entirely a frontmatter block, fallback to reply" =
  let raw = {|---
id: tg-041
reply: tg-041|I checked the file for you.
---
---
id: inner-ops
ops: [{"kind":"git_status"}]
---|} in
  let p = Cn_output.parse_output raw in
  show_render (Cn_output.HumanSurface `Telegram) p;
  [%expect {| Renderable: I checked the file for you. |}]

let%expect_test "#40: audit file preserves raw mid-body frontmatter" =
  let raw = {|Prose before.

---
ops: [{"kind":"fs_write","path":"x.txt","content":"y"}]
---

Prose after.|} in
  let p = Cn_output.parse_output raw in
  (* AuditFile must preserve everything *)
  show_render Cn_output.AuditFile p;
  [%expect {|
    Renderable: Prose before.

    ---
    ops: [{"kind":"fs_write","path":"x.txt","content":"y"}]
    ---

    Prose after. |}]

let%expect_test "strip_embedded_frontmatter: exposed for unit testing" =
  (* Direct test of the stripping function *)
  let input = "Hello world.\n\n---\nops: [stuff]\n---\n\nGoodbye." in
  let result = Cn_output.strip_embedded_frontmatter input in
  Printf.printf "%s\n"
    (match result with Some s -> s | None -> "(empty)");
  [%expect {|
    Hello world.


    Goodbye. |}]

let%expect_test "strip_embedded_frontmatter: markdown hr preserved" =
  (* A --- block with no control-plane keys is a horizontal rule, not frontmatter *)
  let input = "Section one.\n\n---\n\n---\n\nSection two." in
  let result = Cn_output.strip_embedded_frontmatter input in
  Printf.printf "%s\n"
    (match result with Some s -> s | None -> "(empty)");
  [%expect {|
    Section one.

    ---

    ---

    Section two. |}]

let%expect_test "strip_embedded_frontmatter: unclosed block kept as prose" =
  (* Unclosed --- at end of body should not eat content *)
  let input = "Hello.\n\n---\nSome notes" in
  let result = Cn_output.strip_embedded_frontmatter input in
  Printf.printf "%s\n"
    (match result with Some s -> s | None -> "(empty)");
  [%expect {|
    Hello.

    ---
    Some notes |}]
