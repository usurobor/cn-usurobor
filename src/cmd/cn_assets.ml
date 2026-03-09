(** cn_assets.ml — Cognitive Asset Resolver (CAR)

    Three-layer asset resolver per CAR-v3.4:
      Layer A: Bundled core assets   (.cn/vendor/core/)
      Layer B: Installed packages    (.cn/vendor/packages/)
      Layer C: Hub-local overrides   (agent/)

    Resolution priority: hub-local > package > core.
    Wake-up reads only local files — no network access. *)

(* === Types === *)

type asset_source = Core | Package of string | Hub_local

type asset_summary = {
  profile : string option;
  core_mindsets : int;
  core_skills : int;
  packages : (string * int) list;
  hub_overrides_mindsets : int;
  hub_overrides_skills : int;
}

(* === Paths === *)

let vendor_core_path hub_path =
  Cn_ffi.Path.join hub_path ".cn/vendor/core"

let vendor_packages_path hub_path =
  Cn_ffi.Path.join hub_path ".cn/vendor/packages"

let hub_overrides_mindsets_path hub_path =
  Cn_ffi.Path.join hub_path "agent/mindsets"

let hub_overrides_skills_path hub_path =
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

(* === Core validation === *)

(** Checks that .cn/vendor/core/ exists with required assets.
    Returns Error with message if missing. *)
let validate_core ~hub_path =
  let core = vendor_core_path hub_path in
  let required = [
    Cn_ffi.Path.join core "mindsets/COHERENCE.md";
    Cn_ffi.Path.join core "skills/agent/agent-ops/SKILL.md";
  ] in
  let missing = required |> List.filter (fun p -> not (Cn_ffi.Fs.exists p)) in
  match missing with
  | [] -> Ok ()
  | ms ->
      Error (Printf.sprintf "Missing required core assets: %s"
        (String.concat ", " ms))

(* === Mindset loading === *)

(** All 10 core mindsets in deterministic order.
    Role-file is inserted second; its duplicate later in the list is skipped. *)
let mindset_order ~(role : string option) =
  let role_file = match role with
    | Some "pm" -> "PM.md"
    | _ -> "ENGINEERING.md"
  in
  let all = [
    "COHERENCE.md";
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

(** Load mindsets from all three layers, merged by filename (hub > pkg > core).
    Returns concatenated content in deterministic order. *)
let load_mindsets ~hub_path ~(role : string option) : string =
  (* Collect from all three layers — hub-local wins *)
  let tbl = Hashtbl.create 16 in

  (* Layer A: core *)
  let core_dir = Cn_ffi.Path.join (vendor_core_path hub_path) "mindsets" in
  scan_mindsets_dir core_dir |> List.iter (fun (name, content) ->
    Hashtbl.replace tbl name content);

  (* Layer B: packages (all packages contribute) *)
  let pkg_root = vendor_packages_path hub_path in
  if Cn_ffi.Fs.exists pkg_root then
    (try
      Cn_ffi.Fs.readdir pkg_root
      |> List.sort String.compare
      |> List.iter (fun pkg_dir_name ->
          let mdir = Cn_ffi.Path.join
            (Cn_ffi.Path.join pkg_root pkg_dir_name) "mindsets" in
          scan_mindsets_dir mdir |> List.iter (fun (name, content) ->
            Hashtbl.replace tbl name content))
    with _ -> ());

  (* Layer C: hub-local overrides (highest priority) *)
  let hub_dir = hub_overrides_mindsets_path hub_path in
  scan_mindsets_dir hub_dir |> List.iter (fun (name, content) ->
    Hashtbl.replace tbl name content);

  (* Emit in deterministic order *)
  mindset_order ~role
  |> List.filter_map (fun name -> Hashtbl.find_opt tbl name)
  |> String.concat "\n\n---\n\n"

(* === Skill collection === *)

(** Collect skills from all three layers, merged by relative path.
    Hub-local wins over package, package over core.
    Returns (rel_path, content, source) triples. *)
let collect_skills ~hub_path =
  let tbl = Hashtbl.create 64 in

  (* Layer A: core *)
  let core_dir = Cn_ffi.Path.join (vendor_core_path hub_path) "skills" in
  walk_skills core_dir |> List.iter (fun (rel, content) ->
    Hashtbl.replace tbl rel (content, Core));

  (* Layer B: packages *)
  let pkg_root = vendor_packages_path hub_path in
  if Cn_ffi.Fs.exists pkg_root then
    (try
      Cn_ffi.Fs.readdir pkg_root
      |> List.sort String.compare
      |> List.iter (fun pkg_dir_name ->
          let pkg_name = match String.index_opt pkg_dir_name '@' with
            | Some i -> String.sub pkg_dir_name 0 i
            | None -> pkg_dir_name
          in
          let sdir = Cn_ffi.Path.join
            (Cn_ffi.Path.join pkg_root pkg_dir_name) "skills" in
          walk_skills sdir |> List.iter (fun (rel, content) ->
            Hashtbl.replace tbl rel (content, Package pkg_name)))
    with _ -> ());

  (* Layer C: hub-local overrides *)
  let hub_dir = hub_overrides_skills_path hub_path in
  walk_skills hub_dir |> List.iter (fun (rel, content) ->
    Hashtbl.replace tbl rel (content, Hub_local));

  (* Return as sorted list for deterministic ordering *)
  Hashtbl.fold (fun rel (content, source) acc ->
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

  let core_dir = vendor_core_path hub_path in
  let core_mindsets =
    let d = Cn_ffi.Path.join core_dir "mindsets" in
    if Cn_ffi.Fs.exists d then
      (try Cn_ffi.Fs.readdir d
           |> List.filter (fun f -> Filename.check_suffix f ".md")
           |> List.length with _ -> 0)
    else 0
  in
  let core_skills = List.length (walk_skills (Cn_ffi.Path.join core_dir "skills")) in

  let pkg_root = vendor_packages_path hub_path in
  let packages =
    if not (Cn_ffi.Fs.exists pkg_root) then []
    else
      try
        Cn_ffi.Fs.readdir pkg_root
        |> List.sort String.compare
        |> List.map (fun pkg_dir_name ->
            let sdir = Cn_ffi.Path.join
              (Cn_ffi.Path.join pkg_root pkg_dir_name) "skills" in
            let count = List.length (walk_skills sdir) in
            (pkg_dir_name, count))
      with _ -> []
  in

  let hub_m_dir = hub_overrides_mindsets_path hub_path in
  let hub_overrides_mindsets =
    if Cn_ffi.Fs.exists hub_m_dir then
      (try Cn_ffi.Fs.readdir hub_m_dir
           |> List.filter (fun f -> Filename.check_suffix f ".md")
           |> List.length with _ -> 0)
    else 0
  in
  let hub_s_dir = hub_overrides_skills_path hub_path in
  let hub_overrides_skills = List.length (walk_skills hub_s_dir) in

  { profile = role;
    core_mindsets;
    core_skills;
    packages;
    hub_overrides_mindsets;
    hub_overrides_skills }
