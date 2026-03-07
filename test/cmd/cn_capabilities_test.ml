(** cn_capabilities_test: ppx_expect tests for capability discovery block

    Tests the runtime-generated ## CN Shell Capabilities block per
    AGENT-RUNTIME-v3.3.6: deterministic ordering, config-dependent
    content, budget reflection, and conditional field omission. *)

(* ============================================================ *)
(* === DEFAULT CONFIG                                         === *)
(* ============================================================ *)

let default_config = {
  Cn_shell.two_pass = "auto";
  apply_mode = "branch";
  exec_enabled = false;
  exec_allowlist = [];
  max_observe_ops = 10;
  max_artifact_bytes = 65536;
  max_artifact_bytes_per_op = 16384;
}

let%expect_test "default config: exec disabled, apply_mode branch" =
  print_string (Cn_capabilities.render default_config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    effect: fs_write, fs_patch, git_branch, git_commit
    apply_mode: branch
    exec_enabled: false
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]

(* ============================================================ *)
(* === EXEC ENABLED WITH ALLOWLIST                            === *)
(* ============================================================ *)

let%expect_test "exec enabled: exec in effects + allowlist shown" =
  let config = { default_config with exec_enabled = true;
                 exec_allowlist = ["make"; "dune"; "ocamlfind"] } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    effect: fs_write, fs_patch, git_branch, git_commit, exec
    apply_mode: branch
    exec_enabled: true
    exec_allowlist: make, dune, ocamlfind
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]

let%expect_test "exec enabled with empty allowlist" =
  let config = { default_config with exec_enabled = true; exec_allowlist = [] } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    effect: fs_write, fs_patch, git_branch, git_commit, exec
    apply_mode: branch
    exec_enabled: true
    exec_allowlist: (none)
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]

(* ============================================================ *)
(* === APPLY_MODE OFF: OBSERVE-ONLY                           === *)
(* ============================================================ *)

let%expect_test "apply_mode off: no effect kinds listed" =
  let config = { default_config with apply_mode = "off" } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    apply_mode: off
    exec_enabled: false
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}] |}]

(* ============================================================ *)
(* === APPLY_MODE WORKING_TREE                                === *)
(* ============================================================ *)

let%expect_test "apply_mode working_tree: effects included" =
  let config = { default_config with apply_mode = "working_tree" } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    effect: fs_write, fs_patch, git_branch, git_commit
    apply_mode: working_tree
    exec_enabled: false
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]

(* ============================================================ *)
(* === CUSTOM BUDGETS                                         === *)
(* ============================================================ *)

let%expect_test "custom budgets reflected in block" =
  let config = { default_config with
                 max_observe_ops = 20;
                 max_artifact_bytes = 131072;
                 max_artifact_bytes_per_op = 32768 } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    effect: fs_write, fs_patch, git_branch, git_commit
    apply_mode: branch
    exec_enabled: false
    budgets: max_artifact_bytes=131072, max_artifact_bytes_per_op=32768, max_observe_ops=20
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]

(* ============================================================ *)
(* === DETERMINISTIC ORDERING                                 === *)
(* ============================================================ *)

let%expect_test "deterministic: identical config → identical output" =
  let c1 = Cn_capabilities.render default_config in
  let c2 = Cn_capabilities.render default_config in
  Printf.printf "identical: %b\n" (c1 = c2);
  [%expect {| identical: true |}]

let%expect_test "observe kinds follow declaration order" =
  (* The observe line should always be: fs_read, fs_list, fs_glob,
     git_status, git_diff, git_log, git_grep — matching the type
     declaration order in cn_shell.ml *)
  let block = Cn_capabilities.render default_config in
  let lines = String.split_on_char '\n' block in
  let observe_line = List.find_opt (fun l ->
    String.length l >= 8 && String.sub l 0 8 = "observe:"
  ) lines in
  (match observe_line with
   | Some l -> print_endline l
   | None -> print_endline "not found");
  [%expect {| observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep |}]

let%expect_test "effect kinds follow declaration order" =
  let config = { default_config with exec_enabled = true } in
  let block = Cn_capabilities.render config in
  let lines = String.split_on_char '\n' block in
  let effect_line = List.find_opt (fun l ->
    String.length l >= 7 && String.sub l 0 7 = "effect:"
  ) lines in
  (match effect_line with
   | Some l -> print_endline l
   | None -> print_endline "not found");
  [%expect {| effect: fs_write, fs_patch, git_branch, git_commit, exec |}]

let%expect_test "budget keys in lexical order" =
  let block = Cn_capabilities.render default_config in
  let lines = String.split_on_char '\n' block in
  let budget_line = List.find_opt (fun l ->
    String.length l >= 8 && String.sub l 0 8 = "budgets:"
  ) lines in
  (match budget_line with
   | Some l -> print_endline l
   | None -> print_endline "not found");
  [%expect {| budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10 |}]

(* ============================================================ *)
(* === EDGE CASE: APPLY_MODE OFF + EXEC ENABLED               === *)
(* ============================================================ *)

let%expect_test "apply_mode off + exec enabled: no effects at all" =
  let config = { default_config with apply_mode = "off"; exec_enabled = true;
                 exec_allowlist = ["make"] } in
  print_string (Cn_capabilities.render config);
  [%expect {|
    ## CN Shell Capabilities

    observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
    apply_mode: off
    exec_enabled: false
    budgets: max_artifact_bytes=65536, max_artifact_bytes_per_op=16384, max_observe_ops=10
    max_passes: 2
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}] |}]

(* ============================================================ *)
(* === CANONICAL OPS EXAMPLES IN BLOCK                        === *)
(* ============================================================ *)

let%expect_test "capabilities block includes canonical ops examples" =
  let block = Cn_capabilities.render default_config in
  let lines = String.split_on_char '\n' block in
  let syntax =
    List.find_opt (fun l -> String.length l >= 7 && String.sub l 0 7 = "syntax:" ) lines
  in
  let observe =
    List.find_opt
      (fun l -> String.length l >= 16 && String.sub l 0 16 = "example_observe:" )
      lines
  in
  let effect =
    List.find_opt
      (fun l -> String.length l >= 15 && String.sub l 0 15 = "example_effect:" )
      lines
  in
  (match syntax with Some l -> print_endline l | None -> print_endline "syntax: missing");
  (match observe with Some l -> print_endline l | None -> print_endline "example_observe: missing");
  (match effect with Some l -> print_endline l | None -> print_endline "example_effect: missing");
  [%expect {|
    syntax: frontmatter key `ops:` with a single-line JSON array
    example_observe: ops: [{"kind":"fs_read","path":"README.md"}]
    example_effect: ops: [{"kind":"fs_patch","op_id":"patch-001","path":"README.md","unified_diff":"..."}] |}]
