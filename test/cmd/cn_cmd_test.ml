(** cn_cmd_test: ppx_expect tests for cn_cmd module functions

    Tests pure or near-pure functions from the cn_cmd modules:
    - Cn_mail.parse_rejected_branch (string parsing)
    - Cn_agent.version_to_tuple (version string parsing)
    - Cn_agent.is_newer_version (semver comparison)
    - Cn_agent.auto_update_enabled (recursion guard + kill switch)
    - Cn_llm.split_status (curl output parsing)
    - Cn_llm.parse_response (Messages API response extraction)
    - Cn_telegram.parse_update (Telegram update JSON extraction)
    - Cn_context.tokenize (keyword extraction)
    - Cn_context.score_skill (keyword overlap scoring)

    Note: Most cn_cmd functions do I/O (Cn_ffi.Fs, git). Those need
    integration tests with temp directories. This file covers the
    pure subset that can be tested with ppx_expect. *)

(* === Cn_mail: parse_rejected_branch === *)

let%expect_test "parse_rejected_branch: valid rejection notice" =
  let content = "Branch `pi/review-request` rejected and deleted." in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| Some pi/review-request |}]

let%expect_test "parse_rejected_branch: simple branch name" =
  let content = "Branch `fix-bug` rejected and deleted." in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| Some fix-bug |}]

let%expect_test "parse_rejected_branch: not a rejection notice" =
  let content = "Something else `branch` here" in
  (match Cn_mail.parse_rejected_branch content with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: empty string" =
  (match Cn_mail.parse_rejected_branch "" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: too short" =
  (match Cn_mail.parse_rejected_branch "Branch" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: no closing backtick" =
  (match Cn_mail.parse_rejected_branch "Branch `foo" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]

let%expect_test "parse_rejected_branch: empty branch name" =
  (match Cn_mail.parse_rejected_branch "Branch `` rejected" with
   | Some branch -> Printf.printf "Some %s\n" branch
   | None -> print_endline "None");
  [%expect {| None |}]


(* === Cn_agent: version_to_tuple === *)

let show_tuple v =
  match Cn_agent.version_to_tuple v with
  | Some (a, b, c) -> Printf.printf "Some (%d, %d, %d)\n" a b c
  | None -> print_endline "None"

let%expect_test "version_to_tuple: plain semver" =
  show_tuple "2.4.3";
  [%expect {| Some (2, 4, 3) |}]

let%expect_test "version_to_tuple: v-prefix" =
  show_tuple "v2.4.3";
  [%expect {| Some (2, 4, 3) |}]

let%expect_test "version_to_tuple: zero version" =
  show_tuple "0.0.0";
  [%expect {| Some (0, 0, 0) |}]

let%expect_test "version_to_tuple: two segments" =
  show_tuple "2.4";
  [%expect {| None |}]

let%expect_test "version_to_tuple: four segments" =
  show_tuple "2.4.3.1";
  [%expect {| None |}]

let%expect_test "version_to_tuple: non-numeric" =
  show_tuple "2.4.beta";
  [%expect {| None |}]

let%expect_test "version_to_tuple: empty string" =
  show_tuple "";
  [%expect {| None |}]

let%expect_test "version_to_tuple: just v" =
  show_tuple "v";
  [%expect {| None |}]


(* === Cn_agent: is_newer_version === *)

let show_newer remote local =
  Printf.printf "%s vs %s → %b\n" remote local
    (Cn_agent.is_newer_version remote local)

let%expect_test "is_newer_version: patch bump" =
  show_newer "2.4.3" "2.4.2";
  [%expect {| 2.4.3 vs 2.4.2 → true |}]

let%expect_test "is_newer_version: minor bump" =
  show_newer "2.5.0" "2.4.9";
  [%expect {| 2.5.0 vs 2.4.9 → true |}]

let%expect_test "is_newer_version: major bump" =
  show_newer "3.0.0" "2.99.99";
  [%expect {| 3.0.0 vs 2.99.99 → true |}]

let%expect_test "is_newer_version: same version" =
  show_newer "2.4.3" "2.4.3";
  [%expect {| 2.4.3 vs 2.4.3 → false |}]

let%expect_test "is_newer_version: older remote" =
  show_newer "2.4.2" "2.4.3";
  [%expect {| 2.4.2 vs 2.4.3 → false |}]

let%expect_test "is_newer_version: v-prefix mixed" =
  show_newer "v2.5.0" "2.4.0";
  [%expect {| v2.5.0 vs 2.4.0 → true |}]

let%expect_test "is_newer_version: both v-prefix" =
  show_newer "v3.0.0" "v2.0.0";
  [%expect {| v3.0.0 vs v2.0.0 → true |}]

let%expect_test "is_newer_version: garbage remote" =
  show_newer "garbage" "2.4.3";
  [%expect {| garbage vs 2.4.3 → false |}]

let%expect_test "is_newer_version: garbage local" =
  show_newer "2.5.0" "garbage";
  [%expect {| 2.5.0 vs garbage → false |}]

let%expect_test "is_newer_version: both garbage" =
  show_newer "abc" "def";
  [%expect {| abc vs def → false |}]


(* === Cn_agent: auto_update_enabled (recursion guard) ===

   Tests ordered carefully: CN_UPDATE_RUNNING is set last because
   OCaml has no Unix.unsetenv — once set, it persists. *)

let%expect_test "auto_update_enabled: default is true" =
  (* Neither CN_UPDATE_RUNNING nor CN_AUTO_UPDATE=0 set in test env *)
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  [%expect {| true |}]

let%expect_test "auto_update_enabled: CN_AUTO_UPDATE=0 disables" =
  Unix.putenv "CN_AUTO_UPDATE" "0";
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  (* Clean up so subsequent tests aren't affected *)
  Unix.putenv "CN_AUTO_UPDATE" "1";
  [%expect {| false |}]

let%expect_test "auto_update_enabled: CN_UPDATE_RUNNING blocks re-exec loop" =
  (* This test MUST be last — putenv cannot be undone without unsetenv.
     This is the critical guard that prevents the infinite loop from
     MCA: self-update-recursion. *)
  Unix.putenv "CN_UPDATE_RUNNING" "1";
  Printf.printf "%b\n" (Cn_agent.auto_update_enabled ());
  [%expect {| false |}]


(* === Cn_llm: split_status === *)

let show_split output =
  let body, code = Cn_llm.split_status output in
  Printf.printf "(%d, %S)\n" code body

let%expect_test "split_status: normal 200 response" =
  show_split "{\"id\":\"msg_123\"}\n200";
  [%expect {| (200, "{\"id\":\"msg_123\"}") |}]

let%expect_test "split_status: 500 server error" =
  show_split "{\"error\":\"overloaded\"}\n500";
  [%expect {| (500, "{\"error\":\"overloaded\"}") |}]

let%expect_test "split_status: multiline body with 200" =
  show_split "line1\nline2\n200";
  [%expect {| (200, "line1\nline2") |}]

let%expect_test "split_status: garbage (no newline)" =
  show_split "garbage";
  [%expect {| (0, "garbage") |}]

let%expect_test "split_status: only status code" =
  show_split "200";
  [%expect {| (200, "") |}]

let%expect_test "split_status: empty string" =
  show_split "";
  [%expect {| (0, "") |}]


(* === Cn_llm: parse_response === *)

let show_parse body =
  match Cn_llm.parse_response body with
  | Ok r ->
      Printf.printf "content=%S stop=%s in=%d out=%d cache_create=%d cache_read=%d\n"
        r.content r.stop_reason r.input_tokens r.output_tokens
        r.cache_creation_input_tokens r.cache_read_input_tokens
  | Error msg -> Printf.printf "Error: %s\n" msg

let%expect_test "parse_response: single text block" =
  show_parse {|{"content":[{"type":"text","text":"Hello!"}],"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":5}}|};
  [%expect {| content="Hello!" stop=end_turn in=10 out=5 cache_create=0 cache_read=0 |}]

let%expect_test "parse_response: multiple text blocks" =
  show_parse {|{"content":[{"type":"text","text":"First"},{"type":"text","text":"Second"}],"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":8}}|};
  [%expect {| content="First\n\nSecond" stop=end_turn in=10 out=8 cache_create=0 cache_read=0 |}]

let%expect_test "parse_response: thinking block then text" =
  show_parse {|{"content":[{"type":"thinking","thinking":"hmm"},{"type":"text","text":"Answer"}],"stop_reason":"end_turn","usage":{"input_tokens":20,"output_tokens":15}}|};
  [%expect {| content="Answer" stop=end_turn in=20 out=15 cache_create=0 cache_read=0 |}]

let%expect_test "parse_response: with cache metrics" =
  show_parse {|{"content":[{"type":"text","text":"cached"}],"stop_reason":"end_turn","usage":{"input_tokens":10,"output_tokens":3,"cache_creation_input_tokens":100,"cache_read_input_tokens":50}}|};
  [%expect {| content="cached" stop=end_turn in=10 out=3 cache_create=100 cache_read=50 |}]

let%expect_test "parse_response: empty content array" =
  show_parse {|{"content":[],"stop_reason":"end_turn","usage":{"input_tokens":5,"output_tokens":0}}|};
  [%expect {| content="" stop=end_turn in=5 out=0 cache_create=0 cache_read=0 |}]

let%expect_test "parse_response: invalid JSON" =
  show_parse "not json";
  [%expect {| Error: JSON parse error: unexpected char 'n' at pos 0 |}]


(* === Cn_telegram: parse_update === *)

let show_update json_str =
  match Cn_json.parse json_str with
  | Error e -> Printf.printf "parse error: %s\n" e
  | Ok json ->
      match Cn_telegram.parse_update json with
      | None -> print_endline "None"
      | Some m ->
          Printf.printf "update_id=%d msg_id=%d chat=%d user=%d user=%s text=%S date=%d\n"
            m.update_id m.message_id m.chat_id m.user_id
            (match m.username with Some u -> u | None -> "<none>")
            m.text m.date

let%expect_test "parse_update: standard text message" =
  show_update {|{"update_id":100,"message":{"message_id":42,"from":{"id":12345,"is_bot":false,"first_name":"Test","username":"testuser"},"chat":{"id":12345,"type":"private"},"date":1700000000,"text":"Hello"}}|};
  [%expect {| update_id=100 msg_id=42 chat=12345 user=12345 user=testuser text="Hello" date=1700000000 |}]

let%expect_test "parse_update: message with emoji via unicode escape" =
  show_update {|{"update_id":101,"message":{"message_id":43,"from":{"id":999,"is_bot":false,"first_name":"U"},"chat":{"id":999,"type":"private"},"date":1700000001,"text":"Hi \uD83D\uDE00"}}|};
  [%expect {| update_id=101 msg_id=43 chat=999 user=999 user=<none> text="Hi \240\159\152\128" date=1700000001 |}]

let%expect_test "parse_update: no username" =
  show_update {|{"update_id":102,"message":{"message_id":44,"from":{"id":555,"is_bot":false,"first_name":"Anon"},"chat":{"id":555,"type":"private"},"date":1700000002,"text":"hi"}}|};
  [%expect {| update_id=102 msg_id=44 chat=555 user=555 user=<none> text="hi" date=1700000002 |}]

let%expect_test "parse_update: no text field (photo message)" =
  show_update {|{"update_id":103,"message":{"message_id":45,"from":{"id":555,"is_bot":false,"first_name":"Anon"},"chat":{"id":555,"type":"private"},"date":1700000003}}|};
  [%expect {| update_id=103 msg_id=45 chat=555 user=555 user=<none> text="" date=1700000003 |}]

let%expect_test "parse_update: missing message key (channel_post etc.)" =
  show_update {|{"update_id":104,"channel_post":{"message_id":1,"chat":{"id":-100},"date":0,"text":"x"}}|};
  [%expect {| None |}]

let%expect_test "parse_update: missing from field" =
  show_update {|{"update_id":105,"message":{"message_id":46,"chat":{"id":555,"type":"private"},"date":0,"text":"orphan"}}|};
  [%expect {| None |}]


(* === Cn_context: tokenize === *)

let%expect_test "tokenize: basic splitting and lowercasing" =
  Cn_context.tokenize "Hello World, how are you?"
  |> List.iter (fun t -> Printf.printf "%s\n" t);
  [%expect {|
    hello
    world
    how
    are
    you
  |}]

let%expect_test "tokenize: drops short tokens" =
  Cn_context.tokenize "I am an OCaml dev"
  |> List.iter (fun t -> Printf.printf "%s\n" t);
  [%expect {|
    ocaml
    dev
  |}]

let%expect_test "tokenize: numbers included" =
  Cn_context.tokenize "step 42 complete"
  |> List.iter (fun t -> Printf.printf "%s\n" t);
  [%expect {|
    step
    complete
  |}]

let%expect_test "tokenize: empty string" =
  let tokens = Cn_context.tokenize "" in
  Printf.printf "count=%d\n" (List.length tokens);
  [%expect {| count=0 |}]


(* === Cn_context: score_skill === *)

let%expect_test "score_skill: matching keywords" =
  let keywords = ["inbox"; "message"; "process"] in
  let skill = "Process inbound messages from peers. Inbox handling." in
  Printf.printf "score=%d\n" (Cn_context.score_skill keywords skill);
  [%expect {| score=2 |}]

let%expect_test "score_skill: no overlap" =
  let keywords = ["deploy"; "release"] in
  let skill = "Process inbound messages from inbox." in
  Printf.printf "score=%d\n" (Cn_context.score_skill keywords skill);
  [%expect {| score=0 |}]

let%expect_test "score_skill: case insensitive matching" =
  let keywords = ["review"; "code"] in
  let skill = "Code Review process for pull requests" in
  Printf.printf "score=%d\n" (Cn_context.score_skill keywords skill);
  [%expect {| score=2 |}]


(* === Cn_context: load_conversation === *)

let%expect_test "load_conversation: parses conversation JSON fixture" =
  (* Test the pure JSON parsing part via parse + format *)
  let fixture = {|[{"role":"user","content":"Hello"},{"role":"assistant","content":"Hi there!"},{"role":"user","content":"How are you?"}]|} in
  (match Cn_json.parse fixture with
   | Error e -> Printf.printf "error: %s\n" e
   | Ok (Cn_json.Array items) ->
       items |> List.iter (fun entry ->
         let role = match Cn_json.get_string "role" entry with Some r -> r | None -> "?" in
         let content = match Cn_json.get_string "content" entry with Some c -> c | None -> "" in
         Printf.printf "%s: %s\n" role content)
   | _ -> print_endline "unexpected");
  [%expect {|
    user: Hello
    assistant: Hi there!
    user: How are you?
  |}]
