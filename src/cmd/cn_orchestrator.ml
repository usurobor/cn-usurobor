(** cn_orchestrator.ml — N-pass execution orchestrator for CN Shell

    Implements the bounded N-pass bind loop from N-PASS-BIND-v3.8.0:
    - Bounded loop: execute → repack → call → parse → execute → …
    - Observe-class pass: observe ops execute, effects deferred
    - Effect-class pass: all ops execute (no observe ops present)
    - Terminal pass: no typed ops → project final output
    - Any non-terminal pass may continue (not just observe passes)

    Delegates actual op execution to Cn_executor.
    Provides coordination op classification (pass-safe vs pass-unsafe)
    and gating logic (terminal ops gated on effect success).

    Key invariants:
    - pass field is per-receipt (numeric label: "1", "2", ...)
    - max_passes is configurable via shell_config (default 5)
    - n_pass=off → all ops execute in single pass, no continuation
    - n_pass=auto → loop continues after any pass that produces
      new evidence (observe artifacts, deferred effects, or any
      non-first pass), bounded by max_passes / max_total_ops
    - Receipts from all passes written to same file via append
    - Only final pass projected to user; intermediates archived *)

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

(** Classify a coordination op for non-terminal passes.
    Pass-safe: ack, surface/mca.
    Reply: conditionally safe — only if projection is idempotent
    (has_idempotent_projection=true). Without idempotent projection,
    reply is deferred as pass_unsafe.
    Pass-unsafe: done, fail, send, delegate, defer, delete. *)
let classify_coordination_pass_safe
      ?(has_idempotent_projection = true) (op : Cn_lib.agent_op) =
  match op with
  | Ack _ | Surface _ -> Execute
  | Reply _ ->
    if has_idempotent_projection then Execute
    else Skip "pass_unsafe"
  | Done _ | Fail _ | Send _ | Delegate _ | Defer _ | Delete _ ->
    Skip "pass_unsafe"

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

(* === Pass label helper === *)

(** Convert a 0-indexed pass_index to a 1-indexed pass label string. *)
let pass_label_of_index i = string_of_int (i + 1)

(* === Pass execution === *)

(** Run a single pass with observe/effect classification.
    If n_pass=auto and observe ops present: observe ops execute, effects deferred.
    If n_pass=off or no observe ops: all ops execute.
    Returns (receipts, effects_deferred). *)
let run_pass ~hub_path ~trigger_id ~config ~pass_label typed_ops =
  let has_continuation = Cn_shell.needs_continuation
      ~n_pass_mode:config.Cn_shell.n_pass typed_ops in

  let observe_count = List.length (List.filter (fun (op : Cn_shell.typed_op) ->
    not (Cn_shell.is_effect op.kind)) typed_ops) in
  let effect_count = List.length typed_ops - observe_count in

  Cn_trace.gemit ~component:"orchestrator" ~layer:Body
    ~event:"pass.N.start" ~severity:Info ~status:Ok_
    ~trigger_id ~pass:pass_label
    ~reason_code:(if has_continuation then "deferred_effects" else "all_execute")
    ~details:[
      "observe_ops", Cn_json.Int observe_count;
      "effect_ops", Cn_json.Int effect_count;
      "pass_index", Cn_json.Int (int_of_string pass_label - 1);
      "effects_deferred", Cn_json.Bool has_continuation;
    ] ();

  let receipts =
    if not has_continuation then
      List.map (fun (op : Cn_shell.typed_op) ->
        let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
        { r with Cn_shell.pass = pass_label }
      ) typed_ops
    else
      List.map (fun (op : Cn_shell.typed_op) ->
        if Cn_shell.is_effect op.Cn_shell.kind then begin
          Cn_trace.gemit ~component:"orchestrator" ~layer:Governance
            ~event:"ops.classified" ~severity:Info ~status:Skipped
            ~trigger_id ~pass:pass_label
            ~reason_code:"observe_pass_requires_followup"
            ~details:["kind", Cn_json.String (Cn_shell.string_of_op_kind op.kind)] ();
          let now = Cn_executor.now_iso () in
          { (Cn_shell.make_receipt ~pass:pass_label ~op_id:op.op_id
               ~kind:(Cn_shell.string_of_op_kind op.kind)
               ~status:Skipped ~reason:"observe_pass_requires_followup")
            with start_time = now; end_time = now }
        end else
          let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
          { r with Cn_shell.pass = pass_label }
      ) typed_ops
  in

  if receipts <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass:pass_label receipts;

  (receipts, has_continuation)

(* === Effect-class pass (unit-testable helper, not used in main loop) === *)

(** Run an effect-class pass.
    Effect ops execute normally, observe ops denied with max_passes_exceeded.
    Note: retained as a directly testable helper. The main run_n_pass loop
    uses run_pass for all passes — it no longer calls this function. *)
let run_effect_pass ~hub_path ~trigger_id ~config ~pass_label typed_ops =
  Cn_trace.gemit ~component:"orchestrator" ~layer:Body
    ~event:"pass.N.start" ~severity:Info ~status:Ok_
    ~trigger_id ~pass:pass_label
    ~reason_code:"effect_pass"
    ~details:[
      "pass_index", Cn_json.Int (int_of_string pass_label - 1);
    ] ();

  let receipts = List.map (fun (op : Cn_shell.typed_op) ->
    if not (Cn_shell.is_effect op.Cn_shell.kind) then begin
      Cn_trace.gemit ~component:"orchestrator" ~layer:Governance
        ~event:"policy.denied" ~severity:Info ~status:Skipped
        ~trigger_id ~pass:pass_label
        ~reason_code:"max_passes_exceeded"
        ~details:["kind", Cn_json.String (Cn_shell.string_of_op_kind op.kind)] ();
      let now = Cn_executor.now_iso () in
      { (Cn_shell.make_receipt ~pass:pass_label ~op_id:op.Cn_shell.op_id
           ~kind:(Cn_shell.string_of_op_kind op.kind)
           ~status:Denied ~reason:"max_passes_exceeded")
        with start_time = now; end_time = now }
    end else
      let r = Cn_executor.execute_op ~hub_path ~trigger_id ~config op in
      { r with Cn_shell.pass = pass_label }
  ) typed_ops in

  if receipts <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass:pass_label receipts;

  receipts

(* === Denial receipt pass-through === *)

(** Write parser denial receipts with pass tagging.
    Used for ops that failed parsing (unknown_op_kind, missing_kind, etc.)
    before reaching execution. *)
let write_denial_receipts ~hub_path ~trigger_id ~pass denials =
  if denials <> [] then
    Cn_executor.write_receipts ~hub_path ~trigger_id ~pass denials

(* === Context repacking for next pass === *)

(** Classify a receipt as empty-result (op ran but produced no data)
    vs not-executed (op was denied/skipped/errored before producing data).
    Used by receipts_summary to provide explicit signals to the agent,
    preventing confabulation of op results (CDD #49). *)
let receipt_result_signal (r : Cn_shell.receipt) =
  match r.status with
  | Ok_status ->
    if r.artifacts = [] then " [EMPTY_RESULT: op succeeded but returned no data]"
    else ""
  | Denied -> " [NOT_EXECUTED: op was denied before execution]"
  | Skipped -> " [NOT_EXECUTED: op was skipped]"
  | Error_status -> " [FAILED: op execution failed]"

(** Build bounded receipts summary for next-pass injection.
    Deterministic: iterates receipts in list order.
    Includes explicit signals distinguishing empty results from
    non-execution (anti-confabulation, CDD #49). *)
let receipts_summary ~pass_label (receipts : Cn_shell.receipt list) =
  let buf = Buffer.create 512 in
  Buffer.add_string buf (Printf.sprintf "## Pass %s Receipts\n\n" pass_label);
  let has_failures = List.exists (fun (r : Cn_shell.receipt) ->
    match r.status with
    | Denied | Error_status -> true
    | Ok_status | Skipped -> false
  ) receipts in
  if has_failures then
    Buffer.add_string buf
      "**WARNING: One or more ops failed or were denied. Do NOT fabricate \
       results. Report the failure to the user.**\n\n";
  List.iter (fun (r : Cn_shell.receipt) ->
    let op_id_str = match r.op_id with Some id -> id | None -> "(none)" in
    Buffer.add_string buf (Printf.sprintf "- **%s** [%s]: %s"
      op_id_str r.kind (Cn_shell.string_of_receipt_status r.status));
    (if r.reason <> "" then
       Buffer.add_string buf (Printf.sprintf " (reason: %s)" r.reason));
    Buffer.add_string buf (receipt_result_signal r);
    (if r.artifacts <> [] then
       Buffer.add_string buf (Printf.sprintf " — %d artifact(s)"
         (List.length r.artifacts)));
    Buffer.add_char buf '\n'
  ) receipts;
  Buffer.contents buf

(** Build bounded artifact excerpts for next-pass injection.
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

(** Repack context for the next pass.
    Produces a deterministic string containing:
    1. Receipts summary with anti-confabulation signals (bounded)
    2. Artifact excerpts (bounded by max_artifact_bytes_per_op)

    Ordering is stable (receipt list order). Skills are NOT re-scored
    (fixed at first pack time per spec). *)
let repack_for_next_pass ~hub_path ~trigger_id:_ ~config
      ~pass_label ~pass_receipts =
  let buf = Buffer.create 4096 in
  Buffer.add_string buf (receipts_summary ~pass_label pass_receipts);
  Buffer.add_char buf '\n';
  let excerpts = artifact_excerpts ~hub_path ~config pass_receipts in
  if excerpts <> "" then
    Buffer.add_string buf excerpts;
  Buffer.contents buf

(* === N-pass stop reasons === *)

type pass_stop_reason =
  | No_ops
  | N_pass_off
  | Effect_only_initial
  | Max_passes_reached
  | Budget_exhausted
  | Processing_failed

let string_of_stop_reason = function
  | No_ops -> "no_ops"
  | N_pass_off -> "n_pass_off"
  | Effect_only_initial -> "effect_only"
  | Max_passes_reached -> "max_passes_reached"
  | Budget_exhausted -> "budget_exhausted"
  | Processing_failed -> "processing_failed"

(* === N-pass result === *)

type n_pass_result = {
  all_receipts : Cn_shell.receipt list;
  final_coordination_ops : (Cn_lib.agent_op * coord_decision) list;
  final_output : Cn_output.parsed_output option;
  passes_used : int;
  stop_reason : pass_stop_reason;
}

(* === N-pass bind loop === *)

(** Run the bounded N-pass bind loop.

    Takes a mock-able [llm_call] function for testability:
    [llm_call : repack_content -> (Ok output_string | Error msg)]

    And an optional [indicator] handle for processing indicators.

    Flow per pass:
    1. Execute ops (observe defers effects; all-execute otherwise)
    2. Collect receipts
    3. Check stop conditions
    4. If continuing: repack, call LLM, parse, loop

    Continuation rule:
    - n_pass=off → single pass, never continue
    - n_pass=auto → continue after any pass that produces new
      evidence for the LLM (deferred effects, or any non-first pass).
      First-pass effect-only is terminal (LLM already had full context).

    Stop conditions:
    - no ops from LLM (terminal pass)
    - max_passes reached
    - budget exhausted (max_total_ops)
    - fatal runtime failure (LLM error) *)
let run_n_pass ~hub_path ~trigger_id ~config
      ~llm_call ?indicator typed_ops =
  let max_passes = config.Cn_shell.max_passes in
  let max_total_ops = config.Cn_shell.max_total_ops in
  let total_ops = ref 0 in
  let all_receipts = ref [] in

  (* Helper: build terminal result *)
  let make_terminal ~pass_index ~stop_reason ~last_parsed ~effect_receipts =
    let gated_coord_ops = match last_parsed with
      | Some p ->
        List.map (fun op ->
          let decision = gate_coordination ~effect_receipts op in
          (op, decision)
        ) p.Cn_output.coordination_ops
      | None -> []
    in
    Ok {
      all_receipts = !all_receipts;
      final_coordination_ops = gated_coord_ops;
      final_output = last_parsed;
      passes_used = pass_index + 1;
      stop_reason;
    }
  in

  (* Helper: repack, call LLM, parse, and either terminate or continue *)
  let call_llm_and_continue ~pass_index ~pass_label ~receipts =
    let repack_content = repack_for_next_pass ~hub_path ~trigger_id
        ~config ~pass_label ~pass_receipts:receipts in

    Cn_trace.gemit ~component:"orchestrator" ~layer:Mind
      ~event:"pass.N.repack" ~severity:Info ~status:Ok_
      ~trigger_id ~pass:pass_label
      ~details:["repack_bytes", Cn_json.Int (String.length repack_content)] ();

    match llm_call repack_content with
    | Error msg ->
      Cn_trace.gemit ~component:"orchestrator" ~layer:Mind
        ~event:"pass.N.llm.error" ~severity:Error_ ~status:Error_status
        ~trigger_id ~pass:pass_label ~reason_code:"llm_error" ();
      (match indicator with Some h -> Cn_indicator.fail h | None -> ());
      Error (Printf.sprintf "Pass %s LLM call failed: %s" pass_label msg)
    | Ok raw_output ->
      Cn_trace.gemit ~component:"orchestrator" ~layer:Mind
        ~event:"pass.N.llm.ok" ~severity:Info ~status:Ok_
        ~trigger_id ~pass:pass_label ();

      let parsed = Cn_output.parse_output raw_output in

      if parsed.typed_ops = [] then begin
        (* No more ops — terminal pass *)
        let next_label = pass_label_of_index (pass_index + 1) in
        Cn_trace.gemit ~component:"orchestrator" ~layer:Body
          ~event:"pass.N.complete" ~severity:Info ~status:Ok_
          ~trigger_id ~pass:next_label
          ~reason_code:"no_ops"
          ~details:[
            "pass_index", Cn_json.Int (pass_index + 1);
            "typed_op_count", Cn_json.Int 0;
            "coord_op_count", Cn_json.Int (List.length parsed.coordination_ops);
          ] ();

        let gated_coord_ops =
          List.map (fun op ->
            let decision = gate_coordination ~effect_receipts:!all_receipts op in
            (op, decision)
          ) parsed.coordination_ops
        in

        `Terminal {
          all_receipts = !all_receipts;
          final_coordination_ops = gated_coord_ops;
          final_output = Some parsed;
          passes_used = pass_index + 2;
          stop_reason = No_ops;
        }
      end else
        (* Continue to next pass with new ops *)
        `Continue (parsed.typed_ops, Some parsed)
  in

  let rec loop ~pass_index ~current_ops ~last_parsed =
    let pass_label = pass_label_of_index pass_index in

    (* Refresh indicator before LLM call (skip first pass — already started) *)
    if pass_index > 0 then
      (match indicator with Some h -> Cn_indicator.refresh h | None -> ());

    (* Execute pass via run_pass (handles both observe-deferred
       and all-execute cases based on op classification) *)
    let (receipts, effects_deferred) = run_pass ~hub_path ~trigger_id
        ~config ~pass_label current_ops in
    all_receipts := !all_receipts @ receipts;
    total_ops := !total_ops + List.length current_ops;

    (* Continuation rule:
       - n_pass=off → never continue
       - first pass (index 0) effect-only → terminal (LLM had full context)
       - any pass with deferred effects → continue (LLM needs to re-propose)
       - any non-first pass → continue (multi-pass chain may need more work)

       DESIGN NOTE: The "pass 0, effect-only → terminal" rule is an intentional
       optimization, not a legacy constraint. On pass 0, the LLM already had
       the full packed context when it chose effect-only ops. No repack would
       add new information, so an extra LLM call would be pure waste. On pass
       N>0, the LLM may want to verify, observe again, or adapt — so the loop
       always continues regardless of op class. This makes the loop generic
       for multi-pass chains while avoiding a useless round-trip on simple
       single-effect requests. *)
    let should_continue =
      config.Cn_shell.n_pass <> "off"
      && (effects_deferred || pass_index > 0)
    in

    if not should_continue then begin
      (* Terminal: n_pass=off or first-pass effect-only *)
      let stop_reason = if config.n_pass = "off" then N_pass_off
        else Effect_only_initial in
      Cn_trace.gemit ~component:"orchestrator" ~layer:Body
        ~event:"pass.N.complete" ~severity:Info ~status:Ok_
        ~trigger_id ~pass:pass_label
        ~reason_code:(string_of_stop_reason stop_reason)
        ~details:[
          "pass_index", Cn_json.Int pass_index;
          "receipt_count", Cn_json.Int (List.length receipts);
        ] ();
      make_terminal ~pass_index ~stop_reason
        ~last_parsed ~effect_receipts:receipts

    end else if pass_index + 1 >= max_passes then begin
      (* Max passes reached *)
      Cn_trace.gemit ~component:"orchestrator" ~layer:Body
        ~event:"pass.N.complete" ~severity:Info ~status:Ok_
        ~trigger_id ~pass:pass_label
        ~reason_code:"max_passes_reached"
        ~details:[
          "pass_index", Cn_json.Int pass_index;
          "receipt_count", Cn_json.Int (List.length receipts);
        ] ();
      make_terminal ~pass_index ~stop_reason:Max_passes_reached
        ~last_parsed ~effect_receipts:receipts

    end else if !total_ops >= max_total_ops then begin
      (* Budget exhausted *)
      Cn_trace.gemit ~component:"orchestrator" ~layer:Body
        ~event:"pass.N.complete" ~severity:Info ~status:Ok_
        ~trigger_id ~pass:pass_label
        ~reason_code:"budget_exhausted"
        ~details:[
          "pass_index", Cn_json.Int pass_index;
          "total_ops", Cn_json.Int !total_ops;
          "max_total_ops", Cn_json.Int max_total_ops;
        ] ();
      make_terminal ~pass_index ~stop_reason:Budget_exhausted
        ~last_parsed ~effect_receipts:receipts

    end else begin
      (* Continue: repack, call LLM, parse *)
      let reason_code = if effects_deferred then "deferred_effects"
        else "continuation" in
      Cn_trace.gemit ~component:"orchestrator" ~layer:Body
        ~event:"pass.N.complete" ~severity:Info ~status:Ok_
        ~trigger_id ~pass:pass_label
        ~reason_code
        ~details:[
          "pass_index", Cn_json.Int pass_index;
          "receipt_count", Cn_json.Int (List.length receipts);
        ] ();

      match call_llm_and_continue ~pass_index ~pass_label ~receipts with
      | Error msg -> Error msg
      | `Continue (next_ops, next_parsed) ->
        loop ~pass_index:(pass_index + 1) ~current_ops:next_ops
             ~last_parsed:next_parsed
      | `Terminal final -> Ok final
    end
  in

  loop ~pass_index:0 ~current_ops:typed_ops ~last_parsed:None
