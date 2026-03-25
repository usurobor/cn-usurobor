(** cn_extension.ml — Extension manifest parsing, registry, and discovery

    Implements the extension architecture from RUNTIME-EXTENSIONS.md v1.0.6.

    Key concepts:
    - Extension: installed component providing typed ops (not a package, skill, or capability)
    - Capability Provider: runtime-facing execution endpoint (e.g. cnos.net.http)
    - Extension Host: subprocess (default) or native trusted (opt-in)
    - Open Op Registry: replaces closed built-in op vocabulary with registry + dispatch

    Discovery:
    - Scans .cn/vendor/packages/<pkg>@<ver>/extensions/<ext>/cn.extension.json
    - Builds registry with typed ops, permissions, compatibility, lifecycle state
    - Discovers eagerly, activates lazily

    Design constraints:
    - Pure parsing; discovery I/O isolated in discover functions
    - Op kinds must be globally unique — conflicts rejected, never shadowed
    - Extension-declared permissions intersected with runtime config *)

(* === Types === *)

type extension_op = {
  op_kind : string;            (* e.g., "http_get" *)
  op_class : string;         (* "observe" | "effect" *)
  request_schema : string option;
  response_format : string option;
}

type backend = {
  backend_kind : string;     (* "subprocess" | "native" *)
  command : string list;     (* e.g., ["cnos-ext-http"] *)
}

type extension_manifest = {
  schema : string;           (* "cn.extension.v1" *)
  name : string;             (* e.g., "cnos.net.http" *)
  version : string;
  interface : string;        (* e.g., "cn.ext.v1" *)
  ext_kind : string;         (* e.g., "capability-provider" *)
  backend : backend;
  ops : extension_op list;
  permissions : (string * Cn_json.t) list;
  engines : (string * string) list;  (* e.g., [("cnos", ">=3.12.0 <4.0.0")] *)
}

type lifecycle_state =
  | Discovered
  | Compatible
  | Enabled
  | Disabled
  | Rejected of string

type extension_entry = {
  manifest : extension_manifest;
  package_name : string;
  package_path : string;
  state : lifecycle_state;
}

type registry = {
  extensions : extension_entry list;
  op_index : (string, extension_entry * extension_op) Hashtbl.t;
}

(* === Manifest parsing === *)

let parse_backend json =
  match json with
  | Cn_json.Object _ ->
    let kind = match Cn_json.get_string "kind" json with
      | Some k -> k | None -> "subprocess" in
    let command = match Cn_json.get_list "command" json with
      | Some items ->
        List.filter_map (function Cn_json.String s -> Some s | _ -> None) items
      | None -> [] in
    Ok { backend_kind = kind; command }
  | _ -> Error "backend must be an object"

let parse_op json =
  match json with
  | Cn_json.Object _ ->
    let kind = Cn_json.get_string "kind" json in
    let op_class = Cn_json.get_string "class" json in
    (match kind, op_class with
     | Some k, Some c when c = "observe" || c = "effect" ->
       Ok {
         op_kind = k;
         op_class = c;
         request_schema = Cn_json.get_string "request_schema" json;
         response_format = Cn_json.get_string "response_format" json;
       }
     | Some _, Some c ->
       Error (Printf.sprintf "invalid op class: %s (must be observe or effect)" c)
     | None, _ -> Error "op missing required field 'kind'"
     | _, None -> Error "op missing required field 'class'")
  | _ -> Error "op must be an object"

let parse_engines json =
  match json with
  | Cn_json.Object pairs ->
    List.filter_map (fun (k, v) ->
      match v with
      | Cn_json.String s -> Some (k, s)
      | _ -> None
    ) pairs
  | _ -> []

let parse_permissions json =
  match json with
  | Cn_json.Object pairs -> pairs
  | _ -> []

(** Parse an extension manifest from JSON. Pure function. *)
let parse_manifest json =
  match json with
  | Cn_json.Object _ ->
    let get_str key = Cn_json.get_string key json in
    (match get_str "schema", get_str "name", get_str "version",
           get_str "interface" with
     | Some schema, Some name, Some version, Some interface ->
       let ext_kind = match get_str "kind" with
         | Some k -> k | None -> "capability-provider" in
       let backend_result = match Cn_json.get "backend" json with
         | Some b -> parse_backend b
         | None -> Error "missing required field 'backend'" in
       let ops_result =
         match Cn_json.get_list "ops" json with
         | Some items ->
           let results = List.map parse_op items in
           let errors = List.filter_map (function Error e -> Some e | Ok _ -> None) results in
           let oks = List.filter_map (function Ok o -> Some o | Error _ -> None) results in
           if errors <> [] then Error (String.concat "; " errors)
           else Ok oks
         | None -> Error "missing required field 'ops'" in
       let permissions = match Cn_json.get "permissions" json with
         | Some p -> parse_permissions p | None -> [] in
       let engines = match Cn_json.get "engines" json with
         | Some e -> parse_engines e | None -> [] in
       (match backend_result, ops_result with
        | Ok backend, Ok ops ->
          Ok { schema; name; version; interface; ext_kind;
               backend; ops; permissions; engines }
        | Error e, _ | _, Error e -> Error e)
     | _ -> Error "missing required fields (schema, name, version, interface)")
  | _ -> Error "manifest must be a JSON object"

(** Parse a manifest from a JSON string. *)
let parse_manifest_string s =
  match Cn_json.parse s with
  | Ok json -> parse_manifest json
  | Error msg -> Error (Printf.sprintf "JSON parse error: %s" msg)

(* === Version compatibility === *)

(** Simple semver range check: supports >=X.Y.Z and <X.Y.Z constraints.
    Returns true if runtime_version satisfies the constraint string.
    Constraint format: ">=3.12.0 <4.0.0" (space-separated). *)
let check_version_constraint ~runtime_version constraint_str =
  let parse_version v =
    match String.split_on_char '.' v with
    | [maj; min; pat] ->
      (try Some (int_of_string maj, int_of_string min, int_of_string pat)
       with Failure _ -> None)
    | [maj; min] ->
      (try Some (int_of_string maj, int_of_string min, 0)
       with Failure _ -> None)
    | _ -> None
  in
  let compare_versions (a1, a2, a3) (b1, b2, b3) =
    let c1 = compare a1 b1 in
    if c1 <> 0 then c1
    else let c2 = compare a2 b2 in
    if c2 <> 0 then c2
    else compare a3 b3
  in
  (* Parse ">=3.12.0" into (Gte, "3.12.0") etc. *)
  let parse_constraint part =
    let len = String.length part in
    if len > 2 && String.sub part 0 2 = ">=" then
      Some (`Gte, String.sub part 2 (len - 2))
    else if len > 2 && String.sub part 0 2 = "<=" then
      Some (`Lte, String.sub part 2 (len - 2))
    else if len > 1 && part.[0] = '>' then
      Some (`Gt, String.sub part 1 (len - 1))
    else if len > 1 && part.[0] = '<' then
      Some (`Lt, String.sub part 1 (len - 1))
    else if len > 0 then
      Some (`Eq, part)
    else
      None
  in
  match parse_version runtime_version with
  | None -> false
  | Some rv ->
    let parts = String.split_on_char ' ' constraint_str
      |> List.filter (fun s -> s <> "") in
    List.for_all (fun part ->
      match parse_constraint part with
      | None -> false
      | Some (op, ver_str) ->
        match parse_version ver_str with
        | None -> false
        | Some cv ->
          let cmp = compare_versions rv cv in
          match op with
          | `Gte -> cmp >= 0
          | `Gt  -> cmp > 0
          | `Lte -> cmp <= 0
          | `Lt  -> cmp < 0
          | `Eq  -> cmp = 0
    ) parts

(* === Discovery === *)

(** Discover extensions from installed packages.
    Scans .cn/vendor/packages/<pkg>@<ver>/extensions/<ext>/cn.extension.json *)
let discover ~hub_path =
  let vendor_dir = Cn_ffi.Path.join hub_path ".cn/vendor/packages" in
  if not (Cn_ffi.Fs.exists vendor_dir) then []
  else
    let pkg_dirs = try Cn_ffi.Fs.readdir vendor_dir with Sys_error _ -> [] in
    List.concat_map (fun pkg_dir ->
      let pkg_path = Cn_ffi.Path.join vendor_dir pkg_dir in
      let ext_root = Cn_ffi.Path.join pkg_path "extensions" in
      if not (Cn_ffi.Fs.exists ext_root) || not (Sys.is_directory ext_root) then []
      else
        let ext_dirs = try Cn_ffi.Fs.readdir ext_root with Sys_error _ -> [] in
        List.filter_map (fun ext_dir ->
          let ext_path = Cn_ffi.Path.join ext_root ext_dir in
          let manifest_path = Cn_ffi.Path.join ext_path "cn.extension.json" in
          if not (Cn_ffi.Fs.exists manifest_path) then None
          else
            let content = Cn_ffi.Fs.read manifest_path in
            match parse_manifest_string content with
            | Ok manifest ->
              let pkg_name = match String.index_opt pkg_dir '@' with
                | Some i -> String.sub pkg_dir 0 i
                | None -> pkg_dir in
              Some {
                manifest;
                package_name = pkg_name;
                package_path = pkg_path;
                state = Discovered;
              }
            | Error reason ->
              Cn_trace.gemit ~component:"extension" ~layer:Mind
                ~event:"extension.parse_error" ~severity:Warn ~status:Error_status
                ~reason_code:"manifest_parse_failed"
                ~reason
                ~details:[
                  "path", Cn_json.String manifest_path;
                  "package", Cn_json.String pkg_dir;
                ] ();
              None
        ) ext_dirs
    ) pkg_dirs

(** Check engine compatibility for an extension entry. *)
let check_compatibility ~runtime_version entry =
  let cnos_constraint =
    List.assoc_opt "cnos" entry.manifest.engines in
  match cnos_constraint with
  | None -> { entry with state = Compatible }
  | Some constraint_str ->
    if check_version_constraint ~runtime_version constraint_str then
      { entry with state = Compatible }
    else
      { entry with state = Rejected (
          Printf.sprintf "engine incompatible: requires cnos %s, have %s"
            constraint_str runtime_version) }

(** Check for duplicate op kinds across extensions.
    Returns updated entries with conflicts rejected.
    Uses fold to thread the op-owner map through the list without
    mixing mutable state and List.map. *)
let check_op_conflicts entries =
  let _op_owners, result =
    List.fold_left (fun (op_owners, acc) entry ->
      match entry.state with
      | Rejected _ -> (op_owners, entry :: acc)
      | _ ->
        let conflicts = entry.manifest.ops |> List.filter_map (fun op ->
          match Hashtbl.find_opt op_owners op.op_kind with
          | Some owner ->
            Some (Printf.sprintf "op kind '%s' already provided by %s"
                    op.op_kind owner)
          | None -> None
        ) in
        if conflicts <> [] then
          (op_owners, { entry with state = Rejected (String.concat "; " conflicts) } :: acc)
        else begin
          entry.manifest.ops |> List.iter (fun op ->
            Hashtbl.replace op_owners op.op_kind entry.manifest.name);
          (op_owners, entry :: acc)
        end
    ) (Hashtbl.create 32, []) entries
  in
  List.rev result

(** Apply runtime config enablement policy.
    Extensions with state=Compatible are promoted to Enabled
    unless runtime config explicitly disables them. *)
let apply_enablement ?(disabled_extensions = []) entries =
  List.map (fun entry ->
    match entry.state with
    | Compatible ->
      if List.mem entry.manifest.name disabled_extensions then
        { entry with state = Disabled }
      else
        { entry with state = Enabled }
    | _ -> entry
  ) entries

(* === Registry building === *)

(** Build a complete extension registry from hub state.
    Steps: discover → compatibility → conflict check → enablement → index
    Emits traceability events for each extension lifecycle transition. *)
let build_registry ~hub_path ~runtime_version ?(disabled_extensions = []) () =
  let discovered = discover ~hub_path in
  (* Emit discovery events *)
  discovered |> List.iter (fun entry ->
    Cn_trace.gemit ~component:"extension" ~layer:Mind
      ~event:"extension.discovered" ~severity:Info ~status:Ok_
      ~details:[
        "name", Cn_json.String entry.manifest.name;
        "version", Cn_json.String entry.manifest.version;
        "package", Cn_json.String entry.package_name;
        "ops_count", Cn_json.Int (List.length entry.manifest.ops);
      ] ());
  let compatible = List.map (check_compatibility ~runtime_version) discovered in
  let conflict_checked = check_op_conflicts compatible in
  let enabled = apply_enablement ~disabled_extensions conflict_checked in
  (* Emit lifecycle state events *)
  enabled |> List.iter (fun entry ->
    match entry.state with
    | Rejected reason ->
      Cn_trace.gemit ~component:"extension" ~layer:Mind
        ~event:"extension.rejected" ~severity:Warn ~status:Error_status
        ~reason_code:"rejected"
        ~reason
        ~details:["name", Cn_json.String entry.manifest.name] ()
    | Disabled ->
      Cn_trace.gemit ~component:"extension" ~layer:Mind
        ~event:"extension.disabled" ~severity:Info ~status:Skipped
        ~details:["name", Cn_json.String entry.manifest.name] ()
    | Enabled ->
      Cn_trace.gemit ~component:"extension" ~layer:Mind
        ~event:"extension.loaded" ~severity:Info ~status:Ok_
        ~details:[
          "name", Cn_json.String entry.manifest.name;
          "ops", Cn_json.Array (List.map (fun op ->
            Cn_json.String op.op_kind) entry.manifest.ops);
        ] ()
    | Discovered | Compatible -> ());
  (* Build op index from enabled extensions only *)
  let op_index = Hashtbl.create 32 in
  enabled |> List.iter (fun entry ->
    match entry.state with
    | Enabled ->
      entry.manifest.ops |> List.iter (fun op ->
        Hashtbl.replace op_index op.op_kind (entry, op))
    | _ -> ()
  );
  { extensions = enabled; op_index }

(** Look up an op kind in the registry.
    Returns the extension entry and op info if found and enabled. *)
let lookup_op registry kind_str =
  Hashtbl.find_opt registry.op_index kind_str

(** Get all enabled extension op kinds for capabilities block. *)
let enabled_ops registry =
  let ops = Hashtbl.fold (fun _kind (entry, op) acc ->
    (entry.manifest.name, op) :: acc
  ) registry.op_index [] in
  List.sort (fun (a, _) (b, _) -> String.compare a b) ops

(** Get all extension entries (for Runtime Contract / doctor). *)
let all_entries registry = registry.extensions

(** Create an empty registry (for when no extensions are installed). *)
let empty_registry () =
  { extensions = []; op_index = Hashtbl.create 0 }

(* === String helpers === *)

let string_of_lifecycle_state = function
  | Discovered -> "discovered"
  | Compatible -> "compatible"
  | Enabled -> "enabled"
  | Disabled -> "disabled"
  | Rejected reason -> Printf.sprintf "rejected: %s" reason

(* === JSON serialization for doctor / traceability === *)

let extension_to_json entry =
  let str s = Cn_json.String s in
  let (b : backend) = entry.manifest.backend in
  Cn_json.Object [
    "name", str entry.manifest.name;
    "version", str entry.manifest.version;
    "package", str entry.package_name;
    "backend", str b.backend_kind;
    "state", str (string_of_lifecycle_state entry.state);
    "ops", Cn_json.Array (List.map (fun op ->
      Cn_json.Object [
        "kind", str op.op_kind;
        "class", str op.op_class;
      ]
    ) entry.manifest.ops);
  ]
