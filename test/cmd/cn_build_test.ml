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
    "skills": ["agent/hello-world"]
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
    packages |> List.iter (fun (dir_name, pkg) ->
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
