(** cn_trace.ml — Structured event tracing (append-only JSONL)

    Implements the event schema from TRACEABILITY.md §5.
    Primary operational truth: append-only event stream.

    Each event is a single JSON object on one line.
    Events are appended to logs/events/YYYYMMDD.jsonl.
    boot_id is generated once per process start.
    seq is monotonic per boot session. *)

(* === Types === *)

type severity = Debug | Info | Warn | Error_

type status = Ok_ | Degraded | Blocked | Error_status | Skipped

type layer = Sensor | Body | Mind | Governance | World

type refs = {
  input : string option;
  output : string option;
  receipts : string option;
}

type event = {
  component : string;
  layer : layer;
  event : string;
  severity : severity;
  status : status;
  cycle_id : string option;
  trigger_id : string option;
  pass : string option;
  prev_state : string option;
  next_state : string option;
  reason_code : string option;
  reason : string option;
  refs : refs option;
  details : (string * Cn_json.t) list;
}

type session = {
  hub_path : string;
  boot_id : string;
  mutable seq : int;
  min_severity : severity;
}

(* === Severity/status/layer serialization === *)

let string_of_severity = function
  | Debug -> "debug" | Info -> "info" | Warn -> "warn" | Error_ -> "error"

let string_of_status = function
  | Ok_ -> "ok" | Degraded -> "degraded" | Blocked -> "blocked"
  | Error_status -> "error" | Skipped -> "skipped"

let string_of_layer = function
  | Sensor -> "sensor" | Body -> "body" | Mind -> "mind"
  | Governance -> "governance" | World -> "world"

let severity_rank = function
  | Debug -> 0 | Info -> 1 | Warn -> 2 | Error_ -> 3

(* === Boot ID generation === *)

let generate_boot_id () =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  let rand = Random.int 0xFFFF in
  Printf.sprintf "%04d%02d%02d-%02d%02d%02d-%04x"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday
    tm.tm_hour tm.tm_min tm.tm_sec rand

(* === Event path === *)

let event_dir hub_path = Cn_ffi.Path.join hub_path "logs/events"

let event_path_for_day hub_path =
  let t = Unix.gettimeofday () in
  let tm = Unix.gmtime t in
  let date = Printf.sprintf "%04d%02d%02d"
    (tm.tm_year + 1900) (tm.tm_mon + 1) tm.tm_mday in
  Cn_ffi.Path.join (event_dir hub_path) (date ^ ".jsonl")

(* === JSON serialization === *)

let refs_to_json r =
  let fields = [] in
  let fields = match r.receipts with
    | Some s -> ("receipts", Cn_json.String s) :: fields | None -> fields in
  let fields = match r.output with
    | Some s -> ("output", Cn_json.String s) :: fields | None -> fields in
  let fields = match r.input with
    | Some s -> ("input", Cn_json.String s) :: fields | None -> fields in
  Cn_json.Object fields

let event_to_json session ev =
  session.seq <- session.seq + 1;
  let fields = [
    "schema", Cn_json.String "cn.events.v1";
    "ts", Cn_json.String (Cn_fmt.now_iso ());
    "seq", Cn_json.Int session.seq;
    "boot_id", Cn_json.String session.boot_id;
    "component", Cn_json.String ev.component;
    "layer", Cn_json.String (string_of_layer ev.layer);
    "event", Cn_json.String ev.event;
    "severity", Cn_json.String (string_of_severity ev.severity);
    "status", Cn_json.String (string_of_status ev.status);
  ] in
  let opt key v fields = match v with
    | Some s -> fields @ [key, Cn_json.String s] | None -> fields in
  let fields = opt "cycle_id" ev.cycle_id fields in
  let fields = opt "trigger_id" ev.trigger_id fields in
  let fields = opt "pass" ev.pass fields in
  let fields = opt "prev_state" ev.prev_state fields in
  let fields = opt "next_state" ev.next_state fields in
  let fields = opt "reason_code" ev.reason_code fields in
  let fields = opt "reason" ev.reason fields in
  let fields = match ev.refs with
    | Some r -> fields @ ["refs", refs_to_json r] | None -> fields in
  let fields = match ev.details with
    | [] -> fields | d -> fields @ ["details", Cn_json.Object d] in
  Cn_json.Object fields

(* === Session lifecycle === *)

let start_session ?(min_severity = Info) hub_path =
  Random.self_init ();
  { hub_path; boot_id = generate_boot_id (); seq = 0; min_severity }

(* === Global session (set once at boot, used by all modules) === *)

let global_session : session option ref = ref None

let init_global ?(min_severity = Info) hub_path =
  let s = start_session ~min_severity hub_path in
  global_session := Some s;
  s

let get_global () = !global_session

let reset_global () = global_session := None

let boot_id () =
  match !global_session with Some s -> s.boot_id | None -> "unknown"

(* === Emit === *)

let emit session ev =
  if severity_rank ev.severity < severity_rank session.min_severity then ()
  else begin
    let json = event_to_json session ev in
    let line = Cn_json.to_string json ^ "\n" in
    let dir = event_dir session.hub_path in
    Cn_ffi.Fs.ensure_dir dir;
    let path = event_path_for_day session.hub_path in
    let fd = Unix.openfile path
      [Unix.O_WRONLY; Unix.O_CREAT; Unix.O_APPEND] 0o644 in
    (try
       let _ = Unix.write_substring fd line 0 (String.length line) in
       Unix.close fd
     with exn ->
       (try Unix.close fd with _ -> ());
       raise exn)
  end

(* === Convenience helpers === *)

let make_event ~component ~layer ~event ~severity ~status
    ?cycle_id ?trigger_id ?pass
    ?prev_state ?next_state ?reason_code ?reason
    ?refs ?(details = []) () =
  { component; layer; event; severity; status;
    cycle_id; trigger_id; pass;
    prev_state; next_state; reason_code; reason;
    refs; details }

let emit_simple session ~component ~layer ~event ~severity ~status
    ?cycle_id ?trigger_id ?pass
    ?prev_state ?next_state ?reason_code ?reason
    ?refs ?(details = []) () =
  emit session (make_event ~component ~layer ~event ~severity ~status
    ?cycle_id ?trigger_id ?pass
    ?prev_state ?next_state ?reason_code ?reason
    ?refs ~details ())

(** Emit to global session (no-op if no session initialized). *)
let gemit ~component ~layer ~event ~severity ~status
    ?cycle_id ?trigger_id ?pass
    ?prev_state ?next_state ?reason_code ?reason
    ?refs ?(details = []) () =
  match !global_session with
  | None -> ()
  | Some session ->
      emit session (make_event ~component ~layer ~event ~severity ~status
        ?cycle_id ?trigger_id ?pass
        ?prev_state ?next_state ?reason_code ?reason
        ?refs ~details ())
