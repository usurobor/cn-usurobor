(** cn_projection.ml — Projection idempotency markers

    Implements crash-recovery deduplication for outbound projections
    (Telegram, Slack, etc.) per AGENT-RUNTIME-v3.3.6.

    Marker path: state/projected/{projection}/{trigger_id}.sent
    Mechanism: O_CREAT|O_EXCL (atomic, no TOCTOU race)

    The marker MUST be created under the same processor lock as
    IO-pair archival — it is part of the crash-recovery envelope,
    not a separate concern.

    If projection idempotency cannot be guaranteed, reply MUST be
    treated as Pass-A-unsafe and deferred to Pass B. *)

(* === Marker path === *)

(** Compute the marker file path for a projection + trigger_id.
    Shape: state/projected/{projection}/{trigger_id}.sent *)
let marker_path ~hub_path ~projection ~trigger_id =
  Cn_ffi.Path.join hub_path
    (Cn_ffi.Path.join "state/projected"
       (Cn_ffi.Path.join projection (trigger_id ^ ".sent")))

(* === Atomic marker creation === *)

(** Attempt to create the projection marker atomically.
    Returns Ok () if this is the first projection for this trigger_id.
    Returns Error "already_projected" if marker already exists.

    Uses O_CREAT|O_EXCL: the kernel guarantees exactly-once creation
    even under concurrent access or crash-recovery replays. *)
let try_mark ~hub_path ~projection ~trigger_id =
  let path = marker_path ~hub_path ~projection ~trigger_id in
  Cn_ffi.Fs.ensure_dir (Filename.dirname path);
  try
    let fd = Unix.openfile path
               [Unix.O_CREAT; Unix.O_EXCL; Unix.O_WRONLY] 0o644 in
    Unix.close fd;
    Ok ()
  with Unix.Unix_error (Unix.EEXIST, _, _) ->
    Error "already_projected"

(* === Query === *)

(** Check whether a projection marker exists (read-only). *)
let is_projected ~hub_path ~projection ~trigger_id =
  Sys.file_exists (marker_path ~hub_path ~projection ~trigger_id)

(* === Convenience: mark-and-decide === *)

(** Atomically decide whether to send a projection.
    Returns `Send if this is the first attempt (marker created).
    Returns `Already_projected if marker already exists (skip sending).

    Callers should:
    - On `Send: perform the external send, then emit receipt status=ok
    - On `Already_projected: emit receipt status=skipped,
      reason=already_projected *)
let project_reply ~hub_path ~projection ~trigger_id =
  match try_mark ~hub_path ~projection ~trigger_id with
  | Ok () -> `Send
  | Error _ -> `Already_projected
