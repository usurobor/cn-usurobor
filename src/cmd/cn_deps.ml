(** cn_deps.ml — Dependency manifest, lockfile, and asset materialization

    Handles .cn/deps.json (manifest) and .cn/deps.lock.json (lockfile)
    parsing, writing, and the materialize/restore pipeline.

    Key design: runtime never calls this module. Only cn setup,
    cn deps restore, and cn deps commands use it. *)

open Cn_lib

(* === Types === *)

(** Manifest entry: what the human wants. *)
type manifest_dep = {
  name : string;
  version : string;
}

(** Lockfile entry: what the resolver pinned. *)
type locked_dep = {
  name : string;
  version : string;
  source : string;
  rev : string;
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
        Cn_json.get_string "rev" json with
  | Some name, Some version, Some source, Some rev ->
      Some { name; version; source; rev;
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

(* === Bundled core source === *)

(** Find the bundled core asset source (template repo's src/agent/).
    Checks CN_TEMPLATE_PATH env var first, then walks up from cwd. *)
let bundled_core_source () =
  (* 1. CN_TEMPLATE_PATH env var *)
  match Cn_ffi.Process.getenv_opt "CN_TEMPLATE_PATH" with
  | Some p ->
      let agent_dir = Cn_ffi.Path.join p "src/agent" in
      if Cn_ffi.Fs.exists agent_dir then Ok agent_dir
      else Error (Printf.sprintf "CN_TEMPLATE_PATH=%s but %s not found" p agent_dir)
  | None ->
      (* 2. Walk up from cwd looking for src/agent/mindsets/COHERENCE.md *)
      let rec walk dir =
        let candidate = Cn_ffi.Path.join dir "src/agent/mindsets/COHERENCE.md" in
        if Cn_ffi.Fs.exists candidate then
          Ok (Cn_ffi.Path.join dir "src/agent")
        else
          let parent = Filename.dirname dir in
          if parent = dir then
            Error "Cannot find cnos template repo. Set CN_TEMPLATE_PATH or run from within the cnos checkout."
          else walk parent
      in
      walk (Cn_ffi.Process.cwd ())

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

(* === Materialize core === *)

(** Materialize bundled core assets into .cn/vendor/core/.
    Source: cnos template repo's src/agent/ directory. *)
let materialize_core ~hub_path =
  match bundled_core_source () with
  | Error msg -> Error msg
  | Ok agent_dir ->
      let core = Cn_assets.vendor_core_path hub_path in
      (* Copy mindsets *)
      let src_mindsets = Cn_ffi.Path.join agent_dir "mindsets" in
      let dst_mindsets = Cn_ffi.Path.join core "mindsets" in
      Cn_ffi.Fs.ensure_dir dst_mindsets;
      (if Cn_ffi.Fs.exists src_mindsets then
        try
          Cn_ffi.Fs.readdir src_mindsets
          |> List.filter (fun f -> Filename.check_suffix f ".md")
          |> List.iter (fun f ->
            Cn_ffi.Fs.write
              (Cn_ffi.Path.join dst_mindsets f)
              (Cn_ffi.Fs.read (Cn_ffi.Path.join src_mindsets f)))
        with _ -> ());
      (* Copy skills tree *)
      let src_skills = Cn_ffi.Path.join agent_dir "skills" in
      let dst_skills = Cn_ffi.Path.join core "skills" in
      copy_tree src_skills dst_skills;
      Ok ()

(* === Restore === *)

(** Install packages from lockfile into .cn/vendor/packages/.
    Fetches by exact lockfile rev. Also materializes core. *)
let restore ~hub_path =
  (* Always materialize core first *)
  match materialize_core ~hub_path with
  | Error msg -> Error (Printf.sprintf "Core materialization failed: %s" msg)
  | Ok () ->
      match read_lockfile ~hub_path with
      | None ->
          (* No lockfile = nothing to install beyond core *)
          Ok ()
      | Some lock ->
          let pkg_root = Cn_assets.vendor_packages_path hub_path in
          let errors = lock.packages |> List.filter_map (fun (dep : locked_dep) ->
            let pkg_dir = Cn_ffi.Path.join pkg_root
              (Printf.sprintf "%s@%s" dep.name dep.version) in
            if Cn_ffi.Fs.exists pkg_dir then None (* already installed *)
            else begin
              (* Fetch by exact rev *)
              let tmp_dir = Cn_ffi.Path.join hub_path
                (Printf.sprintf ".cn/tmp/%s-%s" dep.name dep.version) in
              Cn_ffi.Fs.ensure_dir tmp_dir;
              let fetch_cmd = Printf.sprintf
                "cd %s && git init -q && git fetch -q --depth=1 %s %s && git checkout -q %s"
                tmp_dir dep.source dep.rev dep.rev in
              match Cn_ffi.Child_process.exec fetch_cmd with
              | None ->
                  (* Clean up *)
                  ignore (Cn_ffi.Child_process.exec
                    (Printf.sprintf "rm -rf %s" tmp_dir));
                  Some (Printf.sprintf "Failed to fetch %s@%s from %s (rev %s)"
                    dep.name dep.version dep.source dep.rev)
              | Some _ ->
                  (* Copy runtime dirs *)
                  Cn_ffi.Fs.ensure_dir pkg_dir;
                  copy_tree (Cn_ffi.Path.join tmp_dir "mindsets")
                    (Cn_ffi.Path.join pkg_dir "mindsets");
                  copy_tree (Cn_ffi.Path.join tmp_dir "skills")
                    (Cn_ffi.Path.join pkg_dir "skills");
                  (* Clean up tmp *)
                  ignore (Cn_ffi.Child_process.exec
                    (Printf.sprintf "rm -rf %s" tmp_dir));
                  None
            end
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

(** Verify installed assets match lockfile. Returns Ok () or Error with
    list of issues found. *)
let doctor ~hub_path =
  let issues = ref [] in
  let add msg = issues := msg :: !issues in

  (* Check core *)
  (match Cn_assets.validate_core ~hub_path with
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

let default_manifest_for_profile profile =
  let pkg_name = Printf.sprintf "cnos.profile.%s" profile in
  { schema = "cn.deps.v1";
    profile;
    packages = [{ name = pkg_name; version = "^1.0.0" }] }

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
  (* Show core status *)
  match Cn_assets.validate_core ~hub_path with
  | Ok () -> print_endline (Cn_fmt.ok "Core assets: present")
  | Error _ -> print_endline (Cn_fmt.warn "Core assets: missing (run 'cn deps restore')")

let run_restore ~hub_path =
  match restore ~hub_path with
  | Ok () ->
      let summary = Cn_assets.summarize ~hub_path in
      print_endline (Cn_fmt.ok (Printf.sprintf
        "Restored: %d core mindsets, %d core skills, %d packages"
        summary.core_mindsets summary.core_skills
        (List.length summary.packages)))
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
