(** cn_protocol.mli — Typed FSMs for the cn protocol

    Four FSMs:
    1. Thread   — GTD lifecycle (received → archived/deleted)
    2. Actor    — agent invocation loop (idle → processing → idle)
    3. Sender   — outbox → delivery
    4. Receiver — fetch → inbox

    Pure module: no I/O, no side effects, fully testable.
    All transitions are total: invalid = Error, never exception.
    Terminal states are idempotent. *)


(** {1 FSM 1: Thread Lifecycle} *)

type thread_state =
  | Received    (** inbox, awaiting triage *)
  | Queued      (** in state/queue/, waiting for agent turn *)
  | Active      (** in state/input.md, agent processing *)
  | Doing       (** agent claimed, work in progress *)
  | Deferred    (** postponed with reason *)
  | Delegated   (** forwarded to peer, enters Sender FSM *)
  | Archived    (** terminal: completed *)
  | Deleted     (** terminal: removed *)

type thread_event =
  | Enqueue
  | Feed
  | Claim
  | Complete
  | Defer
  | Delegate
  | Discard
  | Resurface

val string_of_thread_state : thread_state -> string
val thread_state_of_string : string -> thread_state option
val string_of_thread_event : thread_event -> string

val thread_transition : thread_state -> thread_event -> (thread_state, string) result
(** Apply an event to a thread state. Returns [Ok new_state] or [Error reason]. *)

val thread_state_of_path : string -> thread_state option
(** Derive thread state from directory path (e.g. "threads/doing/x.md" → Doing). *)

val thread_state_of_meta : (string * string) list -> string -> thread_state
(** Derive thread state from frontmatter metadata, falling back to path. *)

val dir_of_thread_state : thread_state -> string
(** Directory for a given thread state (e.g. Doing → "threads/doing"). *)


(** {1 FSM 2: Actor Loop} *)

type actor_state =
  | Idle           (** no input.md, queue may have items *)
  | InputReady     (** input.md written, agent not yet woken *)
  | Processing     (** agent working, awaiting output.md *)
  | OutputReady    (** output.md exists, ready to archive *)

type actor_event =
  | Queue_pop
  | Queue_empty
  | Wake
  | Output_received
  | Archive_complete
  | Archive_fail

val string_of_actor_state : actor_state -> string

val actor_transition : actor_state -> actor_event -> (actor_state, string) result
(** Apply an event to an actor state. Returns [Ok new_state] or [Error reason]. *)

val actor_derive_state : input_exists:bool -> output_exists:bool -> actor_state
(** Derive actor state from filesystem: input.md and output.md existence. *)


(** {1 FSM 3: Transport Sender} *)

type sender_state =
  | S_Pending        (** file in outbox, no branch *)
  | S_BranchCreated  (** branch exists in peer clone *)
  | S_Pushing        (** push in progress *)
  | S_Pushed         (** push confirmed *)
  | S_Failed         (** push rejected or error *)
  | S_Delivered      (** moved to sent, terminal *)

type sender_event =
  | SE_CreateBranch
  | SE_Push
  | SE_PushOk
  | SE_PushFail
  | SE_Retry
  | SE_Cleanup

val string_of_sender_state : sender_state -> string

val sender_transition : sender_state -> sender_event -> (sender_state, string) result
(** Apply an event to a sender state. Returns [Ok new_state] or [Error reason]. *)


(** {1 FSM 4: Transport Receiver} *)

type receiver_state =
  | R_Fetched        (** branch exists after fetch *)
  | R_Materializing  (** writing content to inbox *)
  | R_Materialized   (** content in inbox, branch still exists *)
  | R_Skipped        (** duplicate/archived, skip *)
  | R_Rejected       (** orphan branch *)
  | R_Cleaned        (** branch deleted, terminal *)

type receiver_event =
  | RE_IsNew
  | RE_IsDuplicate
  | RE_IsOrphan
  | RE_WriteOk
  | RE_WriteFail
  | RE_DeleteBranch

val string_of_receiver_state : receiver_state -> string

val receiver_transition : receiver_state -> receiver_event -> (receiver_state, string) result
(** Apply an event to a receiver state. Returns [Ok new_state] or [Error reason]. *)
