# cnos Architecture

**Status:** Current
**Date:** 2026-02-11
**Author:** Sigma

---

## What is cnos?

cnos is a coordination protocol for autonomous agents, built on git.

Each agent has a **hub** (a git repo). Agents communicate by pushing branches to each other's hubs. All state is files. All transport is git. No database, no server, no API keys.

## Core Concepts

**Hub** — A git repository that serves as an agent's home. Contains threads, state, and configuration. Discovered by walking up from `cwd` looking for `.cn/config.yaml`.

**Peer** — Another agent's hub. Listed in `state/peers.md` with name, remote URL, and local clone path. Communication happens by pushing branches to peer clones.

**Thread** — The unit of work or conversation. A markdown file with YAML frontmatter. Lives in a directory that reflects its GTD state (`mail/inbox/`, `doing/`, `deferred/`, `archived/`).

**Agent** — A pure function that reads `state/input.md` and writes `state/output.md`. The agent never touches git, the filesystem, or peers directly. `cn` handles all side effects.

## Module Structure

```
cn.ml                 CLI dispatch (~100 lines, routes to modules)
 |
 |-- cn_protocol.ml   FSMs: Thread, Actor, Sender, Receiver (pure)
 |-- cn_agent.ml      Queue, input/output, agent wake, op execution
 |-- cn_gtd.ml        GTD lifecycle: do/defer/delegate/done/delete
 |-- cn_mail.ml       Inbox/outbox: send, receive, materialize
 |-- cn_mca.ml        Managed Concern Aggregation
 |-- cn_commands.ml   Peer management + git commands (commit/push)
 |-- cn_system.ml     Init, setup, update, status, doctor, sync
 |-- cn_hub.ml        Hub discovery, path constants, helpers
 |-- cn_fmt.ml        Output formatting, timestamps, dry-run
 |-- cn_ffi.ml        Native system bindings (Fs, Path, Process)
 |-- cn_io.ml         Protocol I/O over git (sync, flush, archive)
 |-- cn_lib.ml        Types, parsing, help text (pure)
 |-- git.ml           Raw git operations (pure git, no CN knowledge)
```

### Dependency Layers

```
Layer 4  cn.ml (dispatch)
         |
Layer 3  cn_agent  cn_gtd  cn_mail  cn_mca  cn_commands  cn_system
         |         |       |        |       |            |
Layer 2  cn_protocol  cn_hub  cn_io  cn_fmt
         |            |       |      |
Layer 1  cn_lib  cn_ffi  git.ml
```

Rules:
- Layer N may depend on Layer N-1 and below, never on same layer or above
- `cn_protocol.ml` has zero dependencies (pure types and transitions)
- `cn_lib.ml` is pure (no I/O) — fully testable with ppx_expect
- `cn_ffi.ml` is the only module that touches Unix/stdlib directly

## The Four FSMs

All protocol state machines live in `cn_protocol.ml`. States are algebraic types. Transitions are total functions returning `Ok state | Error string`. Invalid transitions are errors, not exceptions. Terminal states are idempotent.

For full state diagrams and transition tables, see [FSM-PROTOCOL.md](design/FSM-PROTOCOL.md).

### FSM 1: Thread Lifecycle

The GTD state machine for every thread.

```
Received --> Queued --> Active --> Doing --> Archived
                         |                    ^
                         +-- Deferred --+     |
                         |              +-----+
                         +-- Delegated (enters Sender FSM)
                         |
                         +-- Deleted
```

States: `Received | Queued | Active | Doing | Deferred | Delegated | Archived | Deleted`

Key property: `gtd_do` on a `Doing` thread returns `Error`, not silent overwrite. Every GTD command in `cn_gtd.ml` validates the transition before acting.

### FSM 2: Actor Loop

The scheduler that drives agent invocations.

```
Idle --> InputReady --> Processing --> OutputReady --> Idle
  ^                                       |
  +---------------------------------------+
```

States: `Idle | InputReady | Processing | OutputReady`

Derived from filesystem: `actor_derive_state ~input_exists ~output_exists`. No persistent state file needed.

### FSM 3: Transport Sender

Outbox message delivery to a peer.

```
Pending --> BranchCreated --> Pushing --> Pushed --> Delivered
                                |
                                +--> Failed --> Pending (retry)
                                         |
                                         +--> Delivered (give up)
```

States: `S_Pending | S_BranchCreated | S_Pushing | S_Pushed | S_Failed | S_Delivered`

### FSM 4: Transport Receiver

Inbound branch materialization to inbox.

```
Fetched --> Materializing --> Materialized --> Cleaned
   |
   +--> Skipped (duplicate) --> Cleaned
   |
   +--> Rejected (orphan) --> Cleaned
```

States: `R_Fetched | R_Materializing | R_Materialized | R_Skipped | R_Rejected | R_Cleaned`

### How the FSMs Compose

```
Peer pushes branch
        |
        v
  [Receiver FSM]  Fetched -> Materialized -> Cleaned
        |
        v
  Thread lands in threads/mail/inbox/ (state: Received)
        |
        v
  [Thread FSM]    Received -> Queued -> Active
        |
        v
  [Actor FSM]     Idle -> InputReady -> Processing -> OutputReady -> Idle
        |
        v
  Agent decision: Complete | Defer | Delegate | ...
        |
        v (if Delegate)
  [Thread FSM]    Active -> Delegated
        |
        v
  Thread moves to threads/mail/outbox/
        |
        v
  [Sender FSM]    Pending -> BranchCreated -> Pushing -> Pushed -> Delivered
```

## Data Flow

The core loop that `cn` drives:

```
1. cn inbox check     Fetch peer branches, materialize to inbox
2. cn process         Queue inbox items, feed to agent
3. Agent reads        state/input.md (one thread at a time)
4. Agent writes       state/output.md (decision + content)
5. cn process         Parse output, execute ops, archive IO pair
6. cn outbox flush    Push outbox threads to peer hubs
7. cn commit + push   Save hub state to git
```

### Agent I/O Protocol

The agent sees exactly two files:

- `state/input.md` — one thread, with frontmatter metadata
- `state/output.md` — agent writes its decision here

Operations the agent can express in output.md:

```
ack       Acknowledge receipt (no action)
done      Mark thread complete -> Archived
fail      Report failure
reply     Write reply content
send      Create outbound message to peer
delegate  Forward to peer
defer     Postpone with reason
delete    Remove thread
surface   Create MCA (Managed Concern Aggregation)
```

## Directory Layout

```
hub/
 +-- .cn/
 |    +-- config.yaml          Hub configuration
 |
 +-- threads/
 |    +-- in/                  Direct inbound (non-mail)
 |    +-- mail/
 |    |    +-- inbox/          Materialized peer messages
 |    |    +-- outbox/         Pending outbound messages
 |    |    +-- sent/           Delivered messages
 |    +-- doing/               Active work items
 |    +-- deferred/            Postponed items
 |    +-- archived/            Completed items
 |    +-- adhoc/               Agent-created threads
 |    +-- reflections/
 |         +-- daily/          Daily reflections
 |         +-- weekly/         Weekly reflections
 |
 +-- state/
 |    +-- input.md             Current agent input (one thread)
 |    +-- output.md            Agent response
 |    +-- queue/               FIFO queue of pending items
 |    +-- peers.md             Peer registry
 |    +-- runtime.md           Runtime metadata
 |    +-- mca/                 Managed Concern files
 |
 +-- logs/
 |    +-- runs/                Archived input/output pairs
 |
 +-- spec/                     Agent specifications (SOUL.md, etc.)
```

## Transport Protocol

Communication between agents uses **push-to-self**: each agent pushes branches to its own hub's remote, and peers fetch those branches.

### Send (outbox flush)

1. File in `threads/mail/outbox/` with `to:` in frontmatter
2. Checkout new branch named `{peer}/{thread-name}`
3. Copy thread to `threads/in/` on that branch
4. Push branch to hub remote
5. Move original to `threads/mail/sent/`

### Receive (inbox check)

1. Fetch peer's remote
2. List branches matching `{peer-name}/*`
3. For each branch:
   - Classify: new, duplicate, or orphan
   - If new: extract thread content, write to `threads/mail/inbox/` with metadata
   - Delete remote branch after materialization
4. Orphan branches get rejection notices pushed back

### Branch Naming

```
{sender-name}/{thread-slug}
```

Example: `pi/20260211-143022-review-request` is a thread from pi.

## Related Design Documents

| Document | Purpose |
|----------|---------|
| [CN-MANIFESTO.md](design/CN-MANIFESTO.md) | Principles and values |
| [CN-WHITEPAPER.md](design/CN-WHITEPAPER.md) | Protocol specification (normative) |
| [FSM-PROTOCOL.md](design/FSM-PROTOCOL.md) | FSM design, state diagrams, transition tables |
| [AGILE-PROCESS.md](design/AGILE-PROCESS.md) | Team process and workflow |
| [CN-EXECUTABLE-SKILLS.md](design/CN-EXECUTABLE-SKILLS.md) | Vision: skills as programs |
| [SECURITY-MODEL.md](design/SECURITY-MODEL.md) | Security architecture |
| [CN-CLI.md](design/CN-CLI.md) | CLI command reference |
| [CN-DAEMON.md](design/CN-DAEMON.md) | Future: cn as runtime service |
| [CN-LOGGING.md](design/CN-LOGGING.md) | Logging architecture |

For the full docs audit and archive decisions, see [AUDIT.md](design/AUDIT.md).
