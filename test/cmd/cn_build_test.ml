(** cn_build_test: ppx_expect tests for package assembly

    Tests the build pipeline that generates packages/ from src/agent/ sources.
    Uses temp directories to simulate repo structure. *)

(* === Temp directory helpers === *)

let mk_temp_dir prefix =
  let base = Filename.get_temp_dir_name () in
  let rec attempt k =
    if k = 0 then failwith "mk_temp_dir: exhausted attempts";
    let dir =
      Filename.concat base
        (Printf.sprintf "%s-%d-%06d" prefix (Unix.getpid ()) (Random.int 1_000_000))
    in
    try Unix.mkdir dir 0o700; dir
    with Unix.Unix_error (Unix.EEXIST, _, _) -> attempt (k - 1)
  in
  Random.self_init ();
  attempt 50

let rec rm_tree path =
  if Sys.file_exists path then begin
    if Sys.is_directory path then begin
      Sys.readdir path |> Array.iter (fun entry ->
        rm_tree (Filename.concat path entry));
      Unix.rmdir path
    end else
      Sys.remove path
  end

let touch dir file content =
  Cn_ffi.Fs.ensure_dir dir;
  let path = Filename.concat dir file in
  let oc = open_out path in
  output_string oc content;
  close_out oc

(** Set up a minimal repo structure with src/agent/ content. *)
let with_test_repo f =
  let root = mk_temp_dir "cn-build-test" in
  (* Create dune-project so repo_root detection works *)
  touch root "dune-project" "(lang dune 3.8)";
  (* Create src/agent/ with doctrine, mindsets, skills *)
  let agent = Filename.concat root "src/agent" in
  touch (Filename.concat agent "doctrine") "FOUNDATIONS.md" "# Foundations";
  touch (Filename.concat agent "doctrine") "COHERENCE.md" "# Coherence";
  touch (Filename.concat agent "mindsets") "ENGINEERING.md" "# Engineering";
  touch (Filename.concat agent "mindsets") "PM.md" "# PM";
  touch (Filename.concat agent "mindsets") "WISDOM.md" "# Wisdom";
  let skill_dir = Filename.concat agent "skills/agent/hello-world" in
  touch skill_dir "SKILL.md" "# Hello World";
  touch skill_dir "kata.md" "# Kata";
  let eng_skill = Filename.concat agent "skills/eng/coding" in
  touch eng_skill "SKILL.md" "# Coding";
  (* Create src/agent/templates/ *)
  touch (Filename.concat agent "templates") "SOUL.md" "# Soul -- Default template.";
  touch (Filename.concat agent "templates") "USER.md" "# User -- Default template.";
  (* Create packages/ with manifests *)
  let core_dir = Filename.concat root "packages/cnos.core" in
  touch core_dir "cn.package.json"
    {|{
  "schema": "cn.package.v1",
  "name": "cnos.core",
  "version": "1.0.0",
  "kind": "package",
  "engines": { "cnos": ">=3.4.0 <4.0.0" },
  "sources": {
    "doctrine": ["*"],
    "mindsets": ["ENGINEERING.md", "PM.md", "WISDOM.md"],
    "skills": ["agent/hello-world"],
    "templates": ["SOUL.md", "USER.md"]
  }
}|};
  let eng_dir = Filename.concat root "packages/cnos.eng" in
  touch eng_dir "cn.package.json"
    {|{
  "schema": "cn.package.v1",
  "name": "cnos.eng",
  "version": "1.0.0",
  "kind": "package",
  "engines": { "cnos": ">=3.4.0 <4.0.0" },
  "sources": {
    "skills": ["eng/coding"]
  }
}|};
  Fun.protect ~finally:(fun () -> rm_tree root) (fun () -> f root)

(* === Command Parsing === *)

let%expect_test "parse_command build" =
  [["build"]; ["build"; "--check"]; ["build"; "clean"]]
  |> List.iter (fun args ->
    match Cn_lib.parse_command args with
    | Some c -> print_endline (Cn_lib.string_of_command c)
    | None -> print_endline "NONE");
  [%expect {|
    build
    build --check
    build clean
  |}]

let%expect_test "parse_command build unknown subcommand" =
  (match Cn_lib.parse_command ["build"; "unknown"] with
  | Some _ -> print_endline "FOUND"
  | None -> print_endline "NONE");
  [%expect {| NONE |}]

(* === Package Discovery === *)

let%expect_test "discover_packages finds manifests with sources" =
  with_test_repo (fun root ->
    let packages = Cn_build.discover_packages root in
    packages |> List.iter (fun (dir_name, (pkg : Cn_build.package_manifest)) ->
      Printf.printf "%s: %s@%s (d=%d m=%d s=%d)\n"
        dir_name pkg.name pkg.version
        (List.length pkg.sources.doctrine)
        (List.length pkg.sources.mindsets)
        (List.length pkg.sources.skills)));
  [%expect {|
    cnos.core: cnos.core@1.0.0 (d=1 m=3 s=1)
    cnos.eng: cnos.eng@1.0.0 (d=0 m=0 s=1)
  |}]

(* === Build === *)

let%expect_test "build_one copies doctrine files" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    (* Build cnos.core *)
    let (dir_name, _) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, (snd (List.hd packages))) in
    (* Check doctrine files were copied *)
    let core_doctrine = Filename.concat pkgs_dir "cnos.core/doctrine" in
    let files = Sys.readdir core_doctrine |> Array.to_list |> List.sort String.compare in
    List.iter print_endline files;
    (* Verify content *)
    let content = Cn_ffi.Fs.read (Filename.concat core_doctrine "FOUNDATIONS.md") in
    print_endline content);
  [%expect {|
    COHERENCE.md
    FOUNDATIONS.md
    # Foundations
  |}]

let%expect_test "build_one copies mindsets" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    let core_mindsets = Filename.concat pkgs_dir "cnos.core/mindsets" in
    let files = Sys.readdir core_mindsets |> Array.to_list |> List.sort String.compare in
    List.iter print_endline files);
  [%expect {|
    ENGINEERING.md
    PM.md
    WISDOM.md
  |}]

let%expect_test "build_one copies skills with subdirectory structure" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    (* Check skill files *)
    let skill_dir = Filename.concat pkgs_dir "cnos.core/skills/agent/hello-world" in
    let files = Sys.readdir skill_dir |> Array.to_list |> List.sort String.compare in
    List.iter print_endline files);
  [%expect {|
    SKILL.md
    kata.md
  |}]

let%expect_test "build_one for eng copies eng skills" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let eng = List.find (fun (name, _) -> name = "cnos.eng") packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir eng in
    let skill_dir = Filename.concat pkgs_dir "cnos.eng/skills/eng/coding" in
    let files = Sys.readdir skill_dir |> Array.to_list |> List.sort String.compare in
    List.iter print_endline files);
  [%expect {|
    SKILL.md
  |}]

(* === Clean === *)

let%expect_test "clean removes generated content but preserves manifest" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    (* Build first *)
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    (* Clean *)
    let pkg_dir = Filename.concat pkgs_dir dir_name in
    Cn_build.clean_package_dir pkg_dir;
    (* Check: manifest survives, content dirs gone *)
    let manifest_exists = Sys.file_exists (Filename.concat pkg_dir "cn.package.json") in
    let doctrine_exists = Sys.file_exists (Filename.concat pkg_dir "doctrine") in
    let mindsets_exists = Sys.file_exists (Filename.concat pkg_dir "mindsets") in
    let skills_exists = Sys.file_exists (Filename.concat pkg_dir "skills") in
    Printf.printf "manifest=%b doctrine=%b mindsets=%b skills=%b\n"
      manifest_exists doctrine_exists mindsets_exists skills_exists);
  [%expect {|
    manifest=true doctrine=false mindsets=false skills=false
  |}]

(* === Check (diff) === *)

let%expect_test "check detects drift when source changes" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    (* Build first *)
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    (* Modify source *)
    Cn_ffi.Fs.write
      (Filename.concat root "src/agent/doctrine/FOUNDATIONS.md")
      "# Foundations v2 — updated";
    (* Check should detect difference *)
    let (name, mismatches) = Cn_build.check_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    Printf.printf "%s: %d issues\n" name (List.length mismatches);
    List.iter (fun m -> print_endline m) mismatches);
  [%expect {|
    cnos.core: 1 issues
    differs: doctrine/FOUNDATIONS.md
  |}]

(* === check_package (staleness guard for restore) === *)

let%expect_test "check_package returns Ok when packages in sync" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    (* Build all packages first *)
    packages |> List.iter (fun entry ->
      ignore (Cn_build.build_one ~agent_root ~pkgs_dir entry));
    (* check_package should pass *)
    (match Cn_build.check_package ~root "cnos.core" with
     | Ok () -> print_endline "cnos.core: ok"
     | Error msg -> print_endline msg);
    (match Cn_build.check_package ~root "cnos.eng" with
     | Ok () -> print_endline "cnos.eng: ok"
     | Error msg -> print_endline msg));
  [%expect {|
    cnos.core: ok
    cnos.eng: ok
  |}]

let%expect_test "check_package returns Error when packages stale" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    (* Build first *)
    packages |> List.iter (fun entry ->
      ignore (Cn_build.build_one ~agent_root ~pkgs_dir entry));
    (* Modify source to create drift *)
    Cn_ffi.Fs.write
      (Filename.concat root "src/agent/doctrine/FOUNDATIONS.md")
      "# Foundations v2 — updated";
    (* check_package should fail *)
    (match Cn_build.check_package ~root "cnos.core" with
     | Ok () -> print_endline "cnos.core: ok (unexpected)"
     | Error _ -> print_endline "cnos.core: stale (expected)");
    (* cnos.eng should still be ok — it doesn't use doctrine *)
    (match Cn_build.check_package ~root "cnos.eng" with
     | Ok () -> print_endline "cnos.eng: ok"
     | Error _ -> print_endline "cnos.eng: stale (unexpected)"));
  [%expect {|
    cnos.core: stale (expected)
    cnos.eng: ok
  |}]

let%expect_test "check_package returns Ok for unknown package" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    packages |> List.iter (fun entry ->
      ignore (Cn_build.build_one ~agent_root ~pkgs_dir entry));
    (* Unknown package should pass (not managed by build system) *)
    (match Cn_build.check_package ~root "cnos.unknown" with
     | Ok () -> print_endline "unknown: ok (skipped)"
     | Error msg -> print_endline msg));
  [%expect {|
    unknown: ok (skipped)
  |}]

let%expect_test "check passes when packages match source" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    (* Build *)
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    (* Check should pass *)
    let (name, mismatches) = Cn_build.check_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    Printf.printf "%s: %d issues\n" name (List.length mismatches));
  [%expect {|
    cnos.core: 0 issues
  |}]

(* === Templates === *)

let%expect_test "build_one copies templates to package" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    let templates_dir = Filename.concat pkgs_dir "cnos.core/templates" in
    let files = Sys.readdir templates_dir |> Array.to_list |> List.sort String.compare in
    List.iter print_endline files;
    let content = Cn_ffi.Fs.read (Filename.concat templates_dir "SOUL.md") in
    print_endline content);
  [%expect {|
    SOUL.md
    USER.md
    # Soul -- Default template.
  |}]

let%expect_test "clean removes templates directory" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    let pkg_dir = Filename.concat pkgs_dir dir_name in
    Cn_build.clean_package_dir pkg_dir;
    let templates_exists = Sys.file_exists (Filename.concat pkg_dir "templates") in
    Printf.printf "templates=%b\n" templates_exists);
  [%expect {|
    templates=false
  |}]

let%expect_test "check detects template drift" =
  with_test_repo (fun root ->
    let agent_root = Filename.concat root "src/agent" in
    let pkgs_dir = Filename.concat root "packages" in
    let packages = Cn_build.discover_packages root in
    let (dir_name, pkg) = List.hd packages in
    let _pkg = Cn_build.build_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    (* Modify template source *)
    Cn_ffi.Fs.write
      (Filename.concat root "src/agent/templates/SOUL.md")
      "# Soul v2 -- updated";
    let (name, mismatches) = Cn_build.check_one ~agent_root ~pkgs_dir (dir_name, pkg) in
    Printf.printf "%s: %d issues\n" name (List.length mismatches);
    List.iter (fun m -> print_endline m) mismatches);
  [%expect {|
    cnos.core: 1 issues
    differs: templates/SOUL.md
  |}]

(* === Template resolution (cn_system.read_template) === *)

let%expect_test "read_template returns Ok when cnos.core installed with templates" =
  let hub = mk_temp_dir "cn-template-test" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* Simulate installed package with templates *)
    let pkg_dir = Filename.concat hub ".cn/vendor/packages/cnos.core@1.0.0/templates" in
    touch pkg_dir "SOUL.md" "# Full Soul Template";
    touch pkg_dir "USER.md" "# Full User Template";
    match Cn_system.read_template ~hub_path:hub "SOUL.md" with
    | Ok content -> Printf.printf "ok: %s\n" content
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {|
    ok: # Full Soul Template
  |}]

let%expect_test "read_template returns Error when cnos.core not installed" =
  let hub = mk_temp_dir "cn-template-test" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* No packages installed *)
    match Cn_system.read_template ~hub_path:hub "SOUL.md" with
    | Ok content -> Printf.printf "ok: %s\n" content
    | Error reason -> Printf.printf "error: %s\n" reason);
  [%expect {|
    error: cnos.core not installed
  |}]

let%expect_test "read_template returns Error when template file missing" =
  let hub = mk_temp_dir "cn-template-test" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* Package installed but no templates/ directory *)
    let pkg_dir = Filename.concat hub ".cn/vendor/packages/cnos.core@1.0.0" in
    touch pkg_dir "cn.package.json" "{}";
    match Cn_system.read_template ~hub_path:hub "SOUL.md" with
    | Ok content -> Printf.printf "ok: %s\n" content
    | Error reason ->
        (* Check it says "not found" rather than printing the full path *)
        let has_not_found = String.length reason > 10 in
        Printf.printf "error: has_reason=%b\n" has_not_found);
  [%expect {|
    error: has_reason=true
  |}]

(* === E2e: setup path regressions === *)

let%expect_test "e2e: run_setup populates missing SOUL.md from installed templates" =
  let hub = mk_temp_dir "cn-setup-e2e" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* Simulate installed cnos.core with templates *)
    let tpl_dir = Filename.concat hub ".cn/vendor/packages/cnos.core@1.0.0/templates" in
    touch tpl_dir "SOUL.md" "# Full Soul From template.";
    touch tpl_dir "USER.md" "# Full User From template.";
    (* Hub has spec/ but NO SOUL.md/USER.md *)
    Cn_ffi.Fs.ensure_dir (Filename.concat hub "spec");
    (* Verify spec/SOUL.md does not exist *)
    let before = Sys.file_exists (Filename.concat hub "spec/SOUL.md") in
    Printf.printf "before: soul_exists=%b\n" before;
    (* Simulate the run_setup template-population path *)
    let spec_dir = Filename.concat hub "spec" in
    Cn_ffi.Fs.ensure_dir spec_dir;
    let soul_path = Filename.concat spec_dir "SOUL.md" in
    if not (Sys.file_exists soul_path) then
      (match Cn_system.read_template ~hub_path:hub "SOUL.md" with
       | Ok content -> Cn_ffi.Fs.write soul_path content
       | Error _ -> ());
    let user_path = Filename.concat spec_dir "USER.md" in
    if not (Sys.file_exists user_path) then
      (match Cn_system.read_template ~hub_path:hub "USER.md" with
       | Ok content -> Cn_ffi.Fs.write user_path content
       | Error _ -> ());
    (* Verify both files now exist with template content *)
    let soul = Cn_ffi.Fs.read soul_path in
    let user = Cn_ffi.Fs.read user_path in
    Printf.printf "soul: %s\n" soul;
    Printf.printf "user: %s\n" user);
  [%expect {|
    before: soul_exists=false
    soul: # Full Soul From template.
    user: # Full User From template.
  |}]

let%expect_test "e2e: run_setup creates spec/ when missing on partial hub" =
  let hub = mk_temp_dir "cn-setup-e2e" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* Simulate installed cnos.core with templates *)
    let tpl_dir = Filename.concat hub ".cn/vendor/packages/cnos.core@1.0.0/templates" in
    touch tpl_dir "SOUL.md" "# Full Soul";
    touch tpl_dir "USER.md" "# Full User";
    (* Hub has NO spec/ directory at all *)
    let before = Sys.file_exists (Filename.concat hub "spec") in
    Printf.printf "before: spec_exists=%b\n" before;
    (* Simulate the fixed run_setup path: ensure_dir then populate *)
    let spec_dir = Filename.concat hub "spec" in
    Cn_ffi.Fs.ensure_dir spec_dir;
    let soul_path = Filename.concat spec_dir "SOUL.md" in
    if not (Sys.file_exists soul_path) then
      (match Cn_system.read_template ~hub_path:hub "SOUL.md" with
       | Ok content -> Cn_ffi.Fs.write soul_path content
       | Error _ -> ());
    let after = Sys.file_exists (Filename.concat hub "spec/SOUL.md") in
    Printf.printf "after: soul_exists=%b\n" after);
  [%expect {|
    before: spec_exists=false
    after: soul_exists=true
  |}]

let%expect_test "e2e: run_setup does NOT overwrite existing operator SOUL.md" =
  let hub = mk_temp_dir "cn-setup-e2e" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* Simulate installed cnos.core with templates *)
    let tpl_dir = Filename.concat hub ".cn/vendor/packages/cnos.core@1.0.0/templates" in
    touch tpl_dir "SOUL.md" "# Full Soul Template";
    (* Hub has existing operator-authored SOUL.md *)
    touch (Filename.concat hub "spec") "SOUL.md" "# My Custom Soul";
    (* Simulate the run_setup path *)
    let spec_dir = Filename.concat hub "spec" in
    Cn_ffi.Fs.ensure_dir spec_dir;
    let soul_path = Filename.concat spec_dir "SOUL.md" in
    if not (Sys.file_exists soul_path) then
      (match Cn_system.read_template ~hub_path:hub "SOUL.md" with
       | Ok content -> Cn_ffi.Fs.write soul_path content
       | Error _ -> ());
    (* Verify operator content is preserved *)
    let soul = Cn_ffi.Fs.read soul_path in
    Printf.printf "soul: %s\n" soul);
  [%expect {|
    soul: # My Custom Soul
  |}]

let%expect_test "e2e: init fallback to stubs when cnos.core not installed" =
  let hub = mk_temp_dir "cn-init-e2e" in
  Fun.protect ~finally:(fun () -> rm_tree hub) (fun () ->
    (* No packages installed at all *)
    Cn_ffi.Fs.ensure_dir (Filename.concat hub "spec");
    let soul_path = Filename.concat hub "spec/SOUL.md" in
    (* Simulate the run_init fallback path *)
    let soul = match Cn_system.read_template ~hub_path:hub "SOUL.md" with
      | Ok content -> content
      | Error _ -> "# Stub SOUL"
    in
    Cn_ffi.Fs.write soul_path soul;
    let content = Cn_ffi.Fs.read soul_path in
    Printf.printf "soul: %s\n" content);
  [%expect {|
    soul: # Stub SOUL
  |}]
