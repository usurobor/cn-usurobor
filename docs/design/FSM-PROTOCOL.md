# Design: cn Git Protocol as Typed FSM

**Status:** Proposed  
**Author:** Sigma  
**Date:** 2026-02-11  

## Context

The cn protocol uses git branches for peer-to-peer messaging. Current implementation is implicit — state transitions scattered across `cn_io.ml` and `cn_mail.ml`. Recent bug (branches not cleaned up after materialization) shows we need explicit state management.

## Goal

Implement the cn git protocol as a typed Finite State Machine in OCaml, where:
- States are algebraic data types (variants)
- Transitions are total functions with exhaustive pattern matching
- Invalid transitions are compile-time errors (where possible) or explicit `Error` results
- Current scattered logic is refactored to use the FSM

## Protocol Analysis

### Sender Branch Lifecycle (outbox → delivery)

```
Created → Pushed → Acknowledged → Cleaned
                 ↘ Rejected → Cleaned
```

**States:**
- `S_Pending` — message file exists in `threads/outbox/`, branch not yet created
- `S_BranchCreated` — branch exists in peer's clone locally
- `S_Pushed` — branch pushed to peer's origin
- `S_Rejected` — push rejected by remote
- `S_Delivered` — terminal state, branch deleted, message in `threads/sent/`

### Receiver Branch Lifecycle (fetch → inbox)

```
Fetched → Materialized → Cleaned
        ↘ Skipped → Cleaned (already archived)
```

**States:**
- `R_Fetched` — branch exists locally after `git fetch`
- `R_Materialized` — content written to `threads/inbox/`
- `R_Skipped` — content already archived, no action needed
- `R_Cleaned` — terminal state, local branch deleted

### Events

- `E_CreateBranch` — create branch in peer's clone
- `E_Push` — attempt to push branch to remote
- `E_PushOk` — push succeeded
- `E_PushRejected` — remote rejected push
- `E_Fetch` — `git fetch` from peer
- `E_Materialize` — write branch content to inbox
- `E_Skip` — content already archived
- `E_Cleanup` / `E_DeleteBranch` — delete local/remote branch

## Implementation Approach

### 1. Types Module (`cn_protocol.ml`)

```ocaml
(** cn_protocol.ml — Typed FSM for cn git protocol *)

(* === Sender States === *)
type sender_state =
  | S_Pending        (* message in outbox, no branch yet *)
  | S_BranchCreated  (* branch created in peer clone *)
  | S_Pushed         (* branch pushed to peer origin *)
  | S_Rejected       (* push was rejected *)
  | S_Delivered      (* message moved to sent/, cleanup done *)

(* === Receiver States === *)
type receiver_state =
  | R_Fetched        (* branch fetched from peer *)
  | R_Materialized   (* content written to inbox *)
  | R_Skipped        (* already archived, nothing to do *)
  | R_Cleaned        (* branch deleted, terminal *)

(* === Events === *)
type sender_event =
  | E_CreateBranch
  | E_Push
  | E_PushOk
  | E_PushRejected
  | E_Cleanup

type receiver_event =
  | E_Fetch
  | E_Materialize
  | E_Skip
  | E_DeleteBranch

(* === Transition Results === *)
type 'a transition_result =
  | Ok of 'a
  | Invalid of { from_state: string; event: string; reason: string }

(* === Transition Functions === *)
val sender_transition : sender_state -> sender_event -> sender_state transition_result
val receiver_transition : receiver_state -> receiver_event -> receiver_state transition_result
```

### 2. Implementation Requirements

1. **Exhaustive matching** — every `(state, event)` pair must be handled
2. **Invalid transitions return `Error`** — not exceptions
3. **Logging** — each transition logs to `runtime.md` for observability
4. **Idempotency** — re-applying same event in terminal state is no-op, not error

### 3. Integration with Existing Code

Refactor these functions to use FSM:

| Current Function | File | New Approach |
|------------------|------|--------------|
| `send_thread` | cn_io.ml | Drive through sender FSM |
| `sync_inbox` | cn_io.ml | Drive through receiver FSM |
| `flush_single` | cn_mail.ml | Use sender FSM |
| `handle_rejection` | cn_mail.ml | Transition to `S_Rejected` |
| `delete_remote_branch` | cn_mail.ml | `E_Cleanup` event |

### 4. State Persistence

Current state is implicit in filesystem:
- Outbox file exists → `S_Pending`
- Sent file exists → `S_Delivered`
- Inbox branch exists → `R_Fetched`

FSM doesn't need separate state storage — derive state from filesystem artifacts. But transitions must be atomic (do action, then update artifact).

### 5. Testing Requirements

For each FSM:
1. **Happy path**: all valid transitions in sequence
2. **Invalid transitions**: verify `Error` returned
3. **Idempotency**: terminal states accept re-application gracefully
4. **Property tests** (optional): random event sequences never crash

Example test structure:
```ocaml
let%expect_test "sender happy path" =
  let state = S_Pending in
  let state = sender_transition state E_CreateBranch |> unwrap in
  let state = sender_transition state E_Push |> unwrap in
  let state = sender_transition state E_PushOk |> unwrap in
  let state = sender_transition state E_Cleanup |> unwrap in
  print_state state;
  [%expect {| S_Delivered |}]

let%expect_test "invalid transition" =
  let result = sender_transition S_Pending E_PushOk in
  print_result result;
  [%expect {| Invalid: S_Pending + E_PushOk (must create branch first) |}]
```

## Deliverables

1. **`tools/src/cn/cn_protocol.ml`** — FSM types and transition functions
2. **`tools/src/cn/cn_protocol.mli`** — interface file
3. **`tools/test/cn/cn_protocol_test.ml`** — ppx_expect tests
4. **Updated `cn_io.ml`** — refactored to use FSM
5. **Updated `cn_mail.ml`** — refactored to use FSM
6. **Updated `dune`** — add cn_protocol to build

## Constraints

- Pure OCaml (stdlib + unix), no external FSM libraries
- Maintain backward compatibility — CLI behavior unchanged
- All existing tests must pass
- Follow existing code style (see `cn_ffi.ml`, `cn_hub.ml` for reference)

## Verification

```bash
# Build
dune build tools/src/cn/cn.exe

# Tests pass
dune runtest

# CLI unchanged
cn --version
cn sync
cn send self "test"
```

## Branch

`task/fsm-protocol`

## Decision Log

| Date | Decision | Rationale |
|------|----------|-----------|
| 2026-02-11 | FSM over Statecharts | Protocol is simple enough; nested variants handle hierarchy if needed |
| 2026-02-11 | Derive state from filesystem | No extra state file; artifacts are source of truth |
| 2026-02-11 | `Error` over exceptions | Explicit error handling, composable with `Result` |
