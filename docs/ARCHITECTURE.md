# cnos Architecture

**Status:** Current
**Date:** 2026-02-22
**Author:** Sigma

---

## What is cnos?

cnos is a coordination protocol for autonomous agents, built on git.

Each agent has a **hub** (a git repo). Agents publish by pushing branches to their own hub; peers fetch and merge. All state is files. All transport is git. No database, no server, no API keys.

## Core Concepts

**Hub** — A git repository that serves as an agent's home. Contains threads, state, and configuration. Discovered by walking up from `cwd` looking for `.cn/config.json`.

**Peer** — Another agent's hub. Listed in `state/peers.md` with name, remote URL, and local clone path. You maintain a local clone of each peer's hub to fetch their outbound branches.

**Thread** — The unit of work or conversation. A markdown file with YAML frontmatter. Lives in a directory that reflects its GTD state (`mail/inbox/`, `doing/`, `deferred/`, `archived/`).

**Agent** — A pure function: input → output. The agent never touches git, the filesystem, or peers directly. `cn` handles all I/O and side effects.

## Module Structure

```
cn.ml                 CLI dispatch (~100 lines, routes to modules)
 |
 |-- cn_runtime.ml    Agent runtime orchestrator (dequeue → LLM → execute)
 |-- cn_context.ml    Context packer (skills, conversation, artifacts)
 |-- cn_llm.ml        Claude API client (curl-backed, no --fail)
 |-- cn_telegram.ml   Telegram Bot API client
 |-- cn_config.ml     Config loader (env vars + .cn/config.json)
 |-- cn_agent.ml      Queue, input/output, op execution (legacy: run_inbound deprecated)
 |-- cn_protocol.ml   FSMs: Thread, Actor, Sender, Receiver (pure)
 |-- cn_gtd.ml        GTD lifecycle: do/defer/delegate/done/delete
 |-- cn_mail.ml       Inbox/outbox: send, receive, materialize
 |-- cn_mca.ml        Managed Concern Aggregation
 |-- cn_commands.ml   Peer management + git commands (commit/push)
 |-- cn_system.ml     Init, setup, update, status, doctor, sync
 |-- cn_hub.ml        Hub discovery, path constants, helpers
 |-- cn_fmt.ml        Output formatting, timestamps, dry-run
 |-- cn_ffi.ml        Native system bindings (Fs, Path, Process, Http)
 |-- cn_io.ml         Protocol I/O over git (sync, flush, archive)
 |-- cn_lib.ml        Types, parsing, help text (pure)
 |-- cn_json.ml       JSON parser/emitter (pure, zero-dep)
 |-- git.ml           Raw git operations (pure git, no CN knowledge)
```

### Dependency Layers

```
Layer 5  cn.ml (dispatch)
         |
Layer 4  cn_runtime (orchestrator: pack → call → archive → execute → project)
         |
Layer 3  cn_context  cn_llm  cn_telegram  cn_config  cn_agent  cn_gtd  cn_mail  cn_mca  cn_commands  cn_system
         |           |       |            |          |         |       |        |       |            |
Layer 2  cn_protocol  cn_hub  cn_io  cn_fmt
         |            |       |      |
Layer 1  cn_lib  cn_json  cn_ffi  git.ml
```

Rules:
- Layer N may depend on Layer N-1 and below, never on same layer or above
- `cn_protocol.ml` has zero dependencies (pure types and transitions)
- `cn_lib.ml` and `cn_json.ml` are pure (no I/O) — fully testable with ppx_expect
- `cn_ffi.ml` is the only module that touches Unix/stdlib directly
- `cn_runtime.ml` is the only module that calls the LLM

## The Four FSMs

All protocol state machines live in `cn_protocol.ml`. States are algebraic types. Transitions are total functions returning `Ok state | Error string`. Invalid transitions are errors, not exceptions. Terminal states are idempotent.

For full state diagrams and transition tables, see [PROTOCOL.md](design/PROTOCOL.md).

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

The runtime pipeline, executed by `cn agent` (cron) or `cn agent --daemon` (Telegram):

```
1. cn sync            Fetch peer branches, send outbound
2. cn agent           Runtime cycle (under atomic lock):
   a. Queue inbox     Move inbox items to state/queue/
   b. Dequeue         Pop oldest item from queue
   c. Pack context    Build prompt from hub artifacts (identity, skills, conversation, message)
   d. Write input.md  Frontmatter metadata + packed context body
   e. Call LLM        Claude API (body-only prompt, Option B)
   f. Write output.md LLM response (ops in frontmatter, body below)
   g. Archive         Copy input.md + output.md to logs/ (before effects)
   h. Execute ops     Parse output, resolve payloads, execute ops
   i. Project         Route reply to Telegram (if from Telegram)
   j. Conversation    Append to state/conversation.json
   k. Cleanup         Delete state/input.md + state/output.md
3. cn save            Commit + push hub state to git
```

Recovery: if `cn agent` crashes at any point, the next invocation detects
the state (output exists? input only? neither?) and resumes from the correct
step — all under the same atomic lock.

### Prompt Contract (Option B)

- `state/input.md` contains frontmatter metadata (`id`, `from`, `chat_id`, `date`) + packed context body
- The LLM is invoked with the body below frontmatter only (packed context)
- Frontmatter is runtime metadata, not part of the prompt
- `logs/input/` archives the full file for audit

### Agent I/O Protocol

The agent (LLM) sees packed context text and produces structured output:

- **Input:** Packed context (identity, skills, conversation history, inbound message)
- **Output:** `state/output.md` with ops in YAML frontmatter and markdown body below

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
 |    +-- config.json          Hub configuration (env vars override)
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
 |    +-- input.md             Current agent input (frontmatter + packed context)
 |    +-- output.md            LLM response (ops in frontmatter, body below)
 |    +-- queue/               FIFO queue of pending items
 |    +-- agent.lock           Atomic lock (O_CREAT|O_EXCL, prevents cron overlap)
 |    +-- conversation.json    Recent conversation history (last 50 entries)
 |    +-- telegram.offset      Telegram update_id offset (daemon mode)
 |    +-- peers.md             Peer registry
 |    +-- runtime.md           Runtime metadata
 |    +-- mca/                 Managed Concern files
 |
 +-- logs/
 |    +-- input/               Archived input.md files (one per cycle)
 |    +-- output/              Archived output.md files (one per cycle)
 |
 +-- spec/                     Agent specifications (SOUL.md, USER.md)
 +-- skills/                   Agent skills (matched by keyword overlap)
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
| [MANIFESTO.md](design/MANIFESTO.md) | Principles and values |
| [WHITEPAPER.md](design/WHITEPAPER.md) | Protocol specification (normative) |
| [PROTOCOL.md](design/PROTOCOL.md) | FSM design, state diagrams, transition tables |
| [AGILE-PROCESS.md](design/AGILE-PROCESS.md) | Team process and workflow |
| [EXECUTABLE-SKILLS.md](design/EXECUTABLE-SKILLS.md) | Vision: skills as programs |
| [SECURITY-MODEL.md](design/SECURITY-MODEL.md) | Security architecture |
| [CLI.md](design/CLI.md) | CLI command reference |
| [AGENT-RUNTIME-v3.md](design/AGENT-RUNTIME-v3.md) | Native agent runtime design (v3.1.3) |
| [LOGGING.md](design/LOGGING.md) | Logging architecture |

For the full docs audit and archive decisions, see [AUDIT.md](design/AUDIT.md).
