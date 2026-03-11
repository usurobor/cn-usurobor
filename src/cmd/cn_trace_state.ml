(** cn_trace_state.ml — State projections (overwrite-in-place)

    Writes state/ready.json, state/runtime.json, state/coherence.json.
    These are convenience snapshots for operators.
    For v1, written directly by runtime code (not event-sourced). *)

(* === Types === *)

type ready_status = Ready | Degraded | Blocked | Starting

type mind_projection = {
  profile : string;
  packages : string list;
  doctrine_required : int;
  doctrine_loaded : int;
  doctrine_hash : string;
  mindsets_required : int;
  mindsets_loaded : int;
  mindsets_hash : string;
  skills_indexed : int;
  skills_selected_last : string list;
  capabilities_hash : string;
  two_pass : string;
  apply_mode : string;
  exec_enabled : bool;
}

type body_projection = {
  fsm_state : string;
  lock_held : bool;
  current_cycle : string option;
  queue_depth : int;
}

type sensor_telegram = {
  enabled : bool;
  offset : int;
  last_poll_status : string;
  last_poll_at : string;
}

type ready_projection = {
  status : ready_status;
  boot_id : string;
  updated_at : string;
  mind : mind_projection option;
  body : body_projection option;
  sensors_telegram : sensor_telegram option;
  blocked_reason : string option;
}

type runtime_projection = {
  boot_id : string;
  current_cycle_id : string option;
  current_pass : string option;
  active_trigger : string option;
  queue_depth : int;
  lock_held : bool;
  lock_boot_id : string option;
  pending_projection : string option;
  updated_at : string;
}

type coherence_check = Ok_ | Missing | Error_

type coherence_projection = {
  boot_id : string;
  status : string;
  config : coherence_check;
  lockfile : coherence_check;
  doctrine : coherence_check;
  mindsets : coherence_check;
  packages : coherence_check;
  capabilities : coherence_check;
  transport : coherence_check;
  updated_at : string;
}

(* === Helpers === *)

let string_of_ready_status = function
  | Ready -> "ready" | Degraded -> "degraded"
  | Blocked -> "blocked" | Starting -> "starting"

let string_of_check = function
  | Ok_ -> "ok" | Missing -> "missing" | Error_ -> "error"

let state_dir hub_path =
  Cn_ffi.Path.join hub_path "state"

let write_json hub_path filename json =
  let dir = state_dir hub_path in
  Cn_ffi.Fs.ensure_dir dir;
  let path = Cn_ffi.Path.join dir filename in
  Cn_ffi.Fs.write path (Cn_json.to_string json ^ "\n")

(* === Writers === *)

let write_ready hub_path (r : ready_projection) =
  let fields = [
    "schema", Cn_json.String "cn.ready.v1";
    "status", Cn_json.String (string_of_ready_status r.status);
    "boot_id", Cn_json.String r.boot_id;
    "updated_at", Cn_json.String r.updated_at;
  ] in
  let fields = match r.blocked_reason with
    | Some reason -> fields @ ["blocked_reason", Cn_json.String reason]
    | None -> fields in
  let fields = match r.mind with
    | None -> fields
    | Some m ->
        let mind = Cn_json.Object [
          "profile", Cn_json.String m.profile;
          "packages", Cn_json.Array (List.map (fun s -> Cn_json.String s) m.packages);
          "doctrine", Cn_json.Object [
            "required", Cn_json.Int m.doctrine_required;
            "loaded", Cn_json.Int m.doctrine_loaded;
            "hash", Cn_json.String m.doctrine_hash;
          ];
          "mindsets", Cn_json.Object [
            "required", Cn_json.Int m.mindsets_required;
            "loaded", Cn_json.Int m.mindsets_loaded;
            "hash", Cn_json.String m.mindsets_hash;
          ];
          "skills", Cn_json.Object [
            "indexed", Cn_json.Int m.skills_indexed;
            "selected_last", Cn_json.Array
              (List.map (fun s -> Cn_json.String s) m.skills_selected_last);
          ];
          "capabilities", Cn_json.Object [
            "hash", Cn_json.String m.capabilities_hash;
            "two_pass", Cn_json.String m.two_pass;
            "apply_mode", Cn_json.String m.apply_mode;
            "exec_enabled", Cn_json.Bool m.exec_enabled;
          ];
        ] in
        fields @ ["mind", mind]
  in
  let fields = match r.body with
    | None -> fields
    | Some b ->
        let cycle = match b.current_cycle with
          | Some c -> Cn_json.String c | None -> Cn_json.Null in
        let body = Cn_json.Object [
          "fsm_state", Cn_json.String b.fsm_state;
          "lock_held", Cn_json.Bool b.lock_held;
          "current_cycle", cycle;
          "queue_depth", Cn_json.Int b.queue_depth;
        ] in
        fields @ ["body", body]
  in
  let fields = match r.sensors_telegram with
    | None -> fields
    | Some s ->
        let tg = Cn_json.Object [
          "enabled", Cn_json.Bool s.enabled;
          "offset", Cn_json.Int s.offset;
          "last_poll_status", Cn_json.String s.last_poll_status;
          "last_poll_at", Cn_json.String s.last_poll_at;
        ] in
        fields @ ["sensors", Cn_json.Object ["telegram", tg]]
  in
  write_json hub_path "ready.json" (Cn_json.Object fields)

(** Read existing ready.json and return as raw JSON, or None if missing/invalid. *)
let read_ready_json hub_path =
  let path = Cn_ffi.Path.join (state_dir hub_path) "ready.json" in
  if Cn_ffi.Fs.exists path then
    match Cn_ffi.Fs.read path |> Cn_json.parse with
    | Ok obj -> Some obj
    | Error _ -> None
  else None

(** Update only the body section of ready.json, preserving mind and sensors.
    If ready.json doesn't exist yet, writes a minimal projection with body only. *)
let update_ready_body hub_path ~boot_id ~updated_at (body : body_projection) =
  let existing = read_ready_json hub_path in
  (* Start with existing fields or minimal defaults *)
  let base_fields = match existing with
    | Some (Cn_json.Object fields) -> fields
    | _ -> [
        "schema", Cn_json.String "cn.ready.v1";
        "status", Cn_json.String "ready";
        "boot_id", Cn_json.String boot_id;
      ]
  in
  (* Build new body JSON *)
  let cycle = match body.current_cycle with
    | Some c -> Cn_json.String c | None -> Cn_json.Null in
  let body_json = Cn_json.Object [
    "fsm_state", Cn_json.String body.fsm_state;
    "lock_held", Cn_json.Bool body.lock_held;
    "current_cycle", cycle;
    "queue_depth", Cn_json.Int body.queue_depth;
  ] in
  (* Replace/add body and updated_at; preserve everything else *)
  let fields = base_fields
    |> List.filter (fun (k, _) -> k <> "body" && k <> "updated_at")
  in
  let fields = fields @ [
    "body", body_json;
    "updated_at", Cn_json.String updated_at;
  ] in
  write_json hub_path "ready.json" (Cn_json.Object fields)

let write_runtime hub_path (r : runtime_projection) =
  let opt_str = function Some s -> Cn_json.String s | None -> Cn_json.Null in
  let fields = [
    "schema", Cn_json.String "cn.runtime.v1";
    "boot_id", Cn_json.String r.boot_id;
    "current_cycle_id", opt_str r.current_cycle_id;
    "current_pass", opt_str r.current_pass;
    "active_trigger", opt_str r.active_trigger;
    "queue_depth", Cn_json.Int r.queue_depth;
    "lock_held", Cn_json.Bool r.lock_held;
    "lock_boot_id", opt_str r.lock_boot_id;
    "pending_projection", opt_str r.pending_projection;
    "updated_at", Cn_json.String r.updated_at;
  ] in
  write_json hub_path "runtime.json" (Cn_json.Object fields)

let write_coherence hub_path (c : coherence_projection) =
  let fields = [
    "schema", Cn_json.String "cn.coherence.v1";
    "boot_id", Cn_json.String c.boot_id;
    "status", Cn_json.String c.status;
    "checks", Cn_json.Object [
      "config", Cn_json.String (string_of_check c.config);
      "lockfile", Cn_json.String (string_of_check c.lockfile);
      "doctrine", Cn_json.String (string_of_check c.doctrine);
      "mindsets", Cn_json.String (string_of_check c.mindsets);
      "packages", Cn_json.String (string_of_check c.packages);
      "capabilities", Cn_json.String (string_of_check c.capabilities);
      "transport", Cn_json.String (string_of_check c.transport);
    ];
    "updated_at", Cn_json.String c.updated_at;
  ] in
  write_json hub_path "coherence.json" (Cn_json.Object fields)
