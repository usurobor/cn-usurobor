(** cn_extension_test: ppx_expect tests for extension manifest parsing,
    registry building, discovery, and dispatch integration.

    Tests the pure parsing core and registry logic.
    Discovery tests use temp directories. *)

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

(* === Manifest parsing === *)

let show_manifest_result = function
  | Ok (m : Cn_extension.extension_manifest) ->
    Printf.printf "ok name=%s version=%s ops=%d backend=%s\n"
      m.name m.version (List.length m.ops) m.backend.backend_kind
  | Error e ->
    Printf.printf "error: %s\n" e

let%expect_test "parse valid manifest" =
  let json = {|{
    "schema": "cn.extension.v1",
    "name": "cnos.net.http",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "kind": "capability-provider",
    "backend": { "kind": "subprocess", "command": ["cnos-ext-http"] },
    "ops": [
      { "kind": "http_get", "class": "observe" },
      { "kind": "dns_resolve", "class": "observe" }
    ],
    "permissions": { "network": true },
    "engines": { "cnos": ">=3.12.0 <4.0.0" }
  }|} in
  show_manifest_result (Cn_extension.parse_manifest_string json);
  [%expect {| ok name=cnos.net.http version=1.0.0 ops=2 backend=subprocess |}]

let%expect_test "parse manifest missing name" =
  let json = {|{
    "schema": "cn.extension.v1",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": [] },
    "ops": []
  }|} in
  show_manifest_result (Cn_extension.parse_manifest_string json);
  [%expect {| error: missing required fields (schema, name, version, interface) |}]

let%expect_test "parse manifest missing ops" =
  let json = {|{
    "schema": "cn.extension.v1",
    "name": "test.ext",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": [] }
  }|} in
  show_manifest_result (Cn_extension.parse_manifest_string json);
  [%expect {| error: missing required field 'ops' |}]

let%expect_test "parse manifest invalid op class" =
  let json = {|{
    "schema": "cn.extension.v1",
    "name": "test.ext",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": [] },
    "ops": [{ "kind": "foo", "class": "invalid" }],
    "permissions": {},
    "engines": {}
  }|} in
  show_manifest_result (Cn_extension.parse_manifest_string json);
  [%expect {| error: invalid op class: invalid (must be observe or effect) |}]

let%expect_test "parse manifest with effect ops" =
  let json = {|{
    "schema": "cn.extension.v1",
    "name": "test.write",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": ["test-ext"] },
    "ops": [
      { "kind": "custom_write", "class": "effect" },
      { "kind": "custom_read", "class": "observe" }
    ],
    "permissions": {},
    "engines": {}
  }|} in
  show_manifest_result (Cn_extension.parse_manifest_string json);
  [%expect {| ok name=test.write version=1.0.0 ops=2 backend=subprocess |}]

let%expect_test "parse invalid JSON" =
  (match Cn_extension.parse_manifest_string "not json" with
   | Error msg ->
     (* Check prefix only — exact Cn_json.parse error wording varies by env *)
     let prefix = "JSON parse error:" in
     if String.length msg >= String.length prefix
        && String.sub msg 0 (String.length prefix) = prefix
     then print_endline "error: JSON parse error (details vary)"
     else Printf.printf "error: %s\n" msg
   | Ok _ -> print_endline "unexpected ok");
  [%expect {| error: JSON parse error (details vary) |}]

(* === Version compatibility === *)

let%expect_test "version constraint: compatible" =
  Printf.printf "%b\n"
    (Cn_extension.check_version_constraint
       ~runtime_version:"3.16.2" ">=3.12.0 <4.0.0");
  [%expect {| true |}]

let%expect_test "version constraint: too old" =
  Printf.printf "%b\n"
    (Cn_extension.check_version_constraint
       ~runtime_version:"3.11.0" ">=3.12.0 <4.0.0");
  [%expect {| false |}]

let%expect_test "version constraint: too new" =
  Printf.printf "%b\n"
    (Cn_extension.check_version_constraint
       ~runtime_version:"4.0.0" ">=3.12.0 <4.0.0");
  [%expect {| false |}]

let%expect_test "version constraint: exact boundary" =
  Printf.printf "%b\n"
    (Cn_extension.check_version_constraint
       ~runtime_version:"3.12.0" ">=3.12.0 <4.0.0");
  [%expect {| true |}]

(* === Op conflict detection === *)

let make_entry name ops_list state =
  let ops = List.map (fun (k, c) ->
    { Cn_extension.op_kind = k; op_class = c;
      request_schema = None; response_format = None }
  ) ops_list in
  { Cn_extension.
    manifest = {
      schema = "cn.extension.v1"; name; version = "1.0.0";
      interface = "cn.ext.v1"; ext_kind = "capability-provider";
      backend = { backend_kind = "subprocess"; command = [] };
      ops; permissions = []; engines = [];
    };
    package_name = name; package_path = "/tmp/" ^ name;
    state;
  }

let%expect_test "op conflict: no conflicts" =
  let entries = [
    make_entry "ext.a" [("op_a", "observe")] Cn_extension.Compatible;
    make_entry "ext.b" [("op_b", "observe")] Cn_extension.Compatible;
  ] in
  let result = Cn_extension.check_op_conflicts entries in
  List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state)
  ) result;
  [%expect {|
    ext.a: compatible
    ext.b: compatible
  |}]

let%expect_test "op conflict: duplicate op kind rejected" =
  let entries = [
    make_entry "ext.a" [("shared_op", "observe")] Cn_extension.Compatible;
    make_entry "ext.b" [("shared_op", "observe")] Cn_extension.Compatible;
  ] in
  let result = Cn_extension.check_op_conflicts entries in
  List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state)
  ) result;
  [%expect {|
    ext.a: compatible
    ext.b: rejected: op kind 'shared_op' already provided by ext.a
  |}]

let%expect_test "op conflict: already rejected entries skipped" =
  let entries = [
    make_entry "ext.a" [("op_a", "observe")] (Cn_extension.Rejected "bad");
    make_entry "ext.b" [("op_a", "observe")] Cn_extension.Compatible;
  ] in
  let result = Cn_extension.check_op_conflicts entries in
  List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state)
  ) result;
  [%expect {|
    ext.a: rejected: bad
    ext.b: compatible
  |}]

(* === Enablement === *)

let%expect_test "enablement: compatible becomes enabled" =
  let entries = [
    make_entry "ext.a" [("op_a", "observe")] Cn_extension.Compatible;
  ] in
  let result = Cn_extension.apply_enablement entries in
  List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state)
  ) result;
  [%expect {| ext.a: enabled |}]

let%expect_test "enablement: disabled by config" =
  let entries = [
    make_entry "ext.a" [("op_a", "observe")] Cn_extension.Compatible;
  ] in
  let result = Cn_extension.apply_enablement
    ~disabled_extensions:["ext.a"] entries in
  List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state)
  ) result;
  [%expect {| ext.a: disabled |}]

(* === Registry building and op lookup === *)

let%expect_test "registry: lookup enabled op" =
  let entries = [
    make_entry "ext.a" [("op_a", "observe"); ("op_b", "effect")]
      Cn_extension.Compatible;
  ] in
  let enabled = Cn_extension.apply_enablement entries in
  let reg = { Cn_extension.extensions = enabled;
              op_index = Hashtbl.create 8 } in
  enabled |> List.iter (fun entry ->
    match entry.Cn_extension.state with
    | Cn_extension.Enabled ->
      entry.manifest.ops |> List.iter (fun op ->
        Hashtbl.replace reg.op_index op.Cn_extension.op_kind (entry, op))
    | _ -> ());
  (match Cn_extension.lookup_op reg "op_a" with
   | Some (entry, op) ->
     Printf.printf "found: %s %s\n" entry.manifest.name op.op_class
   | None -> Printf.printf "not found\n");
  (match Cn_extension.lookup_op reg "unknown_op" with
   | Some _ -> Printf.printf "found (wrong!)\n"
   | None -> Printf.printf "not found\n");
  [%expect {|
    found: ext.a observe
    not found
  |}]

let%expect_test "empty registry: lookup returns None" =
  let reg = Cn_extension.empty_registry () in
  (match Cn_extension.lookup_op reg "anything" with
   | Some _ -> Printf.printf "found (wrong!)\n"
   | None -> Printf.printf "not found\n");
  [%expect {| not found |}]

(* === Extension op kind in cn_shell === *)

let%expect_test "shell: extension op parsed via ext_lookup" =
  let ext_lookup = function
    | "http_get" -> Some ("http_get", "observe")
    | "custom_write" -> Some ("custom_write", "effect")
    | _ -> None
  in
  let ops, receipts = Cn_shell.parse_ops_manifest ~ext_lookup
    {|[{"kind":"http_get","url":"https://example.com"},{"kind":"custom_write","op_id":"w-01","data":"test"}]|} in
  Printf.printf "ops=%d receipts=%d\n" (List.length ops) (List.length receipts);
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "  %s effect=%b\n"
      (Cn_shell.string_of_op_kind op.kind)
      (Cn_shell.is_effect op.kind)
  ) ops;
  [%expect {|
    ops=2 receipts=0
      http_get effect=false
      custom_write effect=true
  |}]

let%expect_test "shell: unknown op kind without ext_lookup is denied" =
  let ops, receipts = Cn_shell.parse_ops_manifest
    {|[{"kind":"http_get"}]|} in
  Printf.printf "ops=%d receipts=%d\n" (List.length ops) (List.length receipts);
  List.iter (fun r ->
    Printf.printf "  %s %s\n" r.Cn_shell.kind r.Cn_shell.reason
  ) receipts;
  [%expect {|
    ops=0 receipts=1
      http_get unknown_op_kind
  |}]

let%expect_test "shell: extension observe op auto-assigns id" =
  let ext_lookup = function
    | "http_get" -> Some ("http_get", "observe")
    | _ -> None
  in
  let ops, _ = Cn_shell.parse_ops_manifest ~ext_lookup
    {|[{"kind":"http_get","url":"https://example.com"}]|} in
  List.iter (fun (op : Cn_shell.typed_op) ->
    Printf.printf "%s id=%s\n"
      (Cn_shell.string_of_op_kind op.kind)
      (match op.op_id with Some id -> id | None -> "none")
  ) ops;
  [%expect {| http_get id=obs-01 |}]

let%expect_test "shell: extension effect op requires op_id" =
  let ext_lookup = function
    | "custom_write" -> Some ("custom_write", "effect")
    | _ -> None
  in
  let _ops, receipts = Cn_shell.parse_ops_manifest ~ext_lookup
    {|[{"kind":"custom_write","data":"test"}]|} in
  List.iter (fun r ->
    Printf.printf "%s %s %s\n" r.Cn_shell.kind
      (Cn_shell.string_of_receipt_status r.status) r.reason
  ) receipts;
  [%expect {| custom_write denied missing_op_id |}]

(* === Extension JSON serialization === *)

let%expect_test "extension_to_json" =
  let entry = make_entry "cnos.net.http"
    [("http_get", "observe"); ("dns_resolve", "observe")]
    Cn_extension.Enabled in
  let json = Cn_extension.extension_to_json entry in
  let name = Cn_json.get_string "name" json in
  let state = Cn_json.get_string "state" json in
  Printf.printf "name=%s state=%s\n"
    (match name with Some s -> s | None -> "?")
    (match state with Some s -> s | None -> "?");
  [%expect {| name=cnos.net.http state=enabled |}]

(* === Host protocol JSON === *)

let%expect_test "host: execute request serialization" =
  let req = Cn_ext_host.Execute {
    op_kind = "http_get";
    arguments = [("url", Cn_json.String "https://example.com")];
    limits = [("timeout_sec", Cn_json.Int 30)];
    permissions = [("allowed_domains", Cn_json.Array [Cn_json.String "example.com"])];
  } in
  let json = Cn_ext_host.request_to_json req in
  let method_ = Cn_json.get_string "method" json in
  Printf.printf "method=%s\n"
    (match method_ with Some s -> s | None -> "?");
  let op = Cn_json.get "op" json in
  (match op with
   | Some obj ->
     let kind = Cn_json.get_string "kind" obj in
     Printf.printf "op.kind=%s\n"
       (match kind with Some s -> s | None -> "?")
   | None -> Printf.printf "no op\n");
  [%expect {|
    method=execute
    op.kind=http_get
  |}]

let%expect_test "host: describe request serialization" =
  let json = Cn_ext_host.request_to_json Cn_ext_host.Describe in
  let method_ = Cn_json.get_string "method" json in
  Printf.printf "method=%s\n"
    (match method_ with Some s -> s | None -> "?");
  [%expect {| method=describe |}]

let%expect_test "host: parse ok response" =
  let json = Cn_json.Object [
    ("status", Cn_json.String "ok");
    ("data", Cn_json.Object [("content", Cn_json.String "hello")]);
  ] in
  (match Cn_ext_host.parse_response json with
   | Ok resp -> Printf.printf "status=%s has_data=%b\n"
       resp.status (resp.data <> None)
   | Error e -> Printf.printf "error: %s\n" e);
  [%expect {| status=ok has_data=true |}]

let%expect_test "host: parse error response" =
  let json = Cn_json.Object [
    ("status", Cn_json.String "error");
    ("error", Cn_json.String "domain_not_allowed");
  ] in
  (match Cn_ext_host.parse_response json with
   | Ok resp -> Printf.printf "status=%s error=%s\n"
       resp.status (match resp.error with Some e -> e | None -> "none")
   | Error e -> Printf.printf "parse error: %s\n" e);
  [%expect {| status=error error=domain_not_allowed |}]

(* === Discovery integration (filesystem) === *)

let%expect_test "discover: empty vendor dir" =
  let tmp = mk_temp_dir "cn-ext-test" in
  let vendor = tmp ^ "/.cn/vendor/packages" in
  Cn_ffi.Fs.ensure_dir vendor;
  let entries = Cn_extension.discover ~hub_path:tmp in
  Printf.printf "found=%d\n" (List.length entries);
  [%expect {| found=0 |}]

let%expect_test "discover: finds extension manifest" =
  let tmp = mk_temp_dir "cn-ext-test" in
  let ext_dir = tmp ^ "/.cn/vendor/packages/cnos.net.http@1.0.0/extensions/cnos.net.http" in
  Cn_ffi.Fs.ensure_dir ext_dir;
  Cn_ffi.Fs.write (ext_dir ^ "/cn.extension.json") {|{
    "schema": "cn.extension.v1",
    "name": "cnos.net.http",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": ["cnos-ext-http"] },
    "ops": [{ "kind": "http_get", "class": "observe" }],
    "permissions": {},
    "engines": { "cnos": ">=3.12.0 <4.0.0" }
  }|};
  let entries = Cn_extension.discover ~hub_path:tmp in
  Printf.printf "found=%d\n" (List.length entries);
  List.iter (fun e ->
    Printf.printf "  %s pkg=%s state=%s ops=%d\n"
      e.Cn_extension.manifest.name
      e.package_name
      (Cn_extension.string_of_lifecycle_state e.state)
      (List.length e.manifest.ops)
  ) entries;
  [%expect {|
    found=1
      cnos.net.http pkg=cnos.net.http state=discovered ops=1
  |}]

let%expect_test "build_registry: full lifecycle" =
  let tmp = mk_temp_dir "cn-ext-test" in
  let ext_dir = tmp ^ "/.cn/vendor/packages/cnos.net.http@1.0.0/extensions/cnos.net.http" in
  Cn_ffi.Fs.ensure_dir ext_dir;
  Cn_ffi.Fs.write (ext_dir ^ "/cn.extension.json") {|{
    "schema": "cn.extension.v1",
    "name": "cnos.net.http",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": ["cnos-ext-http"] },
    "ops": [
      { "kind": "http_get", "class": "observe" },
      { "kind": "dns_resolve", "class": "observe" }
    ],
    "permissions": { "network": true },
    "engines": { "cnos": ">=3.12.0 <4.0.0" }
  }|};
  let reg = Cn_extension.build_registry ~hub_path:tmp
    ~runtime_version:"3.17.0" () in
  Printf.printf "extensions=%d\n" (List.length reg.extensions);
  reg.extensions |> List.iter (fun e ->
    Printf.printf "  %s state=%s\n"
      e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state));
  (* Verify op lookup works *)
  (match Cn_extension.lookup_op reg "http_get" with
   | Some (_, op) -> Printf.printf "http_get: %s\n" op.op_class
   | None -> Printf.printf "http_get: not found\n");
  (match Cn_extension.lookup_op reg "dns_resolve" with
   | Some (_, op) -> Printf.printf "dns_resolve: %s\n" op.op_class
   | None -> Printf.printf "dns_resolve: not found\n");
  (match Cn_extension.lookup_op reg "fs_read" with
   | Some _ -> Printf.printf "fs_read: found (wrong!)\n"
   | None -> Printf.printf "fs_read: not found (correct — built-in)\n");
  [%expect {|
    extensions=1
      cnos.net.http state=enabled
    http_get: observe
    dns_resolve: observe
    fs_read: not found (correct — built-in)
  |}]

let%expect_test "build_registry: incompatible engine rejected" =
  let tmp = mk_temp_dir "cn-ext-test" in
  let ext_dir = tmp ^ "/.cn/vendor/packages/old.ext@1.0.0/extensions/old.ext" in
  Cn_ffi.Fs.ensure_dir ext_dir;
  Cn_ffi.Fs.write (ext_dir ^ "/cn.extension.json") {|{
    "schema": "cn.extension.v1",
    "name": "old.ext",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": [] },
    "ops": [{ "kind": "old_op", "class": "observe" }],
    "permissions": {},
    "engines": { "cnos": ">=4.0.0 <5.0.0" }
  }|};
  let reg = Cn_extension.build_registry ~hub_path:tmp
    ~runtime_version:"3.17.0" () in
  reg.extensions |> List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state));
  (match Cn_extension.lookup_op reg "old_op" with
   | Some _ -> Printf.printf "old_op: found (wrong!)\n"
   | None -> Printf.printf "old_op: not found (correct — rejected)\n");
  [%expect {|
    old.ext: rejected: engine incompatible: requires cnos >=4.0.0 <5.0.0, have 3.17.0
    old_op: not found (correct — rejected)
  |}]

let%expect_test "build_registry: disabled extension" =
  let tmp = mk_temp_dir "cn-ext-test" in
  let ext_dir = tmp ^ "/.cn/vendor/packages/cnos.net.http@1.0.0/extensions/cnos.net.http" in
  Cn_ffi.Fs.ensure_dir ext_dir;
  Cn_ffi.Fs.write (ext_dir ^ "/cn.extension.json") {|{
    "schema": "cn.extension.v1",
    "name": "cnos.net.http",
    "version": "1.0.0",
    "interface": "cn.ext.v1",
    "backend": { "kind": "subprocess", "command": ["cnos-ext-http"] },
    "ops": [{ "kind": "http_get", "class": "observe" }],
    "permissions": {},
    "engines": {}
  }|};
  let reg = Cn_extension.build_registry ~hub_path:tmp
    ~runtime_version:"3.17.0"
    ~disabled_extensions:["cnos.net.http"] () in
  reg.extensions |> List.iter (fun e ->
    Printf.printf "%s: %s\n" e.Cn_extension.manifest.name
      (Cn_extension.string_of_lifecycle_state e.state));
  (match Cn_extension.lookup_op reg "http_get" with
   | Some _ -> Printf.printf "http_get: found (wrong — should be disabled)\n"
   | None -> Printf.printf "http_get: not found (correct — disabled)\n");
  [%expect {|
    cnos.net.http: disabled
    http_get: not found (correct — disabled)
  |}]

(* === Policy intersection === *)

(* Invariant: effective permissions = extension-declared ∩ runtime-allowed.
   Secrets are always stripped. Network passes through if declared. *)

let test_manifest ?(permissions = []) () : Cn_extension.extension_manifest =
  { schema = "cn.extension.v1"; name = "test.ext"; version = "1.0.0";
    interface = "cn.ext.v1"; ext_kind = "capability-provider";
    backend = { backend_kind = "subprocess"; command = ["test-host"] };
    ops = []; permissions;
    engines = [] }

(* exec_enabled=true to test permission intersection; false tested below *)
let exec_config = { Cn_shell.default_shell_config with exec_enabled = true }

let%expect_test "effective_permissions: network passes through when declared" =
  let manifest = test_manifest ~permissions:[
    "network", Cn_json.Bool true;
    "default_read_only", Cn_json.Bool true;
  ] () in
  let eff = Cn_extension.effective_permissions ~manifest ~config:exec_config in
  List.iter (fun (k, _) -> Printf.printf "%s\n" k) eff;
  [%expect {|
    network
    default_read_only
  |}]

let%expect_test "effective_permissions: no network when not declared" =
  let manifest = test_manifest ~permissions:[
    "default_read_only", Cn_json.Bool true;
  ] () in
  let eff = Cn_extension.effective_permissions ~manifest ~config:exec_config in
  List.iter (fun (k, _) -> Printf.printf "%s\n" k) eff;
  [%expect {| default_read_only |}]

(* Invariant: secrets are never passed to the host — always stripped to empty *)
let%expect_test "effective_permissions: secrets always stripped" =
  let manifest = test_manifest ~permissions:[
    "allow_secrets", Cn_json.Array [Cn_json.String "API_KEY"];
  ] () in
  let eff = Cn_extension.effective_permissions ~manifest ~config:exec_config in
  List.iter (fun (k, v) ->
    Printf.printf "%s=%s\n" k (Cn_json.to_string v)) eff;
  [%expect {| allow_secrets=[] |}]

(* Invariant: exec_enabled=false gates ALL permissions — nothing passes through *)
let%expect_test "effective_permissions: exec_disabled returns empty" =
  let manifest = test_manifest ~permissions:[
    "network", Cn_json.Bool true;
    "default_read_only", Cn_json.Bool true;
    "allow_secrets", Cn_json.Array [Cn_json.String "KEY"];
  ] () in
  let config = Cn_shell.default_shell_config in (* exec_enabled=false *)
  let eff = Cn_extension.effective_permissions ~manifest ~config in
  Printf.printf "permissions count: %d\n" (List.length eff);
  [%expect {| permissions count: 0 |}]

let%expect_test "execution_limits: derives from shell_config" =
  let config = { Cn_shell.default_shell_config with
    max_artifact_bytes_per_op = 8192 } in
  let limits = Cn_extension.execution_limits ~config in
  List.iter (fun (k, v) ->
    Printf.printf "%s=%s\n" k (Cn_json.to_string v)) limits;
  [%expect {| max_artifact_bytes=8192 |}]

(* === Host binary protocol (cnos-ext-http stub) === *)

(* Resolve host binary path. Works from repo root (local dev),
   dune build sandbox (_build/default/test/cmd/), and dune inline_tests.
   The dune (deps) stanza ensures the file is available. *)
let find_host_binary () =
  let rel = "src/agent/extensions/cnos.net.http/host/cnos-ext-http" in
  let candidates = [
    (* dune inline_tests: deps path relative to test/cmd/ *)
    "../../" ^ rel;
    (* repo root (cwd = repo root) *)
    Sys.getcwd () ^ "/" ^ rel;
    (* walk up from cwd to find repo root *)
    "../../../" ^ rel;
    "../../../../" ^ rel;
  ] in
  List.find_opt Sys.file_exists candidates

(* Invariant: host responds to describe with extension metadata *)
let%expect_test "host stub: describe returns extension info" =
  (match find_host_binary () with
   | None -> Printf.printf "host not found (skipping)\n"
   | Some host_path ->
     let request = Cn_ext_host.request_to_json Cn_ext_host.Describe in
     let input = Cn_json.to_string request ^ "\n" in
     let code, output =
       Cn_ffi.Process.exec_args ~prog:host_path ~args:[]
         ~stdin_data:input () in
     Printf.printf "exit=%d\n" code;
     (match Cn_json.parse (String.trim output) with
      | Ok json ->
        (match Cn_json.get_string "status" json with
         | Some s -> Printf.printf "status=%s\n" s
         | None -> Printf.printf "no status\n");
        (match Cn_json.get "data" json with
         | Some data ->
           (match Cn_json.get_string "name" data with
            | Some n -> Printf.printf "name=%s\n" n
            | None -> Printf.printf "no name\n")
         | None -> Printf.printf "no data\n")
      | Error e -> Printf.printf "parse error: %s\n" e));
  [%expect {|
    exit=0
    status=ok
    name=cnos.net.http
  |}]

(* Invariant: host responds to health check *)
let%expect_test "host stub: health returns ok" =
  (match find_host_binary () with
   | None -> Printf.printf "host not found (skipping)\n"
   | Some host_path ->
     match Cn_ext_host.check_health ~command:[host_path] () with
     | Ok () -> Printf.printf "healthy\n"
     | Error msg -> Printf.printf "unhealthy: %s\n" msg);
  [%expect {| healthy |}]

(* Negative space: host rejects unknown op kinds *)
let%expect_test "host stub: unknown op kind rejected" =
  (match find_host_binary () with
   | None -> Printf.printf "host not found (skipping)\n"
   | Some host_path ->
     let result = Cn_ext_host.execute_extension_op
       ~command:[host_path] ~op_kind:"nonexistent_op"
       ~arguments:[] () in
     match result with
     | Ok _ -> Printf.printf "ok (wrong — should reject)\n"
     | Error msg -> Printf.printf "rejected: %s\n" msg);
  [%expect {| rejected: unknown op kind: nonexistent_op |}]

(* Negative space: http_get rejects missing URL *)
let%expect_test "host stub: http_get without url rejected" =
  (match find_host_binary () with
   | None -> Printf.printf "host not found (skipping)\n"
   | Some host_path ->
     let result = Cn_ext_host.execute_extension_op
       ~command:[host_path] ~op_kind:"http_get"
       ~arguments:[] () in
     match result with
     | Ok _ -> Printf.printf "ok (wrong — should reject)\n"
     | Error msg -> Printf.printf "rejected: %s\n" msg);
  [%expect {| rejected: missing required field: url |}]

(* Negative space: http_get rejects non-http URL schemes *)
let%expect_test "host stub: http_get rejects file:// scheme" =
  (match find_host_binary () with
   | None -> Printf.printf "host not found (skipping)\n"
   | Some host_path ->
     let result = Cn_ext_host.execute_extension_op
       ~command:[host_path] ~op_kind:"http_get"
       ~arguments:["url", Cn_json.String "file:///etc/passwd"] () in
     match result with
     | Ok _ -> Printf.printf "ok (wrong — should reject)\n"
     | Error msg -> Printf.printf "rejected: %s\n" msg);
  [%expect {| rejected: url must use http or https scheme |}]
