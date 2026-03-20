(** cn_shell.ml — CN Shell types + ops manifest parser

    Defines typed ops for the CN Shell capability runtime.
    Parses the ops: JSON array from output.md frontmatter.

    Design constraints:
    - ops: value MUST be single-line JSON array
    - Each op is a JSON object with required "kind" field
    - Effect ops require op_id; observe ops auto-assign if absent
    - Unknown kind → receipt denied, unknown_op_kind
    - Duplicate op_id within manifest → receipt denied, duplicate_op_id
    - Pure parsing; no I/O *)

(* === Types === *)

type observe_kind =
  | Fs_read
  | Fs_list
  | Fs_glob
  | Git_status
  | Git_diff
  | Git_log
  | Git_grep

type effect_kind =
  | Fs_write
  | Fs_patch
  | Git_branch
  | Git_stage
  | Git_commit
  | Exec

type op_kind =
  | Observe of observe_kind
  | Effect of effect_kind

type op_phase =
  | Observe_phase
  | Effect_phase

type typed_op = {
  kind : op_kind;
  op_id : string option;
  fields : (string * Cn_json.t) list;
}

type receipt_status =
  | Ok_status
  | Denied
  | Error_status
  | Skipped

type artifact = {
  path : string;
  hash : string;
  size : int;
}

type receipt = {
  pass : string;
  op_id : string option;
  kind : string;
  status : receipt_status;
  reason : string;
  start_time : string;
  end_time : string;
  artifacts : artifact list;
}

type shell_config = {
  two_pass : string;            (* "off" | "auto" *)
  apply_mode : string;          (* "off" | "branch" | "working_tree" *)
  exec_enabled : bool;
  exec_allowlist : string list;
  max_observe_ops : int;
  max_artifact_bytes : int;
  max_artifact_bytes_per_op : int;
}

let default_shell_config = {
  two_pass = "auto";
  apply_mode = "branch";
  exec_enabled = false;
  exec_allowlist = [];
  max_observe_ops = 10;
  max_artifact_bytes = 65536;
  max_artifact_bytes_per_op = 16384;
}

(* === Kind parsing === *)

let observe_kind_of_string = function
  | "fs_read"    -> Some Fs_read
  | "fs_list"    -> Some Fs_list
  | "fs_glob"    -> Some Fs_glob
  | "git_status" -> Some Git_status
  | "git_diff"   -> Some Git_diff
  | "git_log"    -> Some Git_log
  | "git_grep"   -> Some Git_grep
  | _ -> None

let effect_kind_of_string = function
  | "fs_write"   -> Some Fs_write
  | "fs_patch"   -> Some Fs_patch
  | "git_branch" -> Some Git_branch
  | "git_stage"  -> Some Git_stage
  | "git_commit" -> Some Git_commit
  | "exec"       -> Some Exec
  | _ -> None

let op_kind_of_string s =
  match observe_kind_of_string s with
  | Some k -> Some (Observe k)
  | None ->
    match effect_kind_of_string s with
    | Some k -> Some (Effect k)
    | None -> None

let string_of_observe_kind = function
  | Fs_read    -> "fs_read"
  | Fs_list    -> "fs_list"
  | Fs_glob    -> "fs_glob"
  | Git_status -> "git_status"
  | Git_diff   -> "git_diff"
  | Git_log    -> "git_log"
  | Git_grep   -> "git_grep"

let string_of_effect_kind = function
  | Fs_write   -> "fs_write"
  | Fs_patch   -> "fs_patch"
  | Git_branch -> "git_branch"
  | Git_stage  -> "git_stage"
  | Git_commit -> "git_commit"
  | Exec       -> "exec"

let string_of_op_kind = function
  | Observe k -> string_of_observe_kind k
  | Effect k  -> string_of_effect_kind k

let is_effect = function
  | Effect _ -> true
  | Observe _ -> false

let phase_of_string = function
  | "observe" -> Some Observe_phase
  | "effect" -> Some Effect_phase
  | _ -> None

let phase_matches kind = function
  | Observe_phase -> not (is_effect kind)
  | Effect_phase -> is_effect kind

(* === Receipt helpers === *)

let string_of_receipt_status = function
  | Ok_status    -> "ok"
  | Denied       -> "denied"
  | Error_status -> "error"
  | Skipped      -> "skipped"

let make_receipt ~pass ~op_id ~kind ~status ~reason =
  { pass; op_id; kind; status; reason;
    start_time = ""; end_time = ""; artifacts = [] }

(* === Manifest parsing === *)

(** Check that ops: value is single-line (no embedded newlines). *)
let is_single_line s =
  not (String.contains s '\n') && not (String.contains s '\r')

(** Assign deterministic op_id for observe ops missing one.
    Format: obs-NN where NN is 1-indexed position among observe ops. *)
let assign_observe_id obs_counter =
  obs_counter := !obs_counter + 1;
  Printf.sprintf "obs-%02d" !obs_counter

(** Parse a single op JSON object into a typed_op or a denial receipt. *)
let parse_single_op ~obs_counter json =
  match Cn_json.get_string "kind" json with
  | None ->
    Error (make_receipt ~pass:"A" ~op_id:None ~kind:"unknown"
             ~status:Denied ~reason:"missing_kind")
  | Some kind_str ->
    let op_id = Cn_json.get_string "op_id" json in
    let phase_raw = Cn_json.get_string "phase" json in
    let fields = match json with
      | Cn_json.Object pairs ->
        List.filter (fun (k, _) ->
          k <> "kind" && k <> "op_id" && k <> "phase"
        ) pairs
      | _ -> []
    in
    match op_kind_of_string kind_str with
    | None ->
      Error (make_receipt ~pass:"A" ~op_id ~kind:kind_str
               ~status:Denied ~reason:"unknown_op_kind")
    | Some kind ->
      let phase_check = match phase_raw with
        | None -> Ok ()
        | Some phase_str ->
          match phase_of_string phase_str with
          | None ->
            Error (make_receipt ~pass:"A" ~op_id ~kind:kind_str
                     ~status:Denied ~reason:"invalid_phase")
          | Some phase when phase_matches kind phase -> Ok ()
          | Some _ ->
            Error (make_receipt ~pass:"A" ~op_id ~kind:kind_str
                     ~status:Denied ~reason:"phase_mismatch")
      in
      match phase_check with
      | Error r -> Error r
      | Ok () ->
        match kind with
        | Effect _ when op_id = None ->
          Error (make_receipt ~pass:"A" ~op_id:None ~kind:kind_str
                   ~status:Denied ~reason:"missing_op_id")
        | Observe _ ->
          let resolved_id = match op_id with
            | Some id -> id
            | None -> assign_observe_id obs_counter
          in
          Ok { kind; op_id = Some resolved_id; fields }
        | Effect _ ->
          Ok { kind; op_id; fields }

(** Check for duplicate op_ids within a manifest.
    Returns list of ops/receipts with duplicates converted to denials. *)
let check_duplicates results =
  let seen = Hashtbl.create 16 in
  List.map (fun result ->
    match result with
    | Error r -> Error r
    | Ok (op : typed_op) ->
      match op.op_id with
      | None -> Ok op
      | Some id ->
        if Hashtbl.mem seen id then
          Error (make_receipt ~pass:"A" ~op_id:(Some id)
                   ~kind:(string_of_op_kind op.kind)
                   ~status:Denied ~reason:"duplicate_op_id")
        else begin
          Hashtbl.add seen id ();
          Ok op
        end
  ) results

(** Parse ops: manifest string into typed ops and denial receipts.
    Returns (valid_ops, denial_receipts). *)
let parse_ops_manifest raw_value =
  if not (is_single_line raw_value) then
    ([], [make_receipt ~pass:"A" ~op_id:None ~kind:"manifest"
            ~status:Denied ~reason:"ops_not_single_line"])
  else
    match Cn_json.parse raw_value with
    | Error msg ->
      ([], [make_receipt ~pass:"A" ~op_id:None ~kind:"manifest"
              ~status:Denied ~reason:(Printf.sprintf "parse_error: %s" msg)])
    | Ok (Cn_json.Array items) ->
      let obs_counter = ref 0 in
      let results = List.map (parse_single_op ~obs_counter) items in
      let results = check_duplicates results in
      let ops = List.filter_map (function Ok op -> Some op | Error _ -> None) results in
      let receipts = List.filter_map (function Error r -> Some r | Ok _ -> None) results in
      (ops, receipts)
    | Ok _ ->
      ([], [make_receipt ~pass:"A" ~op_id:None ~kind:"manifest"
              ~status:Denied ~reason:"ops_not_array"])

(** Classify ops into observe and effect groups. *)
let classify ops =
  let observe = List.filter (fun (op : typed_op) -> not (is_effect op.kind)) ops in
  let effect = List.filter (fun (op : typed_op) -> is_effect op.kind) ops in
  (observe, effect)

(** Determine if two-pass mode is needed.
    Under auto: any observe op triggers two-pass. *)
let needs_two_pass ~two_pass_mode ops =
  match two_pass_mode with
  | "off" -> false
  | _ (* "auto" *) ->
    let observe, _ = classify ops in
    List.length observe > 0

(* === Receipt serialization === *)

let receipt_to_json r =
  let status_str = string_of_receipt_status r.status in
  let op_id_json = match r.op_id with
    | Some id -> Cn_json.String id
    | None -> Cn_json.Null
  in
  let artifacts_json = Cn_json.Array (List.map (fun a ->
    Cn_json.Object [
      ("path", Cn_json.String a.path);
      ("hash", Cn_json.String a.hash);
      ("size", Cn_json.Int a.size);
    ]
  ) r.artifacts) in
  Cn_json.Object [
    ("pass", Cn_json.String r.pass);
    ("op_id", op_id_json);
    ("kind", Cn_json.String r.kind);
    ("status", Cn_json.String status_str);
    ("reason", Cn_json.String r.reason);
    ("start", Cn_json.String r.start_time);
    ("end", Cn_json.String r.end_time);
    ("artifacts", artifacts_json);
  ]

let receipts_to_json ~trigger_id receipts =
  Cn_json.Object [
    ("schema", Cn_json.String "cn.receipts.v1");
    ("trigger_id", Cn_json.String trigger_id);
    ("receipts", Cn_json.Array (List.map receipt_to_json receipts));
  ]

(* === Execute: canonical entry point for typed op execution === *)

(** Execute a parsed ops manifest through the CN Shell pipeline.

    Handles denial receipts and delegates typed op execution to [orchestrate].
    Keeps Cn_shell pure (no I/O) by accepting callbacks:

    - [orchestrate typed_ops] runs the two-pass execution (observe → LLM → effect).
      Returns [Ok result] on success, [Error msg] on failure.
    - [write_denials denials] persists parser denial receipts to disk.

    Returns [Ok (Some result)] when typed ops were executed,
    [Ok None] when the manifest contained no typed ops,
    or [Error msg] when orchestration failed.

    This is the single entry point that cn_runtime should call for
    typed op execution — replacing direct Cn_orchestrator.run_two_pass calls. *)
let execute ~orchestrate ~write_denials ~typed_ops ~denial_receipts =
  if denial_receipts <> [] then
    write_denials denial_receipts;
  if typed_ops = [] then
    Ok None
  else
    match orchestrate typed_ops with
    | Ok result -> Ok (Some result)
    | Error msg -> Error msg
