(** cn_capabilities.ml — CN Shell capability discovery block

    Runtime-generated ## CN Shell Capabilities block for the packed
    context, per AGENT-RUNTIME v3.3.6.

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
    Pure function: config in, string out.
    v3.4: optional asset summary appended for cognitive substrate awareness. *)
let render ?(assets : Cn_assets.asset_summary option) ?(peers : string list = []) (config : Cn_shell.shell_config) =
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

  (* Canonical emission examples — always present so the model sees
     the exact ops: syntax on every wake-up *)
  Buffer.add_string buf "syntax: frontmatter key `ops:` with a single-line JSON array\n";
  Buffer.add_string buf
    "example_observe: ops: [{\"kind\":\"fs_read\",\"path\":\"README.md\"}]\n";
  if effects_enabled then
    Buffer.add_string buf
      "example_effect: ops: [{\"kind\":\"fs_patch\",\"op_id\":\"patch-001\",\"path\":\"README.md\",\"unified_diff\":\"...\"}]\n";

  (* Coordination op examples — send, surface, done go in frontmatter *)
  Buffer.add_string buf "coordination_ops: send, reply, done, ack, fail, delegate, defer, delete, surface\n";
  Buffer.add_string buf "example_send: send: sigma|Found issue in sync module\n";
  Buffer.add_string buf "example_surface: surface: Boot drain missing from daemon path\n";
  Buffer.add_string buf "CRITICAL: ops and coordination ops MUST be in YAML frontmatter. Never describe them in body text or code blocks.\n";

  (* Known peers — valid targets for send: and delegate: *)
  if peers <> [] then begin
    Buffer.add_string buf (Printf.sprintf "known_peers: %s\n"
      (String.concat ", " peers))
  end;

  (* v3.5: Cognitive asset summary — unified package model *)
  (match assets with
   | None -> ()
   | Some a ->
       Buffer.add_string buf "\n### Cognitive Assets\n";
       (match a.profile with
        | Some p -> Buffer.add_string buf (Printf.sprintf "- profile: %s\n" p)
        | None -> ());
       Buffer.add_string buf (Printf.sprintf
         "- doctrine: %d files (always-on)\n" a.doctrine_count);
       Buffer.add_string buf (Printf.sprintf
         "- mindsets: %d (always-on)\n" a.mindset_count);
       if a.packages <> [] then begin
         Buffer.add_string buf "- packages:\n";
         a.packages |> List.iter (fun (name, skill_count) ->
           Buffer.add_string buf (Printf.sprintf
             "  - %s (%d skills)\n" name skill_count))
       end;
       if a.hub_overrides_mindsets > 0 || a.hub_overrides_skills > 0 then
         Buffer.add_string buf (Printf.sprintf
           "- hub-local overrides: %d mindsets, %d skills\n"
           a.hub_overrides_mindsets a.hub_overrides_skills));

  Buffer.contents buf
