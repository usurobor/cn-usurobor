(** cn_logs.ml — cn logs CLI: unified log reader + formatter

    Single command for all operator log access.
    Reads from logs/unified/YYYYMMDD.jsonl. *)

(* === Options === *)

type log_opts = {
  since : float option;       (* Unix timestamp cutoff *)
  msg_id : string option;     (* filter to specific msg_id *)
  errors_only : bool;         (* only warn/error *)
  json_mode : bool;           (* raw JSONL output *)
  kind_filter : string option; (* filter by event kind *)
  max_entries : int;          (* max entries to show *)
}

let default_opts = {
  since = None;
  msg_id = None;
  errors_only = false;
  json_mode = false;
  kind_filter = None;
  max_entries = 50;
}

(* === Duration parsing === *)

let parse_duration s =
  let len = String.length s in
  if len < 2 then None
  else
    let num_s = String.sub s 0 (len - 1) in
    let unit_c = s.[len - 1] in
    match int_of_string_opt num_s, unit_c with
    | Some n, 'm' -> Some (float_of_int (n * 60))
    | Some n, 'h' -> Some (float_of_int (n * 3600))
    | Some n, 'd' -> Some (float_of_int (n * 86400))
    | Some n, 's' -> Some (float_of_int n)
    | _ -> None

(* === ISO timestamp parsing === *)

let parse_iso_ts s =
  (* Parse YYYY-MM-DDTHH:MM:SS.000Z to Unix timestamp.
     OCaml lacks timegm; we use mktime (local) and subtract the
     system's UTC offset. This is correct for the daemon's timezone
     but may be off by up to 1 hour during DST transitions.
     Acceptable for --since filtering where precision is ~minutes. *)
  if String.length s < 19 then None
  else
    try
      let year = int_of_string (String.sub s 0 4) in
      let month = int_of_string (String.sub s 5 2) in
      let day = int_of_string (String.sub s 8 2) in
      let hour = int_of_string (String.sub s 11 2) in
      let min = int_of_string (String.sub s 14 2) in
      let sec = int_of_string (String.sub s 17 2) in
      let tm = {
        Unix.tm_sec = sec; tm_min = min; tm_hour = hour;
        tm_mday = day; tm_mon = month - 1; tm_year = year - 1900;
        tm_wday = 0; tm_yday = 0; tm_isdst = false
      } in
      (* mktime interprets as local time; compute UTC offset from epoch *)
      let (t, _) = Unix.mktime tm in
      let utc_of_epoch = Unix.gmtime 0.0 in
      let local_of_epoch = Unix.localtime 0.0 in
      let utc_offset =
        float_of_int ((local_of_epoch.tm_hour - utc_of_epoch.tm_hour) * 3600 +
                       (local_of_epoch.tm_min - utc_of_epoch.tm_min) * 60) in
      Some (t -. utc_offset)
    with _ -> None

(* === Filtering === *)

let filter_entries opts entries =
  entries
  |> (fun es -> match opts.since with
    | None -> es
    | Some cutoff ->
      List.filter (fun (e : Cn_ulog.entry) ->
        match parse_iso_ts e.ts with
        | Some t -> t >= cutoff
        | None -> true) es)
  |> (fun es -> match opts.msg_id with
    | None -> es
    | Some id ->
      List.filter (fun (e : Cn_ulog.entry) ->
        e.msg_id = Some id) es)
  |> (fun es -> if opts.errors_only then
      List.filter (fun (e : Cn_ulog.entry) ->
        match e.severity with Warn | Error_ -> true | Info -> false) es
    else es)
  |> (fun es -> match opts.kind_filter with
    | None -> es
    | Some k ->
      List.filter (fun (e : Cn_ulog.entry) ->
        Cn_ulog.string_of_kind e.kind = k) es)

(* === Human formatting === *)

let format_time ts =
  if String.length ts >= 19 then String.sub ts 11 8
  else ts

let format_severity = function
  | Cn_ulog.Info -> " "
  | Cn_ulog.Warn -> Cn_fmt.yellow "!"
  | Cn_ulog.Error_ -> Cn_fmt.red "E"

let format_kind = function
  | Cn_ulog.Message_received -> Cn_fmt.cyan "recv"
  | Cn_ulog.Invocation_start -> Cn_fmt.dim "start"
  | Cn_ulog.Invocation_end -> Cn_fmt.green "done"
  | Cn_ulog.Message_sent -> Cn_fmt.cyan "sent"
  | Cn_ulog.Error -> Cn_fmt.red "error"

let format_entry (e : Cn_ulog.entry) =
  let time = format_time e.ts in
  let sev = format_severity e.severity in
  let kind = format_kind e.kind in
  let msg_id = match e.msg_id with Some id -> id | None -> "-" in
  let detail = match e.kind with
    | Message_received ->
      let src = Option.value ~default:"?" e.source in
      let msg = match e.user_msg with
        | Some m -> " " ^ Cn_ulog.truncate_string 60 m
        | None -> "" in
      Printf.sprintf "%s%s" src msg
    | Invocation_start ->
      let pass = match e.pass with Some p -> string_of_int p | None -> "1" in
      Printf.sprintf "pass %s" pass
    | Invocation_end ->
      let passes = match e.passes with Some p -> string_of_int p | None -> "?" in
      let ops = match e.ops with Some o -> string_of_int o | None -> "?" in
      let tok_in = match e.tokens_in with Some t -> string_of_int t | None -> "?" in
      let tok_out = match e.tokens_out with Some t -> string_of_int t | None -> "?" in
      let dur = match e.duration_ms with Some d -> string_of_int d ^ "ms" | None -> "?" in
      Printf.sprintf "%sp %sops %s/%stok %s" passes ops tok_in tok_out dur
    | Message_sent ->
      (match e.response_preview with
       | Some p -> Cn_ulog.truncate_string 60 p
       | None -> "")
    | Error ->
      (match e.error with Some err -> err | None -> "unknown error")
  in
  Printf.sprintf "%s %s %-5s %-14s %s" time sev kind msg_id detail

(* === CLI argument parsing === *)

let parse_log_args args =
  let rec go opts = function
    | [] -> opts
    | "--since" :: v :: rest ->
      (match parse_duration v with
       | Some secs ->
         let cutoff = Unix.gettimeofday () -. secs in
         go { opts with since = Some cutoff } rest
       | None ->
         Printf.eprintf "Warning: invalid duration '%s', ignoring\n" v;
         go opts rest)
    | "--msg" :: id :: rest ->
      go { opts with msg_id = Some id } rest
    | "--errors" :: rest ->
      go { opts with errors_only = true } rest
    | "--json" :: rest ->
      go { opts with json_mode = true } rest
    | "--kind" :: k :: rest ->
      go { opts with kind_filter = Some k } rest
    | "-n" :: n :: rest ->
      (match int_of_string_opt n with
       | Some max -> go { opts with max_entries = max } rest
       | None -> go opts rest)
    | _ :: rest -> go opts rest
  in
  go default_opts args

(* === Main entry point === *)

let run_logs hub_path args =
  let opts = parse_log_args args in
  let dir = Cn_ulog.unified_dir hub_path in
  if not (Cn_ffi.Fs.exists dir) then begin
    print_endline (Cn_fmt.info "No unified logs yet.");
    print_endline (Printf.sprintf "  Logs will appear in %s/ after the next agent invocation." dir)
  end else begin
    let entries = match opts.since, opts.msg_id with
      | None, None ->
        Cn_ulog.read_recent hub_path ~max_entries:opts.max_entries
      | _ ->
        (* Read all files, apply filters *)
        let files = List.rev (Cn_ulog.list_unified_files hub_path) in
        List.concat_map (fun f ->
          let path = Cn_ffi.Path.join dir f in
          Cn_ulog.read_file path
        ) files
    in
    let filtered = filter_entries opts entries in
    let limited = match opts.since, opts.msg_id with
      | None, None -> filtered (* already limited by read_recent *)
      | _ ->
        let n = List.length filtered in
        if n > opts.max_entries then
          List.filteri (fun i _ -> i >= n - opts.max_entries) filtered
        else filtered
    in
    if opts.json_mode then
      List.iter (fun e ->
        print_endline (Cn_json.to_string (Cn_ulog.entry_to_json e))
      ) limited
    else begin
      if limited = [] then
        print_endline (Cn_fmt.dim "(no matching log entries)")
      else
        List.iter (fun e -> print_endline (format_entry e)) limited
    end
  end
