(** cn_dotenv.ml — Dotenv loader with env→file fallback

    Parses .cn/secrets.env for secrets (API keys, tokens).
    Resolution order: environment variable > secrets.env file.

    Design constraints:
    - No export, interpolation, multiline, or escape sequences
    - Key must match [A-Z0-9_]+
    - Missing file → empty; unreadable → warn, empty
    - Permissions > 0600 → error (refuse to load)
    - Pure parsing; I/O at edges only *)

(** Parse a .env-style string into key-value pairs.
    Skips blank lines and comments. Strips one layer of quotes from values. *)
let parse content =
  let lines = String.split_on_char '\n' content in
  let is_key_char c =
    (c >= 'A' && c <= 'Z') || (c >= '0' && c <= '9') || c = '_'
  in
  let valid_key s =
    String.length s > 0 && String.to_seq s |> Seq.for_all is_key_char
  in
  let strip_quotes s =
    let len = String.length s in
    if len >= 2 then
      match s.[0], s.[len - 1] with
      | '"', '"' | '\'', '\'' -> String.sub s 1 (len - 2)
      | _ -> s
    else s
  in
  let parse_line line =
    let trimmed = String.trim line in
    if trimmed = "" || (String.length trimmed > 0 && trimmed.[0] = '#') then
      None
    else
      match String.index_opt trimmed '=' with
      | None -> None
      | Some i ->
        let key = String.sub trimmed 0 i |> String.trim in
        let value = String.sub trimmed (i + 1) (String.length trimmed - i - 1) in
        if valid_key key then
          Some (key, strip_quotes (String.trim value))
        else
          None
  in
  List.filter_map parse_line lines

(** Check file permissions. Returns Error if > 0600. *)
let check_permissions path =
  try
    let stat = Unix.stat path in
    let perm = stat.Unix.st_perm land 0o777 in
    if perm land (lnot 0o600) <> 0 then
      Error (Printf.sprintf
        "%s has permissions %03o, expected 0600 or stricter. Run: chmod 600 %s"
        path perm path)
    else
      Ok ()
  with Unix.Unix_error (e, _, _) ->
    Error (Printf.sprintf "%s: %s" path (Unix.error_message e))

(** Load and parse a secrets file. Returns pairs or empty on missing/unreadable. *)
let load_file path =
  if not (Sys.file_exists path) then
    Ok []
  else
    match check_permissions path with
    | Error msg -> Error msg
    | Ok () ->
      try
        let content = Cn_ffi.Fs.read path in
        Ok (parse content)
      with Sys_error msg ->
        (* Unreadable → warn, treat as empty *)
        Printf.eprintf "cn: warning: cannot read %s: %s\n" path msg;
        Ok []

(** Resolve a secret: env var takes precedence, then secrets.env file.
    Empty string in env treated as unset. *)
let resolve_secret ~hub_path ~env_key =
  match Cn_ffi.Process.getenv_opt env_key with
  | Some s when s <> "" -> Some s
  | _ ->
    let secrets_path = Cn_ffi.Path.join hub_path ".cn/secrets.env" in
    match load_file secrets_path with
    | Error msg ->
      Printf.eprintf "cn: error: %s\n" msg;
      None
    | Ok pairs ->
      List.assoc_opt env_key pairs
