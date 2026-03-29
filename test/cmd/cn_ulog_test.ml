(** cn_ulog_test.ml — Tests for unified operator log *)

(* === Serialization === *)

let%expect_test "entry serialization shape" =
  let entry = Cn_ulog.make_entry
    ~kind:Message_received ~severity:Info
    ~msg_id:"tg-123" ~source:"telegram"
    ~user_msg:"Hello agent" () in
  let json = Cn_ulog.entry_to_json entry in
  let s = Cn_json.to_string json in
  (match Cn_json.parse s with
   | Ok obj ->
     assert (Cn_json.get_string "schema" obj = Some "cn.ulog.v1");
     assert (Cn_json.get_string "kind" obj = Some "message.received");
     assert (Cn_json.get_string "severity" obj = Some "info");
     assert (Cn_json.get_string "msg_id" obj = Some "tg-123");
     assert (Cn_json.get_string "source" obj = Some "telegram");
     assert (Cn_json.get_string "user_msg" obj = Some "Hello agent");
     assert (Cn_json.get_string "ts" obj <> None);
     print_endline "ok: required fields present"
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: required fields present |}]

let%expect_test "invocation_end has numeric fields" =
  let entry = Cn_ulog.make_entry
    ~kind:Invocation_end ~severity:Info
    ~msg_id:"tg-456" ~passes:3 ~ops:5
    ~tokens_in:28000 ~tokens_out:304
    ~duration_ms:7500 () in
  let json = Cn_ulog.entry_to_json entry in
  (match Cn_json.parse (Cn_json.to_string json) with
   | Ok obj ->
     assert (Cn_json.get_string "kind" obj = Some "invocation.end");
     assert (Cn_json.get_int "passes" obj = Some 3);
     assert (Cn_json.get_int "ops" obj = Some 5);
     assert (Cn_json.get_int "tokens_in" obj = Some 28000);
     assert (Cn_json.get_int "tokens_out" obj = Some 304);
     assert (Cn_json.get_int "duration_ms" obj = Some 7500);
     print_endline "ok: numeric fields present"
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: numeric fields present |}]

let%expect_test "error entry has error field" =
  let entry = Cn_ulog.make_entry
    ~kind:Error ~severity:Error_
    ~msg_id:"tg-789"
    ~error:"LLM call failed: timeout" () in
  let json = Cn_ulog.entry_to_json entry in
  (match Cn_json.parse (Cn_json.to_string json) with
   | Ok obj ->
     assert (Cn_json.get_string "kind" obj = Some "error");
     assert (Cn_json.get_string "severity" obj = Some "error");
     assert (Cn_json.get_string "error" obj = Some "LLM call failed: timeout");
     print_endline "ok: error field present"
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: error field present |}]

let%expect_test "single-line output (JSONL invariant)" =
  let entry = Cn_ulog.make_entry
    ~kind:Message_received ~severity:Info
    ~msg_id:"tg-100" ~user_msg:"line1\nline2\ttab" () in
  let json = Cn_ulog.entry_to_json entry in
  let s = Cn_json.to_string json in
  let has_newline = String.contains s '\n' in
  Printf.printf "has newline: %b\n" has_newline;
  [%expect {| has newline: false |}]

let%expect_test "user_msg truncated at 200 chars" =
  let long_msg = String.make 300 'x' in
  let entry = Cn_ulog.make_entry
    ~kind:Message_received ~severity:Info
    ~msg_id:"tg-101" ~user_msg:long_msg () in
  let json = Cn_ulog.entry_to_json entry in
  (match Cn_json.parse (Cn_json.to_string json) with
   | Ok obj ->
     (match Cn_json.get_string "user_msg" obj with
      | Some s ->
        Printf.printf "length: %d\n" (String.length s);
        Printf.printf "ends_with_ellipsis: %b\n"
          (String.length s >= 3 &&
           String.sub s (String.length s - 3) 3 = "...")
      | None -> print_endline "missing user_msg")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {|
    length: 203
    ends_with_ellipsis: true |}]

let%expect_test "optional fields omitted when None" =
  let entry = Cn_ulog.make_entry
    ~kind:Invocation_start ~severity:Info () in
  let json = Cn_ulog.entry_to_json entry in
  let s = Cn_json.to_string json in
  (* Should NOT contain msg_id, source, etc. *)
  let has key =
    match Cn_json.parse s with
    | Ok obj -> Cn_json.get key obj <> None
    | Error _ -> false in
  Printf.printf "has msg_id: %b\n" (has "msg_id");
  Printf.printf "has source: %b\n" (has "source");
  Printf.printf "has schema: %b\n" (has "schema");
  [%expect {|
    has msg_id: false
    has source: false
    has schema: true |}]

(* === Kind serialization roundtrip === *)

let%expect_test "kind roundtrip" =
  let kinds = [
    Cn_ulog.Message_received; Invocation_start;
    Invocation_end; Message_sent; Error
  ] in
  List.iter (fun k ->
    let s = Cn_ulog.string_of_kind k in
    let k' = Cn_ulog.kind_of_string s in
    Printf.printf "%s: roundtrip=%b\n" s (k' = Some k)
  ) kinds;
  [%expect {|
    message.received: roundtrip=true
    invocation.start: roundtrip=true
    invocation.end: roundtrip=true
    message.sent: roundtrip=true
    error: roundtrip=true |}]

let%expect_test "severity roundtrip" =
  let sevs = [Cn_ulog.Info; Warn; Error_] in
  List.iter (fun s ->
    let str = Cn_ulog.string_of_severity s in
    let s' = Cn_ulog.severity_of_string str in
    Printf.printf "%s: roundtrip=%b\n" str (s' = Some s)
  ) sevs;
  [%expect {|
    info: roundtrip=true
    warn: roundtrip=true
    error: roundtrip=true |}]

(* === Write + read roundtrip === *)

let tmp_counter = ref 0

let make_tmp_hub () =
  incr tmp_counter;
  let base = Filename.concat (Filename.get_temp_dir_name ())
    (Printf.sprintf "cn-ulog-test-%d-%d" (Unix.getpid ()) !tmp_counter) in
  Cn_ffi.Fs.ensure_dir (Filename.concat base "logs/unified");
  base

let%expect_test "write + read roundtrip" =
  let hub = make_tmp_hub () in
  Cn_ulog.write hub (Cn_ulog.make_entry
    ~kind:Message_received ~severity:Info
    ~msg_id:"tg-200" ~source:"telegram"
    ~user_msg:"hello" ());
  Cn_ulog.write hub (Cn_ulog.make_entry
    ~kind:Invocation_end ~severity:Info
    ~msg_id:"tg-200" ~passes:2 ~ops:3 ());
  Cn_ulog.write hub (Cn_ulog.make_entry
    ~kind:Message_sent ~severity:Info
    ~msg_id:"tg-200" ~response_preview:"world" ());
  let entries = Cn_ulog.read_recent hub ~max_entries:10 in
  Printf.printf "count: %d\n" (List.length entries);
  List.iter (fun (e : Cn_ulog.entry) ->
    Printf.printf "%s msg_id=%s\n"
      (Cn_ulog.string_of_kind e.kind)
      (Option.value ~default:"-" e.msg_id)
  ) entries;
  [%expect {|
    count: 3
    message.received msg_id=tg-200
    invocation.end msg_id=tg-200
    message.sent msg_id=tg-200 |}]

let%expect_test "read_recent respects max_entries" =
  let hub = make_tmp_hub () in
  for i = 1 to 10 do
    Cn_ulog.write hub (Cn_ulog.make_entry
      ~kind:Message_received ~severity:Info
      ~msg_id:(Printf.sprintf "tg-%d" i) ())
  done;
  let entries = Cn_ulog.read_recent hub ~max_entries:3 in
  Printf.printf "count: %d\n" (List.length entries);
  List.iter (fun (e : Cn_ulog.entry) ->
    Printf.printf "msg_id=%s\n" (Option.value ~default:"-" e.msg_id)
  ) entries;
  [%expect {|
    count: 3
    msg_id=tg-8
    msg_id=tg-9
    msg_id=tg-10 |}]

(* === Deserialization === *)

let%expect_test "entry_of_json roundtrip" =
  let entry = Cn_ulog.make_entry
    ~kind:Invocation_end ~severity:Info
    ~msg_id:"tg-300" ~passes:2 ~ops:5
    ~tokens_in:1200 ~tokens_out:800
    ~duration_ms:4500 () in
  let json = Cn_ulog.entry_to_json entry in
  (match Cn_ulog.entry_of_json json with
   | Some e ->
     Printf.printf "kind=%s\n" (Cn_ulog.string_of_kind e.kind);
     Printf.printf "msg_id=%s\n" (Option.value ~default:"-" e.msg_id);
     Printf.printf "passes=%d\n" (Option.value ~default:0 e.passes);
     Printf.printf "ops=%d\n" (Option.value ~default:0 e.ops);
     Printf.printf "tokens_in=%d\n" (Option.value ~default:0 e.tokens_in);
     print_endline "ok"
   | None -> print_endline "deserialization failed");
  [%expect {|
    kind=invocation.end
    msg_id=tg-300
    passes=2
    ops=5
    tokens_in=1200
    ok |}]
