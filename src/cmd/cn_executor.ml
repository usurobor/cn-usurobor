(** cn_executor.ml — Typed op executor for CN Shell

    Executes observe and effect ops, produces receipts and artifacts.
    Uses cn_sandbox for path validation, cn_sha256 for artifact hashing.

    Design:
    - Three separate execution paths: fs, git, exec
    - All produce receipts in a single place (execute_op)
    - Artifacts written to state/artifacts/<trigger_id>/<op_id>.*
    - Receipts written to state/receipts/<trigger_id>.json
    - No two-pass logic here — that belongs in Step 5 (orchestrator) *)

(* === Timestamps === *)

let now_iso () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  Printf.sprintf "%04d-%02d-%02dT%02d:%02d:%02dZ"
    (tm.Unix.tm_year + 1900) (tm.Unix.tm_mon + 1) tm.Unix.tm_mday
    tm.Unix.tm_hour tm.Unix.tm_min tm.Unix.tm_sec

(* === Artifact writing === *)

(** Write artifact content, returning artifact record.
    Caps content at max_bytes. *)
let write_artifact ~hub_path ~trigger_id ~op_id ~ext ~content ~max_bytes =
  let dir = Cn_ffi.Path.join hub_path
              (Printf.sprintf "state/artifacts/%s" trigger_id) in
  Cn_ffi.Fs.ensure_dir dir;
  let capped = if String.length content > max_bytes
    then String.sub content 0 max_bytes
    else content in
  let filename = Printf.sprintf "%s.%s" op_id ext in
  let path = Cn_ffi.Path.join dir filename in
  Cn_ffi.Fs.write path capped;
  let rel_path = Printf.sprintf "state/artifacts/%s/%s" trigger_id filename in
  { Cn_shell.path = rel_path;
    hash = Cn_sha256.hash_prefixed capped;
    size = String.length capped }

(* === Environment scrubbing === *)

(** Drop vars matching *_KEY, *_TOKEN, *_SECRET, plus explicit list. *)
let scrub_env ~extra_keys =
  let is_secret key =
    let ends_with ~suffix s =
      let sl = String.length suffix and kl = String.length s in
      kl >= sl && String.sub s (kl - sl) sl = suffix
    in
    ends_with ~suffix:"_KEY" key
    || ends_with ~suffix:"_TOKEN" key
    || ends_with ~suffix:"_SECRET" key
    || List.mem key extra_keys
  in
  (* Read current environment, filter out secrets *)
  let env = Unix.environment () |> Array.to_list in
  List.filter_map (fun entry ->
    match String.index_opt entry '=' with
    | None -> Some entry  (* malformed, pass through *)
    | Some i ->
      let key = String.sub entry 0 i in
      if is_secret key then None
      else Some entry
  ) env
  |> List.map (fun entry ->
    match String.index_opt entry '=' with
    | None -> (entry, "")
    | Some i ->
      (String.sub entry 0 i,
       String.sub entry (i + 1) (String.length entry - i - 1)))

(* === Git path exclusion === *)

(** Pathspec exclusions for git observe ops (diff, log, grep).
    Excludes internal dirs only — protected files are readable.
    Write-protection for protected files is enforced per-candidate
    in git_stage via Cn_sandbox.validate_path ~access:Write_access. *)
let git_observe_exclusions =
  ["--"; "."; ":!.cn"; ":!state"; ":!logs"]

(* === Op field extraction helpers === *)

let get_field_string key op =
  match List.assoc_opt key op.Cn_shell.fields with
  | Some (Cn_json.String s) -> Some s
  | _ -> None

let get_field_int key op =
  match List.assoc_opt key op.Cn_shell.fields with
  | Some (Cn_json.Int i) -> Some i
  | _ -> None

let require_field_string key op =
  match get_field_string key op with
  | Some s -> Ok s
  | None -> Error (Printf.sprintf "missing required field '%s'" key)

(* === Observe op executors === *)

let execute_fs_read ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  match require_field_string "path" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_read";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok raw_path ->
    match Cn_sandbox.validate_path ~hub_path ~access:Read_access raw_path with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_read";
        status = Cn_shell.Denied;
        reason = Cn_sandbox.string_of_denial_reason reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok resolved ->
      let full = Cn_ffi.Path.join hub_path resolved in
      if not (Cn_ffi.Fs.exists full) then
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_read";
          status = Cn_shell.Error_status; reason = "file_not_found";
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
        let full_content = Cn_ffi.Fs.read full in
        let file_len = String.length full_content in
        (* v3.8.0: chunking support — offset and limit fields *)
        let offset = match get_field_int "offset" op with
          | Some o when o >= 0 -> o | _ -> 0 in
        let budget = config.Cn_shell.max_artifact_bytes_per_op in
        let limit = match get_field_int "limit" op with
          | Some l when l > 0 -> min l budget
          | _ -> budget in
        let content =
          if offset >= file_len then ""
          else
            let remaining = file_len - offset in
            let take = min limit remaining in
            String.sub full_content offset take
        in
        let op_id_str = match op.op_id with Some id -> id | None -> "unknown" in
        let artifact = write_artifact ~hub_path ~trigger_id ~op_id:op_id_str
                         ~ext:"txt" ~content
                         ~max_bytes:budget in
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_read";
          status = Cn_shell.Ok_status; reason = "";
          start_time = start; end_time = now_iso (); artifacts = [artifact] }

let execute_fs_list ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  match require_field_string "path" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_list";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok raw_path ->
    match Cn_sandbox.validate_path ~hub_path ~access:Read_access raw_path with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_list";
        status = Cn_shell.Denied;
        reason = Cn_sandbox.string_of_denial_reason reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok resolved ->
      let full = Cn_ffi.Path.join hub_path resolved in
      if not (Cn_ffi.Fs.exists full) then
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_list";
          status = Cn_shell.Error_status; reason = "directory_not_found";
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
        let entries = Cn_ffi.Fs.readdir full in
        let content = String.concat "\n" (List.sort String.compare entries) in
        let op_id_str = match op.op_id with Some id -> id | None -> "unknown" in
        let artifact = write_artifact ~hub_path ~trigger_id ~op_id:op_id_str
                         ~ext:"txt" ~content
                         ~max_bytes:config.Cn_shell.max_artifact_bytes_per_op in
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_list";
          status = Cn_shell.Ok_status; reason = "";
          start_time = start; end_time = now_iso (); artifacts = [artifact] }

let execute_git_op ~hub_path ~trigger_id ~config ~kind_str ~args (op : Cn_shell.typed_op) =
  let start = now_iso () in
  let code, output =
    Cn_ffi.Process.exec_args ~prog:"git"
      ~args:([ "-C"; hub_path ] @ args) ()
  in
  let op_id_str = match op.Cn_shell.op_id with Some id -> id | None -> "unknown" in
  if code <> 0 then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = kind_str;
      status = Cn_shell.Error_status;
      reason = Printf.sprintf "git_exit_%d" code;
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
    let artifact = write_artifact ~hub_path ~trigger_id ~op_id:op_id_str
                     ~ext:"txt" ~content:output
                     ~max_bytes:config.Cn_shell.max_artifact_bytes_per_op in
    { Cn_shell.pass = ""; op_id = op.op_id; kind = kind_str;
      status = Cn_shell.Ok_status; reason = "";
      start_time = start; end_time = now_iso (); artifacts = [artifact] }

let execute_git_status ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  execute_git_op ~hub_path ~trigger_id ~config ~kind_str:"git_status"
    ~args:["status"; "--porcelain"] op

let execute_git_diff ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let rev = match get_field_string "rev" op with
    | Some r -> [r]
    | None -> []
  in
  execute_git_op ~hub_path ~trigger_id ~config ~kind_str:"git_diff"
    ~args:(["diff"] @ rev @ git_observe_exclusions) op

let execute_git_log ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let max_n = match get_field_int "max" op with
    | Some n -> ["-n"; string_of_int n]
    | None -> ["-n"; "20"]
  in
  let rev = match get_field_string "rev" op with
    | Some r -> [r]
    | None -> []
  in
  execute_git_op ~hub_path ~trigger_id ~config ~kind_str:"git_log"
    ~args:(["log"; "--oneline"] @ max_n @ rev @ git_observe_exclusions) op

let execute_git_grep ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  match require_field_string "query" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_grep";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok query ->
    let path_args = match get_field_string "path" op with
      | Some raw_path ->
        (match Cn_sandbox.validate_path ~hub_path ~access:Read_access raw_path with
         | Error reason ->
           Error (Cn_sandbox.string_of_denial_reason reason)
         | Ok resolved -> Ok ["--"; resolved])
      | None -> Ok git_observe_exclusions
    in
    match path_args with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_grep";
        status = Cn_shell.Denied; reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok extra_args ->
      execute_git_op ~hub_path ~trigger_id ~config ~kind_str:"git_grep"
        ~args:(["grep"; "-n"; query] @ extra_args) op

(* === Glob matching (pure OCaml, no external dependency) === *)

(** Simple glob pattern matching: supports *, **, and ? *)
let rec glob_match pattern name =
  match pattern, name with
  | [], [] -> true
  | "**" :: rest, _ ->
    (* ** matches zero or more path segments *)
    glob_match rest name
    || (match name with _ :: name_rest -> glob_match pattern name_rest | [] -> false)
  | pat :: prest, seg :: nrest ->
    segment_match pat seg && glob_match prest nrest
  | _ :: _, [] | [], _ :: _ -> false

and segment_match pattern segment =
  let plen = String.length pattern in
  let slen = String.length segment in
  let rec aux pi si =
    if pi = plen && si = slen then true
    else if pi = plen then false
    else
      match pattern.[pi] with
      | '*' ->
        (* * matches zero or more chars within a segment *)
        let rec try_star si' =
          if si' > slen then false
          else if aux (pi + 1) si' then true
          else try_star (si' + 1)
        in
        try_star si
      | '?' ->
        if si < slen then aux (pi + 1) (si + 1) else false
      | c ->
        if si < slen && segment.[si] = c then aux (pi + 1) (si + 1) else false
  in
  aux 0 0

(** Split a glob pattern into path segments *)
let split_glob_pattern pat =
  String.split_on_char '/' pat
  |> List.filter (fun s -> s <> "")

(** Recursively walk a directory tree, returning relative paths.
    Validates each entry via Cn_sandbox.validate_path before descending
    or returning it. Tracks visited realpaths to prevent symlink cycles. *)
let walk_dir ~hub_path ~base_rel base_path =
  let visited = Hashtbl.create 64 in
  let rec go rel_prefix =
    let full = Cn_ffi.Path.join base_path rel_prefix in
    if not (Cn_ffi.Fs.exists full) then []
    else
      let entries = try Cn_ffi.Fs.readdir full with _ -> [] in
      List.concat_map (fun entry ->
        let rel = if rel_prefix = "." || rel_prefix = "" then entry
                  else rel_prefix ^ "/" ^ entry in
        let sandbox_rel = if base_rel = "." then rel
                          else base_rel ^ "/" ^ rel in
        let full_entry = Cn_ffi.Path.join base_path rel in
        (* Validate via sandbox before descending or returning *)
        match Cn_sandbox.validate_path ~hub_path ~access:Read_access sandbox_rel with
        | Error _ -> []
        | Ok _resolved ->
          if Sys.is_directory full_entry then
            (* Cycle detection via realpath *)
            let real = try Some (Unix.realpath full_entry)
                       with Unix.Unix_error _ -> None in
            (match real with
             | None -> []
             | Some rp ->
               if Hashtbl.mem visited rp then []
               else begin
                 Hashtbl.replace visited rp true;
                 rel :: go rel
               end)
          else
            [rel]
      ) entries
  in
  go ""

let execute_fs_glob ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  match require_field_string "pattern" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_glob";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok pattern ->
    let base = match get_field_string "base" op with
      | Some b -> b | None -> "." in
    match Cn_sandbox.validate_path ~hub_path ~access:Read_access base with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_glob";
        status = Cn_shell.Denied;
        reason = Cn_sandbox.string_of_denial_reason reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok resolved_base ->
      let base_full = Cn_ffi.Path.join hub_path resolved_base in
      let all_paths = walk_dir ~hub_path ~base_rel:resolved_base base_full in
      let glob_segs = split_glob_pattern pattern in
      (* walk_dir already validates and excludes denied paths and dirs *)
      let filtered = List.filter (fun p ->
        let path_segs = String.split_on_char '/' p
          |> List.filter (fun s -> s <> "") in
        glob_match glob_segs path_segs
      ) all_paths in
      let sorted = List.sort String.compare filtered in
      let content = String.concat "\n" sorted in
      let op_id_str = match op.op_id with Some id -> id | None -> "unknown" in
      let artifact = write_artifact ~hub_path ~trigger_id ~op_id:op_id_str
                       ~ext:"txt" ~content
                       ~max_bytes:config.Cn_shell.max_artifact_bytes_per_op in
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_glob";
        status = Cn_shell.Ok_status; reason = "";
        start_time = start; end_time = now_iso (); artifacts = [artifact] }

(* === Effect op executors === *)

let execute_fs_write ~hub_path ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if config.Cn_shell.apply_mode = "off" then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_write";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
  match require_field_string "path" op, require_field_string "content" op with
  | Error msg, _ | _, Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_write";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok raw_path, Ok content ->
    match Cn_sandbox.validate_path ~hub_path ~access:Write_access raw_path with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_write";
        status = Cn_shell.Denied;
        reason = Cn_sandbox.string_of_denial_reason reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok resolved ->
      let full = Cn_ffi.Path.join hub_path resolved in
      Cn_ffi.Fs.ensure_dir (Cn_ffi.Path.dirname full);
      Cn_ffi.Fs.write full content;
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_write";
        status = Cn_shell.Ok_status; reason = "";
        start_time = start; end_time = now_iso (); artifacts = [] }

let execute_fs_patch ~hub_path ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if config.Cn_shell.apply_mode = "off" then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_patch";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
  match require_field_string "path" op, require_field_string "unified_diff" op with
  | Error msg, _ | _, Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_patch";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok raw_path, Ok diff ->
    match Cn_sandbox.validate_path ~hub_path ~access:Write_access raw_path with
    | Error reason ->
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_patch";
        status = Cn_shell.Denied;
        reason = Cn_sandbox.string_of_denial_reason reason;
        start_time = start; end_time = now_iso (); artifacts = [] }
    | Ok resolved ->
      let full = Cn_ffi.Path.join hub_path resolved in
      (* Apply patch via `patch` command — argv-only, no shell *)
      let code, output =
        Cn_ffi.Process.exec_args ~prog:"patch"
          ~args:["--no-backup-if-mismatch"; "-p0"; full]
          ~stdin_data:diff ()
      in
      if code = 0 then
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_patch";
          status = Cn_shell.Ok_status; reason = "";
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "fs_patch";
          status = Cn_shell.Error_status;
          reason = Printf.sprintf "patch_failed: %s" (String.trim output);
          start_time = start; end_time = now_iso (); artifacts = [] }

let execute_git_branch ~hub_path ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if config.Cn_shell.apply_mode = "off" then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_branch";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
  match require_field_string "name" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_branch";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok name ->
    let code, output =
      Cn_ffi.Process.exec_args ~prog:"git"
        ~args:["-C"; hub_path; "checkout"; "-b"; name] ()
    in
    if code = 0 then
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_branch";
        status = Cn_shell.Ok_status; reason = "";
        start_time = start; end_time = now_iso (); artifacts = [] }
    else
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_branch";
        status = Cn_shell.Error_status;
        reason = Printf.sprintf "git_exit_%d: %s" code (String.trim output);
        start_time = start; end_time = now_iso (); artifacts = [] }

let execute_git_stage ~hub_path ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if config.Cn_shell.apply_mode = "off" then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
    (* Check for optional paths field (list of literal paths) *)
    let paths = match List.assoc_opt "paths" op.Cn_shell.fields with
      | Some (Cn_json.Array items) ->
        Some (List.filter_map (function
          | Cn_json.String s -> Some s | _ -> None) items)
      | _ -> None
    in
    match paths with
    | Some literal_paths ->
      (* Sandbox-check each path: must pass write validation AND must
         not be a directory (directories would stage descendants that
         were never individually validated) *)
      let bad = List.find_opt (fun p ->
        match Cn_sandbox.validate_path ~hub_path ~access:Write_access p with
        | Error _ -> true
        | Ok _ ->
          let full = Filename.concat hub_path p in
          try Sys.is_directory full with Sys_error _ -> false
      ) literal_paths in
      (match bad with
       | Some denied_path ->
         let is_dir = try Sys.is_directory (Filename.concat hub_path denied_path)
           with Sys_error _ -> false in
         let reason = if is_dir
           then Printf.sprintf "directory_not_allowed: %s" denied_path
           else Printf.sprintf "path_denied: %s" denied_path in
         { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
           status = Cn_shell.Denied; reason;
           start_time = start; end_time = now_iso (); artifacts = [] }
       | None ->
         (* Use --literal-pathspecs to prevent glob/magic interpretation,
            and -- to separate options from filenames *)
         let code, output =
           Cn_ffi.Process.exec_args ~prog:"git"
             ~args:(["--literal-pathspecs"; "-C"; hub_path; "add"; "--"]
                    @ literal_paths) ()
         in
         if code = 0 then
           { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
             status = Cn_shell.Ok_status; reason = "";
             start_time = start; end_time = now_iso (); artifacts = [] }
         else
           { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
             status = Cn_shell.Error_status;
             reason = Printf.sprintf "git_add_exit_%d: %s" code (String.trim output);
             start_time = start; end_time = now_iso (); artifacts = [] })
    | None ->
      (* No paths specified: enumerate all changed/untracked files,
         validate each through the sandbox, stage only the validated set.
         This ensures symlink resolution and protected file rules apply
         identically to stage-all and explicit-path modes.

         We use --porcelain=v1 -z --no-renames -uall for safe machine
         parsing: -z gives NUL-delimited output with unquoted paths,
         --no-renames suppresses the "<orig> -> <new>" rename format. *)
      let status_code, porcelain =
        Cn_ffi.Process.exec_args ~prog:"git"
          ~args:["-C"; hub_path; "status"; "--porcelain=v1"; "-z";
                 "--no-renames"; "-uall"] ()
      in
      if status_code <> 0 then
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
          status = Cn_shell.Error_status;
          reason = Printf.sprintf "git_status_exit_%d: %s" status_code
                     (String.trim porcelain);
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
      let candidates =
        String.split_on_char '\000' porcelain
        |> List.filter_map (fun entry ->
          if String.length entry < 4 then None
          else
            let path = String.sub entry 3 (String.length entry - 3) in
            if path = "" then None else Some path)
      in
      let safe_paths = List.filter (fun p ->
        match Cn_sandbox.validate_path ~hub_path ~access:Write_access p with
        | Ok _ ->
          let full = Filename.concat hub_path p in
          not (try Sys.is_directory full with Sys_error _ -> false)
        | Error _ -> false
      ) candidates in
      if safe_paths = [] then
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
          status = Cn_shell.Ok_status; reason = "";
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
        let code, output =
          Cn_ffi.Process.exec_args ~prog:"git"
            ~args:(["--literal-pathspecs"; "-C"; hub_path; "add"; "--"]
                   @ safe_paths) ()
        in
        if code = 0 then
          { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
            status = Cn_shell.Ok_status; reason = "";
            start_time = start; end_time = now_iso (); artifacts = [] }
        else
          { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_stage";
            status = Cn_shell.Error_status;
            reason = Printf.sprintf "git_add_exit_%d: %s" code (String.trim output);
            start_time = start; end_time = now_iso (); artifacts = [] }

let execute_git_commit ~hub_path ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if config.Cn_shell.apply_mode = "off" then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_commit";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
  match require_field_string "message" op with
  | Error msg ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_commit";
      status = Cn_shell.Error_status; reason = msg;
      start_time = start; end_time = now_iso (); artifacts = [] }
  | Ok message ->
    let allow_empty = match List.assoc_opt "allow_empty" op.Cn_shell.fields with
      | Some (Cn_json.Bool true) -> true | _ -> false in
    (* Commit current index only — no implicit staging.
       Use git_stage to stage files before git_commit. *)
    let commit_args = ["-C"; hub_path; "commit"; "-m"; message]
      @ (if allow_empty then ["--allow-empty"] else []) in
    let code, output =
      Cn_ffi.Process.exec_args ~prog:"git" ~args:commit_args ()
    in
    if code = 0 then
      { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_commit";
        status = Cn_shell.Ok_status; reason = "";
        start_time = start; end_time = now_iso (); artifacts = [] }
    else
      (* Check if nothing was staged *)
      let _porcelain_code, _porcelain_out =
        Cn_ffi.Process.exec_args ~prog:"git"
          ~args:["-C"; hub_path; "diff"; "--cached"; "--quiet"] ()
      in
      if _porcelain_code = 0 && not allow_empty then
        (* Nothing in the index — skip *)
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_commit";
          status = Cn_shell.Skipped; reason = "nothing_staged";
          start_time = start; end_time = now_iso (); artifacts = [] }
      else
        { Cn_shell.pass = ""; op_id = op.op_id; kind = "git_commit";
          status = Cn_shell.Error_status;
          reason = Printf.sprintf "git_commit_exit_%d: %s" code (String.trim output);
          start_time = start; end_time = now_iso (); artifacts = [] }

let execute_exec ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  let start = now_iso () in
  if not config.Cn_shell.exec_enabled then
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
      status = Cn_shell.Denied; reason = "policy_rejected";
      start_time = start; end_time = now_iso (); artifacts = [] }
  else
  match List.assoc_opt "argv" op.Cn_shell.fields with
  | Some (Cn_json.Array items) ->
    let argv = List.filter_map (function
      | Cn_json.String s -> Some s | _ -> None
    ) items in
    (match argv with
     | [] ->
       { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
         status = Cn_shell.Error_status; reason = "empty_argv";
         start_time = start; end_time = now_iso (); artifacts = [] }
     | prog :: args ->
       (* Resolve and check allowlist *)
       let resolved_prog =
         if String.length prog > 0 && prog.[0] = '/' then prog
         else
           (* Search PATH for the binary *)
           let path_dirs = match Sys.getenv_opt "PATH" with
             | Some p -> String.split_on_char ':' p
             | None -> ["/usr/bin"; "/bin"]
           in
           let found = List.find_opt (fun dir ->
             Sys.file_exists (Filename.concat dir prog)
           ) path_dirs in
           match found with
           | Some dir -> Filename.concat dir prog
           | None -> prog  (* will fail on exec *)
       in
       if not (List.mem resolved_prog config.exec_allowlist) then
         { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
           status = Cn_shell.Denied; reason = "policy_rejected";
           start_time = start; end_time = now_iso (); artifacts = [] }
       else
         let env = scrub_env ~extra_keys:[] in
         let code, output =
           Cn_ffi.Process.exec_args_env ~prog:resolved_prog ~args ~env ()
         in
         let op_id_str = match op.op_id with Some id -> id | None -> "unknown" in
         let artifact = write_artifact ~hub_path ~trigger_id ~op_id:op_id_str
                          ~ext:"stdout" ~content:output
                          ~max_bytes:config.max_artifact_bytes_per_op in
         if code = 0 then
           { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
             status = Cn_shell.Ok_status; reason = "";
             start_time = start; end_time = now_iso (); artifacts = [artifact] }
         else
           { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
             status = Cn_shell.Error_status;
             reason = Printf.sprintf "non_zero_exit";
             start_time = start; end_time = now_iso (); artifacts = [artifact] })
  | _ ->
    { Cn_shell.pass = ""; op_id = op.op_id; kind = "exec";
      status = Cn_shell.Error_status; reason = "missing required field 'argv'";
      start_time = start; end_time = now_iso (); artifacts = [] }

(* === Dispatch === *)

(** Execute a single typed op. Returns a receipt (pass field left blank —
    the orchestrator fills it in based on which pass is running). *)
let execute_op ~hub_path ~trigger_id ~config (op : Cn_shell.typed_op) =
  match op.Cn_shell.kind with
  (* Observe ops *)
  | Observe Fs_read -> execute_fs_read ~hub_path ~trigger_id ~config op
  | Observe Fs_list -> execute_fs_list ~hub_path ~trigger_id ~config op
  | Observe Fs_glob -> execute_fs_glob ~hub_path ~trigger_id ~config op
  | Observe Git_status -> execute_git_status ~hub_path ~trigger_id ~config op
  | Observe Git_diff -> execute_git_diff ~hub_path ~trigger_id ~config op
  | Observe Git_log -> execute_git_log ~hub_path ~trigger_id ~config op
  | Observe Git_grep -> execute_git_grep ~hub_path ~trigger_id ~config op
  (* Effect ops *)
  | Effect Fs_write -> execute_fs_write ~hub_path ~config op
  | Effect Fs_patch -> execute_fs_patch ~hub_path ~config op
  | Effect Git_branch -> execute_git_branch ~hub_path ~config op
  | Effect Git_stage -> execute_git_stage ~hub_path ~config op
  | Effect Git_commit -> execute_git_commit ~hub_path ~config op
  | Effect Exec -> execute_exec ~hub_path ~trigger_id ~config op

(* === Receipt I/O === *)

(** Write receipts to state/receipts/<trigger_id>.json.
    Appends to existing file if present (for Pass B). *)
let write_receipts ~hub_path ~trigger_id ~pass receipts =
  let dir = Cn_ffi.Path.join hub_path "state/receipts" in
  Cn_ffi.Fs.ensure_dir dir;
  let path = Cn_ffi.Path.join dir (trigger_id ^ ".json") in
  (* Set pass on all receipts *)
  let stamped = List.map (fun r -> { r with Cn_shell.pass }) receipts in
  (* Read existing receipts if any *)
  let existing =
    if Cn_ffi.Fs.exists path then
      match Cn_ffi.Fs.read path |> Cn_json.parse with
      | Ok obj ->
        (match Cn_json.get_list "receipts" obj with
         | Some items ->
           (* Parse back — but simpler to just keep raw JSON list *)
           items
         | None -> [])
      | Error _ -> []
    else []
  in
  let new_receipt_jsons = List.map Cn_shell.receipt_to_json stamped in
  let all = existing @ new_receipt_jsons in
  let container = Cn_json.Object [
    ("schema", Cn_json.String "cn.receipts.v1");
    ("trigger_id", Cn_json.String trigger_id);
    ("receipts", Cn_json.Array all);
  ] in
  Cn_ffi.Fs.write path (Cn_json.to_string container ^ "\n")

(** Read existing receipts from file. Returns empty list if missing/unparseable. *)
let read_receipts ~hub_path ~trigger_id =
  let path = Cn_ffi.Path.join hub_path
               (Printf.sprintf "state/receipts/%s.json" trigger_id) in
  if not (Cn_ffi.Fs.exists path) then []
  else
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Ok obj ->
      (match Cn_json.get_list "receipts" obj with
       | Some items -> items  (* Returns raw JSON — caller can inspect *)
       | None -> [])
    | Error _ -> []
