(** cn_capabilities.ml — CN Shell capability discovery block

    Runtime-generated ## CN Shell Capabilities block for the packed
    context, per AGENT-RUNTIME-v3.3.6.

    Placed after skills, before conversation history. Declares the
    syscall ABI at call time so the agent knows what the runtime
    supports before proposing ops.

    Ordering invariants (maximizes prompt cache hits):
    - Observe kinds in declaration order (fs_read → git_grep)
    - Effect kinds in declaration order (fs_write → exec)
    - Budget keys in lexical order

    Config-dependent rules:
    - apply_mode=off → omit all effect kinds (observe-only)
    - exec_enabled=false → omit exec from effects, omit exec_allowlist
    - Budgets reflect current runtime config, not hardcoded defaults
    - max_passes is always 2 (hard limit, not configurable) *)

(* === Fixed kind lists in declaration order === *)

let observe_kinds =
  ["fs_read"; "fs_list"; "fs_glob"; "git_status"; "git_diff"; "git_log"; "git_grep"]

let effect_kinds_base =
  ["fs_write"; "fs_patch"; "git_branch"; "git_commit"]

(* === Render === *)

(** Render the capabilities block as a markdown string.
    Pure function: config in, string out. *)
let render (config : Cn_shell.shell_config) =
  let buf = Buffer.create 512 in
  Buffer.add_string buf "## CN Shell Capabilities\n\n";

  (* Observe kinds: always all, in declaration order *)
  Buffer.add_string buf "observe: ";
  Buffer.add_string buf (String.concat ", " observe_kinds);
  Buffer.add_char buf '\n';

  (* Effect kinds: conditional on apply_mode *)
  let effects_enabled = config.apply_mode <> "off" in
  if effects_enabled then begin
    let effect_kinds =
      if config.exec_enabled then effect_kinds_base @ ["exec"]
      else effect_kinds_base
    in
    Buffer.add_string buf "effect: ";
    Buffer.add_string buf (String.concat ", " effect_kinds);
    Buffer.add_char buf '\n'
  end;

  (* apply_mode *)
  Buffer.add_string buf (Printf.sprintf "apply_mode: %s\n" config.apply_mode);

  (* exec_enabled: show actual state (off if apply_mode=off overrides) *)
  let effective_exec = effects_enabled && config.exec_enabled in
  Buffer.add_string buf (Printf.sprintf "exec_enabled: %b\n" effective_exec);

  (* exec_allowlist: only when exec is effectively enabled *)
  if effective_exec then begin
    let allowlist_str =
      if config.exec_allowlist = [] then "(none)"
      else String.concat ", " config.exec_allowlist
    in
    Buffer.add_string buf (Printf.sprintf "exec_allowlist: %s\n" allowlist_str)
  end;

  (* Budgets: keys in lexical order *)
  Buffer.add_string buf (Printf.sprintf
    "budgets: max_artifact_bytes=%d, max_artifact_bytes_per_op=%d, max_observe_ops=%d\n"
    config.max_artifact_bytes config.max_artifact_bytes_per_op config.max_observe_ops);

  (* max_passes: hard limit, always 2 *)
  Buffer.add_string buf "max_passes: 2\n";

  Buffer.contents buf
