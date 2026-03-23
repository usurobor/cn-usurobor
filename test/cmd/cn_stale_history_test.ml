(** cn_stale_history_test: ppx_expect tests for stale history handling (issue #63)

    Tests:
    - Conversation entries from current version load without annotation
    - Conversation entries from prior version get staleness prefix
    - Entries without cn_version (pre-versioning) are treated as stale
    - Staleness prefix references the Runtime Contract as authoritative *)

(* === Helpers === *)

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

let with_test_hub f =
  let hub = mk_temp_dir "cn-stale-test" in
  let dirs = ["state"; "spec"; ".cn";
              ".cn/vendor/packages/cnos.core@1.0.0/doctrine";
              ".cn/vendor/packages/cnos.core@1.0.0/mindsets"] in
  List.iter (fun d ->
    Cn_ffi.Fs.ensure_dir (Filename.concat hub d)
  ) dirs;
  let touch path content =
    let full = Filename.concat hub path in
    Cn_ffi.Fs.ensure_dir (Filename.dirname full);
    let oc = open_out full in
    output_string oc content;
    close_out oc
  in
  (* Minimal doctrine so validate_packages passes *)
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/FOUNDATIONS.md" "# FOUNDATIONS";
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/COHERENCE.md" "# COHERENCE";
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/CAP.md" "# CAP";
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/CA-CONDUCT.md" "# CA-CONDUCT";
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/CBP.md" "# CBP";
  touch ".cn/vendor/packages/cnos.core@1.0.0/doctrine/AGENT-OPS.md" "# AGENT-OPS";
  touch ".cn/vendor/packages/cnos.core@1.0.0/mindsets/ENGINEERING.md" "# ENGINEERING";
  touch ".cn/vendor/packages/cnos.core@1.0.0/mindsets/WRITING.md" "# WRITING";
  touch "spec/SOUL.md" "# Identity";
  touch "spec/USER.md" "# User";
  Fun.protect ~finally:(fun () ->
    let rec rm path =
      if Sys.is_directory path then begin
        Sys.readdir path |> Array.iter (fun entry ->
          rm (Filename.concat path entry)
        );
        Unix.rmdir path
      end else
        Sys.remove path
    in
    (try rm hub with _ -> ())
  ) (fun () -> f hub)

let write_conversation hub entries =
  let path = Filename.concat hub "state/conversation.json" in
  let json = Cn_json.Array entries in
  Cn_ffi.Fs.write path (Cn_json.to_string json ^ "\n")

(* === Tests === *)

let%expect_test "current version entries load without annotation" =
  with_test_hub (fun hub ->
    let current = Cn_lib.version in
    write_conversation hub [
      Cn_json.Object [
        "role", Cn_json.String "user";
        "content", Cn_json.String "hello";
        "cn_version", Cn_json.String current];
      Cn_json.Object [
        "role", Cn_json.String "assistant";
        "content", Cn_json.String "hi there";
        "cn_version", Cn_json.String current];
    ];
    let turns = Cn_context.load_conversation_turns ~hub_path:hub ~n:10 in
    List.iter (fun (t : Cn_llm.message_turn) ->
      let has_stale = Cn_orchestrator.contains_sub t.content "[stale:" in
      Printf.printf "%s: stale=%b\n" t.role has_stale
    ) turns);
  [%expect {|
    user: stale=false
    assistant: stale=false |}]

let%expect_test "prior version entries get staleness prefix" =
  with_test_hub (fun hub ->
    write_conversation hub [
      Cn_json.Object [
        "role", Cn_json.String "user";
        "content", Cn_json.String "where is agent/?";
        "cn_version", Cn_json.String "0.0.1"];
      Cn_json.Object [
        "role", Cn_json.String "assistant";
        "content", Cn_json.String "agent/ was not found";
        "cn_version", Cn_json.String "0.0.1"];
    ];
    let turns = Cn_context.load_conversation_turns ~hub_path:hub ~n:10 in
    List.iter (fun (t : Cn_llm.message_turn) ->
      let has_stale = Cn_orchestrator.contains_sub t.content "[stale:" in
      let has_authority = Cn_orchestrator.contains_sub t.content "Runtime Contract is authoritative" in
      Printf.printf "%s: stale=%b authority_ref=%b\n" t.role has_stale has_authority
    ) turns);
  [%expect {|
    user: stale=true authority_ref=true
    assistant: stale=true authority_ref=true |}]

let%expect_test "entries without cn_version are stale" =
  with_test_hub (fun hub ->
    write_conversation hub [
      Cn_json.Object [
        "role", Cn_json.String "user";
        "content", Cn_json.String "old message"];
    ];
    let turns = Cn_context.load_conversation_turns ~hub_path:hub ~n:10 in
    List.iter (fun (t : Cn_llm.message_turn) ->
      let has_stale = Cn_orchestrator.contains_sub t.content "[stale:" in
      let has_unknown = Cn_orchestrator.contains_sub t.content "unknown" in
      Printf.printf "%s: stale=%b unknown_version=%b\n" t.role has_stale has_unknown
    ) turns);
  [%expect {| user: stale=true unknown_version=true |}]

let%expect_test "staleness prefix preserves original content" =
  with_test_hub (fun hub ->
    write_conversation hub [
      Cn_json.Object [
        "role", Cn_json.String "assistant";
        "content", Cn_json.String "agent/ directory does not exist";
        "cn_version", Cn_json.String "3.11.0"];
    ];
    let turns = Cn_context.load_conversation_turns ~hub_path:hub ~n:10 in
    List.iter (fun (t : Cn_llm.message_turn) ->
      let has_original = Cn_orchestrator.contains_sub t.content
        "agent/ directory does not exist" in
      Printf.printf "original_preserved: %b\n" has_original
    ) turns);
  [%expect {| original_preserved: true |}]
