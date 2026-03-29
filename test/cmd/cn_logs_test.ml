(** cn_logs_test.ml — Tests for cn logs CLI *)

(* === Duration parsing === *)

let%expect_test "parse_duration basic units" =
  let test s = match Cn_logs.parse_duration s with
    | Some f -> Printf.printf "%s = %.0f\n" s f
    | None -> Printf.printf "%s = None\n" s in
  test "30s";
  test "5m";
  test "2h";
  test "1d";
  test "bad";
  test "";
  [%expect {|
    30s = 30
    5m = 300
    2h = 7200
    1d = 86400
    bad = None
     = None |}]

(* === ISO timestamp parsing === *)

let%expect_test "parse_iso_ts valid" =
  (match Cn_logs.parse_iso_ts "2026-03-28T14:30:00.000Z" with
   | Some t ->
     Printf.printf "parsed: %b\n" (t > 1.0e9);
     Printf.printf "is_number: %b\n" (Float.is_finite t)
   | None -> print_endline "failed");
  [%expect {|
    parsed: true
    is_number: true |}]

let%expect_test "parse_iso_ts invalid" =
  let test s = Printf.printf "%s: %b\n" s (Cn_logs.parse_iso_ts s <> None) in
  test "not-a-date";
  test "2026";
  test "";
  [%expect {|
    not-a-date: false
    2026: false
    : false |}]

(* === Argument parsing === *)

let%expect_test "parse_log_args defaults" =
  let opts = Cn_logs.parse_log_args [] in
  Printf.printf "since: %b\n" (opts.since <> None);
  Printf.printf "msg_id: %b\n" (opts.msg_id <> None);
  Printf.printf "errors_only: %b\n" opts.errors_only;
  Printf.printf "json_mode: %b\n" opts.json_mode;
  Printf.printf "kind_filter: %b\n" (opts.kind_filter <> None);
  Printf.printf "max_entries: %d\n" opts.max_entries;
  [%expect {|
    since: false
    msg_id: false
    errors_only: false
    json_mode: false
    kind_filter: false
    max_entries: 50 |}]

let%expect_test "parse_log_args with flags" =
  let opts = Cn_logs.parse_log_args
    ["--errors"; "--json"; "--msg"; "tg-123"; "--kind"; "error";
     "-n"; "10"] in
  Printf.printf "errors_only: %b\n" opts.errors_only;
  Printf.printf "json_mode: %b\n" opts.json_mode;
  Printf.printf "msg_id: %s\n" (Option.value ~default:"none" opts.msg_id);
  Printf.printf "kind_filter: %s\n" (Option.value ~default:"none" opts.kind_filter);
  Printf.printf "max_entries: %d\n" opts.max_entries;
  [%expect {|
    errors_only: true
    json_mode: true
    msg_id: tg-123
    kind_filter: error
    max_entries: 10 |}]

let%expect_test "parse_log_args since" =
  let opts = Cn_logs.parse_log_args ["--since"; "2h"] in
  Printf.printf "has_since: %b\n" (Option.is_some opts.since);
  [%expect {| has_since: true |}]

(* === Filtering === *)

let%expect_test "filter by msg_id" =
  let entries = [
    Cn_ulog.make_entry ~kind:Message_received ~severity:Info ~msg_id:"tg-1" ();
    Cn_ulog.make_entry ~kind:Message_received ~severity:Info ~msg_id:"tg-2" ();
    Cn_ulog.make_entry ~kind:Invocation_end ~severity:Info ~msg_id:"tg-1" ();
  ] in
  let opts = { Cn_logs.default_opts with msg_id = Some "tg-1" } in
  let filtered = Cn_logs.filter_entries opts entries in
  Printf.printf "count: %d\n" (List.length filtered);
  List.iter (fun (e : Cn_ulog.entry) ->
    Printf.printf "%s %s\n"
      (Cn_ulog.string_of_kind e.kind)
      (Option.value ~default:"-" e.msg_id)
  ) filtered;
  [%expect {|
    count: 2
    message.received tg-1
    invocation.end tg-1 |}]

let%expect_test "filter errors only" =
  let entries = [
    Cn_ulog.make_entry ~kind:Message_received ~severity:Info ~msg_id:"tg-1" ();
    Cn_ulog.make_entry ~kind:Error ~severity:Error_ ~msg_id:"tg-1" ~error:"fail" ();
    Cn_ulog.make_entry ~kind:Message_sent ~severity:Warn ~msg_id:"tg-2" ();
  ] in
  let opts = { Cn_logs.default_opts with errors_only = true } in
  let filtered = Cn_logs.filter_entries opts entries in
  Printf.printf "count: %d\n" (List.length filtered);
  List.iter (fun (e : Cn_ulog.entry) ->
    Printf.printf "%s %s\n"
      (Cn_ulog.string_of_severity e.severity)
      (Cn_ulog.string_of_kind e.kind)
  ) filtered;
  [%expect {|
    count: 2
    error error
    warn message.sent |}]

let%expect_test "filter by kind" =
  let entries = [
    Cn_ulog.make_entry ~kind:Message_received ~severity:Info ();
    Cn_ulog.make_entry ~kind:Invocation_start ~severity:Info ();
    Cn_ulog.make_entry ~kind:Message_received ~severity:Info ();
  ] in
  let opts = { Cn_logs.default_opts with kind_filter = Some "message.received" } in
  let filtered = Cn_logs.filter_entries opts entries in
  Printf.printf "count: %d\n" (List.length filtered);
  [%expect {| count: 2 |}]

(* === Human formatting === *)

let%expect_test "format_entry message received" =
  let entry = { (Cn_ulog.make_entry
    ~kind:Message_received ~severity:Info
    ~msg_id:"tg-123" ~source:"telegram"
    ~user_msg:"Hello agent" ()) with ts = "2026-03-28T14:30:00.000Z" } in
  let s = Cn_logs.format_entry entry in
  (* Should contain time, kind, msg_id, source, message *)
  Printf.printf "has_time: %b\n" (String.length s > 0);
  Printf.printf "has_msg_id: %b\n"
    (let rec check i = if i >= String.length s - 5 then false
       else if String.sub s i 6 = "tg-123" then true else check (i+1)
     in check 0);
  [%expect {|
    has_time: true
    has_msg_id: true |}]
