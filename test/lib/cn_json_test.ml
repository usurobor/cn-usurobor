(** cn_json_test: ppx_expect tests for cn_json parser/emitter *)

open Cn_json

(* === Parse Primitives === *)

let%expect_test "parse null" =
  (match parse "null" with Ok Null -> print_endline "null" | _ -> print_endline "FAIL");
  [%expect {| null |}]

let%expect_test "parse booleans" =
  ["true"; "false"] |> List.iter (fun s ->
    match parse s with
    | Ok (Bool b) -> Printf.printf "%s -> %b\n" s b
    | _ -> print_endline "FAIL");
  [%expect {|
    true -> true
    false -> false
  |}]

let%expect_test "parse integers" =
  ["0"; "42"; "-7"; "1000000"] |> List.iter (fun s ->
    match parse s with
    | Ok (Int i) -> Printf.printf "%s -> %d\n" s i
    | _ -> print_endline "FAIL");
  [%expect {|
    0 -> 0
    42 -> 42
    -7 -> -7
    1000000 -> 1000000
  |}]

let%expect_test "parse floats" =
  ["3.14"; "-0.5"; "1e10"; "2.5E-3"] |> List.iter (fun s ->
    match parse s with
    | Ok (Float f) -> Printf.printf "%s -> %g\n" s f
    | _ -> print_endline "FAIL");
  [%expect {|
    3.14 -> 3.14
    -0.5 -> -0.5
    1e10 -> 1e+10
    2.5E-3 -> 0.0025
  |}]

let%expect_test "parse simple string" =
  (match parse {|"hello world"|} with
   | Ok (String s) -> print_endline s
   | _ -> print_endline "FAIL");
  [%expect {| hello world |}]

(* === String Escape Handling === *)

let%expect_test "parse string escapes" =
  let input = {|"line1\nline2\ttab\\back\"quote\/slash"|} in
  (match parse input with
   | Ok (String s) -> print_endline s
   | _ -> print_endline "FAIL");
  [%expect {| line1
line2	tab\back"quote/slash |}]

let%expect_test "parse unicode BMP escape" =
  (* \u0041 = 'A', \u00e9 = 'e with acute' *)
  (match parse {|"\u0041\u00e9"|} with
   | Ok (String s) -> print_endline s
   | _ -> print_endline "FAIL");
  [%expect {| Aé |}]

let%expect_test "parse unicode surrogate pair" =
  (* U+1F600 (grinning face) = \uD83D\uDE00 *)
  (match parse {|"\uD83D\uDE00"|} with
   | Ok (String s) ->
       Printf.printf "len=%d\n" (String.length s);
       print_endline s
   | _ -> print_endline "FAIL");
  [%expect {|
    len=4
    😀
  |}]

(* === Nested Structures === *)

let%expect_test "parse empty object" =
  (match parse "{}" with
   | Ok (Object []) -> print_endline "empty object"
   | _ -> print_endline "FAIL");
  [%expect {| empty object |}]

let%expect_test "parse empty array" =
  (match parse "[]" with
   | Ok (Array []) -> print_endline "empty array"
   | _ -> print_endline "FAIL");
  [%expect {| empty array |}]

let%expect_test "parse nested object" =
  let input = {|{"name":"sigma","age":3,"active":true,"meta":null}|} in
  (match parse input with
   | Ok obj ->
       (match get_string "name" obj with Some s -> Printf.printf "name=%s\n" s | None -> ());
       (match get_int "age" obj with Some i -> Printf.printf "age=%d\n" i | None -> ());
       (match get "active" obj with Some (Bool b) -> Printf.printf "active=%b\n" b | _ -> ());
       (match get "meta" obj with Some Null -> print_endline "meta=null" | _ -> ())
   | Error e -> print_endline e);
  [%expect {|
    name=sigma
    age=3
    active=true
    meta=null
  |}]

let%expect_test "parse nested array of objects" =
  let input = {|[{"id":1},{"id":2}]|} in
  (match parse input with
   | Ok (Array items) ->
       items |> List.iter (fun item ->
         match get_int "id" item with
         | Some i -> Printf.printf "id=%d\n" i
         | None -> ())
   | _ -> print_endline "FAIL");
  [%expect {|
    id=1
    id=2
  |}]

(* === Accessors === *)

let%expect_test "get_list accessor" =
  let input = {|{"items":[1,2,3]}|} in
  (match parse input with
   | Ok obj ->
       (match get_list "items" obj with
        | Some items -> Printf.printf "count=%d\n" (List.length items)
        | None -> print_endline "FAIL")
   | _ -> print_endline "FAIL");
  [%expect {| count=3 |}]

let%expect_test "accessor on missing key returns None" =
  let input = {|{"a":1}|} in
  (match parse input with
   | Ok obj ->
       (match get_string "missing" obj with
        | None -> print_endline "None"
        | Some _ -> print_endline "FAIL")
   | _ -> print_endline "FAIL");
  [%expect {| None |}]

(* === Emitter === *)

let%expect_test "to_string produces single-line output" =
  let j = Object [
    ("model", String "claude-sonnet-4-20250514");
    ("max_tokens", Int 8192);
    ("messages", Array [
      Object [("role", String "user"); ("content", String "hello\nworld")]
    ])
  ] in
  let s = to_string j in
  let lines = String.split_on_char '\n' s in
  Printf.printf "lines=%d\n" (List.length lines);
  print_endline s;
  [%expect {|
    lines=1
    {"model":"claude-sonnet-4-20250514","max_tokens":8192,"messages":[{"role":"user","content":"hello\nworld"}]}
  |}]

let%expect_test "to_string roundtrip" =
  let j = Object [("key", String "value"); ("n", Int 42); ("b", Bool true); ("x", Null)] in
  let s = to_string j in
  (match parse s with
   | Ok j2 when to_string j2 = s -> print_endline "roundtrip ok"
   | Ok _ -> print_endline "roundtrip mismatch"
   | Error e -> print_endline e);
  [%expect {| roundtrip ok |}]

(* === Whitespace tolerance === *)

let%expect_test "parse with whitespace" =
  let input = {|
    {
      "key" : "value" ,
      "arr" : [ 1 , 2 , 3 ]
    }
  |} in
  (match parse input with
   | Ok obj ->
       (match get_string "key" obj with Some s -> print_endline s | None -> ());
       (match get_list "arr" obj with
        | Some items -> Printf.printf "arr_len=%d\n" (List.length items)
        | None -> ())
   | Error e -> print_endline e);
  [%expect {|
    value
    arr_len=3
  |}]

(* === Error handling === *)

let%expect_test "parse error on invalid input" =
  (match parse "{bad" with
   | Ok _ -> print_endline "SHOULD FAIL"
   | Error _ -> print_endline "error");
  [%expect {| error |}]

let%expect_test "parse error on trailing content" =
  (match parse "42 extra" with
   | Ok _ -> print_endline "SHOULD FAIL"
   | Error _ -> print_endline "error");
  [%expect {| error |}]

(* === Real API Response Fixtures === *)

let%expect_test "parse Anthropic Messages API response shape" =
  let input = {|{"id":"msg_01XFDUDYJgAACzvnptvVoYEL","type":"message","role":"assistant","content":[{"type":"text","text":"Hello! How can I help you today?"}],"model":"claude-sonnet-4-20250514","stop_reason":"end_turn","stop_sequence":null,"usage":{"input_tokens":25,"output_tokens":15}}|} in
  (match parse input with
   | Ok obj ->
       (match get_string "id" obj with Some s -> Printf.printf "id=%s\n" s | None -> ());
       (match get_string "stop_reason" obj with Some s -> Printf.printf "stop=%s\n" s | None -> ());
       (match get "content" obj with
        | Some (Array (first :: _)) ->
            (match get_string "text" first with
             | Some t -> Printf.printf "text=%s\n" t | None -> ())
        | _ -> ());
       (match get "usage" obj with
        | Some usage ->
            (match get_int "input_tokens" usage with
             | Some i -> Printf.printf "input_tokens=%d\n" i | None -> ());
            (match get_int "output_tokens" usage with
             | Some i -> Printf.printf "output_tokens=%d\n" i | None -> ());
            (* Cache fields are optional — missing returns None *)
            (match get_int "cache_creation_input_tokens" usage with
             | None -> print_endline "cache_creation=absent"
             | Some i -> Printf.printf "cache_creation=%d\n" i)
        | _ -> ())
   | Error e -> print_endline e);
  [%expect {|
    id=msg_01XFDUDYJgAACzvnptvVoYEL
    stop=end_turn
    text=Hello! How can I help you today?
    input_tokens=25
    output_tokens=15
    cache_creation=absent
  |}]

let%expect_test "parse Telegram getUpdates response shape" =
  let input = {|{"ok":true,"result":[{"update_id":123456789,"message":{"message_id":42,"from":{"id":498316684,"is_bot":false,"first_name":"User","username":"testuser"},"chat":{"id":498316684,"type":"private"},"date":1708300000,"text":"Hello agent \u0041"}}]}|} in
  (match parse input with
   | Ok obj ->
       (match get "ok" obj with Some (Bool b) -> Printf.printf "ok=%b\n" b | _ -> ());
       (match get_list "result" obj with
        | Some (upd :: _) ->
            (match get_int "update_id" upd with
             | Some i -> Printf.printf "update_id=%d\n" i | None -> ());
            (match get "message" upd with
             | Some msg ->
                 (match get_string "text" msg with
                  | Some t -> Printf.printf "text=%s\n" t | None -> ());
                 (match get "from" msg with
                  | Some from ->
                      (match get_int "id" from with
                       | Some i -> Printf.printf "from_id=%d\n" i | None -> ());
                      (match get_string "username" from with
                       | Some u -> Printf.printf "username=%s\n" u | None -> ())
                  | _ -> ())
             | _ -> ())
        | _ -> ())
   | Error e -> print_endline e);
  [%expect {|
    ok=true
    update_id=123456789
    text=Hello agent A
    from_id=498316684
    username=testuser
  |}]

let%expect_test "parse Anthropic response with cache metrics" =
  let input = {|{"usage":{"input_tokens":100,"output_tokens":50,"cache_creation_input_tokens":2000,"cache_read_input_tokens":1500}}|} in
  (match parse input with
   | Ok obj ->
       (match get "usage" obj with
        | Some usage ->
            (match get_int "cache_creation_input_tokens" usage with
             | Some i -> Printf.printf "cache_creation=%d\n" i | None -> ());
            (match get_int "cache_read_input_tokens" usage with
             | Some i -> Printf.printf "cache_read=%d\n" i | None -> ())
        | _ -> ())
   | Error e -> print_endline e);
  [%expect {|
    cache_creation=2000
    cache_read=1500
  |}]
