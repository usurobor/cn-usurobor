(** cn_protocol.ml — Typed FSMs for the cn protocol

    Four FSMs:
    1. Thread   — GTD lifecycle (received → archived/deleted)
    2. Actor    — agent invocation loop (idle → processing → idle)
    3. Sender   — outbox → delivery
    4. Receiver — fetch → inbox

    All transitions are total. Invalid = Error, not exception.
    Terminal states are idempotent.

    Pure module: no I/O, no side effects, fully testable. *)

(* === FSM 1: Thread Lifecycle === *)

type thread_state =
  | Received    (* inbox, awaiting triage *)
  | Queued      (* in state/queue/, waiting for agent turn *)
  | Active      (* in state/input.md, agent processing *)
  | Doing       (* agent claimed, work in progress *)
  | Deferred    (* postponed with reason *)
  | Delegated   (* forwarded to peer, enters Sender FSM *)
  | Archived    (* terminal: completed *)
  | Deleted     (* terminal: removed *)

type thread_event =
  | Enqueue
  | Feed
  | Claim
  | Complete
  | Defer
  | Delegate
  | Discard
  | Resurface

let string_of_thread_state = function
  | Received -> "received" | Queued -> "queued" | Active -> "active"
  | Doing -> "doing" | Deferred -> "deferred" | Delegated -> "delegated"
  | Archived -> "archived" | Deleted -> "deleted"

let thread_state_of_string = function
  | "received" -> Some Received | "queued" -> Some Queued
  | "active" -> Some Active | "doing" -> Some Doing
  | "deferred" -> Some Deferred | "delegated" -> Some Delegated
  | "archived" -> Some Archived | "deleted" -> Some Deleted
  | _ -> None

let string_of_thread_event = function
  | Enqueue -> "enqueue" | Feed -> "feed" | Claim -> "claim"
  | Complete -> "complete" | Defer -> "defer" | Delegate -> "delegate"
  | Discard -> "discard" | Resurface -> "resurface"

let thread_transition state event =
  match state, event with
  (* Inbox processing *)
  | Received,  Enqueue   -> Ok Queued
  | Queued,    Feed      -> Ok Active
  (* Agent decisions — from Active *)
  | Active,    Claim     -> Ok Doing
  | Active,    Complete  -> Ok Archived
  | Active,    Defer     -> Ok Deferred
  | Active,    Delegate  -> Ok Delegated
  | Active,    Discard   -> Ok Deleted
  (* Doing lifecycle *)
  | Doing,     Complete  -> Ok Archived
  | Doing,     Defer     -> Ok Deferred
  (* Deferred lifecycle *)
  | Deferred,  Resurface -> Ok Queued
  | Deferred,  Discard   -> Ok Deleted
  (* Received can also be directly triaged by human *)
  | Received,  Claim     -> Ok Doing
  | Received,  Defer     -> Ok Deferred
  | Received,  Delegate  -> Ok Delegated
  | Received,  Discard   -> Ok Deleted
  | Received,  Complete  -> Ok Archived
  (* Terminals are idempotent *)
  | Archived,  _         -> Ok Archived
  | Deleted,   _         -> Ok Deleted
  (* Everything else is invalid *)
  | s, e -> Error (Printf.sprintf "invalid transition: %s + %s"
      (string_of_thread_state s) (string_of_thread_event e))

(* Derive thread state from directory path *)
let thread_state_of_path path =
  let parts = String.split_on_char '/' path in
  let has s = List.mem s parts in
  if has "queue" then Some Queued
  else if has "doing" then Some Doing
  else if has "deferred" then Some Deferred
  else if has "inbox" then Some Received
  else if has "outbox" then Some Delegated
  else if has "archived" then Some Archived
  else if has "sent" then Some Delegated
  else None

(* Read state from frontmatter, fall back to directory *)
let thread_state_of_meta meta path =
  let from_meta =
    meta |> List.find_map (fun (k, v) ->
      if k = "state" then thread_state_of_string v else None)
  in
  match from_meta with
  | Some s -> s
  | None ->
      match thread_state_of_path path with
      | Some s -> s
      | None -> Received  (* safe default for unknown *)

(* Directory for a given thread state *)
let dir_of_thread_state = function
  | Received  -> "threads/mail/inbox"
  | Queued    -> "state/queue"
  | Active    -> "state"
  | Doing     -> "threads/doing"
  | Deferred  -> "threads/deferred"
  | Delegated -> "threads/mail/outbox"
  | Archived  -> "threads/archived"
  | Deleted   -> ""  (* removed from filesystem *)


(* === FSM 2: Actor Loop === *)

type actor_state =
  | Idle           (* no input.md, queue may have items *)
  | Updating       (* downloading/installing update *)
  | InputReady     (* input.md written, agent not yet woken *)
  | Processing     (* agent working, awaiting output.md *)
  | OutputReady    (* output.md exists, ready to archive *)
  | TimedOut       (* agent exceeded max processing time *)

type actor_event =
  | Update_available   (* newer version detected *)
  | Update_complete    (* update installed, will re-exec *)
  | Update_fail        (* update failed, proceed with current *)
  | Update_skip        (* no update available or disabled *)
  | Queue_pop
  | Queue_empty
  | Wake
  | Output_received
  | Timeout          (* processing exceeded max cycles *)
  | Archive_complete
  | Archive_fail

let string_of_actor_state = function
  | Idle -> "idle" | Updating -> "updating" | InputReady -> "input_ready"
  | Processing -> "processing" | OutputReady -> "output_ready"
  | TimedOut -> "timed_out"

let string_of_actor_event = function
  | Update_available -> "update_available" | Update_complete -> "update_complete"
  | Update_fail -> "update_fail" | Update_skip -> "update_skip"
  | Queue_pop -> "queue_pop" | Queue_empty -> "queue_empty"
  | Wake -> "wake" | Output_received -> "output_received"
  | Timeout -> "timeout"
  | Archive_complete -> "archive_complete" | Archive_fail -> "archive_fail"

let actor_transition state event =
  match state, event with
  (* Update transitions — only from Idle *)
  | Idle,         Update_available  -> Ok Updating
  | Idle,         Update_skip       -> Ok Idle      (* no update, continue *)
  | Updating,     Update_complete   -> Ok Idle      (* re-exec; new process starts fresh *)
  | Updating,     Update_fail       -> Ok Idle      (* fallback to current version *)
  (* Normal processing transitions *)
  | Idle,         Queue_pop         -> Ok InputReady
  | Idle,         Queue_empty       -> Ok Idle
  | InputReady,   Wake              -> Ok Processing
  | Processing,   Output_received   -> Ok OutputReady
  | Processing,   Timeout           -> Ok TimedOut     (* supervisor recovery *)
  | OutputReady,  Archive_complete  -> Ok Idle
  | OutputReady,  Archive_fail      -> Ok OutputReady  (* retry *)
  | TimedOut,     Archive_complete  -> Ok Idle         (* timeout recovery done *)
  | s, e ->
      Error (Printf.sprintf "invalid actor transition: %s + %s"
        (string_of_actor_state s) (string_of_actor_event e))

(* Derive actor state from filesystem *)
let actor_derive_state ~input_exists ~output_exists =
  match input_exists, output_exists with
  | false, false -> Idle
  | true,  false -> Processing  (* caller checks age for TimedOut *)
  | true,  true  -> OutputReady
  | false, true  -> Idle  (* stale output, treat as idle *)

(* Derive actor state with timeout check *)
let actor_derive_state_with_timeout ~input_exists ~output_exists ~input_age_min ~max_age_min =
  match input_exists, output_exists with
  | false, false -> Idle
  | true,  false -> if input_age_min > max_age_min then TimedOut else Processing
  | true,  true  -> OutputReady
  | false, true  -> Idle  (* stale output, treat as idle *)


(* === FSM 3: Transport Sender === *)

type sender_state =
  | S_Pending        (* file in outbox, no branch *)
  | S_BranchCreated  (* branch exists in peer clone *)
  | S_Pushing        (* push in progress *)
  | S_Pushed         (* push confirmed *)
  | S_Failed         (* push rejected or error *)
  | S_Delivered      (* moved to sent, terminal *)

type sender_event =
  | SE_CreateBranch
  | SE_Push
  | SE_PushOk
  | SE_PushFail
  | SE_Retry
  | SE_Cleanup

let string_of_sender_state = function
  | S_Pending -> "pending" | S_BranchCreated -> "branch_created"
  | S_Pushing -> "pushing" | S_Pushed -> "pushed"
  | S_Failed -> "failed" | S_Delivered -> "delivered"

let sender_transition state event =
  match state, event with
  | S_Pending,       SE_CreateBranch -> Ok S_BranchCreated
  | S_BranchCreated, SE_Push         -> Ok S_Pushing
  | S_Pushing,       SE_PushOk       -> Ok S_Pushed
  | S_Pushing,       SE_PushFail     -> Ok S_Failed
  | S_Pushed,        SE_Cleanup      -> Ok S_Delivered
  | S_Failed,        SE_Retry        -> Ok S_Pending
  | S_Failed,        SE_Cleanup      -> Ok S_Delivered
  | S_Delivered,     _               -> Ok S_Delivered  (* idempotent *)
  | s, _ -> Error (Printf.sprintf "invalid sender transition from %s"
      (string_of_sender_state s))


(* === FSM 4: Transport Receiver === *)

type receiver_state =
  | R_Fetched        (* branch exists after fetch *)
  | R_Materializing  (* writing content to inbox *)
  | R_Materialized   (* content in inbox, branch still exists *)
  | R_Skipped        (* duplicate/archived, skip *)
  | R_Rejected       (* orphan branch *)
  | R_Cleaned        (* branch deleted, terminal *)

type receiver_event =
  | RE_IsNew
  | RE_IsDuplicate
  | RE_IsOrphan
  | RE_WriteOk
  | RE_WriteFail
  | RE_DeleteBranch

let string_of_receiver_state = function
  | R_Fetched -> "fetched" | R_Materializing -> "materializing"
  | R_Materialized -> "materialized" | R_Skipped -> "skipped"
  | R_Rejected -> "rejected" | R_Cleaned -> "cleaned"

let receiver_transition state event =
  match state, event with
  | R_Fetched,       RE_IsNew       -> Ok R_Materializing
  | R_Fetched,       RE_IsDuplicate -> Ok R_Skipped
  | R_Fetched,       RE_IsOrphan    -> Ok R_Rejected
  | R_Materializing, RE_WriteOk     -> Ok R_Materialized
  | R_Materializing, RE_WriteFail   -> Ok R_Fetched  (* retry *)
  | R_Materialized,  RE_DeleteBranch -> Ok R_Cleaned
  | R_Skipped,       RE_DeleteBranch -> Ok R_Cleaned
  | R_Rejected,      RE_DeleteBranch -> Ok R_Cleaned
  | R_Cleaned,       _              -> Ok R_Cleaned  (* idempotent *)
  | s, _ -> Error (Printf.sprintf "invalid receiver transition from %s"
      (string_of_receiver_state s))
