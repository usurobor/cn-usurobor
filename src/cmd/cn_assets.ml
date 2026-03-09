(** cn_assets.ml — Cognitive Asset Resolver (CAR)

    Unified two-layer asset resolver:
      Layer 1: Installed packages    (.cn/vendor/packages/<name>@<version>/)
      Layer 2: Hub-local overrides   (agent/<class>/<package>/)

    Resolution priority: hub-local override > installed package.
    Wake-up reads only local files — no network access.

    Three cognitive strata:
    1. Doctrine — always-on core principles (from cnos.core, not scored)
    2. Mindsets — always-on behavioral frames (from all packages, not scored)
    3. Skills — task-specific, keyword-scored, bounded *)

(* === Types === *)

type asset_source = Package of string | Hub_local

type asset_summary = {
  profile : string option;
  doctrine_count : int;
  mindset_count : int;
  packages : (string * int) list;  (* (pkg_dir_name, skill_count) *)
  hub_overrides_mindsets : int;
  hub_overrides_skills : int;
}

(* === Paths === *)

let vendor_packages_path hub_path =
  Cn_ffi.Path.join hub_path ".cn/vendor/packages"

(** Find the installed directory for a named package (e.g. "cnos.core").
    Returns the first match under .cn/vendor/packages/<name>@*/. *)
let find_installed_package hub_path pkg_name =
  let pkg_root = vendor_packages_path hub_path in
  if not (Cn_ffi.Fs.exists pkg_root) then None
  else
    try
      Cn_ffi.Fs.readdir pkg_root
      |> List.sort String.compare
      |> List.find_opt (fun dir_name ->
        match String.index_opt dir_name '@' with
        | Some i -> String.sub dir_name 0 i = pkg_name
        | None -> dir_name = pkg_name)
      |> Option.map (fun dir_name -> Cn_ffi.Path.join pkg_root dir_name)
    with _ -> None

(** List all installed package directories. Returns (pkg_name, pkg_path) pairs. *)
let list_installed_packages hub_path =
  let pkg_root = vendor_packages_path hub_path in
  if not (Cn_ffi.Fs.exists pkg_root) then []
  else
    try
      Cn_ffi.Fs.readdir pkg_root
      |> List.sort String.compare
      |> List.map (fun dir_name ->
        let pkg_name = match String.index_opt dir_name '@' with
          | Some i -> String.sub dir_name 0 i
          | None -> dir_name
        in
        (pkg_name, Cn_ffi.Path.join pkg_root dir_name))
    with _ -> []

(* Hub override paths — namespaced by package *)
let hub_doctrine_override_path hub_path pkg_name =
  Cn_ffi.Path.join hub_path (Printf.sprintf "agent/doctrine/%s" pkg_name)

let hub_mindsets_override_path hub_path pkg_name =
  Cn_ffi.Path.join hub_path (Printf.sprintf "agent/mindsets/%s" pkg_name)

let hub_skills_override_path hub_path pkg_name =
  Cn_ffi.Path.join hub_path (Printf.sprintf "agent/skills/%s" pkg_name)

(** Flat hub override paths — backward compat for hubs that use
    agent/mindsets/*.md and agent/skills/... without package namespace. *)
let hub_flat_mindsets_path hub_path =
  Cn_ffi.Path.join hub_path "agent/mindsets"

let hub_flat_skills_path hub_path =
  Cn_ffi.Path.join hub_path "agent/skills"

(* === Helpers === *)

let read_opt path =
  if Cn_ffi.Fs.exists path then
    (try Cn_ffi.Fs.read path with _ -> "")
  else ""

(** Substring containment check (no Str dependency). *)
let contains_sub (s : string) (sub : string) : bool =
  let n = String.length s in
  let m = String.length sub in
  if m = 0 then true
  else if m > n then false
  else
    let rec loop i =
      if i + m > n then false
      else if String.sub s i m = sub then true
      else loop (i + 1)
    in
    loop 0

(** Recursively walk a directory for SKILL.md files.
    Returns (relative_path, content) pairs. relative_path is the
    skill directory path relative to the skills root, e.g. "agent/agent-ops". *)
let walk_skills root_dir =
  if not (Cn_ffi.Fs.exists root_dir) then []
  else
    let rec walk dir =
      try
        Cn_ffi.Fs.readdir dir
        |> List.sort String.compare
        |> List.concat_map (fun entry ->
          let path = Cn_ffi.Path.join dir entry in
          let skill_path = Cn_ffi.Path.join path "SKILL.md" in
          if Cn_ffi.Fs.exists skill_path then
            let content = read_opt skill_path in
            if content = "" then []
            else
              (* Compute relative path from root_dir *)
              let prefix_len = String.length root_dir + 1 in
              let rel = String.sub path prefix_len
                (String.length path - prefix_len) in
              [(rel, content)]
          else if Sys.is_directory path then
            walk path
          else [])
      with _ -> []
    in
    walk root_dir

(* === Package validation === *)

(** Required doctrine files in cnos.core package. *)
let required_doctrine = [
  "COHERENCE.md";
  "CAP.md";
  "CA-CONDUCT.md";
  "AGENT-OPS.md";
]

(** Checks that cnos.core is installed with required doctrine files.
    Returns Error with message if missing. *)
let validate_packages ~hub_path =
  match find_installed_package hub_path "cnos.core" with
  | None ->
      Error "Package cnos.core not installed. Run 'cn setup' or 'cn deps restore'."
  | Some core_path ->
      let doctrine_dir = Cn_ffi.Path.join core_path "doctrine" in
      let missing = required_doctrine |> List.filter (fun f ->
        not (Cn_ffi.Fs.exists (Cn_ffi.Path.join doctrine_dir f))) in
      match missing with
      | [] -> Ok ()
      | ms ->
          Error (Printf.sprintf "Missing required doctrine in cnos.core: %s"
            (String.concat ", " ms))

(* === Doctrine loading === *)

(** Deterministic doctrine order. *)
let doctrine_order = [
  "COHERENCE.md";
  "CAP.md";
  "CA-CONDUCT.md";
  "CBP.md";
  "AGENT-OPS.md";
]

(** Load core doctrine from installed cnos.core + optional hub overrides.
    Always-on, not scored, not bounded. Returns concatenated content. *)
let load_core_doctrine ~hub_path : string =
  let tbl = Hashtbl.create 8 in

  (* Layer 1: installed cnos.core package *)
  (match find_installed_package hub_path "cnos.core" with
   | None -> ()
   | Some core_path ->
       let doctrine_dir = Cn_ffi.Path.join core_path "doctrine" in
       doctrine_order |> List.iter (fun name ->
         let content = String.trim (read_opt (Cn_ffi.Path.join doctrine_dir name)) in
         if content <> "" then Hashtbl.replace tbl name content));

  (* Layer 2: hub-local overrides (agent/doctrine/cnos.core/) *)
  let override_dir = hub_doctrine_override_path hub_path "cnos.core" in
  if Cn_ffi.Fs.exists override_dir then
    (try
      Cn_ffi.Fs.readdir override_dir
      |> List.filter (fun f -> Filename.check_suffix f ".md")
      |> List.iter (fun f ->
        let content = String.trim (read_opt (Cn_ffi.Path.join override_dir f)) in
        if content <> "" then Hashtbl.replace tbl f content)
    with _ -> ());

  (* Emit in deterministic order *)
  doctrine_order
  |> List.filter_map (fun name -> Hashtbl.find_opt tbl name)
  |> String.concat "\n\n---\n\n"

(* === Mindset loading === *)

(** Mindset order — COHERENCE is doctrine now, not a mindset.
    Role-file is inserted first; its duplicate later in the list is skipped. *)
let mindset_order ~(role : string option) =
  let role_file = match role with
    | Some "pm" -> "PM.md"
    | _ -> "ENGINEERING.md"
  in
  let all = [
    role_file;
    "ENGINEERING.md"; "PM.md"; "WRITING.md"; "OPERATIONS.md";
    "PERSONALITY.md"; "MEMES.md"; "THINKING.md"; "WISDOM.md"; "FUNCTIONAL.md"
  ] in
  (* Deduplicate: keep first occurrence of each name *)
  let seen = Hashtbl.create 16 in
  all |> List.filter (fun name ->
    if Hashtbl.mem seen name then false
    else (Hashtbl.add seen name (); true))

(** Scan a single directory for mindset .md files.
    Returns (filename, content) pairs. *)
let scan_mindsets_dir dir =
  if not (Cn_ffi.Fs.exists dir) then []
  else
    try
      Cn_ffi.Fs.readdir dir
      |> List.filter (fun f -> Filename.check_suffix f ".md")
      |> List.filter_map (fun f ->
          let content = String.trim (read_opt (Cn_ffi.Path.join dir f)) in
          if content = "" then None else Some (f, content))
    with _ -> []

(** Load mindsets from installed packages + hub-local overrides.
    Two layers only: installed package > hub override.
    Returns concatenated content in deterministic order. *)
let load_mindsets ~hub_path ~(role : string option) : string =
  let tbl = Hashtbl.create 16 in

  (* Layer 1: all installed packages contribute mindsets *)
  list_installed_packages hub_path |> List.iter (fun (pkg_name, pkg_path) ->
    let mdir = Cn_ffi.Path.join pkg_path "mindsets" in
    scan_mindsets_dir mdir |> List.iter (fun (name, content) ->
      Hashtbl.replace tbl name content);
    (* Also check namespaced hub overrides for this package *)
    let override_dir = hub_mindsets_override_path hub_path pkg_name in
    scan_mindsets_dir override_dir |> List.iter (fun (name, content) ->
      Hashtbl.replace tbl name content));

  (* Backward compat: flat hub overrides (agent/mindsets/*.md) treated as cnos.core *)
  let flat_dir = hub_flat_mindsets_path hub_path in
  if Cn_ffi.Fs.exists flat_dir then begin
    (* Only use flat overrides if there are .md files directly in agent/mindsets/
       (not subdirectories which would be package namespaces) *)
    (try
      Cn_ffi.Fs.readdir flat_dir
      |> List.filter (fun f -> Filename.check_suffix f ".md")
      |> List.iter (fun f ->
        let path = Cn_ffi.Path.join flat_dir f in
        if not (Sys.is_directory path) then
          let content = String.trim (read_opt path) in
          if content <> "" then Hashtbl.replace tbl f content)
    with _ -> ())
  end;

  (* Emit in deterministic order *)
  mindset_order ~role
  |> List.filter_map (fun name -> Hashtbl.find_opt tbl name)
  |> String.concat "\n\n---\n\n"

(* === Skill collection === *)

(** Collect skills from all installed packages + hub-local overrides.
    Hub-local wins over package.
    Deduplicates by (package_name, rel_path) to prevent cross-package collisions.
    Returns (qualified_key, rel_path, content, source) quads. *)
let collect_skills ~hub_path =
  let tbl = Hashtbl.create 64 in

  (* Layer 1: all installed packages *)
  list_installed_packages hub_path |> List.iter (fun (pkg_name, pkg_path) ->
    let sdir = Cn_ffi.Path.join pkg_path "skills" in
    walk_skills sdir |> List.iter (fun (rel, content) ->
      let key = Printf.sprintf "%s::%s" pkg_name rel in
      Hashtbl.replace tbl key (rel, content, Package pkg_name)));

  (* Layer 2: hub-local overrides (namespaced) *)
  list_installed_packages hub_path |> List.iter (fun (pkg_name, _) ->
    let override_dir = hub_skills_override_path hub_path pkg_name in
    walk_skills override_dir |> List.iter (fun (rel, content) ->
      let key = Printf.sprintf "%s::%s" pkg_name rel in
      Hashtbl.replace tbl key (rel, content, Hub_local)));

  (* Backward compat: flat hub overrides (agent/skills/...) *)
  let flat_dir = hub_flat_skills_path hub_path in
  if Cn_ffi.Fs.exists flat_dir then begin
    walk_skills flat_dir |> List.iter (fun (rel, content) ->
      (* Flat overrides go into cnos.core namespace *)
      let key = Printf.sprintf "cnos.core::%s" rel in
      Hashtbl.replace tbl key (rel, content, Hub_local))
  end;

  (* Return as sorted list for deterministic ordering *)
  Hashtbl.fold (fun _key (rel, content, source) acc ->
    (rel, content, source) :: acc) tbl []
  |> List.sort (fun (a, _, _) (b, _, _) -> String.compare a b)

(* === Summary === *)

(** Build asset summary for capability block. *)
let summarize ~hub_path =
  let role =
    let cfg = Cn_ffi.Path.join hub_path ".cn/config.json" in
    let raw = read_opt cfg in
    if raw = "" then None
    else match Cn_json.parse raw with
    | Error _ -> None
    | Ok json ->
        (match Cn_json.get "runtime" json with
         | None -> None
         | Some rt -> Cn_json.get_string "role" rt)
  in

  (* Count doctrine files *)
  let doctrine_count =
    match find_installed_package hub_path "cnos.core" with
    | None -> 0
    | Some core_path ->
        let d = Cn_ffi.Path.join core_path "doctrine" in
        if Cn_ffi.Fs.exists d then
          (try Cn_ffi.Fs.readdir d
               |> List.filter (fun f -> Filename.check_suffix f ".md")
               |> List.length with _ -> 0)
        else 0
  in

  (* Count mindsets across all packages *)
  let mindset_count =
    let tbl = Hashtbl.create 16 in
    list_installed_packages hub_path |> List.iter (fun (_pkg_name, pkg_path) ->
      let d = Cn_ffi.Path.join pkg_path "mindsets" in
      if Cn_ffi.Fs.exists d then
        (try Cn_ffi.Fs.readdir d
             |> List.filter (fun f -> Filename.check_suffix f ".md")
             |> List.iter (fun f -> Hashtbl.replace tbl f ())
         with _ -> ()));
    Hashtbl.length tbl
  in

  (* Per-package skill counts *)
  let packages =
    list_installed_packages hub_path |> List.map (fun (_pkg_name, pkg_path) ->
      let dir_name = Filename.basename pkg_path in
      let sdir = Cn_ffi.Path.join pkg_path "skills" in
      let count = List.length (walk_skills sdir) in
      (dir_name, count))
  in

  (* Hub override counts *)
  let hub_overrides_mindsets =
    let count = ref 0 in
    list_installed_packages hub_path |> List.iter (fun (pkg_name, _) ->
      let d = hub_mindsets_override_path hub_path pkg_name in
      if Cn_ffi.Fs.exists d then
        (try count := !count +
          (Cn_ffi.Fs.readdir d
           |> List.filter (fun f -> Filename.check_suffix f ".md")
           |> List.length)
        with _ -> ()));
    !count
  in
  let hub_overrides_skills =
    let count = ref 0 in
    list_installed_packages hub_path |> List.iter (fun (pkg_name, _) ->
      let d = hub_skills_override_path hub_path pkg_name in
      count := !count + List.length (walk_skills d));
    !count
  in

  { profile = role;
    doctrine_count;
    mindset_count;
    packages;
    hub_overrides_mindsets;
    hub_overrides_skills }
