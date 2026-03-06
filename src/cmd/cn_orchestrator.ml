(** cn_orchestrator.ml — Two-pass execution orchestrator for CN Shell

    Implements the two-pass execution model from AGENT-RUNTIME-v3.3.6:
    - Pass A: observe ops execute, effect ops deferred
    - Pass B: effect ops execute, observe ops denied (max_passes_exceeded)

    Delegates actual op execution to Cn_executor.
    Provides coordination op classification (pass-A-safe vs pass-A-unsafe)
    and gating logic (terminal ops gated on effect success).

    Key invariants:
    - pass field is per-receipt ("A" or "B"), not per-container
    - max_passes = 2 (hard limit, not configurable)
    - two_pass=off → all ops execute in single pass, no Pass B
    - two_pass=auto → any observe op triggers two-pass
    - Receipts from both passes written to same file via append *)

(* === Coordination decision type === *)

type coord_decision =
  | Execute
  | Skip of string

(* === Substring helper (exposed for tests) === *)

let contains_sub (s : string) (sub : string) : bool =
  let n = String.length s in
  let m = String.length sub in
  if m = 0 then true
  else if m > n then false
  else
    let rec loop i =
      if i + m > n then false
      else if String.sub s i m = sub then true
      else loop (i + 1)
    in
    loop 0

(* === Coordination classification === *)

(** Classify a coordination op for Pass A.
    Pass-A-safe: ack, surface/mca, reply (caller ensures idempotent projection).
    Pass-A-unsafe: done, fail, send, delegate, defer, delete. *)
let classify_coordination_pass_a (op : Cn_lib.agent_op) =
  match op with
  | Ack _ | Surface _ | Reply _ -> Execute
  | Done _ | Fail _ | Send _ | Delegate _ | Defer _ | Delete _ ->
    Skip "pass_a_unsafe"

(* === Coordination gating === *)

(** Check if a coordination op is terminal (subject to effect gating).
    Terminal ops: done, fail, send, delegate, defer, delete.
    Non-terminal: ack, reply, surface. *)
let is_terminal_op (op : Cn_lib.agent_op) =
  match op with
  | Done _ | Fail _ | Send _ | Delegate _ | Defer _ | Delete _ -> true
  | Ack _ | Reply _ | Surface _ -> false

(** Check if all effect receipts succeeded.
    ok and skipped (deferred) count as success; denied and error do not. *)
let effects_all_ok receipts =
  let effect_receipts = List.filter (fun (r : Cn_shell.receipt) ->
    Cn_shell.effect_kind_of_string r.kind <> None
  ) receipts in
  List.for_all (fun (r : Cn_shell.receipt) ->
    match r.status with
    | Ok_status | Skipped -> true
    | Denied | Error_status -> false
  ) effect_receipts

(** Gate a coordination op based on effect outcomes.
    Terminal ops blocked with "effects_failed" when any effect
    has denied or error status. Non-terminal ops always allowed. *)
let gate_coordination ~effect_receipts (op : Cn_lib.agent_op) =
  if is_terminal_op op && not (effects_all_ok effect_receipts) then
    Skip "effects_failed"
  else
    Execute

(* === Pass A === *)

type pass_a_result = {
  receipts : Cn_shell.receipt list;
  needs_pass_b : bool;
}

(** Run Pass A of the two-pass model.

    - two_pass=auto + any observe op → two-pass:
      observe ops execute, effects skipped (observe_pass_requires_followup)
    - two_pass=auto + effect-only → single pass: all execute
    - two_pass=off → single pass: all execute
    - Empty ops → single pass, empty receipts

    All receipts tagged with pass="A".
    Writes receipts to state/receipts/<trigger_id>.json. *)
let run_pass_a ~hub_path ~trigger_id ~config typed_ops =
  let two_pass_needed = Cn_shell.needs_two_pass
      ~two_pass_mode:config.Cn_shell.two_pass typed_ops in

  let receipts =
    if not two_pass_needed then
      (* Single pass: execute all ops *)
      List.map (fun op ->
        let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
        { r with Cn_shell.pass = "A" }
      ) typed_ops
    else
      (* Two-pass: observe executes, effects deferred *)
      List.map (fun op ->
        if Cn_shell.is_effect op.Cn_shell.kind then
          let now = Cn_executor.now_iso () in
          { (Cn_shell.make_receipt ~pass:"A" ~op_id:op.op_id
               ~kind:(Cn_shell.string_of_op_kind op.kind)
               ~status:Skipped ~reason:"observe_pass_requires_followup")
            with start_time = now; end_time = now }
        else
          let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
          { r with Cn_shell.pass = "A" }
      ) typed_ops
  in

  (* Write receipts *)
  if receipts <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass:"A" receipts;

  { receipts; needs_pass_b = two_pass_needed }

(* === Pass B === *)

(** Run Pass B of the two-pass model.

    - Observe ops denied with max_passes_exceeded (no third call)
    - Effect ops execute normally
    - All receipts tagged with pass="B"
    - Receipts appended to existing file (Pass A already wrote) *)
let run_pass_b ~hub_path ~trigger_id ~config typed_ops =
  let receipts = List.map (fun op ->
    if not (Cn_shell.is_effect op.Cn_shell.kind) then
      (* Observe in Pass B → denied *)
      let now = Cn_executor.now_iso () in
      { (Cn_shell.make_receipt ~pass:"B" ~op_id:op.Cn_shell.op_id
           ~kind:(Cn_shell.string_of_op_kind op.kind)
           ~status:Denied ~reason:"max_passes_exceeded")
        with start_time = now; end_time = now }
    else
      let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
      { r with Cn_shell.pass = "B" }
  ) typed_ops in

  (* Append to receipts file *)
  if receipts <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass:"B" receipts;

  receipts

(* === Denial receipt pass-through === *)

(** Write parser denial receipts with pass tagging.
    Used for ops that failed parsing (unknown_op_kind, missing_kind, etc.)
    before reaching execution. *)
let write_denial_receipts ~hub_path ~trigger_id ~pass denials =
  if denials <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass denials

(* === Pass B context repacking === *)

(** Build bounded receipts summary for Pass B injection.
    Deterministic: iterates receipts in list order. *)
let receipts_summary (receipts : Cn_shell.receipt list) =
  let buf = Buffer.create 512 in
  Buffer.add_string buf "## Pass A Receipts\n\n";
  List.iter (fun (r : Cn_shell.receipt) ->
    let op_id_str = match r.op_id with Some id -> id | None -> "(none)" in
    Buffer.add_string buf (Printf.sprintf "- **%s** [%s]: %s"
      op_id_str r.kind (Cn_shell.string_of_receipt_status r.status));
    (if r.reason <> "" then
       Buffer.add_string buf (Printf.sprintf " (%s)" r.reason));
    (if r.artifacts <> [] then
       Buffer.add_string buf (Printf.sprintf " — %d artifact(s)"
         (List.length r.artifacts)));
    Buffer.add_char buf '\n'
  ) receipts;
  Buffer.contents buf

(** Build bounded artifact excerpts for Pass B injection.
    Reads artifact files from disk, caps at max_artifact_bytes_per_op.
    Deterministic: iterates receipts in list order, artifacts within each. *)
let artifact_excerpts ~hub_path ~config (receipts : Cn_shell.receipt list) =
  let buf = Buffer.create 2048 in
  let max = config.Cn_shell.max_artifact_bytes_per_op in
  List.iter (fun (r : Cn_shell.receipt) ->
    List.iter (fun (a : Cn_shell.artifact) ->
      let full_path = Cn_ffi.Path.join hub_path a.path in
      if Cn_ffi.Fs.exists full_path then begin
        let content = Cn_ffi.Fs.read full_path in
        let capped = if String.length content > max
          then String.sub content 0 max ^ "\n[truncated]"
          else content in
        let op_id_str = match r.op_id with Some id -> id | None -> "(none)" in
        Buffer.add_string buf (Printf.sprintf "## Artifact: %s (%s)\n\n" op_id_str r.kind);
        Buffer.add_string buf "```\n";
        Buffer.add_string buf capped;
        if not (String.length capped > 0 && capped.[String.length capped - 1] = '\n') then
          Buffer.add_char buf '\n';
        Buffer.add_string buf "```\n\n"
      end
    ) r.artifacts
  ) receipts;
  Buffer.contents buf

(** Repack context for Pass B.
    Produces a deterministic string containing:
    1. Receipts summary (bounded)
    2. Artifact excerpts (bounded by max_artifact_bytes_per_op)

    Ordering is stable (receipt list order). Skills are NOT re-scored
    (fixed at Pass A pack time per spec). *)
let repack_for_pass_b ~hub_path ~trigger_id:_ ~config
      ~pass_a_receipts =
  let buf = Buffer.create 4096 in
  (* 1. Receipts summary *)
  Buffer.add_string buf (receipts_summary pass_a_receipts);
  Buffer.add_char buf '\n';
  (* 2. Artifact excerpts *)
  let excerpts = artifact_excerpts ~hub_path ~config pass_a_receipts in
  if excerpts <> "" then
    Buffer.add_string buf excerpts;
  Buffer.contents buf
