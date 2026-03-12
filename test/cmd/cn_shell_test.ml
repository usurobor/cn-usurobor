(** cn_shell_test: ppx_expect tests for cn_shell types + ops parser

    Tests the pure parsing core of the CN Shell capability runtime.
    All tests are deterministic — no I/O. *)

let show_manifest raw =
  let ops, receipts = Cn_shell.parse_ops_manifest raw in
  Printf.printf "ops=%d receipts=%d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  %s %s %s\n"
      r.Cn_shell.kind
      (Cn_shell.string_of_receipt_status r.Cn_shell.status)
      r.Cn_shell.reason
  ) receipts;
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  %s %s\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "none")
  ) ops

(* === Kind parsing === *)

let%expect_test "op_kind_of_string: observe kinds" =
  ["fs_read"; "fs_list"; "fs_glob"; "git_status"; "git_diff"; "git_log"; "git_grep"]
  |> List.iter (fun s ->
    match Cn_shell.op_kind_of_string s with
    | Some (Cn_shell.Observe _) -> Printf.printf "%s -> observe\n" s
    | Some (Cn_shell.Effect _) -> Printf.printf "%s -> effect (wrong!)\n" s
    | None -> Printf.printf "%s -> unknown (wrong!)\n" s);
  [%expect {|
    fs_read -> observe
    fs_list -> observe
    fs_glob -> observe
    git_status -> observe
    git_diff -> observe
    git_log -> observe
    git_grep -> observe
  |}]

let%expect_test "op_kind_of_string: effect kinds" =
  ["fs_write"; "fs_patch"; "git_branch"; "git_stage"; "git_commit"; "exec"]
  |> List.iter (fun s ->
    match Cn_shell.op_kind_of_string s with
    | Some (Cn_shell.Effect _) -> Printf.printf "%s -> effect\n" s
    | Some (Cn_shell.Observe _) -> Printf.printf "%s -> observe (wrong!)\n" s
    | None -> Printf.printf "%s -> unknown (wrong!)\n" s);
  [%expect {|
    fs_write -> effect
    fs_patch -> effect
    git_branch -> effect
    git_stage -> effect
    git_commit -> effect
    exec -> effect
  |}]

let%expect_test "op_kind_of_string: unknown kind" =
  (match Cn_shell.op_kind_of_string "frobnicate" with
   | None -> print_endline "none"
   | Some _ -> print_endline "some (wrong!)");
  [%expect {| none |}]

(* === Kind string roundtrip === *)

let%expect_test "string_of_op_kind roundtrip" =
  let kinds = [
    Cn_shell.Observe Cn_shell.Fs_read; Observe Fs_list; Observe Fs_glob;
    Observe Git_status; Observe Git_diff; Observe Git_log; Observe Git_grep;
    Effect Fs_write; Effect Fs_patch; Effect Git_branch; Effect Git_stage;
    Effect Git_commit; Effect Exec;
  ] in
  kinds |> List.iter (fun k ->
    let s = Cn_shell.string_of_op_kind k in
    match Cn_shell.op_kind_of_string s with
    | Some k2 when Cn_shell.string_of_op_kind k2 = s ->
      Printf.printf "%s -> roundtrip ok\n" s
    | _ -> Printf.printf "%s -> roundtrip FAILED\n" s);
  [%expect {|
    fs_read -> roundtrip ok
    fs_list -> roundtrip ok
    fs_glob -> roundtrip ok
    git_status -> roundtrip ok
    git_diff -> roundtrip ok
    git_log -> roundtrip ok
    git_grep -> roundtrip ok
    fs_write -> roundtrip ok
    fs_patch -> roundtrip ok
    git_branch -> roundtrip ok
    git_stage -> roundtrip ok
    git_commit -> roundtrip ok
    exec -> roundtrip ok
  |}]

(* === Manifest parsing: valid inputs === *)

let%expect_test "parse: single observe op" =
  let input = {|[{"kind":"fs_read","path":"src/main.ml"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  kind=%s op_id=%s\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  [%expect {|
    ops: 1, receipts: 0
      kind=fs_read op_id=obs-01
  |}]

let%expect_test "parse: single effect op with op_id" =
  let input = {|[{"kind":"fs_write","op_id":"write-1","path":"out.txt","content":"hi"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  kind=%s op_id=%s\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  [%expect {|
    ops: 1, receipts: 0
      kind=fs_write op_id=write-1
  |}]

let%expect_test "parse: mixed observe and effect" =
  let input = {|[{"kind":"fs_read","path":"a.ml"},{"kind":"fs_write","op_id":"w1","path":"b.ml","content":""}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  kind=%s op_id=%s\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  [%expect {|
    ops: 2, receipts: 0
      kind=fs_read op_id=obs-01
      kind=fs_write op_id=w1
  |}]

let%expect_test "parse: observe op with explicit op_id" =
  let input = {|[{"kind":"git_status","op_id":"my-status"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "op_id=%s\n"
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  [%expect {| op_id=my-status |}]

let%expect_test "parse: auto-assign observe ids sequentially" =
  let input = {|[{"kind":"fs_read","path":"a"},{"kind":"git_status"},{"kind":"fs_read","path":"b"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "%s: %s\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  [%expect {|
    fs_read: obs-01
    git_status: obs-02
    fs_read: obs-03
  |}]

let%expect_test "parse: fields preserved (minus kind and op_id)" =
  let input = {|[{"kind":"git_diff","op_id":"d1","rev":"HEAD~3..HEAD"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "fields: %d\n" (List.length op.Cn_shell.fields);
    List.iter (fun (k, v) ->
      Printf.printf "  %s=%s\n" k (Cn_json.to_string v)
    ) op.Cn_shell.fields
  ) ops;
  [%expect {|
    fields: 1
      rev="HEAD~3..HEAD"
  |}]

(* === Manifest parsing: denial cases === *)

let%expect_test "parse: unknown kind denied" =
  let input = {|[{"kind":"frobnicate","op_id":"x1"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  status=%s reason=%s op_id=%s kind=%s\n"
      (Cn_shell.string_of_receipt_status r.Cn_shell.status)
      r.Cn_shell.reason
      (match r.Cn_shell.op_id with Some id -> id | None -> "<null>")
      r.Cn_shell.kind
  ) receipts;
  [%expect {|
    ops: 0, receipts: 1
      status=denied reason=unknown_op_kind op_id=x1 kind=frobnicate
  |}]

let%expect_test "parse: missing op_id on effect denied" =
  let input = {|[{"kind":"fs_write","path":"out.txt","content":"hi"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  status=%s reason=%s\n"
      (Cn_shell.string_of_receipt_status r.Cn_shell.status)
      r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops: 0, receipts: 1
      status=denied reason=missing_op_id
  |}]

let%expect_test "parse: multi-line manifest denied" =
  let input = "[\n{\"kind\":\"fs_read\",\"path\":\"a\"}\n]" in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  reason=%s\n" r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops: 0, receipts: 1
      reason=ops_not_single_line
  |}]

let%expect_test "parse: duplicate op_id denied" =
  let input = {|[{"kind":"fs_read","op_id":"dup"},{"kind":"git_status","op_id":"dup"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  status=%s reason=%s op_id=%s\n"
      (Cn_shell.string_of_receipt_status r.Cn_shell.status)
      r.Cn_shell.reason
      (match r.Cn_shell.op_id with Some id -> id | None -> "<null>")
  ) receipts;
  [%expect {|
    ops: 1, receipts: 1
      status=denied reason=duplicate_op_id op_id=dup
  |}]

let%expect_test "parse: missing kind denied" =
  let input = {|[{"op_id":"no-kind","path":"a"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  reason=%s\n" r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops: 0, receipts: 1
      reason=missing_kind
  |}]

let%expect_test "parse: not an array denied" =
  let input = {|{"kind":"fs_read"}|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  reason=%s\n" r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops: 0, receipts: 1
      reason=ops_not_array
  |}]

let%expect_test "parse: invalid JSON denied" =
  let input = "not json at all" in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  (match receipts with
   | [r] -> Printf.printf "  starts with parse_error: %b\n"
     (String.length r.Cn_shell.reason > 12 &&
      String.sub r.Cn_shell.reason 0 12 = "parse_error:")
   | _ -> print_endline "unexpected receipt count");
  [%expect {|
    ops: 0, receipts: 1
      starts with parse_error: true
  |}]

(* === Mixed valid + denied ops === *)

let%expect_test "parse: mixed valid and denied in same manifest" =
  let input = {|[{"kind":"fs_read","path":"a"},{"kind":"frobnicate","op_id":"x"},{"kind":"fs_write","path":"b","content":""},{"kind":"git_status"}]|} in
  let ops, receipts = Cn_shell.parse_ops_manifest input in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  print_endline "--- valid ops ---";
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  %s (%s)\n"
      (Cn_shell.string_of_op_kind op.Cn_shell.kind)
      (match op.Cn_shell.op_id with Some id -> id | None -> "<none>")
  ) ops;
  print_endline "--- denied ---";
  List.iter (fun r ->
    Printf.printf "  %s: %s\n" r.Cn_shell.kind r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops: 2, receipts: 2
    --- valid ops ---
      fs_read (obs-01)
      git_status (obs-02)
    --- denied ---
      frobnicate: unknown_op_kind
      fs_write: missing_op_id
  |}]

(* === Classification === *)

let%expect_test "classify: separate observe and effect" =
  let input = {|[{"kind":"fs_read","path":"a"},{"kind":"fs_write","op_id":"w","path":"b","content":""}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  let observe, effect = Cn_shell.classify ops in
  Printf.printf "observe: %d, effect: %d\n" (List.length observe) (List.length effect);
  [%expect {| observe: 1, effect: 1 |}]

(* === Two-pass decision === *)

let%expect_test "needs_two_pass: observe ops trigger under auto" =
  let input = {|[{"kind":"fs_read","path":"a"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  Printf.printf "%b\n" (Cn_shell.needs_two_pass ~two_pass_mode:"auto" ops);
  [%expect {| true |}]

let%expect_test "needs_two_pass: effect-only does not trigger" =
  let input = {|[{"kind":"fs_write","op_id":"w","path":"a","content":""}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  Printf.printf "%b\n" (Cn_shell.needs_two_pass ~two_pass_mode:"auto" ops);
  [%expect {| false |}]

let%expect_test "needs_two_pass: off mode never triggers" =
  let input = {|[{"kind":"fs_read","path":"a"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  Printf.printf "%b\n" (Cn_shell.needs_two_pass ~two_pass_mode:"off" ops);
  [%expect {| false |}]

let%expect_test "needs_two_pass: empty ops does not trigger" =
  Printf.printf "%b\n" (Cn_shell.needs_two_pass ~two_pass_mode:"auto" []);
  [%expect {| false |}]

(* === Receipt serialization === *)

let%expect_test "receipt_to_json: basic structure" =
  let r = {
    Cn_shell.pass = "A"; op_id = Some "obs-01"; kind = "fs_read";
    status = Cn_shell.Ok_status; reason = "";
    start_time = "2026-03-05T09:12:01Z"; end_time = "2026-03-05T09:12:01Z";
    artifacts = [{
      Cn_shell.path = "state/artifacts/abc/obs-01.txt";
      hash = "sha256:deadbeef"; size = 1024;
    }];
  } in
  let json = Cn_shell.receipt_to_json r in
  print_endline (Cn_json.to_string json);
  [%expect {| {"pass":"A","op_id":"obs-01","kind":"fs_read","status":"ok","reason":"","start":"2026-03-05T09:12:01Z","end":"2026-03-05T09:12:01Z","artifacts":[{"path":"state/artifacts/abc/obs-01.txt","hash":"sha256:deadbeef","size":1024}]} |}]

let%expect_test "receipt_to_json: null op_id" =
  let r = {
    Cn_shell.pass = "A"; op_id = None; kind = "fs_write";
    status = Cn_shell.Denied; reason = "missing_op_id";
    start_time = ""; end_time = ""; artifacts = [];
  } in
  let json = Cn_shell.receipt_to_json r in
  (* Check op_id is null *)
  (match Cn_json.get "op_id" json with
   | Some Cn_json.Null -> print_endline "op_id is null"
   | _ -> print_endline "wrong");
  [%expect {| op_id is null |}]

let%expect_test "receipts_to_json: container format" =
  let r = Cn_shell.make_receipt ~pass:"A" ~op_id:(Some "obs-01")
    ~kind:"fs_read" ~status:Cn_shell.Ok_status ~reason:"" in
  let json = Cn_shell.receipts_to_json ~trigger_id:"20260305-abc" [r] in
  (match Cn_json.get_string "schema" json with
   | Some s -> Printf.printf "schema: %s\n" s
   | None -> print_endline "missing schema");
  (match Cn_json.get_string "trigger_id" json with
   | Some s -> Printf.printf "trigger_id: %s\n" s
   | None -> print_endline "missing trigger_id");
  (match Cn_json.get_list "receipts" json with
   | Some l -> Printf.printf "receipts: %d\n" (List.length l)
   | None -> print_endline "missing receipts");
  [%expect {|
    schema: cn.receipts.v1
    trigger_id: 20260305-abc
    receipts: 1
  |}]

(* === Shell config defaults === *)

let%expect_test "default_shell_config: two_pass defaults to auto" =
  Printf.printf "two_pass=%s\n" Cn_shell.default_shell_config.two_pass;
  [%expect {| two_pass=auto |}]

let%expect_test "default_shell_config values" =
  let c = Cn_shell.default_shell_config in
  Printf.printf "two_pass: %s\n" c.two_pass;
  Printf.printf "apply_mode: %s\n" c.apply_mode;
  Printf.printf "exec_enabled: %b\n" c.exec_enabled;
  Printf.printf "exec_allowlist: %d\n" (List.length c.exec_allowlist);
  Printf.printf "max_observe_ops: %d\n" c.max_observe_ops;
  Printf.printf "max_artifact_bytes: %d\n" c.max_artifact_bytes;
  Printf.printf "max_artifact_bytes_per_op: %d\n" c.max_artifact_bytes_per_op;
  [%expect {|
    two_pass: auto
    apply_mode: branch
    exec_enabled: false
    exec_allowlist: 0
    max_observe_ops: 10
    max_artifact_bytes: 65536
    max_artifact_bytes_per_op: 16384
  |}]

(* === Empty manifest === *)

let%expect_test "parse: empty array" =
  let ops, receipts = Cn_shell.parse_ops_manifest "[]" in
  Printf.printf "ops: %d, receipts: %d\n" (List.length ops) (List.length receipts);
  [%expect {| ops: 0, receipts: 0 |}]

(* === Phase validation === *)

let%expect_test "parse: matching phase accepted (observe)" =
  show_manifest {|[{"kind":"fs_read","phase":"observe","path":"README.md"}]|};
  [%expect {|
    ops=1 receipts=0
      fs_read obs-01
  |}]

let%expect_test "parse: matching phase accepted (effect)" =
  show_manifest {|[{"kind":"fs_write","op_id":"w1","phase":"effect","path":"a","content":""}]|};
  [%expect {|
    ops=1 receipts=0
      fs_write w1
  |}]

let%expect_test "parse: phase mismatch denied (observe kind with effect phase)" =
  show_manifest {|[{"kind":"fs_read","phase":"effect","path":"README.md"}]|};
  [%expect {|
    ops=0 receipts=1
      fs_read denied phase_mismatch
  |}]

let%expect_test "parse: phase mismatch denied (effect kind with observe phase)" =
  show_manifest {|[{"kind":"fs_write","op_id":"w1","phase":"observe","path":"a","content":""}]|};
  [%expect {|
    ops=0 receipts=1
      fs_write denied phase_mismatch
  |}]

let%expect_test "parse: invalid phase string denied" =
  show_manifest {|[{"kind":"fs_read","phase":"weird","path":"README.md"}]|};
  [%expect {|
    ops=0 receipts=1
      fs_read denied invalid_phase
  |}]

let%expect_test "parse: absent phase accepted (no validation)" =
  show_manifest {|[{"kind":"fs_read","path":"a"},{"kind":"fs_write","op_id":"w1","path":"b","content":""}]|};
  [%expect {|
    ops=2 receipts=0
      fs_read obs-01
      fs_write w1
  |}]

let%expect_test "parse: phase field stripped from fields list" =
  let input = {|[{"kind":"git_diff","op_id":"d1","phase":"observe","rev":"HEAD~3"}]|} in
  let ops, _ = Cn_shell.parse_ops_manifest input in
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "fields: %d\n" (List.length op.Cn_shell.fields);
    List.iter (fun (k, _) -> Printf.printf "  %s\n" k) op.Cn_shell.fields
  ) ops;
  [%expect {|
    fields: 1
      rev
  |}]

(* === v3.8.0: git_stage parsing === *)

let%expect_test "parse: git_stage with paths" =
  show_manifest {|[{"kind":"git_stage","op_id":"stage-1","paths":["src/main.ml","docs/README.md"]}]|};
  [%expect {|
    ops=1 receipts=0
      git_stage stage-1
  |}]

let%expect_test "parse: git_stage without paths (stage all)" =
  show_manifest {|[{"kind":"git_stage","op_id":"stage-2"}]|};
  [%expect {|
    ops=1 receipts=0
      git_stage stage-2
  |}]

let%expect_test "parse: git_stage missing op_id denied" =
  show_manifest {|[{"kind":"git_stage"}]|};
  [%expect {|
    ops=0 receipts=1
      git_stage denied missing_op_id
  |}]

let%expect_test "parse: git_stage + git_commit compose" =
  show_manifest {|[{"kind":"git_stage","op_id":"s1","paths":["src/a.ml"]},{"kind":"git_commit","op_id":"c1","message":"fix"}]|};
  [%expect {|
    ops=2 receipts=0
      git_stage s1
      git_commit c1
  |}]
