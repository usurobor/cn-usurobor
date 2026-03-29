(** cn_ulog.ml — Unified operator log (append-only JSONL)

    High-signal, low-noise log for operator observability.
    One line per event. Correlation via msg_id.
    Written to logs/unified/YYYYMMDD.jsonl.

    Schema: cn.ulog.v1 *)

(* === Types === *)

type severity = Info | Warn | Error_

type kind =
  | Message_received
  | Invocation_start
  | Invocation_end
  | Message_sent
  | Error

type entry = {
  ts : string;
  kind : kind;
  severity : severity;
  msg_id : string option;
  source : string option;
  user_msg : string option;
  response_preview : string option;
  pass : int option;
  passes : int option;
  ops : int option;
  tokens_in : int option;
  tokens_out : int option;
  duration_ms : int option;
  error : string option;
  details : (string * Cn_json.t) list;
}

(* === Serialization === *)

let string_of_severity = function
  | Info -> "info" | Warn -> "warn" | Error_ -> "error"

let severity_of_string = function
  | "info" -> Some Info | "warn" -> Some Warn | "error" -> Some Error_
  | _ -> None

let string_of_kind = function
  | Message_received -> "message.received"
  | Invocation_start -> "invocation.start"
  | Invocation_end -> "invocation.end"
  | Message_sent -> "message.sent"
  | Error -> "error"

let kind_of_string = function
  | "message.received" -> Some Message_received
  | "invocation.start" -> Some Invocation_start
  | "invocation.end" -> Some Invocation_end
  | "message.sent" -> Some Message_sent
  | "error" -> Some Error
  | _ -> None

(* === Entry construction === *)

let make_entry ~kind ~severity ?msg_id ?source ?user_msg
    ?response_preview ?pass ?passes ?ops ?tokens_in ?tokens_out
    ?duration_ms ?error ?(details = []) () =
  { ts = Cn_fmt.now_iso ();
    kind; severity; msg_id; source; user_msg;
    response_preview; pass; passes; ops; tokens_in; tokens_out;
    duration_ms; error; details }

(* === JSON serialization === *)

let truncate_string max_len s =
  if String.length s <= max_len then s
  else String.sub s 0 max_len ^ "..."

let entry_to_json e =
  let fields = [
    "schema", Cn_json.String "cn.ulog.v1";
    "ts", Cn_json.String e.ts;
    "kind", Cn_json.String (string_of_kind e.kind);
    "severity", Cn_json.String (string_of_severity e.severity);
  ] in
  let opt key v fields = match v with
    | Some s -> fields @ [key, Cn_json.String s] | None -> fields in
  let opt_int key v fields = match v with
    | Some i -> fields @ [key, Cn_json.Int i] | None -> fields in
  let fields = opt "msg_id" e.msg_id fields in
  let fields = opt "source" e.source fields in
  let fields = opt "user_msg" (Option.map (truncate_string 200) e.user_msg) fields in
  let fields = opt "response_preview" (Option.map (truncate_string 200) e.response_preview) fields in
  let fields = opt_int "pass" e.pass fields in
  let fields = opt_int "passes" e.passes fields in
  let fields = opt_int "ops" e.ops fields in
  let fields = opt_int "tokens_in" e.tokens_in fields in
  let fields = opt_int "tokens_out" e.tokens_out fields in
  let fields = opt_int "duration_ms" e.duration_ms fields in
  let fields = opt "error" e.error fields in
  let fields = match e.details with
    | [] -> fields | d -> fields @ ["details", Cn_json.Object d] in
  Cn_json.Object fields

(* === JSON deserialization === *)

let entry_of_json json =
  match Cn_json.get_string "kind" json, Cn_json.get_string "severity" json,
        Cn_json.get_string "ts" json with
  | Some kind_s, Some sev_s, Some ts ->
    (match kind_of_string kind_s, severity_of_string sev_s with
     | Some kind, Some severity ->
       let get_s = Cn_json.get_string in
       let get_i = Cn_json.get_int in
       let details = match Cn_json.get "details" json with
         | Some (Cn_json.Object fields) -> fields
         | _ -> [] in
       Some { ts; kind; severity;
              msg_id = get_s "msg_id" json;
              source = get_s "source" json;
              user_msg = get_s "user_msg" json;
              response_preview = get_s "response_preview" json;
              pass = get_i "pass" json;
              passes = get_i "passes" json;
              ops = get_i "ops" json;
              tokens_in = get_i "tokens_in" json;
              tokens_out = get_i "tokens_out" json;
              duration_ms = get_i "duration_ms" json;
              error = get_s "error" json;
              details }
     | _ -> None)
  | _ -> None

(* === File paths === *)

let unified_dir hub_path = Cn_ffi.Path.join hub_path "logs/unified"

let unified_path_for_day hub_path =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  let date = Printf.sprintf "%04d%02d%02d"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday in
  Cn_ffi.Path.join (unified_dir hub_path) (date ^ ".jsonl")

let date_path hub_path date =
  Cn_ffi.Path.join (unified_dir hub_path) (date ^ ".jsonl")

(* === Write === *)

let write hub_path entry =
  let json = entry_to_json entry in
  let line = Cn_json.to_string json ^ "\n" in
  let dir = unified_dir hub_path in
  Cn_ffi.Fs.ensure_dir dir;
  let path = unified_path_for_day hub_path in
  Cn_ffi.Fs.append path line

(* === Read === *)

let parse_lines content =
  String.split_on_char '\n' content
  |> List.filter (fun s -> String.trim s <> "")
  |> List.filter_map (fun line ->
    match Cn_json.parse line with
    | Ok json -> entry_of_json json
    | Error _ -> None)

let read_file path =
  if Cn_ffi.Fs.exists path then
    parse_lines (Cn_ffi.Fs.read path)
  else []

let read_day hub_path date =
  read_file (date_path hub_path date)

let list_unified_files hub_path =
  let dir = unified_dir hub_path in
  if Cn_ffi.Fs.exists dir then
    Cn_ffi.Fs.readdir dir
    |> List.filter (fun f -> Filename.check_suffix f ".jsonl")
    |> List.sort (fun a b -> compare b a) (* newest first *)
  else []

let read_recent hub_path ~max_entries =
  let files = list_unified_files hub_path in
  let rec collect acc remaining = function
    | [] -> acc
    | _ when remaining <= 0 -> acc
    | f :: rest ->
      let path = Cn_ffi.Path.join (unified_dir hub_path) f in
      let entries = read_file path in
      let n = List.length entries in
      if n <= remaining then
        collect (entries :: acc) (remaining - n) rest
      else
        let tail = List.filteri (fun i _ -> i >= n - remaining) entries in
        tail :: acc
  in
  (* Chunks accumulate newest-first; List.concat reverses to chronological *)
  List.concat (collect [] max_entries files)
