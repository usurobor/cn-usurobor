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
    - Cn_context.contains_sub (substring containment)
    - Cn_context.pack (mindsets + role-weighted skills integration)
    - Cn_runtime.extract_inbound_message (message slicing from packed context)
    - Cn_runtime.telegram_payload (Telegram reply fallback chain)
    - Cn_config.load (config loading: defaults, env override, clamping, errors)
    - Cn_runtime.is_in_flight (frontmatter id matching in state/input.md|output.md)
    - Cn_runtime.is_queued (filename suffix matching in state/queue/)
    - Cn_runtime.enqueue_telegram (idempotent queue insertion)

    Note: Most cn_cmd functions do I/O (Cn_ffi.Fs, git). Those need
    integration tests with temp directories. This file covers the
    pure subset that can be tested with ppx_expect, plus filesystem
    tests that use temp hub directories for config and daemon helpers.

    Cn_config tests use temp directories for .cn/config.json fixtures.
    Each config test calls reset_config_env() to clear env vars
    (Cn_config treats "" as unset, so tests run in any order). *)

(** Create a fresh temp directory. Works on OCaml >= 4.14 — avoids
    Filename.temp_dir which requires 5.1+. *)
let mk_temp_dir prefix =
  let base = Filename.get_temp_dir_name () in
  let rec attempt k =
    if k = 0 then failwith "mk_temp_dir: exhausted attempts";
    let dir =
      Filename.concat base
        (Printf.sprintf "%s-%d-%06d" prefix (Unix.getpid ()) (Random.int 1_000_000))
    in
    try Unix.mkdir dir 0o700; dir
    with Unix.Unix_error (Unix.EEXIST, _, _) -> attempt (k - 1)
  in
  Random.self_init ();
  attempt 50

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


(* === Cn_context: contains_sub === *)

let%expect_test "contains_sub: present" =
  Printf.printf "%b\n" (Cn_context.contains_sub "/skills/eng/alpha/SKILL.md" "/skills/eng/");
  [%expect {| true |}]

let%expect_test "contains_sub: absent" =
  Printf.printf "%b\n" (Cn_context.contains_sub "/skills/eng/alpha/SKILL.md" "/skills/pm/");
  [%expect {| false |}]

let%expect_test "contains_sub: empty sub" =
  Printf.printf "%b\n" (Cn_context.contains_sub "anything" "");
  [%expect {| true |}]

let%expect_test "contains_sub: sub longer than string" =
  Printf.printf "%b\n" (Cn_context.contains_sub "ab" "abc");
  [%expect {| false |}]


(* === Cn_context: pack — mindsets + role-weighted skills ===

   Integration test: creates a temp hub with config, spec, mindsets,
   and two skills with identical keyword overlap. Verifies:
   1. Mindsets section is present in packed output
   2. COHERENCE precedes ENGINEERING (deterministic order)
   3. Engineer-role skill ranks before PM skill (role weighting) *)

let find_sub_idx (s : string) (sub : string) : int =
  let n = String.length s in
  let m = String.length sub in
  let rec loop i =
    if i + m > n then -1
    else if String.sub s i m = sub then i
    else loop (i + 1)
  in
  if m = 0 then 0 else loop 0

let with_pack_hub f =
  let tmp = mk_temp_dir "cn_pack_test" in
  (* Build hub structure *)
  let dirs = [
    ".cn"; "spec"; "src/agent/mindsets";
    "src/agent/skills/eng/alpha"; "src/agent/skills/pm/beta";
    "state";
  ] in
  List.iter (fun d -> Cn_ffi.Fs.mkdir_p (Filename.concat tmp d)) dirs;
  Fun.protect ~finally:(fun () ->
    (* Best-effort recursive cleanup *)
    let rec rm path =
      if Sys.is_directory path then begin
        Sys.readdir path |> Array.iter (fun f -> rm (Filename.concat path f));
        Unix.rmdir path
      end else Sys.remove path
    in
    (try rm tmp with _ -> ()))
    (fun () -> f tmp)

let%expect_test "pack: mindsets inserted + engineer skill ranks first" =
  with_pack_hub (fun hub ->
    Cn_ffi.Fs.write (Filename.concat hub ".cn/config.json")
      {|{"runtime":{"role":"engineer"}}|};
    Cn_ffi.Fs.write (Filename.concat hub "spec/SOUL.md") "# SOUL\n";
    Cn_ffi.Fs.write (Filename.concat hub "spec/USER.md") "# USER\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/mindsets/COHERENCE.md")
      "# COHERENCE\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/mindsets/ENGINEERING.md")
      "# ENGINEERING\n";
    (* Two skills with identical keyword overlap on "ship patch" *)
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/skills/eng/alpha/SKILL.md")
      "# ENG SKILL\nship patch\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/skills/pm/beta/SKILL.md")
      "# PM SKILL\nship patch\n";

    let packed =
      Cn_context.pack ~hub_path:hub ~trigger_id:"t1"
        ~message:"ship patch" ~from:"test"
    in
    let c = packed.content in
    let has_mindsets = find_sub_idx c "## Mindsets" >= 0 in
    let coh_i = find_sub_idx c "# COHERENCE" in
    let eng_i = find_sub_idx c "# ENGINEERING" in
    let mindset_order = coh_i >= 0 && eng_i >= 0 && coh_i < eng_i in
    let eng_skill_i = find_sub_idx c "# ENG SKILL" in
    let pm_skill_i = find_sub_idx c "# PM SKILL" in
    let skill_order = eng_skill_i >= 0 && pm_skill_i >= 0
                      && eng_skill_i < pm_skill_i in
    Printf.printf "has_mindsets=%b\nmindset_order=%b\nskill_order=%b\n"
      has_mindsets mindset_order skill_order);
  [%expect {|
    has_mindsets=true
    mindset_order=true
    skill_order=true
  |}]

let%expect_test "pack: role normalization — Engineer (capitalized) works" =
  with_pack_hub (fun hub ->
    Cn_ffi.Fs.write (Filename.concat hub ".cn/config.json")
      {|{"runtime":{"role":"Engineer"}}|};
    Cn_ffi.Fs.write (Filename.concat hub "spec/SOUL.md") "# SOUL\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/mindsets/ENGINEERING.md")
      "# ENGINEERING\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/skills/eng/alpha/SKILL.md")
      "# ENG SKILL\nship patch\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/skills/pm/beta/SKILL.md")
      "# PM SKILL\nship patch\n";

    let packed =
      Cn_context.pack ~hub_path:hub ~trigger_id:"t2"
        ~message:"ship patch" ~from:"test"
    in
    let c = packed.content in
    let eng_i = find_sub_idx c "# ENG SKILL" in
    let pm_i = find_sub_idx c "# PM SKILL" in
    Printf.printf "eng_first=%b\n" (eng_i >= 0 && pm_i >= 0 && eng_i < pm_i));
  [%expect {| eng_first=true |}]

let%expect_test "pack: no config → no mindsets crash, skills still work" =
  with_pack_hub (fun hub ->
    (* No .cn/config.json at all *)
    (try Sys.remove (Filename.concat hub ".cn/config.json") with _ -> ());
    Cn_ffi.Fs.write (Filename.concat hub "spec/SOUL.md") "# SOUL\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/mindsets/ENGINEERING.md")
      "# ENGINEERING\n";
    Cn_ffi.Fs.write (Filename.concat hub "src/agent/skills/eng/alpha/SKILL.md")
      "# SKILL\nship patch\n";

    let packed =
      Cn_context.pack ~hub_path:hub ~trigger_id:"t3"
        ~message:"ship patch" ~from:"test"
    in
    let has_eng = find_sub_idx packed.content "# ENGINEERING" >= 0 in
    let has_skill = find_sub_idx packed.content "# SKILL" >= 0 in
    Printf.printf "has_eng=%b has_skill=%b\n" has_eng has_skill);
  [%expect {| has_eng=true has_skill=true |}]


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


(* === Cn_runtime: extract_inbound_message === *)

let%expect_test "extract_inbound_message: extracts message from packed context" =
  let packed = {|## Identity

You are Sigma.

## Inbound Message

**From**: telegram
**ID**: tg-42

Hello, how are you?
|} in
  let msg = Cn_runtime.extract_inbound_message packed in
  Printf.printf "%s\n" msg;
  [%expect {| Hello, how are you? |}]

let%expect_test "extract_inbound_message: multiline message body" =
  let packed = {|## Identity

Core identity here.

## Inbound Message

**From**: pi
**ID**: pi-review

Please review this code.
It has three files.
Thanks!
|} in
  let msg = Cn_runtime.extract_inbound_message packed in
  Printf.printf "%s\n" msg;
  [%expect {|
    Please review this code.
    It has three files.
    Thanks!
  |}]

let%expect_test "extract_inbound_message: no marker returns full input" =
  let text = "Just some raw text without any sections" in
  let msg = Cn_runtime.extract_inbound_message text in
  Printf.printf "%s\n" msg;
  [%expect {| Just some raw text without any sections |}]

let%expect_test "extract_inbound_message: empty packed body" =
  let msg = Cn_runtime.extract_inbound_message "" in
  Printf.printf "%S\n" msg;
  [%expect {| "" |}]

let%expect_test "extract_inbound_message: message with no metadata lines" =
  let packed = "## Inbound Message\n\nJust the message\n" in
  let msg = Cn_runtime.extract_inbound_message packed in
  Printf.printf "%s\n" msg;
  [%expect {| Just the message |}]


(* === Cn_runtime: telegram_payload === *)

let%expect_test "telegram_payload: body takes priority" =
  let ops : Cn_lib.agent_op list = [Reply ("id-1", "reply text")] in
  let result = Cn_runtime.telegram_payload ops (Some "Body content") in
  Printf.printf "%s\n" result;
  [%expect {| Body content |}]

let%expect_test "telegram_payload: falls back to Reply op message" =
  let ops : Cn_lib.agent_op list = [Ack "id-1"; Reply ("id-2", "The reply")] in
  let result = Cn_runtime.telegram_payload ops None in
  Printf.printf "%s\n" result;
  [%expect {| The reply |}]

let%expect_test "telegram_payload: no body and no Reply op" =
  let ops : Cn_lib.agent_op list = [Ack "id-1"; Done "id-2"] in
  let result = Cn_runtime.telegram_payload ops None in
  Printf.printf "%s\n" result;
  [%expect {| (acknowledged) |}]

let%expect_test "telegram_payload: empty ops and no body" =
  let result = Cn_runtime.telegram_payload [] None in
  Printf.printf "%s\n" result;
  [%expect {| (acknowledged) |}]

let%expect_test "telegram_payload: body=Some empty string still wins" =
  let ops : Cn_lib.agent_op list = [Reply ("id-1", "reply")] in
  let result = Cn_runtime.telegram_payload ops (Some "") in
  Printf.printf "%S\n" result;
  [%expect {| "" |}]


(* === Cn_config: load ===

   Uses temp directories with real .cn/config.json files.
   Cn_config.non_empty_env treats "" as unset, so putenv "" is safe
   cleanup — no ordering constraints between tests. *)

let with_temp_hub ?config_json f =
  let tmp = mk_temp_dir "cn_config_test" in
  let cn_dir = Filename.concat tmp ".cn" in
  Cn_ffi.Fs.mkdir_p cn_dir;
  (match config_json with
   | Some json -> Cn_ffi.Fs.write (Filename.concat cn_dir "config.json") json
   | None -> ());
  Fun.protect ~finally:(fun () ->
    (try Sys.remove (Filename.concat cn_dir "config.json") with _ -> ());
    (try Unix.rmdir cn_dir with _ -> ());
    (try Unix.rmdir tmp with _ -> ()))
    (fun () -> f tmp)

(* Reset env to baseline before each config test *)
let reset_config_env () =
  Unix.putenv "ANTHROPIC_KEY" "";
  Unix.putenv "CN_MODEL" "";
  Unix.putenv "TELEGRAM_TOKEN" ""

let show_config hub_path =
  match Cn_config.load ~hub_path with
  | Error msg -> Printf.printf "Error: %s\n" msg
  | Ok c ->
      Printf.printf "model=%s poll=%d timeout=%d max=%d users=[%s] tg=%s\n"
        c.model c.poll_interval c.poll_timeout c.max_tokens
        (c.allowed_users |> List.map string_of_int |> String.concat ",")
        (match c.telegram_token with Some _ -> "set" | None -> "unset")

let%expect_test "config: missing ANTHROPIC_KEY → Error" =
  reset_config_env ();
  with_temp_hub (fun hub_path ->
    show_config hub_path);
  [%expect {| Error: ANTHROPIC_KEY not set (required for agent runtime) |}]

let%expect_test "config: defaults with no config file" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub (fun hub_path ->
    show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=8192 users=[] tg=unset |}]

let%expect_test "config: runtime key overrides defaults" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"model":"claude-haiku-4-latest","poll_interval":5,"poll_timeout":60,"max_tokens":4096}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-haiku-4-latest poll=5 timeout=60 max=4096 users=[] tg=unset |}]

let%expect_test "config: allowed_users parsed as int list" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"allowed_users":[111,222,333]}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=8192 users=[111,222,333] tg=unset |}]

let%expect_test "config: empty allowed_users means deny all" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"allowed_users":[]}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=8192 users=[] tg=unset |}]

let%expect_test "config: integer clamping — poll_interval < 1 clamped to 1" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"poll_interval":0}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=8192 users=[] tg=unset |}]

let%expect_test "config: integer clamping — poll_timeout < 0 clamped to 0" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"poll_timeout":-5}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=0 max=8192 users=[] tg=unset |}]

let%expect_test "config: integer clamping — max_tokens < 1 clamped to 1" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"runtime":{"max_tokens":0}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=1 users=[] tg=unset |}]

let%expect_test "config: invalid JSON → Error with path" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:"not valid json {"
    (fun hub_path ->
      match Cn_config.load ~hub_path with
      | Error msg ->
          (* Error format: "<hub>/.cn/config.json: <parse error>"
             Strip the random temp prefix, keep the stable suffix *)
          let has_path = Cn_lib.starts_with ~prefix:hub_path msg in
          let suffix =
            let plen = String.length hub_path in
            if String.length msg > plen then String.sub msg plen (String.length msg - plen)
            else msg
          in
          Printf.printf "has_path=%b suffix=%s\n" has_path suffix
      | Ok _ -> print_endline "unexpected Ok");
  [%expect {| has_path=true suffix=/.cn/config.json: unexpected char 'n' at pos 0 |}]

let%expect_test "config: no runtime key in JSON → defaults" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  with_temp_hub
    ~config_json:{|{"other_key":"value"}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-sonnet-4-latest poll=1 timeout=30 max=8192 users=[] tg=unset |}]

let%expect_test "config: CN_MODEL env overrides config file model" =
  reset_config_env ();
  Unix.putenv "ANTHROPIC_KEY" "sk-test-key";
  Unix.putenv "CN_MODEL" "claude-opus-4";
  with_temp_hub
    ~config_json:{|{"runtime":{"model":"claude-haiku-4-latest"}}|}
    (fun hub_path -> show_config hub_path);
  [%expect {| model=claude-opus-4 poll=1 timeout=30 max=8192 users=[] tg=unset |}]


(* === Cn_runtime: daemon helpers (filesystem) ===

   Tests is_in_flight, is_queued, and enqueue_telegram using
   real temp hub directories with state/input.md, state/output.md,
   and state/queue/ files. *)

let with_daemon_hub f =
  let tmp = mk_temp_dir "cn_daemon_test" in
  let state_dir = Filename.concat tmp "state" in
  let queue_dir = Filename.concat state_dir "queue" in
  Cn_ffi.Fs.mkdir_p queue_dir;
  Fun.protect ~finally:(fun () ->
    (* Best-effort cleanup *)
    let rm_files dir =
      if Sys.file_exists dir then
        Sys.readdir dir |> Array.iter (fun f ->
          try Sys.remove (Filename.concat dir f) with _ -> ())
    in
    rm_files queue_dir;
    rm_files state_dir;
    (try Unix.rmdir queue_dir with _ -> ());
    (try Unix.rmdir state_dir with _ -> ());
    (try Unix.rmdir tmp with _ -> ()))
    (fun () -> f tmp)

(* --- is_in_flight --- *)

let%expect_test "is_in_flight: false when no input.md or output.md" =
  with_daemon_hub (fun hub_path ->
    Printf.printf "%b\n" (Cn_runtime.is_in_flight hub_path "tg-100"));
  [%expect {| false |}]

let%expect_test "is_in_flight: true when input.md has matching id" =
  with_daemon_hub (fun hub_path ->
    Cn_ffi.Fs.write (Cn_agent.input_path hub_path)
      "---\nid: tg-100\nfrom: telegram\n---\n\nHello";
    Printf.printf "%b\n" (Cn_runtime.is_in_flight hub_path "tg-100"));
  [%expect {| true |}]

let%expect_test "is_in_flight: false when input.md has different id" =
  with_daemon_hub (fun hub_path ->
    Cn_ffi.Fs.write (Cn_agent.input_path hub_path)
      "---\nid: tg-99\nfrom: telegram\n---\n\nOther message";
    Printf.printf "%b\n" (Cn_runtime.is_in_flight hub_path "tg-100"));
  [%expect {| false |}]

let%expect_test "is_in_flight: true when output.md has matching id" =
  with_daemon_hub (fun hub_path ->
    Cn_ffi.Fs.write (Cn_agent.output_path hub_path)
      "---\nid: tg-100\nfrom: telegram\n---\n\nReply text";
    Printf.printf "%b\n" (Cn_runtime.is_in_flight hub_path "tg-100"));
  [%expect {| true |}]

let%expect_test "is_in_flight: checks both input.md and output.md" =
  with_daemon_hub (fun hub_path ->
    (* input.md has different id, output.md has matching id *)
    Cn_ffi.Fs.write (Cn_agent.input_path hub_path)
      "---\nid: tg-50\nfrom: telegram\n---\n\nOld";
    Cn_ffi.Fs.write (Cn_agent.output_path hub_path)
      "---\nid: tg-100\nfrom: telegram\n---\n\nReply";
    Printf.printf "%b\n" (Cn_runtime.is_in_flight hub_path "tg-100"));
  [%expect {| true |}]

(* --- is_queued --- *)

let%expect_test "is_queued: false when queue is empty" =
  with_daemon_hub (fun hub_path ->
    Printf.printf "%b\n" (Cn_runtime.is_queued hub_path "tg-100"));
  [%expect {| false |}]

let%expect_test "is_queued: true when queue has matching file" =
  with_daemon_hub (fun hub_path ->
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T10-00-00Z-telegram-tg-100.md")
      "---\nid: tg-100\n---\n\nHello";
    Printf.printf "%b\n" (Cn_runtime.is_queued hub_path "tg-100"));
  [%expect {| true |}]

let%expect_test "is_queued: false when queue has different trigger" =
  with_daemon_hub (fun hub_path ->
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T10-00-00Z-telegram-tg-99.md")
      "---\nid: tg-99\n---\n\nOther";
    Printf.printf "%b\n" (Cn_runtime.is_queued hub_path "tg-100"));
  [%expect {| false |}]

let%expect_test "is_queued: finds correct file among multiple queue items" =
  with_daemon_hub (fun hub_path ->
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T09-00-00Z-telegram-tg-98.md")
      "---\nid: tg-98\n---\n\nFirst";
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T10-00-00Z-telegram-tg-100.md")
      "---\nid: tg-100\n---\n\nTarget";
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T11-00-00Z-telegram-tg-101.md")
      "---\nid: tg-101\n---\n\nThird";
    Printf.printf "%b\n" (Cn_runtime.is_queued hub_path "tg-100"));
  [%expect {| true |}]

(* --- enqueue_telegram --- *)

let%expect_test "enqueue_telegram: creates queue file with correct content" =
  with_daemon_hub (fun hub_path ->
    let msg : Cn_telegram.message = {
      message_id = 42; chat_id = 12345; user_id = 12345;
      username = Some "testuser"; text = "Hello agent";
      date = 1700000000; update_id = 100;
    } in
    Cn_runtime.enqueue_telegram hub_path msg;
    (* Verify file was created *)
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    let files = Cn_ffi.Fs.readdir queue_dir in
    Printf.printf "count=%d\n" (List.length files);
    (* Verify filename suffix *)
    let has_suffix = files |> List.exists (fun f ->
      Cn_lib.ends_with ~suffix:"-telegram-tg-100.md" f) in
    Printf.printf "suffix=%b\n" has_suffix;
    (* Verify content has frontmatter with trigger id *)
    let content = files |> List.hd |> fun f ->
      Cn_ffi.Fs.read (Cn_ffi.Path.join queue_dir f) in
    let meta = Cn_lib.parse_frontmatter content in
    let id = meta |> List.find_map (fun (k, v) ->
      if k = "id" then Some v else None) in
    let chat = meta |> List.find_map (fun (k, v) ->
      if k = "chat_id" then Some v else None) in
    Printf.printf "id=%s chat=%s\n"
      (Option.value ~default:"none" id)
      (Option.value ~default:"none" chat));
  [%expect {|
    count=1
    suffix=true
    id=tg-100 chat=12345
  |}]

let%expect_test "enqueue_telegram: idempotent — second enqueue is no-op" =
  with_daemon_hub (fun hub_path ->
    let msg : Cn_telegram.message = {
      message_id = 42; chat_id = 12345; user_id = 12345;
      username = Some "testuser"; text = "Hello agent";
      date = 1700000000; update_id = 200;
    } in
    Cn_runtime.enqueue_telegram hub_path msg;
    Cn_runtime.enqueue_telegram hub_path msg;
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    let files = Cn_ffi.Fs.readdir queue_dir in
    Printf.printf "count=%d\n" (List.length files));
  [%expect {| count=1 |}]

let%expect_test "enqueue_telegram: skips when already in-flight" =
  with_daemon_hub (fun hub_path ->
    (* Place trigger in state/input.md *)
    Cn_ffi.Fs.write (Cn_agent.input_path hub_path)
      "---\nid: tg-300\nfrom: telegram\n---\n\nIn progress";
    let msg : Cn_telegram.message = {
      message_id = 43; chat_id = 12345; user_id = 12345;
      username = None; text = "Hello";
      date = 1700000001; update_id = 300;
    } in
    Cn_runtime.enqueue_telegram hub_path msg;
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    let files = Cn_ffi.Fs.readdir queue_dir in
    Printf.printf "count=%d\n" (List.length files));
  [%expect {| count=0 |}]

(* --- post-ack guard: combined predicate behavior --- *)

let%expect_test "post-ack guard: queued → should NOT advance offset" =
  with_daemon_hub (fun hub_path ->
    let queue_dir = Cn_ffi.Path.join hub_path "state/queue" in
    Cn_ffi.Fs.write (Cn_ffi.Path.join queue_dir "2026-02-22T10-00-00Z-telegram-tg-400.md")
      "---\nid: tg-400\n---\n\nPending";
    let should_advance =
      not (Cn_runtime.is_queued hub_path "tg-400")
      && not (Cn_runtime.is_in_flight hub_path "tg-400") in
    Printf.printf "advance=%b\n" should_advance);
  [%expect {| advance=false |}]

let%expect_test "post-ack guard: in-flight → should NOT advance offset" =
  with_daemon_hub (fun hub_path ->
    Cn_ffi.Fs.write (Cn_agent.input_path hub_path)
      "---\nid: tg-400\nfrom: telegram\n---\n\nProcessing";
    let should_advance =
      not (Cn_runtime.is_queued hub_path "tg-400")
      && not (Cn_runtime.is_in_flight hub_path "tg-400") in
    Printf.printf "advance=%b\n" should_advance);
  [%expect {| advance=false |}]

let%expect_test "post-ack guard: neither queued nor in-flight → advance" =
  with_daemon_hub (fun hub_path ->
    let should_advance =
      not (Cn_runtime.is_queued hub_path "tg-400")
      && not (Cn_runtime.is_in_flight hub_path "tg-400") in
    Printf.printf "advance=%b\n" should_advance);
  [%expect {| advance=true |}]
