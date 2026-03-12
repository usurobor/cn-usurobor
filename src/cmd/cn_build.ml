(** cn_build.ml — Package assembly from src/agent/ sources

    Reads cn.package.json manifests in packages/<name>/ and copies
    declared assets from src/agent/ into each package directory.

    This eliminates manual duplication between src/agent/ (source of
    truth) and packages/ (distributable output).

    Three modes:
    - build (default): assemble packages/ from src/agent/
    - build --check:   verify packages/ matches src/agent/ (CI mode)
    - build clean:     remove generated content from packages/ *)

(* === Types === *)

(** Parsed source declaration from cn.package.json.
    Maps asset categories to paths relative to src/agent/<category>/. *)
type source_decl = {
  doctrine : string list;
  mindsets : string list;
  skills : string list;
}

type package_manifest = {
  name : string;
  version : string;
  sources : source_decl;
}

(* === Paths === *)

let repo_root () =
  let cwd = Cn_ffi.Process.cwd () in
  let rec walk dir =
    if Cn_ffi.Fs.exists (Cn_ffi.Path.join dir "dune-project") then Some dir
    else
      let parent = Filename.dirname dir in
      if parent = dir then None
      else walk parent
  in
  walk cwd

let agent_path root = Cn_ffi.Path.join root "src/agent"
let packages_path root = Cn_ffi.Path.join root "packages"

(* === JSON parsing === *)

let parse_string_array json key =
  match Cn_json.get key json with
  | Some (Cn_json.Array items) ->
      items |> List.filter_map (function
        | Cn_json.String s -> Some s
        | _ -> None)
  | _ -> []

let parse_sources json =
  match Cn_json.get "sources" json with
  | None -> None
  | Some src_json ->
      Some {
        doctrine = parse_string_array src_json "doctrine";
        mindsets = parse_string_array src_json "mindsets";
        skills = parse_string_array src_json "skills";
      }

let parse_package_json path =
  if not (Cn_ffi.Fs.exists path) then None
  else
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Error _ -> None
    | Ok json ->
        match Cn_json.get_string "name" json,
              Cn_json.get_string "version" json,
              parse_sources json with
        | Some name, Some version, Some sources ->
            Some { name; version; sources }
        | _ -> None

(* === File operations === *)

(** Recursive copy: src_dir → dst_dir, preserving structure. *)
let rec copy_tree src_dir dst_dir =
  if Cn_ffi.Fs.exists src_dir then begin
    Cn_ffi.Fs.ensure_dir dst_dir;
    (try
      Cn_ffi.Fs.readdir src_dir
      |> List.iter (fun entry ->
        let src = Cn_ffi.Path.join src_dir entry in
        let dst = Cn_ffi.Path.join dst_dir entry in
        if Sys.is_directory src then
          copy_tree src dst
        else
          Cn_ffi.Fs.write dst (Cn_ffi.Fs.read src))
    with _ -> ())
  end

(** Remove a directory tree. *)
let rec rm_tree path =
  if Cn_ffi.Fs.exists path then begin
    (try
      if Sys.is_directory path then begin
        Cn_ffi.Fs.readdir path |> List.iter (fun entry ->
          rm_tree (Cn_ffi.Path.join path entry));
        Unix.rmdir path
      end else
        Sys.remove path
    with _ -> ())
  end

(** Copy a single source entry for a given category.
    For doctrine/mindsets, entries can be "*" (all .md files) or specific filenames.
    For skills, entries are directory paths relative to src/agent/skills/. *)
let copy_source ~agent_root ~pkg_dir ~category entry =
  let src_category_dir = Cn_ffi.Path.join agent_root category in
  let dst_category_dir = Cn_ffi.Path.join pkg_dir category in
  if entry = "*" then begin
    (* Copy all .md files from the category directory *)
    if Cn_ffi.Fs.exists src_category_dir then begin
      Cn_ffi.Fs.ensure_dir dst_category_dir;
      (try
        Cn_ffi.Fs.readdir src_category_dir
        |> List.filter (fun f -> Filename.check_suffix f ".md")
        |> List.iter (fun f ->
          let src = Cn_ffi.Path.join src_category_dir f in
          let dst = Cn_ffi.Path.join dst_category_dir f in
          if not (Sys.is_directory src) then
            Cn_ffi.Fs.write dst (Cn_ffi.Fs.read src))
      with _ -> ())
    end
  end else if category = "mindsets" then begin
    (* Individual file copy *)
    let src = Cn_ffi.Path.join src_category_dir entry in
    if Cn_ffi.Fs.exists src then begin
      Cn_ffi.Fs.ensure_dir dst_category_dir;
      Cn_ffi.Fs.write (Cn_ffi.Path.join dst_category_dir entry)
        (Cn_ffi.Fs.read src)
    end
  end else begin
    (* Directory copy (skills) *)
    let src = Cn_ffi.Path.join src_category_dir entry in
    let dst = Cn_ffi.Path.join dst_category_dir entry in
    if Cn_ffi.Fs.exists src then
      copy_tree src dst
  end

(** Clean generated content from a package directory.
    Preserves cn.package.json, removes doctrine/, mindsets/, skills/. *)
let clean_package_dir pkg_dir =
  List.iter (fun sub ->
    let path = Cn_ffi.Path.join pkg_dir sub in
    if Cn_ffi.Fs.exists path then rm_tree path
  ) ["doctrine"; "mindsets"; "skills"]

(* === Build === *)

(** Discover all package manifests under packages/. *)
let discover_packages root =
  let pkgs_dir = packages_path root in
  if not (Cn_ffi.Fs.exists pkgs_dir) then []
  else
    try
      Cn_ffi.Fs.readdir pkgs_dir
      |> List.sort String.compare
      |> List.filter_map (fun dir_name ->
        let manifest_path = Cn_ffi.Path.join
          (Cn_ffi.Path.join pkgs_dir dir_name) "cn.package.json" in
        match parse_package_json manifest_path with
        | Some pkg -> Some (dir_name, pkg)
        | None -> None)
    with _ -> []

(** Build a single package: clean then copy sources. *)
let build_one ~agent_root ~pkgs_dir (dir_name, pkg) =
  let pkg_dir = Cn_ffi.Path.join pkgs_dir dir_name in
  clean_package_dir pkg_dir;
  (* Copy doctrine *)
  pkg.sources.doctrine |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir ~category:"doctrine" entry);
  (* Copy mindsets *)
  pkg.sources.mindsets |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir ~category:"mindsets" entry);
  (* Copy skills *)
  pkg.sources.skills |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir ~category:"skills" entry);
  pkg

(** Compare file content between two paths. Returns list of mismatches. *)
let rec diff_tree src dst prefix =
  let mismatches = ref [] in
  let add msg = mismatches := msg :: !mismatches in
  if Cn_ffi.Fs.exists src then begin
    if not (Cn_ffi.Fs.exists dst) then
      add (Printf.sprintf "missing: %s/" prefix)
    else begin
      (try
        let src_entries = Cn_ffi.Fs.readdir src |> List.sort String.compare in
        let dst_entries = Cn_ffi.Fs.readdir dst |> List.sort String.compare in
        (* Check for files in src not in dst *)
        src_entries |> List.iter (fun entry ->
          let src_path = Cn_ffi.Path.join src entry in
          let dst_path = Cn_ffi.Path.join dst entry in
          let rel = if prefix = "" then entry else prefix ^ "/" ^ entry in
          if Sys.is_directory src_path then
            mismatches := !mismatches @ diff_tree src_path dst_path rel
          else if not (Cn_ffi.Fs.exists dst_path) then
            add (Printf.sprintf "missing: %s" rel)
          else begin
            let src_content = Cn_ffi.Fs.read src_path in
            let dst_content = Cn_ffi.Fs.read dst_path in
            if src_content <> dst_content then
              add (Printf.sprintf "differs: %s" rel)
          end);
        (* Check for files in dst not in src *)
        dst_entries |> List.iter (fun entry ->
          let src_path = Cn_ffi.Path.join src entry in
          let rel = if prefix = "" then entry else prefix ^ "/" ^ entry in
          if not (Cn_ffi.Fs.exists src_path) then
            add (Printf.sprintf "extra: %s" rel))
      with _ -> add (Printf.sprintf "error reading: %s" prefix))
    end
  end;
  !mismatches

(** Check a single package: build to temp, compare with current. *)
let check_one ~agent_root ~pkgs_dir (dir_name, pkg) =
  let pkg_dir = Cn_ffi.Path.join pkgs_dir dir_name in
  let tmp_dir = Cn_ffi.Path.join "/tmp"
    (Printf.sprintf "cn-build-check-%s" dir_name) in
  (* Build into tmp *)
  rm_tree tmp_dir;
  Cn_ffi.Fs.ensure_dir tmp_dir;
  pkg.sources.doctrine |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir:tmp_dir ~category:"doctrine" entry);
  pkg.sources.mindsets |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir:tmp_dir ~category:"mindsets" entry);
  pkg.sources.skills |> List.iter (fun entry ->
    copy_source ~agent_root ~pkg_dir:tmp_dir ~category:"skills" entry);
  (* Compare *)
  let mismatches =
    List.concat_map (fun cat ->
      let tmp_cat = Cn_ffi.Path.join tmp_dir cat in
      let pkg_cat = Cn_ffi.Path.join pkg_dir cat in
      if Cn_ffi.Fs.exists tmp_cat || Cn_ffi.Fs.exists pkg_cat then
        diff_tree tmp_cat pkg_cat cat
      else []
    ) ["doctrine"; "mindsets"; "skills"]
  in
  rm_tree tmp_dir;
  (pkg.name, mismatches)

(* === Programmatic check for a single package === *)

(** Check whether a specific package's built output in packages/ is in sync
    with src/agent/.  Returns Ok () if in sync (or if we're not in the cnos
    repo / no src/agent/ exists), Error msg if stale.
    Called by cn_deps before local first-party restore to prevent installing
    stale generated artifacts. *)
let check_package ?root pkg_name =
  let root = match root with Some r -> Some r | None -> repo_root () in
  match root with
  | None -> Ok ()  (* not in cnos repo — nothing to check *)
  | Some root ->
      let agent_root = agent_path root in
      let pkgs_dir = packages_path root in
      if not (Cn_ffi.Fs.exists agent_root) then Ok ()
      else
        let packages = discover_packages root in
        match List.find_opt (fun (_, pkg) -> pkg.name = pkg_name) packages with
        | None -> Ok ()  (* package not managed by build system *)
        | Some entry ->
            let (_name, mismatches) = check_one ~agent_root ~pkgs_dir entry in
            match mismatches with
            | [] -> Ok ()
            | issues ->
                Error (Printf.sprintf
                  "packages/%s is stale relative to src/agent/ — run 'cn build'\n  %s"
                  pkg_name (String.concat "\n  " issues))

(* === CLI entry points === *)

let run_build () =
  match repo_root () with
  | None ->
      print_endline (Cn_fmt.fail "Not in cnos repo (no dune-project found)");
      Cn_ffi.Process.exit 1
  | Some root ->
      let agent_root = agent_path root in
      let pkgs_dir = packages_path root in
      if not (Cn_ffi.Fs.exists agent_root) then begin
        print_endline (Cn_fmt.fail "src/agent/ not found");
        Cn_ffi.Process.exit 1
      end;
      let packages = discover_packages root in
      if packages = [] then begin
        print_endline (Cn_fmt.warn "No package manifests found in packages/");
        Cn_ffi.Process.exit 1
      end;
      print_endline (Cn_fmt.info "Building packages from src/agent/...");
      packages |> List.iter (fun entry ->
        let pkg = build_one ~agent_root ~pkgs_dir entry in
        let n_doctrine = List.length pkg.sources.doctrine in
        let n_mindsets = List.length pkg.sources.mindsets in
        let n_skills = List.length pkg.sources.skills in
        print_endline (Cn_fmt.ok (Printf.sprintf
          "%s@%s: %d doctrine, %d mindsets, %d skills"
          pkg.name pkg.version n_doctrine n_mindsets n_skills)));
      print_endline (Cn_fmt.ok (Printf.sprintf
        "Built %d packages" (List.length packages)))

let run_check () =
  match repo_root () with
  | None ->
      print_endline (Cn_fmt.fail "Not in cnos repo (no dune-project found)");
      Cn_ffi.Process.exit 1
  | Some root ->
      let agent_root = agent_path root in
      let pkgs_dir = packages_path root in
      let packages = discover_packages root in
      if packages = [] then begin
        print_endline (Cn_fmt.warn "No package manifests found");
        Cn_ffi.Process.exit 1
      end;
      let all_ok = ref true in
      packages |> List.iter (fun entry ->
        let (name, mismatches) = check_one ~agent_root ~pkgs_dir entry in
        match mismatches with
        | [] ->
            print_endline (Cn_fmt.ok (Printf.sprintf "%s: up to date" name))
        | issues ->
            all_ok := false;
            print_endline (Cn_fmt.fail (Printf.sprintf "%s: out of sync" name));
            issues |> List.iter (fun msg ->
              print_endline (Printf.sprintf "  %s" msg)));
      if not !all_ok then begin
        print_endline "";
        print_endline (Cn_fmt.fail "packages/ out of sync with src/agent/ — run 'cn build'");
        Cn_ffi.Process.exit 1
      end else
        print_endline (Cn_fmt.ok "All packages in sync with src/agent/")

let run_clean () =
  match repo_root () with
  | None ->
      print_endline (Cn_fmt.fail "Not in cnos repo (no dune-project found)");
      Cn_ffi.Process.exit 1
  | Some root ->
      let pkgs_dir = packages_path root in
      let packages = discover_packages root in
      packages |> List.iter (fun (dir_name, pkg) ->
        let pkg_dir = Cn_ffi.Path.join pkgs_dir dir_name in
        clean_package_dir pkg_dir;
        print_endline (Cn_fmt.ok (Printf.sprintf "Cleaned %s" pkg.name)));
      print_endline (Cn_fmt.ok (Printf.sprintf
        "Cleaned %d packages" (List.length packages)))
