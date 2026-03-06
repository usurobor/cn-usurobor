(** cn_sandbox.ml — Path sandbox for CN Shell typed ops

    Enforces filesystem path policy: normalization, escape detection,
    symlink resolution, denylist, and protected file rules.

    Design:
    - normalize_path and check_denylist are pure (testable, no I/O)
    - validate_path does one I/O call (Unix.realpath for symlinks)
    - Denylist applies to the RESOLVED canonical path, not raw input.
      A symlink pointing into .cn/ is denied even if the symlink
      itself lives outside .cn/.
    - Step order follows the normative spec:
      1. Reject absolute paths
      2. Collapse .. components
      3. Resolve symlinks
      4. Apply denylist to resolved path *)

(* === Denial reasons (exhaustive for path validation) === *)

type denial_reason =
  | Absolute_path
  | Path_escape
  | Symlink_escape
  | Path_denied of string   (* which denylist prefix matched *)
  | Protected_file

let string_of_denial_reason = function
  | Absolute_path     -> "absolute_path"
  | Path_escape       -> "path_escape"
  | Symlink_escape    -> "symlink_escape"
  | Path_denied _     -> "path_denied"
  | Protected_file    -> "protected_file"

(* === Default denylist prefixes === *)

let default_denylist = [
  ".cn/";
  ".git/";
  "state/";
  "logs/";
]

(* === Protected files (never writable, regardless of denylist) === *)

let protected_files = [
  "spec/SOUL.md";
  "spec/USER.md";
  "state/peers.md";
]

let is_protected_file path =
  List.mem path protected_files

(* === Pure path normalization === *)

(** Split a path into components on '/' *)
let split_path path =
  String.split_on_char '/' path
  |> List.filter (fun s -> s <> "" && s <> ".")

(** Collapse .. components. Returns None if the path escapes root. *)
let collapse_dots components =
  let rec loop acc = function
    | [] -> Some (List.rev acc)
    | ".." :: rest ->
      (match acc with
       | [] -> None  (* escapes root *)
       | _ :: parent -> loop parent rest)
    | seg :: rest -> loop (seg :: acc) rest
  in
  loop [] components

(** Normalize a relative path: split, collapse dots, rejoin.
    Returns Ok normalized_path or Error denial_reason. *)
let normalize_path raw =
  (* Step 1: reject absolute paths *)
  if String.length raw > 0 && raw.[0] = '/' then
    Error Absolute_path
  else if raw = "" then
    Ok "."
  else
    let components = split_path raw in
    (* Step 2: collapse .. *)
    match collapse_dots components with
    | None -> Error Path_escape
    | Some [] -> Ok "."
    | Some parts -> Ok (String.concat "/" parts)

(* === Denylist check (pure) === *)

(** Check if a normalized path hits a denylist prefix.
    The path MUST be the resolved/canonical relative path.
    Returns None if allowed, Some prefix if denied. *)
let check_denylist ?(denylist = default_denylist) path =
  (* Match exact prefix: "state/" matches "state/foo" and "state/foo/bar"
     Also match the directory itself without trailing content *)
  let path_with_slash = if path = "." then "" else path ^ "/" in
  let matches prefix =
    (* ".cn/" matches ".cn/secrets.env", ".cn/" itself, etc. *)
    String.length path_with_slash >= String.length prefix
    && String.sub path_with_slash 0 (String.length prefix) = prefix
  in
  List.find_opt matches denylist

(* === Path class: observe vs effect safety === *)

type path_access =
  | Read_access
  | Write_access

(** Check if a path is allowed for the given access type.
    Returns Ok relative_path or Error denial_reason.
    Pure — operates on an already-normalized, already-resolved path. *)
let check_access ~access normalized_path =
  match check_denylist normalized_path with
  | Some prefix -> Error (Path_denied prefix)
  | None ->
    match access with
    | Write_access when is_protected_file normalized_path ->
      Error Protected_file
    | _ -> Ok normalized_path

(* === Full validation (includes symlink resolution — one I/O call) === *)

(** Make a path relative to a hub root.
    Both paths must be absolute. Returns None if not under hub. *)
let make_relative ~hub_root path =
  let hub_len = String.length hub_root in
  let path_len = String.length path in
  if path_len > hub_len
     && String.sub path 0 hub_len = hub_root
     && path.[hub_len] = '/' then
    Some (String.sub path (hub_len + 1) (path_len - hub_len - 1))
  else if path = hub_root then
    Some "."
  else
    None

(** Find the deepest existing ancestor of a path and the remaining suffix.
    Returns (existing_ancestor, suffix_components).
    E.g. for "/hub/docs/link/new.txt" where /hub/docs/link exists:
    returns ("/hub/docs/link", ["new.txt"]) *)
let find_existing_ancestor path =
  let rec walk current suffix =
    if Sys.file_exists current then
      (current, suffix)
    else
      let parent = Filename.dirname current in
      let base = Filename.basename current in
      if parent = current then
        (* Reached filesystem root without finding anything *)
        (current, suffix)
      else
        walk parent (base :: suffix)
  in
  walk path []

(** Full path validation with symlink resolution.
    This is the only function with I/O (Unix.realpath).
    Returns Ok resolved_relative_path or Error denial_reason.

    Steps (normative order):
    1. Reject absolute paths
    2. Collapse .. (deny if escapes)
    3. Resolve symlinks via realpath (deny if escapes hub)
    4. Apply denylist to resolved canonical relative path
    5. For write access, check protected files

    For paths whose target does not yet exist (new files), we resolve
    the deepest existing ancestor and append the remaining suffix.
    This prevents symlinked parent directories from bypassing the
    denylist — e.g. docs/link/new.txt where docs/link → .cn/. *)
let validate_path ~hub_path ~access raw_path =
  (* Steps 1-2: normalize *)
  match normalize_path raw_path with
  | Error reason -> Error reason
  | Ok normalized ->
    let hub_canonical =
      try Some (Unix.realpath hub_path)
      with Unix.Unix_error _ -> None
    in
    match hub_canonical with
    | None ->
      (* Hub doesn't exist — shouldn't happen in practice *)
      Error Path_escape
    | Some hub_abs ->
    (* Step 3: resolve symlinks *)
    let full_path = Filename.concat hub_abs normalized in
    let resolved =
      try Some (Unix.realpath full_path)
      with Unix.Unix_error _ -> None
    in
    match resolved with
    | Some resolved_abs ->
      (* Full path exists — check it's under hub *)
      (match make_relative ~hub_root:hub_abs resolved_abs with
       | None -> Error Symlink_escape
       | Some resolved_rel ->
         (* Step 4+5: denylist and protected file check *)
         check_access ~access resolved_rel)
    | None ->
      (* Target doesn't exist yet. Resolve deepest existing ancestor
         to catch symlinked parent directories. *)
      let ancestor, suffix = find_existing_ancestor full_path in
      let ancestor_resolved =
        try Some (Unix.realpath ancestor)
        with Unix.Unix_error _ -> None
      in
      (match ancestor_resolved with
       | None ->
         (* No ancestor exists at all — fall back to normalized path *)
         check_access ~access normalized
       | Some ancestor_abs ->
         (* Reconstruct: resolved_ancestor + suffix components *)
         let reconstructed =
           List.fold_left Filename.concat ancestor_abs suffix
         in
         match make_relative ~hub_root:hub_abs reconstructed with
         | None -> Error Symlink_escape
         | Some resolved_rel ->
           check_access ~access resolved_rel)
