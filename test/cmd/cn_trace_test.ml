(** cn_trace_test.ml — Tests for cn_trace event schema and JSONL writer *)

open Cn_cmd

let%expect_test "event serialization shape" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "20260315-140203-abcd";
    seq = 0;
    min_severity = Cn_trace.Debug;
  } in
  let ev = Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"boot.start"
    ~severity:Info ~status:Ok_ () in
  let json = Cn_trace.event_to_json session ev in
  let s = Cn_json.to_string json in
  (* Verify required fields present *)
  assert (String.length s > 0);
  (match Cn_json.parse s with
   | Ok obj ->
       assert (Cn_json.get_string "schema" obj = Some "cn.events.v1");
       assert (Cn_json.get_string "boot_id" obj = Some "20260315-140203-abcd");
       assert (Cn_json.get_int "seq" obj = Some 1);
       assert (Cn_json.get_string "component" obj = Some "runtime");
       assert (Cn_json.get_string "layer" obj = Some "body");
       assert (Cn_json.get_string "event" obj = Some "boot.start");
       assert (Cn_json.get_string "severity" obj = Some "info");
       assert (Cn_json.get_string "status" obj = Some "ok");
       (* ts must be present *)
       assert (Cn_json.get_string "ts" obj <> None);
       print_endline "ok: required fields present"
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: required fields present |}]

let%expect_test "seq increments monotonically" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "test-boot";
    seq = 0;
    min_severity = Cn_trace.Debug;
  } in
  let ev = Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"test"
    ~severity:Info ~status:Ok_ () in
  let j1 = Cn_trace.event_to_json session ev in
  let j2 = Cn_trace.event_to_json session ev in
  let j3 = Cn_trace.event_to_json session ev in
  let get_seq j = match Cn_json.get_int "seq" j with Some i -> i | None -> -1 in
  Printf.printf "seq: %d %d %d\n" (get_seq j1) (get_seq j2) (get_seq j3);
  [%expect {| seq: 1 2 3 |}]

let%expect_test "optional fields included when set" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "test-boot";
    seq = 0;
    min_severity = Cn_trace.Debug;
  } in
  let ev = Cn_trace.make_event
    ~component:"orchestrator" ~layer:Body ~event:"pass.selected"
    ~severity:Info ~status:Ok_
    ~cycle_id:"tg-123" ~trigger_id:"tg-123" ~pass:"A"
    ~prev_state:"idle" ~next_state:"pass_a"
    ~reason_code:"observe_detected"
    ~reason:"ops manifest contains observe-class kinds"
    ~details:[
      "observe_ops", Cn_json.Int 2;
      "effect_ops", Cn_json.Int 1;
    ] () in
  let json = Cn_trace.event_to_json session ev in
  let s = Cn_json.to_string json in
  (match Cn_json.parse s with
   | Ok obj ->
       assert (Cn_json.get_string "cycle_id" obj = Some "tg-123");
       assert (Cn_json.get_string "pass" obj = Some "A");
       assert (Cn_json.get_string "prev_state" obj = Some "idle");
       assert (Cn_json.get_string "next_state" obj = Some "pass_a");
       assert (Cn_json.get_string "reason_code" obj = Some "observe_detected");
       (match Cn_json.get "details" obj with
        | Some details ->
            assert (Cn_json.get_int "observe_ops" details = Some 2);
            assert (Cn_json.get_int "effect_ops" details = Some 1);
            print_endline "ok: optional fields + details present"
        | None -> print_endline "missing details")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: optional fields + details present |}]

let%expect_test "refs serialization" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "test-boot";
    seq = 0;
    min_severity = Cn_trace.Debug;
  } in
  let ev = Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"finalize.complete"
    ~severity:Info ~status:Ok_
    ~refs:{ input = Some "logs/input/tg-123.md";
            output = Some "logs/output/tg-123.md";
            receipts = Some "state/receipts/tg-123.json" }
    () in
  let json = Cn_trace.event_to_json session ev in
  (match Cn_json.parse (Cn_json.to_string json) with
   | Ok obj ->
       (match Cn_json.get "refs" obj with
        | Some refs ->
            assert (Cn_json.get_string "input" refs = Some "logs/input/tg-123.md");
            assert (Cn_json.get_string "output" refs = Some "logs/output/tg-123.md");
            assert (Cn_json.get_string "receipts" refs = Some "state/receipts/tg-123.json");
            print_endline "ok: refs serialized"
        | None -> print_endline "missing refs")
   | Error e -> print_endline ("parse error: " ^ e));
  [%expect {| ok: refs serialized |}]

let%expect_test "severity filtering" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "test-boot";
    seq = 0;
    min_severity = Cn_trace.Info;
  } in
  (* Debug event should be skipped *)
  let ev = Cn_trace.make_event
    ~component:"sensor" ~layer:Sensor ~event:"typing.start"
    ~severity:Debug ~status:Ok_ () in
  (* emit would skip this due to severity, but we can test the rank *)
  let skip = Cn_trace.severity_rank ev.severity < Cn_trace.severity_rank session.min_severity in
  Printf.printf "debug skipped at info level: %b\n" skip;
  (* Info event should pass *)
  let ev2 = { ev with severity = Info } in
  let pass = not (Cn_trace.severity_rank ev2.severity < Cn_trace.severity_rank session.min_severity) in
  Printf.printf "info passes at info level: %b\n" pass;
  [%expect {|
    debug skipped at info level: true
    info passes at info level: true |}]

let%expect_test "severity string rendering" =
  Printf.printf "%s %s %s %s\n"
    (Cn_trace.string_of_severity Debug)
    (Cn_trace.string_of_severity Info)
    (Cn_trace.string_of_severity Warn)
    (Cn_trace.string_of_severity Error_);
  [%expect {| debug info warn error |}]

let%expect_test "status string rendering" =
  Printf.printf "%s %s %s %s %s\n"
    (Cn_trace.string_of_status Ok_)
    (Cn_trace.string_of_status Degraded)
    (Cn_trace.string_of_status Blocked)
    (Cn_trace.string_of_status Error_status)
    (Cn_trace.string_of_status Skipped);
  [%expect {| ok degraded blocked error skipped |}]

let%expect_test "layer string rendering" =
  Printf.printf "%s %s %s %s %s\n"
    (Cn_trace.string_of_layer Sensor)
    (Cn_trace.string_of_layer Body)
    (Cn_trace.string_of_layer Mind)
    (Cn_trace.string_of_layer Governance)
    (Cn_trace.string_of_layer World);
  [%expect {| sensor body mind governance world |}]

let%expect_test "single-line output (no newlines in JSON)" =
  let session = {
    Cn_trace.hub_path = "/tmp/test-hub";
    boot_id = "test-boot";
    seq = 0;
    min_severity = Cn_trace.Debug;
  } in
  let ev = Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"boot.start"
    ~severity:Info ~status:Ok_
    ~reason:"line1\nline2\ttab" () in
  let json = Cn_trace.event_to_json session ev in
  let s = Cn_json.to_string json in
  let has_newline = String.contains s '\n' in
  Printf.printf "has newline: %b\n" has_newline;
  [%expect {| has newline: false |}]

(* === Integration tests: full boot event sequence to JSONL === *)

let make_tmp_hub () =
  let base = Filename.concat (Filename.get_temp_dir_name ())
    (Printf.sprintf "cn-trace-test-%d" (Random.int 100000)) in
  Cn_ffi.Fs.ensure_dir (Filename.concat base "logs/events");
  base

let%expect_test "boot sequence emits required events in order" =
  let hub = make_tmp_hub () in
  let session = Cn_trace.start_session ~min_severity:Debug hub in
  (* Emit the normative boot sequence from TRACEABILITY §7 *)
  let boot_events = [
    "boot.start"; "config.loaded"; "deps.lock.loaded";
    "assets.validated"; "doctrine.loaded"; "mindsets.loaded";
    "skills.indexed"; "capabilities.rendered"; "boot.ready";
  ] in
  List.iter (fun event_name ->
    Cn_trace.emit session (Cn_trace.make_event
      ~component:"runtime" ~layer:Body ~event:event_name
      ~severity:Info ~status:Ok_ ())
  ) boot_events;
  (* Read the JSONL file and verify event sequence *)
  let dir = Filename.concat hub "logs/events" in
  let files = Array.to_list (Sys.readdir dir) in
  assert (List.length files = 1);
  let path = Filename.concat dir (List.hd files) in
  let content = Cn_ffi.Fs.read path in
  let lines = String.split_on_char '\n' content
    |> List.filter (fun s -> String.trim s <> "") in
  assert (List.length lines = 9);
  (* Extract event names in order *)
  let event_names = List.filter_map (fun line ->
    match Cn_json.parse line with
    | Ok obj -> Cn_json.get_string "event" obj
    | Error _ -> None
  ) lines in
  if event_names = boot_events then
    print_endline "ok: boot sequence events in normative order"
  else begin
    print_endline "FAIL: event order mismatch";
    List.iter (fun e -> Printf.printf "  got: %s\n" e) event_names
  end;
  [%expect {| ok: boot sequence events in normative order |}]

let%expect_test "boot sequence events have monotonic seq" =
  let hub = make_tmp_hub () in
  let session = Cn_trace.start_session ~min_severity:Debug hub in
  List.iter (fun event_name ->
    Cn_trace.emit session (Cn_trace.make_event
      ~component:"runtime" ~layer:Body ~event:event_name
      ~severity:Info ~status:Ok_ ())
  ) ["boot.start"; "config.loaded"; "boot.ready"];
  let dir = Filename.concat hub "logs/events" in
  let files = Array.to_list (Sys.readdir dir) in
  let path = Filename.concat dir (List.hd files) in
  let content = Cn_ffi.Fs.read path in
  let lines = String.split_on_char '\n' content
    |> List.filter (fun s -> String.trim s <> "") in
  let seqs = List.filter_map (fun line ->
    match Cn_json.parse line with
    | Ok obj -> Cn_json.get_int "seq" obj
    | Error _ -> None
  ) lines in
  (* Verify strictly increasing *)
  let rec is_ascending = function
    | [] | [_] -> true
    | a :: b :: rest -> a < b && is_ascending (b :: rest)
  in
  Printf.printf "monotonic: %b\n" (is_ascending seqs);
  Printf.printf "seqs: %s\n" (String.concat "," (List.map string_of_int seqs));
  [%expect {|
    monotonic: true
    seqs: 1,2,3 |}]

let%expect_test "cycle events interleave correctly with boot events" =
  let hub = make_tmp_hub () in
  let session = Cn_trace.start_session ~min_severity:Debug hub in
  (* Boot *)
  Cn_trace.emit session (Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"boot.start"
    ~severity:Info ~status:Ok_ ());
  Cn_trace.emit session (Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"boot.ready"
    ~severity:Info ~status:Ok_ ());
  (* Cycle *)
  Cn_trace.emit session (Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"cycle.start"
    ~severity:Info ~status:Ok_ ~trigger_id:"tg-1" ());
  Cn_trace.emit session (Cn_trace.make_event
    ~component:"runtime" ~layer:Mind ~event:"llm.call.ok"
    ~severity:Info ~status:Ok_ ~trigger_id:"tg-1" ());
  Cn_trace.emit session (Cn_trace.make_event
    ~component:"runtime" ~layer:Body ~event:"finalize.complete"
    ~severity:Info ~status:Ok_ ~trigger_id:"tg-1" ());
  (* Read and verify *)
  let dir = Filename.concat hub "logs/events" in
  let files = Array.to_list (Sys.readdir dir) in
  let path = Filename.concat dir (List.hd files) in
  let content = Cn_ffi.Fs.read path in
  let lines = String.split_on_char '\n' content
    |> List.filter (fun s -> String.trim s <> "") in
  assert (List.length lines = 5);
  let events = List.filter_map (fun line ->
    match Cn_json.parse line with
    | Ok obj -> Cn_json.get_string "event" obj
    | Error _ -> None
  ) lines in
  let expected = ["boot.start"; "boot.ready"; "cycle.start";
                  "llm.call.ok"; "finalize.complete"] in
  if events = expected then
    print_endline "ok: boot + cycle events in correct order"
  else
    print_endline "FAIL: event order mismatch";
  (* Verify trigger_id on cycle events *)
  let trigger_events = List.filter_map (fun line ->
    match Cn_json.parse line with
    | Ok obj ->
        (match Cn_json.get_string "trigger_id" obj with
         | Some tid -> Some (Option.get (Cn_json.get_string "event" obj), tid)
         | None -> None)
    | Error _ -> None
  ) lines in
  List.iter (fun (ev, tid) ->
    Printf.printf "%s: trigger_id=%s\n" ev tid
  ) trigger_events;
  [%expect {|
    ok: boot + cycle events in correct order
    cycle.start: trigger_id=tg-1
    llm.call.ok: trigger_id=tg-1
    finalize.complete: trigger_id=tg-1 |}]
