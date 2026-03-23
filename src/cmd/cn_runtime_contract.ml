(** cn_runtime_contract.ml — Runtime Contract (v3.10.0, Issue #56)

    Emits a structured self-model at every wake so the agent can
    determine its version, packages, overrides, workspace layout,
    and capabilities from packed context alone.

    Three sub-blocks:
    - self_model: who the agent is (version, hub, packages, overrides)
    - workspace: what world it inhabits (directories, writable/protected)
    - capabilities: what the runtime can do (observe/effect ABI, budgets)

    Body scanning for self-knowledge becomes a contract bug, not normal. *)

(* === Types === *)

type package_info = {
  name : string;
  doctrine_count : int;
  mindset_count : int;
  skill_count : int;
}

type override_info = {
  doctrine : string list;
  mindsets : string list;
  skills : string list;
}

type runtime_contract = {
  cn_version : string;
  hub_name : string;
  profile : string;
  packages : package_info list;
  overrides : override_info;
  workspace_dirs : (string * string) list;
  writable : string list;
  protected : string list;
  peers : string list;
  capabilities_text : string;
}

(* === Gather === *)

(** List .md files in a directory, returning hub-relative paths. *)
let list_md_relative ~hub_path dir =
  let full = Cn_ffi.Path.join hub_path dir in
  if not (Cn_ffi.Fs.exists full) then []
  else
    try
      Cn_ffi.Fs.readdir full
      |> List.filter (fun f -> Filename.check_suffix f ".md")
      |> List.sort String.compare
      |> List.map (fun f -> dir ^ "/" ^ f)
    with _ -> []

(** List SKILL.md overrides under a directory, returning hub-relative paths. *)
let list_skill_overrides ~hub_path dir =
  let full = Cn_ffi.Path.join hub_path dir in
  if not (Cn_ffi.Fs.exists full) then []
  else
    Cn_assets.walk_skills full
    |> List.map (fun (rel, _content) -> dir ^ "/" ^ rel ^ "/SKILL.md")

(** Build the runtime contract from current hub state. *)
let gather ~hub_path ~(shell_config : Cn_shell.shell_config)
      ~(assets : Cn_assets.asset_summary) ~peers =
  let hub_name = Filename.basename hub_path in

  (* Package info: walk installed packages for detail *)
  let packages =
    Cn_assets.list_installed_packages hub_path
    |> List.map (fun (pkg_name, pkg_path) ->
      let doctrine_dir = Cn_ffi.Path.join pkg_path "doctrine" in
      let doctrine_count =
        if Cn_ffi.Fs.exists doctrine_dir then
          (try Cn_ffi.Fs.readdir doctrine_dir
               |> List.filter (fun f -> Filename.check_suffix f ".md")
               |> List.length with _ -> 0)
        else 0
      in
      let mindsets_dir = Cn_ffi.Path.join pkg_path "mindsets" in
      let mindset_count =
        if Cn_ffi.Fs.exists mindsets_dir then
          (try Cn_ffi.Fs.readdir mindsets_dir
               |> List.filter (fun f -> Filename.check_suffix f ".md")
               |> List.length with _ -> 0)
        else 0
      in
      let skills_dir = Cn_ffi.Path.join pkg_path "skills" in
      let skill_count = List.length (Cn_assets.walk_skills skills_dir) in
      { name = pkg_name; doctrine_count; mindset_count; skill_count })
  in

  (* Override info: scan agent/ directories *)
  let doctrine_overrides =
    Cn_assets.list_installed_packages hub_path
    |> List.concat_map (fun (pkg_name, _) ->
      list_md_relative ~hub_path
        (Printf.sprintf "agent/doctrine/%s" pkg_name))
  in
  let mindset_overrides =
    Cn_assets.list_installed_packages hub_path
    |> List.concat_map (fun (pkg_name, _) ->
      list_md_relative ~hub_path
        (Printf.sprintf "agent/mindsets/%s" pkg_name))
  in
  let skill_overrides =
    Cn_assets.list_installed_packages hub_path
    |> List.concat_map (fun (pkg_name, _) ->
      list_skill_overrides ~hub_path
        (Printf.sprintf "agent/skills/%s" pkg_name))
  in

  (* Workspace: check which canonical directories exist *)
  let check_dir rel =
    let full = Cn_ffi.Path.join hub_path rel in
    if Cn_ffi.Fs.exists full then Some (rel, rel) else None
  in
  let workspace_dirs = [
    "spec"; "agent"; "threads/reflections";
    "state"; ".cn/vendor/packages"; "docs"; "src";
  ] |> List.filter_map check_dir in

  let profile = match assets.profile with
    | Some p -> p | None -> "engineer"
  in

  let capabilities_text =
    Cn_capabilities.render ~assets ~peers shell_config
  in

  {
    cn_version = Cn_lib.version;
    hub_name;
    profile;
    packages;
    overrides = {
      doctrine = doctrine_overrides;
      mindsets = mindset_overrides;
      skills = skill_overrides;
    };
    workspace_dirs;
    (* Derive protected from Cn_sandbox — single source of truth *)
    writable = ["src/**"; "docs/**"; "agent/**"; "threads/**"];
    protected =
      (Cn_sandbox.default_denylist |> List.map (fun prefix ->
        (* "state/" → "state/**" *)
        if String.length prefix > 0 && prefix.[String.length prefix - 1] = '/' then
          String.sub prefix 0 (String.length prefix - 1) ^ "/**"
        else prefix ^ "/**"))
      @ Cn_sandbox.protected_files;
    peers;
    capabilities_text;
  }

(* === Render markdown for packed context === *)

(** Render the contract as a markdown section for the LLM system prompt.
    Deterministic field ordering for prompt-cache stability. *)
let render_markdown (c : runtime_contract) =
  let buf = Buffer.create 2048 in
  Buffer.add_string buf "## Runtime Contract\n\n";

  (* Authority declaration — issue #63: conversation history must not
     override the current contract. This preamble is the agent-facing
     instruction that closes the stale-history gap. *)
  Buffer.add_string buf "**Authority:** This contract is the authoritative source for version, \
packages, workspace layout, and capabilities. It is emitted fresh at every wake. \
If conversation history contains contradictory claims (e.g. a directory that \
was absent in a prior session), this contract supersedes them.\n\n";

  (* Self Model *)
  Buffer.add_string buf "### Self Model\n";
  Buffer.add_string buf (Printf.sprintf "cn_version: %s\n" c.cn_version);
  Buffer.add_string buf (Printf.sprintf "hub_name: %s\n" c.hub_name);
  Buffer.add_string buf (Printf.sprintf "profile: %s\n" c.profile);

  Buffer.add_string buf "installed_packages:";
  if c.packages = [] then Buffer.add_string buf " (none)\n"
  else begin
    Buffer.add_char buf '\n';
    List.iter (fun (p : package_info) ->
      Buffer.add_string buf (Printf.sprintf "  - %s (%d doctrine, %d mindsets, %d skills)\n"
        p.name p.doctrine_count p.mindset_count p.skill_count)
    ) c.packages
  end;

  let total_overrides = List.length c.overrides.doctrine
    + List.length c.overrides.mindsets
    + List.length c.overrides.skills in
  Buffer.add_string buf (Printf.sprintf "active_overrides: %d" total_overrides);
  if total_overrides > 0 then begin
    Buffer.add_char buf '\n';
    List.iter (fun p ->
      Buffer.add_string buf (Printf.sprintf "  - %s\n" p)
    ) (c.overrides.doctrine @ c.overrides.mindsets @ c.overrides.skills)
  end else
    Buffer.add_string buf " (none)\n";

  (* Workspace *)
  Buffer.add_string buf "\n### Workspace\n";
  Buffer.add_string buf "root: .\n";
  List.iter (fun (rel, _) ->
    Buffer.add_string buf (Printf.sprintf "%s: %s/\n" rel rel)
  ) c.workspace_dirs;
  Buffer.add_string buf (Printf.sprintf "writable: %s\n"
    (String.concat ", " c.writable));
  Buffer.add_string buf (Printf.sprintf "protected: %s\n"
    (String.concat ", " c.protected));

  (* Capabilities — delegate to existing renderer *)
  Buffer.add_string buf "\n";
  Buffer.add_string buf c.capabilities_text;

  Buffer.contents buf

(* === JSON persistence === *)

(** Convert the contract to JSON for state/runtime-contract.json.
    Capabilities read from Cn_capabilities (single source of truth, §4.5.2). *)
let to_json ~(shell_config : Cn_shell.shell_config) (c : runtime_contract) =
  let effects_enabled = shell_config.apply_mode <> "off" in
  let effective_exec = effects_enabled && shell_config.exec_enabled in
  let effect_kinds =
    if not effects_enabled then []
    else if effective_exec then Cn_capabilities.effect_kinds_base @ ["exec"]
    else Cn_capabilities.effect_kinds_base
  in
  let str s = Cn_json.String s in
  Cn_json.Object [
    "schema", str "cn.runtime_contract.v1";
    "self_model", Cn_json.Object [
      "cn_version", str c.cn_version;
      "hub_name", str c.hub_name;
      "profile", str c.profile;
      "installed_packages", Cn_json.Array (List.map (fun (p : package_info) ->
        Cn_json.Object [
          "name", str p.name;
          "doctrine_count", Cn_json.Int p.doctrine_count;
          "mindset_count", Cn_json.Int p.mindset_count;
          "skill_count", Cn_json.Int p.skill_count;
        ]) c.packages);
      "active_overrides", Cn_json.Object [
        "doctrine", Cn_json.Array (List.map str c.overrides.doctrine);
        "mindsets", Cn_json.Array (List.map str c.overrides.mindsets);
        "skills", Cn_json.Array (List.map str c.overrides.skills);
      ];
    ];
    "workspace", Cn_json.Object [
      "root", str ".";
      "directories", Cn_json.Array (List.map (fun (rel, _) -> str rel) c.workspace_dirs);
      "writable", Cn_json.Array (List.map str c.writable);
      "protected", Cn_json.Array (List.map str c.protected);
    ];
    "peers", Cn_json.Array (List.map str c.peers);
    "capabilities", Cn_json.Object ([
      "observe", Cn_json.Array (List.map str Cn_capabilities.observe_kinds);
      "effect", Cn_json.Array (List.map str effect_kinds);
      "apply_mode", str shell_config.apply_mode;
      "exec_enabled", Cn_json.Bool effective_exec;
      "max_passes", Cn_json.Int shell_config.max_passes;
      "budgets", Cn_json.Object [
        "max_artifact_bytes", Cn_json.Int shell_config.max_artifact_bytes;
        "max_artifact_bytes_per_op", Cn_json.Int shell_config.max_artifact_bytes_per_op;
        "max_observe_ops", Cn_json.Int shell_config.max_observe_ops;
        "max_total_artifact_bytes", Cn_json.Int shell_config.max_total_artifact_bytes;
        "max_total_ops", Cn_json.Int shell_config.max_total_ops;
      ];
    ] @ (if effective_exec && shell_config.exec_allowlist <> [] then
      ["exec_allowlist", Cn_json.Array (List.map str shell_config.exec_allowlist)]
    else []));
  ]

(** Write the contract to state/runtime-contract.json. *)
let write ~hub_path ~shell_config (c : runtime_contract) =
  let path = Cn_ffi.Path.join hub_path "state/runtime-contract.json" in
  Cn_ffi.Fs.ensure_dir (Filename.dirname path);
  Cn_ffi.Fs.write path (Cn_json.to_string (to_json ~shell_config c))
