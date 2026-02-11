# Design: cn Protocol as Typed FSMs

**Status:** Implemented (v2 — `cn_protocol.ml` matches this spec)
**Author:** Sigma
**Date:** 2026-02-11
**Reviewers:** Pi, Axiom

## Context

The cn protocol has **four** distinct state machines, not two. The v1 proposal covered only transport (sender/receiver). This revision covers the full system:

1. **Transport Sender** — outbox message → peer delivery
2. **Transport Receiver** — peer branch → inbox materialization
3. **Thread Lifecycle** — GTD state transitions (the user-visible FSM)
4. **Actor Loop** — agent invocation cycle (the scheduler FSM)

Additionally, `cn_io.ml` and `cn_mail.ml` are **duplicate implementations** of transport. The FSM unification eliminates this duplication.

### Problem Evidence

| Bug | Root Cause | FSM That Would Prevent It |
|-----|-----------|---------------------------|
| Branches not cleaned after materialization | No terminal-state enforcement | Receiver FSM |
| 4-hour coordination failure (RCA 2026-02-05) | No delivery confirmation state | Sender FSM |
| Double-processing of inbox items | No `queued-for-processing` guard (added ad-hoc) | Actor Loop FSM |
| `gtd_do` on already-doing thread silently overwrites | No transition validation | Thread Lifecycle FSM |
| `cn_io.ml` vs `cn_mail.ml` divergence | Duplicate transport logic | Single FSM replaces both |

## Goal

Model the cn protocol as four typed FSMs where:
- States are algebraic data types
- Transitions are total functions with exhaustive matching
- Invalid transitions return `Error`, not exceptions
- Scattered logic in `cn_io.ml` + `cn_mail.ml` is unified into one transport FSM
- Thread lifecycle gets compile-time transition safety

---

## FSM 1: Transport Sender

Lifecycle of an outbound message from creation to delivery.

```
                ┌──────────┐
                │ Pending  │  file in threads/mail/outbox/
                └────┬─────┘
                     │ create_branch
                     ▼
              ┌──────────────┐
              │ BranchCreated│  branch in peer's clone
              └──────┬───────┘
                     │ push
                     ▼
               ┌───────────┐
          ┌────│  Pushing   │────┐
          │    └───────────┘    │
      push_ok              push_fail
          │                     │
          ▼                     ▼
    ┌───────────┐        ┌──────────┐
    │  Pushed   │        │  Failed  │
    └─────┬─────┘        └────┬─────┘
          │ cleanup            │ retry (→ Pending)
          ▼                    │ or cleanup
    ┌───────────┐              ▼
    │ Delivered │        ┌───────────┐
    └───────────┘        │ Delivered │
                         └───────────┘
```

```ocaml
type sender_state =
  | Pending        (* file in outbox/, no branch *)
  | BranchCreated  (* branch exists in peer clone *)
  | Pushing        (* push in progress *)
  | Pushed         (* push confirmed *)
  | Failed         (* push rejected or error *)
  | Delivered      (* moved to sent/, terminal *)

type sender_event =
  | Create_branch
  | Push
  | Push_ok
  | Push_fail of string  (* reason *)
  | Retry
  | Cleanup

let sender_transition state event =
  match state, event with
  | Pending,        Create_branch -> Ok BranchCreated
  | BranchCreated,  Push          -> Ok Pushing
  | Pushing,        Push_ok       -> Ok Pushed
  | Pushing,        Push_fail _   -> Ok Failed
  | Pushed,         Cleanup       -> Ok Delivered
  | Failed,         Retry         -> Ok Pending
  | Failed,         Cleanup       -> Ok Delivered
  | Delivered,      _             -> Ok Delivered  (* idempotent terminal *)
  | from, ev -> Error { from; ev; reason = "invalid transition" }
```

**Maps to current code:** `cn_mail.ml:send_thread` + `cn_io.ml:send_thread` → unified.

---

## FSM 2: Transport Receiver

Lifecycle of an inbound message from fetch to inbox.

```
         ┌──────────┐
         │ Fetched  │  branch in my repo after git fetch
         └────┬─────┘
              │
         ┌────┴────┐
         │         │
     is_new    is_duplicate
         │         │
         ▼         ▼
   ┌───────────┐ ┌─────────┐
   │Materializ-│ │ Skipped │
   │   ing     │ └────┬────┘
   └─────┬─────┘      │ delete_branch
         │ write_ok    ▼
         ▼       ┌───────────┐
   ┌───────────┐ │  Cleaned  │
   │Materialized│ └───────────┘
   └─────┬─────┘
         │ delete_branch
         ▼
   ┌───────────┐
   │  Cleaned  │
   └───────────┘
```

```ocaml
type receiver_state =
  | Fetched          (* branch exists after fetch *)
  | Materializing    (* writing content to inbox *)
  | Materialized     (* content in inbox, branch still exists *)
  | Skipped          (* duplicate/archived, skip *)
  | Rejected         (* orphan branch, rejected *)
  | Cleaned          (* branch deleted, terminal *)

type receiver_event =
  | Check_duplicate
  | Check_orphan
  | Is_new
  | Is_duplicate
  | Is_orphan
  | Write_ok
  | Write_fail of string
  | Delete_branch

let receiver_transition state event =
  match state, event with
  | Fetched,       Is_new         -> Ok Materializing
  | Fetched,       Is_duplicate   -> Ok Skipped
  | Fetched,       Is_orphan      -> Ok Rejected
  | Materializing, Write_ok       -> Ok Materialized
  | Materializing, Write_fail _   -> Ok Fetched  (* retry *)
  | Materialized,  Delete_branch  -> Ok Cleaned
  | Skipped,       Delete_branch  -> Ok Cleaned
  | Rejected,      Delete_branch  -> Ok Cleaned
  | Cleaned,       _              -> Ok Cleaned  (* idempotent terminal *)
  | from, ev -> Error { from; ev; reason = "invalid transition" }
```

**Maps to current code:** `cn_mail.ml:materialize_branch` + `cn_io.ml:materialize_branch` → unified.

---

## FSM 3: Thread Lifecycle (GTD)

Lifecycle of a thread from creation to archival. This is the **user-visible** FSM.

```
                    ┌──────────┐
          ┌─────── │ Received │ ←── inbox materialization
          │        └────┬─────┘
          │             │ triage
          │        ┌────┴────┐────────────┐
          │        │         │            │
          │     gtd_do   gtd_defer   gtd_delegate
          │        │         │            │
          │        ▼         ▼            ▼
          │  ┌─────────┐ ┌──────────┐ ┌───────────┐
          │  │  Doing  │ │ Deferred │ │ Delegated │
          │  └────┬────┘ └────┬─────┘ └─────┬─────┘
          │       │           │              │
          │    gtd_done    re-queue     (→ Sender FSM)
          │       │           │
          │       ▼           ▼
          │  ┌──────────┐  back to
          │  │ Archived │  Received
          │  └──────────┘
          │
       gtd_delete
          │
          ▼
    ┌──────────┐
    │ Deleted  │
    └──────────┘
```

```ocaml
type thread_state =
  | Received    (* inbox, awaiting triage *)
  | Queued      (* in state/queue/, waiting for agent turn *)
  | Active      (* in state/input.md, agent is processing *)
  | Doing       (* agent claimed, work in progress *)
  | Deferred    (* postponed with reason/until *)
  | Delegated   (* forwarded to peer, enters Sender FSM *)
  | Archived    (* terminal: completed or discarded *)
  | Deleted     (* terminal: removed *)

type thread_event =
  | Enqueue               (* inbox → queue *)
  | Feed                  (* queue → input.md *)
  | Claim                 (* agent: Do *)
  | Complete              (* agent: Done *)
  | Defer of string       (* agent: Defer, with reason *)
  | Delegate of string    (* agent: Delegate, to peer *)
  | Discard               (* agent: Delete *)
  | Resurface             (* deferred → re-queue *)

let thread_transition state event =
  match state, event with
  (* Inbox processing *)
  | Received,  Enqueue        -> Ok Queued
  | Queued,    Feed           -> Ok Active
  (* Agent decisions *)
  | Active,    Claim          -> Ok Doing
  | Active,    Complete       -> Ok Archived    (* direct completion *)
  | Active,    Defer _        -> Ok Deferred
  | Active,    Delegate _     -> Ok Delegated
  | Active,    Discard        -> Ok Deleted
  (* Doing lifecycle *)
  | Doing,     Complete       -> Ok Archived
  | Doing,     Defer _        -> Ok Deferred    (* pause mid-work *)
  (* Deferred lifecycle *)
  | Deferred,  Resurface      -> Ok Queued      (* re-enters queue *)
  | Deferred,  Discard        -> Ok Deleted
  (* Terminals are idempotent *)
  | Archived,  _              -> Ok Archived
  | Deleted,   _              -> Ok Deleted
  (* Everything else is invalid *)
  | from, ev -> Error { from; ev; reason = "invalid transition" }
```

**Key improvement over current code:** `cn_gtd.ml` currently allows any GTD command on any thread regardless of state. With this FSM, `gtd_do` on a `Doing` thread returns `Error` instead of silently overwriting.

**State persistence:** Add `state:` field to thread frontmatter. Directory placement remains for human readability, but the frontmatter field is the source of truth:

```yaml
---
from: pi
state: received
trigger: a1b2c3d
received: 2026-02-11T10:00:00Z
---
```

---

## FSM 4: Actor Loop

The cn scheduler's invocation cycle. One agent turn at a time.

```
    ┌───────┐
    │ Idle  │ ←──────────────────────────┐
    └───┬───┘                            │
        │ queue_pop (items exist)        │
        ▼                                │
  ┌────────────┐                         │
  │ InputReady │  state/input.md written │
  └──────┬─────┘                         │
         │ wake_agent                    │
         ▼                               │
  ┌─────────────┐                        │
  │ Processing  │  agent working         │
  └──────┬──────┘                        │
         │ output.md appears             │
         ▼                               │
  ┌─────────────┐                        │
  │ OutputReady │                        │
  └──────┬──────┘                        │
         │ archive + execute ops         │
         ▼                               │
  ┌─────────────┐                        │
  │  Archiving  │  logs written          │
  └──────┬──────┘                        │
         │ auto-save + clear             │
         └───────────────────────────────┘
```

```ocaml
type actor_state =
  | Idle           (* no input.md, queue may have items *)
  | InputReady     (* input.md written, agent not yet woken *)
  | Processing     (* agent working, awaiting output.md *)
  | OutputReady    (* output.md exists, ready to archive *)
  | Archiving      (* executing ops, writing logs *)

type actor_event =
  | Queue_pop          (* dequeue item → input.md *)
  | Queue_empty        (* nothing to process *)
  | Wake               (* trigger agent *)
  | Output_received    (* output.md detected *)
  | Archive_complete   (* ops executed, logs written *)
  | Archive_fail of string

let actor_transition state event =
  match state, event with
  | Idle,         Queue_pop         -> Ok InputReady
  | Idle,         Queue_empty       -> Ok Idle      (* stay idle *)
  | InputReady,   Wake              -> Ok Processing
  | Processing,   Output_received   -> Ok OutputReady
  | OutputReady,  Archive_complete  -> Ok Idle       (* cycle complete *)
  | OutputReady,  Archive_fail _    -> Ok OutputReady  (* retry *)
  | Archiving,    Archive_complete  -> Ok Idle
  | from, ev -> Error { from; ev; reason = "invalid transition" }
```

**Maps to current code:** `cn_agent.ml:run_inbound` — currently a 35-line function with nested if/else. With this FSM, each branch becomes a state transition, and crash recovery is deterministic.

**State derivation:**
| Filesystem | Actor State |
|------------|-------------|
| No `input.md`, no `output.md` | `Idle` |
| `input.md` exists, no `output.md` | `Processing` |
| `input.md` exists, `output.md` exists | `OutputReady` |
| Neither (just cleared) | `Idle` |

---

## Composition: How the Four FSMs Interact

```
                          EXTERNAL
                         (peer push)
                             │
                             ▼
                    ┌─────────────────┐
                    │ Receiver FSM    │
                    │ (per branch)    │
                    └────────┬────────┘
                             │ Materialized
                             ▼
                    ┌─────────────────┐
                    │ Thread FSM      │   ←── gtd commands
                    │ (per thread)    │       (cn delete, cn defer, etc.)
                    └──┬──────────┬───┘
                       │          │
                  Enqueue     Delegate
                       │          │
                       ▼          ▼
              ┌────────────┐  ┌──────────────┐
              │ Actor FSM  │  │ Sender FSM   │
              │ (singleton)│  │ (per message) │
              └────────────┘  └──────────────┘
                                     │
                                     ▼
                                  EXTERNAL
                                (git push to peer)
```

Invariants:
- **Actor FSM is singleton** — one agent turn at a time
- **Thread FSM is per-thread** — each thread has independent state
- **Transport FSMs are per-message** — each send/receive is independent
- **Thread → Actor** coupling: `Enqueue` in Thread FSM triggers `Queue_pop` in Actor FSM
- **Thread → Sender** coupling: `Delegate` in Thread FSM creates a new Sender FSM instance

---

## Unifying cn_io.ml and cn_mail.ml

Current state: two modules implement overlapping transport logic.

| Operation | cn_mail.ml | cn_io.ml |
|-----------|-----------|----------|
| Materialize branch | `materialize_branch` (175 lines, orphan detection, rejection notices) | `materialize_branch` (20 lines, simple) |
| Send thread | `send_thread` (55 lines, uses hub as working tree) | `send_thread` (30 lines, uses peer clone) |
| Inbox check | `inbox_check` (uses peer clones) | `sync_inbox` (uses hub fetch) |
| Branch cleanup | `delete_remote_branch` | (inline) |

**Resolution:** The FSM becomes the single transport module. Both `cn_io.ml` and `cn_mail.ml` transport functions are replaced by FSM-driven functions in `cn_protocol.ml`. Domain-specific logic (orphan detection, rejection notices) becomes guard conditions on transitions.

After unification:
- `cn_protocol.ml` — FSM types, transitions, transport execution
- `cn_mail.ml` — inbox/outbox CLI commands (thin wrappers calling protocol)
- `cn_io.ml` — **removed**, absorbed into cn_protocol.ml

---

## Implementation

### Module: `cn_protocol.ml`

```ocaml
(** cn_protocol.ml — Typed FSMs for the cn protocol

    Four FSMs:
    1. sender_fsm    — outbox → delivery
    2. receiver_fsm  — fetch → inbox
    3. thread_fsm    — GTD lifecycle
    4. actor_fsm     — agent invocation loop

    All transitions are total. Invalid = Error, not exception.
    Terminal states are idempotent. *)

(* === Shared === *)

type ('s, 'e) error = {
  from_state : 's;
  event : 'e;
  reason : string;
}

(* === FSM 1: Sender === *)
(* ... types as above ... *)

(* === FSM 2: Receiver === *)
(* ... types as above ... *)

(* === FSM 3: Thread === *)
(* ... types as above ... *)

(* === FSM 4: Actor === *)
(* ... types as above ... *)

(* === Execution: drive FSM + perform side effects === *)

val send_message : hub_path:string -> name:string -> peer:Cn_lib.peer_info -> file:string -> (sender_state, string) result
(** Drive a message through the full Sender FSM. Returns terminal state or error. *)

val receive_branch : hub_path:string -> clone_path:string -> peer_name:string -> branch:string -> (receiver_state, string) result
(** Drive a branch through the full Receiver FSM. Returns terminal state or error. *)

val thread_apply : hub_path:string -> thread_id:string -> thread_event -> (thread_state, string) result
(** Apply a GTD event to a thread. Validates current state, performs transition. *)

val actor_step : hub_path:string -> name:string -> (actor_state, string) result
(** Run one step of the actor loop. Determines current state from filesystem,
    applies the appropriate event, returns new state. *)
```

### State in Frontmatter

Every thread gets an explicit `state:` field:

```yaml
---
from: pi
state: received
trigger: a1b2c3d
received: 2026-02-11T10:00:00Z
---
```

On each GTD transition, cn updates the field:
```ocaml
let thread_apply ~hub_path ~thread_id event =
  match find_thread hub_path thread_id with
  | None -> Error "thread not found"
  | Some (path, content) ->
      let current = state_of_frontmatter content in
      match thread_transition current event with
      | Error e -> Error (format_error e)
      | Ok new_state ->
          let content' = update_frontmatter content [("state", string_of_thread_state new_state)] in
          move_to_directory hub_path path new_state content';
          Ok new_state
```

Directory placement **follows** state — it's a derived artifact, not the source of truth:

| State | Directory |
|-------|-----------|
| `Received` | `threads/mail/inbox/` |
| `Queued` | `state/queue/` |
| `Active` | `state/input.md` |
| `Doing` | `threads/doing/` |
| `Deferred` | `threads/deferred/` |
| `Delegated` | `threads/mail/outbox/` |
| `Archived` | `threads/archived/` |
| `Deleted` | (removed from filesystem) |

---

## Testing

### Per-FSM tests (ppx_expect)

```ocaml
(* Sender happy path *)
let%expect_test "sender: pending → delivered" =
  S_Pending
  |> apply Create_branch |> apply Push
  |> apply Push_ok |> apply Cleanup
  |> print_state;
  [%expect {| Delivered |}]

(* Thread: invalid transition *)
let%expect_test "thread: cannot complete a received thread" =
  thread_transition Received Complete |> print_result;
  [%expect {| Error: Received + Complete (must triage first) |}]

(* Actor: derive state from filesystem *)
let%expect_test "actor: input exists, no output → Processing" =
  (* setup: write input.md, no output.md *)
  actor_derive_state hub_path |> print_state;
  [%expect {| Processing |}]

(* Thread: defer → resurface → queue *)
let%expect_test "thread: defer then resurface" =
  Received |> apply (Defer "busy")
  |> apply Resurface
  |> print_state;
  [%expect {| Queued |}]
```

### Property tests (optional)

```ocaml
(* Any sequence of valid events from any reachable state never panics *)
let%expect_test "thread FSM: no panics" =
  let all_events = [Enqueue; Feed; Claim; Complete; Defer "x"; Delegate "y"; Discard; Resurface] in
  let all_states = [Received; Queued; Active; Doing; Deferred; Delegated; Archived; Deleted] in
  all_states |> List.iter (fun s ->
    all_events |> List.iter (fun e ->
      (* Must return Ok or Error, never raise *)
      ignore (thread_transition s e)));
  [%expect {| |}]
```

---

## Crash Recovery

Each FSM supports deterministic recovery from any intermediate state:

| FSM | Recovery Logic |
|-----|----------------|
| **Sender** | If `BranchCreated` but not `Pushed`: retry push. If `Pushed` but not `Delivered`: cleanup. |
| **Receiver** | If `Materialized` but not `Cleaned`: delete branch. If `Fetched`: re-run materialization. |
| **Thread** | State in frontmatter survives crash. Re-derive and continue. |
| **Actor** | Derive from `input.md`/`output.md` existence (table above). Resume from derived state. |

---

## Deliverables

1. **`tools/src/cn/cn_protocol.ml`** — all four FSMs, types, transitions, execution
2. **`tools/src/cn/cn_protocol.mli`** — interface
3. **`tools/test/cn/cn_protocol_test.ml`** — ppx_expect tests
4. **Updated `cn_mail.ml`** — thin wrapper calling cn_protocol
5. **Updated `cn_gtd.ml`** — GTD commands go through Thread FSM
6. **Updated `cn_agent.ml`** — actor loop driven by Actor FSM
7. **Remove `cn_io.ml` transport functions** — absorbed into cn_protocol
8. **Updated `dune`** — add cn_protocol to build

## Constraints

- Pure OCaml (stdlib + unix), no external FSM libraries
- Backward compatible: CLI behavior unchanged
- All existing tests pass
- State field added to frontmatter is optional (missing = derive from directory)

## Migration

1. Add `state:` field to new threads (forward-compatible)
2. Old threads without `state:` derive state from directory (backward-compatible)
3. No big-bang migration needed — gradual adoption

---

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-11 | FSM over Statecharts | Protocol is simple enough; nested variants handle hierarchy if needed |
| 2026-02-11 | Derive state from filesystem | No extra state file; artifacts are source of truth |
| 2026-02-11 | `Error` over exceptions | Explicit error handling, composable with `Result` |
| 2026-02-11 | Four FSMs, not two | Actor loop and Thread lifecycle have distinct failure modes; modeling them prevents bugs |
| 2026-02-11 | Explicit `state:` in frontmatter | Directory placement is derived, not source of truth; survives crashes |
| 2026-02-11 | Unify cn_io.ml + cn_mail.ml | Duplicate transport logic is a bug vector; single FSM eliminates it |
| 2026-02-11 | Terminal state idempotency | Re-applying events to Archived/Delivered is no-op, enabling safe retries |
