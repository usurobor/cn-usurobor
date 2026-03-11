(** cn_deps.ml — Dependency manifest, lockfile, and package restore

    Handles .cn/deps.json (manifest) and .cn/deps.lock.json (lockfile)
    parsing, writing, and the restore pipeline.

    Unified package model (v3.5):
    - Everything cognitive is a package (cnos.core, cnos.eng, cnos.pm)
    - Profiles are setup-time presets, not packages
    - Restore fetches by (source, rev, subdir) and copies into
      .cn/vendor/packages/<name>@<version>/
    - No CN_TEMPLATE_PATH, no vendor/core, no runtime network

    Key design: runtime never calls this module. Only cn setup,
    cn deps restore, and cn deps commands use it. *)

(* open Cn_lib — unused; types referenced fully qualified *)

(* === Constants === *)

(** Default git source for first-party packages. *)
let default_first_party_source = "https://github.com/usurobor/cnos.git"

(** Subdirectory prefix for packages within the cnos repo. *)
let packages_subdir = "packages"

(* === Types === *)

(** Manifest entry: what the human wants. *)
type manifest_dep = {
  name : string;
  version : string;
}

(** Lockfile entry: what the resolver pinned.
    subdir is required — multiple packages may live in one git repo. *)
type locked_dep = {
  name : string;
  version : string;
  source : string;
  rev : string;
  subdir : string;
  integrity : string option;
}

type manifest = {
  schema : string;
  profile : string;
  packages : manifest_dep list;
}

type lockfile = {
  schema : string;
  packages : locked_dep list;
}

(* === Paths === *)

let manifest_path hub_path =
  Cn_ffi.Path.join hub_path ".cn/deps.json"

let lockfile_path hub_path =
  Cn_ffi.Path.join hub_path ".cn/deps.lock.json"

(* === JSON helpers === *)

let manifest_dep_to_json (d : manifest_dep) =
  Cn_json.Object [
    "name", Cn_json.String d.name;
    "version", Cn_json.String d.version;
  ]

let locked_dep_to_json (d : locked_dep) =
  let fields = [
    "name", Cn_json.String d.name;
    "version", Cn_json.String d.version;
    "source", Cn_json.String d.source;
    "rev", Cn_json.String d.rev;
    "subdir", Cn_json.String d.subdir;
  ] in
  let fields = match d.integrity with
    | Some h -> fields @ ["integrity", Cn_json.String h]
    | None -> fields
  in
  Cn_json.Object fields

let parse_manifest_dep json =
  match Cn_json.get_string "name" json, Cn_json.get_string "version" json with
  | Some name, Some version -> Some { name; version }
  | _ -> None

let parse_locked_dep json =
  match Cn_json.get_string "name" json,
        Cn_json.get_string "version" json,
        Cn_json.get_string "source" json,
        Cn_json.get_string "rev" json,
        Cn_json.get_string "subdir" json with
  | Some name, Some version, Some source, Some rev, Some subdir ->
      Some { name; version; source; rev; subdir;
             integrity = Cn_json.get_string "integrity" json }
  | _ -> None

(* === Read/write === *)

let read_manifest ~hub_path =
  let path = manifest_path hub_path in
  if not (Cn_ffi.Fs.exists path) then None
  else
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Error _ -> None
    | Ok json ->
        let schema = Cn_json.get_string "schema" json
          |> Option.value ~default:"cn.deps.v1" in
        let profile = Cn_json.get_string "profile" json
          |> Option.value ~default:"engineer" in
        let packages = match Cn_json.get "packages" json with
          | Some (Cn_json.Array items) -> List.filter_map parse_manifest_dep items
          | _ -> []
        in
        Some { schema; profile; packages }

let read_lockfile ~hub_path =
  let path = lockfile_path hub_path in
  if not (Cn_ffi.Fs.exists path) then None
  else
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Error _ -> None
    | Ok json ->
        let schema = Cn_json.get_string "schema" json
          |> Option.value ~default:"cn.deps.lock.v1" in
        let packages = match Cn_json.get "packages" json with
          | Some (Cn_json.Array items) -> List.filter_map parse_locked_dep items
          | _ -> []
        in
        Some { schema; packages }

let write_manifest ~hub_path (m : manifest) =
  let json = Cn_json.Object [
    "schema", Cn_json.String m.schema;
    "profile", Cn_json.String m.profile;
    "packages", Cn_json.Array (List.map manifest_dep_to_json m.packages);
  ] in
  Cn_ffi.Fs.write (manifest_path hub_path) (Cn_json.to_string json ^ "\n")

let write_lockfile ~hub_path (l : lockfile) =
  let json = Cn_json.Object [
    "schema", Cn_json.String l.schema;
    "packages", Cn_json.Array (List.map locked_dep_to_json l.packages);
  ] in
  Cn_ffi.Fs.write (lockfile_path hub_path) (Cn_json.to_string json ^ "\n")

(* === Recursive copy helper === *)

(** Copy all files from src_dir to dst_dir, preserving directory structure.
    Creates directories as needed. *)
let rec copy_tree src_dir dst_dir =
  if Cn_ffi.Fs.exists src_dir then begin
    Cn_ffi.Fs.ensure_dir dst_dir;
    try
      Cn_ffi.Fs.readdir src_dir
      |> List.iter (fun entry ->
        let src = Cn_ffi.Path.join src_dir entry in
        let dst = Cn_ffi.Path.join dst_dir entry in
        if Sys.is_directory src then
          copy_tree src dst
        else
          Cn_ffi.Fs.write dst (Cn_ffi.Fs.read src))
    with _ -> ()
  end

(* === First-party package source resolution === *)

(** Resolve the source directory for a first-party package.
    First-party packages live in the cnos repo under packages/<name>/.
    At setup time, we look for a local cnos checkout (walk up from cwd).
    Returns Ok (local_path) if found locally, Error msg otherwise. *)
let find_local_package_source pkg_name =
  let rec walk dir =
    let candidate = Cn_ffi.Path.join dir
      (Printf.sprintf "packages/%s/cn.package.json" pkg_name) in
    if Cn_ffi.Fs.exists candidate then
      Ok (Cn_ffi.Path.join dir (Printf.sprintf "packages/%s" pkg_name))
    else
      let parent = Filename.dirname dir in
      if parent = dir then Error "not found locally"
      else walk parent
  in
  walk (Cn_ffi.Process.cwd ())

(** Check if a package name is first-party (cnos.xxx). *)
let is_first_party name =
  String.length name >= 5 && String.sub name 0 5 = "cnos."

(* === Safe git helpers (argv-only, no shell strings) === *)

(** Run git with structured args in a given directory.
    Returns Ok stdout on exit 0, Error msg otherwise. *)
let git_in ~cwd args =
  let full_args = ["-C"; cwd] @ args in
  let (code, output) = Cn_ffi.Process.exec_args ~prog:"git" ~args:full_args () in
  if code = 0 then Ok output
  else Error (Printf.sprintf "git %s failed (exit %d): %s"
    (String.concat " " args) code output)

(** Remove a directory tree using structured args (no shell injection). *)
let rm_tree path =
  if Cn_ffi.Fs.exists path then
    ignore (Cn_ffi.Process.exec_args ~prog:"rm" ~args:["-rf"; path] ())

(* === Restore === *)

(** Install a single package from its lock entry.
    Uses (source, rev, subdir) to fetch only the package subtree.
    Returns None on success, Some error_msg on failure. *)
let restore_one ~hub_path (dep : locked_dep) =
  let pkg_root = Cn_assets.vendor_packages_path hub_path in
  let pkg_dir = Cn_ffi.Path.join pkg_root
    (Printf.sprintf "%s@%s" dep.name dep.version) in
  if Cn_ffi.Fs.exists pkg_dir then None (* already installed *)
  else
    (* Try local first-party source first *)
    let local_result =
      if is_first_party dep.name then
        match find_local_package_source dep.name with
        | Ok local_path ->
            (* Guard: verify packages/ is in sync with src/agent/.
               Prevents installing stale generated artifacts. *)
            (match Cn_build.check_package dep.name with
             | Error msg -> Some (Error msg)
             | Ok () ->
                 Cn_ffi.Fs.ensure_dir pkg_dir;
                 copy_tree local_path pkg_dir;
                 Some (Ok ()))
        | Error _ -> None
      else None
    in
    match local_result with
    | Some (Ok ()) -> None
    | Some (Error msg) -> Some msg
    | None ->
      (* Fetch by exact rev using structured argv calls *)
      let tmp_dir = Cn_ffi.Path.join hub_path
        (Printf.sprintf ".cn/tmp/%s-%s" dep.name dep.version) in
      Cn_ffi.Fs.ensure_dir tmp_dir;
      let result =
        match git_in ~cwd:tmp_dir ["init"; "-q"] with
        | Error msg -> Error msg
        | Ok _ ->
        match git_in ~cwd:tmp_dir
          ["fetch"; "-q"; "--depth=1"; dep.source; dep.rev] with
        | Error msg -> Error msg
        | Ok _ ->
        match git_in ~cwd:tmp_dir ["checkout"; "-q"; dep.rev] with
        | Error msg -> Error msg
        | Ok _ -> Ok ()
      in
      match result with
      | Error msg ->
          rm_tree tmp_dir;
          Some (Printf.sprintf "Failed to fetch %s@%s from %s (rev %s): %s"
            dep.name dep.version dep.source dep.rev msg)
      | Ok () ->
          Cn_ffi.Fs.ensure_dir pkg_dir;
          (* Copy from subdir if specified, else copy entire checkout *)
          let src_root = if dep.subdir <> "" then
            Cn_ffi.Path.join tmp_dir dep.subdir
          else tmp_dir in
          (* Copy all asset directories: doctrine, mindsets, skills, plus metadata *)
          List.iter (fun sub ->
            let src = Cn_ffi.Path.join src_root sub in
            if Cn_ffi.Fs.exists src then
              copy_tree src (Cn_ffi.Path.join pkg_dir sub)
          ) ["doctrine"; "mindsets"; "skills"];
          (* Copy cn.package.json if present *)
          let pkg_json = Cn_ffi.Path.join src_root "cn.package.json" in
          if Cn_ffi.Fs.exists pkg_json then
            Cn_ffi.Fs.write (Cn_ffi.Path.join pkg_dir "cn.package.json")
              (Cn_ffi.Fs.read pkg_json);
          rm_tree tmp_dir;
          None

(** Install packages from lockfile into .cn/vendor/packages/.
    Fetches by exact lockfile rev + subdir using argv-only git calls.
    No vendor/core — everything is a package. *)
let restore ~hub_path =
  match read_lockfile ~hub_path with
  | None ->
      (* No lockfile = nothing to install *)
      Ok ()
  | Some lock ->
      let errors = lock.packages |> List.filter_map (fun dep ->
        restore_one ~hub_path dep
      ) in
      match errors with
      | [] -> Ok ()
      | errs -> Error (String.concat "\n" errs)

(* === List installed === *)

let list_installed ~hub_path =
  let pkg_root = Cn_assets.vendor_packages_path hub_path in
  if not (Cn_ffi.Fs.exists pkg_root) then []
  else
    try
      Cn_ffi.Fs.readdir pkg_root
      |> List.sort String.compare
      |> List.filter_map (fun dir_name ->
        match String.index_opt dir_name '@' with
        | Some i ->
            let name = String.sub dir_name 0 i in
            let version = String.sub dir_name (i + 1)
              (String.length dir_name - i - 1) in
            Some (name, version)
        | None -> Some (dir_name, "unknown"))
    with _ -> []

(* === Doctor === *)

(** Verify installed packages match lockfile. Returns Ok () or Error with
    list of issues found. *)
let doctor ~hub_path =
  let issues = ref [] in
  let add msg = issues := msg :: !issues in

  (* Check installed packages have required assets *)
  (match Cn_assets.validate_packages ~hub_path with
   | Ok () -> ()
   | Error msg -> add msg);

  (* Check manifest exists *)
  if not (Cn_ffi.Fs.exists (manifest_path hub_path)) then
    add "Missing .cn/deps.json — run 'cn setup'";

  (* Check lockfile exists *)
  if not (Cn_ffi.Fs.exists (lockfile_path hub_path)) then
    add "Missing .cn/deps.lock.json — run 'cn setup'"
  else begin
    match read_lockfile ~hub_path with
    | None -> add "Cannot parse .cn/deps.lock.json"
    | Some lock ->
        let pkg_root = Cn_assets.vendor_packages_path hub_path in
        lock.packages |> List.iter (fun (dep : locked_dep) ->
          let pkg_dir = Cn_ffi.Path.join pkg_root
            (Printf.sprintf "%s@%s" dep.name dep.version) in
          if not (Cn_ffi.Fs.exists pkg_dir) then
            add (Printf.sprintf "Package %s@%s declared in lockfile but not installed"
              dep.name dep.version))
  end;

  match !issues with
  | [] -> Ok ()
  | is -> Error (List.rev is)

(* === Default manifest for profile === *)

(** Expand a profile name to its package list.
    engineer => [cnos.core, cnos.eng]
    pm       => [cnos.core, cnos.pm] *)
let default_manifest_for_profile profile =
  let packages = match String.lowercase_ascii profile with
    | "pm" -> [
        { name = "cnos.core"; version = "^1.0.0" };
        { name = "cnos.pm"; version = "^1.0.0" };
      ]
    | _ -> (* engineer is default *)
      [
        { name = "cnos.core"; version = "^1.0.0" };
        { name = "cnos.eng"; version = "^1.0.0" };
      ]
  in
  { schema = "cn.deps.v1"; profile; packages }

(** Create a lockfile with first-party package entries.
    Queries the source repo via ls-remote to get the correct HEAD rev. *)
let lockfile_for_manifest (m : manifest) =
  let rev =
    let (code, output) = Cn_ffi.Process.exec_args ~prog:"git"
      ~args:["ls-remote"; default_first_party_source; "HEAD"] () in
    if code = 0 then
      (* ls-remote output: "<sha>\tHEAD\n" — extract the SHA *)
      let trimmed = String.trim output in
      match String.index_opt trimmed '\t' with
      | Some i -> String.sub trimmed 0 i
      | None -> ""
    else ""
  in
  let packages = m.packages |> List.map (fun (dep : manifest_dep) ->
    let source, subdir =
      if is_first_party dep.name then
        (default_first_party_source,
         Printf.sprintf "%s/%s" packages_subdir dep.name)
      else
        ("", "")
    in
    let version = if dep.version = "" || dep.version.[0] = '^'
                     || dep.version.[0] = '~'
      then "1.0.0" else dep.version in
    { name = dep.name; version; source; rev; subdir;
      integrity = None }
  ) in
  { schema = "cn.deps.lock.v1"; packages }

let empty_lockfile =
  { schema = "cn.deps.lock.v1"; packages = [] }

(* === CLI entry points === *)

let run_list ~hub_path =
  let installed = list_installed ~hub_path in
  if installed = [] then
    print_endline (Cn_fmt.dim "No packages installed")
  else begin
    print_endline (Cn_fmt.info "Installed packages:");
    installed |> List.iter (fun (name, version) ->
      print_endline (Printf.sprintf "  %s@%s" name version))
  end;
  (* Show package validation status *)
  match Cn_assets.validate_packages ~hub_path with
  | Ok () -> print_endline (Cn_fmt.ok "Core doctrine: present")
  | Error _ -> print_endline (Cn_fmt.warn "Core doctrine: missing (run 'cn deps restore')")

let run_restore ~hub_path =
  match restore ~hub_path with
  | Ok () ->
      let summary = Cn_assets.summarize ~hub_path in
      let pkg_count = List.length summary.packages in
      let total_skills = List.fold_left (fun acc (_, c) -> acc + c) 0 summary.packages in
      print_endline (Cn_fmt.ok (Printf.sprintf
        "Restored: %d packages, %d doctrine files, %d mindsets, %d skills"
        pkg_count summary.doctrine_count summary.mindset_count total_skills))
  | Error msg ->
      print_endline (Cn_fmt.fail msg);
      Cn_ffi.Process.exit 1

let run_doctor ~hub_path =
  match doctor ~hub_path with
  | Ok () -> print_endline (Cn_fmt.ok "All dependencies verified")
  | Error msgs ->
      msgs |> List.iter (fun m -> print_endline (Cn_fmt.warn m));
      Cn_ffi.Process.exit 1

let run_add ~hub_path pkg_spec =
  (* Parse pkg_spec as name@version or just name *)
  let name, version = match String.index_opt pkg_spec '@' with
    | Some i ->
        (String.sub pkg_spec 0 i,
         String.sub pkg_spec (i + 1) (String.length pkg_spec - i - 1))
    | None -> (pkg_spec, "*")
  in
  let manifest = match read_manifest ~hub_path with
    | Some m -> m
    | None -> default_manifest_for_profile "engineer"
  in
  (* Check if already present *)
  if List.exists (fun (d : manifest_dep) -> d.name = name) manifest.packages then begin
    print_endline (Cn_fmt.warn (Printf.sprintf "%s already in deps" name));
  end else begin
    let manifest = { manifest with
      packages = manifest.packages @ [{ name; version }] } in
    write_manifest ~hub_path manifest;
    print_endline (Cn_fmt.ok (Printf.sprintf "Added %s@%s to .cn/deps.json" name version));
    print_endline (Cn_fmt.dim "Run 'cn deps update' to resolve and 'cn deps restore' to install")
  end

let run_remove ~hub_path pkg_name =
  match read_manifest ~hub_path with
  | None ->
      print_endline (Cn_fmt.fail "No .cn/deps.json found")
  | Some manifest ->
      let packages = manifest.packages
        |> List.filter (fun (d : manifest_dep) -> d.name <> pkg_name) in
      if List.length packages = List.length manifest.packages then
        print_endline (Cn_fmt.warn (Printf.sprintf "%s not found in deps" pkg_name))
      else begin
        write_manifest ~hub_path { manifest with packages };
        print_endline (Cn_fmt.ok (Printf.sprintf "Removed %s from .cn/deps.json" pkg_name))
      end

let run_vendor ~hub_path =
  (* Ensure vendor exists first *)
  (match restore ~hub_path with
   | Ok () -> ()
   | Error msg ->
       print_endline (Cn_fmt.fail msg);
       Cn_ffi.Process.exit 1);
  (* Remove .cn/vendor from .gitignore if present *)
  let gitignore = Cn_ffi.Path.join hub_path ".gitignore" in
  if Cn_ffi.Fs.exists gitignore then begin
    let content = Cn_ffi.Fs.read gitignore in
    let lines = String.split_on_char '\n' content in
    let filtered = lines |> List.filter (fun l ->
      let t = String.trim l in
      t <> ".cn/vendor/" && t <> ".cn/vendor") in
    Cn_ffi.Fs.write gitignore (String.concat "\n" filtered)
  end;
  print_endline (Cn_fmt.ok "Vendor tree ready for commit");
  print_endline (Cn_fmt.dim "Run 'git add .cn/vendor/' to stage")
