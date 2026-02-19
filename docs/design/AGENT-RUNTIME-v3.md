# Agent Runtime: Native cnos Agent

**Version:** 3.1
**Authors:** Sigma (original), Pi (revision, CLP)
**Date:** 2026-02-19
**Status:** Draft
**Reviewers:** usurobor, external

---

## Executive Summary

This document proposes a native OCaml agent runtime for cnos, replacing OpenClaw (OC) as the orchestration layer. The design emphasizes separation of concerns: a minimal "dumb" daemon handles I/O, while all intelligence resides in the processing layer.

Key design decisions:
- **Daemon architecture:** Trivial polling loop (~50 lines) with systemd supervision
- **Memory model:** Propagation-first (daily → weekly → skills), not search-first
- **Scope:** Minimal viable runtime (~850 lines) that enables full self-reliance

---

## Problem Statement

### Current State

cnos agents depend on OpenClaw for:

| Function | OC Component |
|----------|--------------|
| Telegram I/O | Bot infrastructure, webhooks |
| LLM orchestration | Context management, tool loops |
| Session management | Conversation history |
| Periodic wake | Heartbeat/cron system |
| Tool execution | Shell, file I/O, browser |

### Issues with External Dependency

| Issue | Impact |
|-------|--------|
| No ownership | Cannot fix bugs, add features, or audit behavior |
| Coupling | cnos architecture constrained by OC's model |
| Fragility | OC outages = agent downtime |
| Redundancy | OC duplicates functionality cn already provides |
| Opacity | Cannot inspect or verify OC's behavior |

### Core Insight

OpenClaw's agent loop is:

```
Receive message → Build context → Call LLM → Execute tools → Respond
```

This is thin orchestration. cn already handles file I/O, state management, peer coordination, and cron automation. The missing pieces are tractable:

1. Telegram client (HTTP polling + send)
2. LLM client (Claude API + tool use)
3. Context builder (load memory artifacts)

Building these gives us full ownership in ~850 lines of OCaml.

---

## Constraints

1. **Pure OCaml** — No Python, JavaScript, or external runtimes
2. **Minimal dependencies** — Prefer stdlib; add only essential libraries
3. **Single binary** — Native executable, zero runtime dependencies
4. **Unix philosophy** — Composable commands, single responsibility
5. **Backward compatible** — Existing hub structure unchanged

---

## Architecture

### Separation of Concerns

```
┌─────────────────────────────────────────────────────────────┐
│                        systemd                              │
│                   (process supervision)                     │
└─────────────────────────┬───────────────────────────────────┘
                          │ manages
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   cn agent --daemon                         │
│                                                             │
│   ┌─────────────────────────────────────────────────────┐   │
│   │                  Poll Loop (~50 lines)              │   │
│   │                                                     │   │
│   │   loop:                                             │   │
│   │     messages ← Telegram.get_updates(offset)        │   │
│   │     for msg in messages:                            │   │
│   │       write state/input.json ← msg                  │   │
│   │       exec "cn agent --process"                     │   │
│   │       offset ← msg.update_id + 1                    │   │
│   │     sleep 1s                                        │   │
│   └─────────────────────────────────────────────────────┘   │
│                                                             │
│   Responsibilities: Receive, write, invoke, loop            │
│   Intelligence: None                                        │
└─────────────────────────┬───────────────────────────────────┘
                          │ invokes per message
                          ▼
┌─────────────────────────────────────────────────────────────┐
│                   cn agent --process                        │
│                                                             │
│   ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐   │
│   │ Context  │→ │   LLM    │→ │  Tools   │→ │ Respond  │   │
│   │ Builder  │  │  Client  │  │ Dispatch │  │  & Log   │   │
│   └──────────┘  └──────────┘  └──────────┘  └──────────┘   │
│                                                             │
│   Responsibilities: Think, decide, act                      │
│   Intelligence: All of it                                   │
└─────────────────────────────────────────────────────────────┘
```

### Why This Separation?

| Concern | Owner | Rationale |
|---------|-------|-----------|
| Process lifecycle | systemd | Battle-tested, handles crashes, logging, dependencies |
| Network I/O | Daemon | Isolated failure domain; trivial to restart |
| Intelligence | Processor | Stateless per invocation; easy to test, debug, iterate |

The daemon is intentionally "dumb" — it has no knowledge of LLMs, context, or tools. If the daemon has bugs, they're in ~50 lines of polling logic. All complexity lives in the processor, which runs as a separate invocation per message.

---

## Memory Model

### Design Philosophy: Propagation Over Search

cnos uses a **propagation model** for memory, not a search model:

```
Daily reflection
    ↓ weekly review catches patterns
Weekly reflection  
    ↓ monthly review catches themes
Monthly reflection
    ↓ patterns become principles
Skills / Mindsets / Personas
```

Each level distills insights from the level below. By the time something is important, it has migrated to a durable artifact (skill, mindset, persona).

**Implication:** Search is a fallback for propagation failure — when a pattern wasn't noticed or didn't migrate. If we frequently need search, that's a signal to fix propagation discipline, not search infrastructure.

### Context Loading Strategy

**Always loaded (no search required):**

| Artifact | Purpose | Tokens (est.) |
|----------|---------|---------------|
| `SOUL.md` | Agent identity, behavioral contract | ~500 |
| `USER.md` | Human preferences, working contract | ~300 |
| `threads/daily/today.md` | Current day's context | ~500 |
| `threads/daily/yesterday.md` | Recent continuity | ~500 |
| `threads/daily/day-before.md` | Short-term memory | ~500 |
| `threads/weekly/current.md` | Active patterns (β/γ axes) | ~500 |
| Matched skills (top 3) | Relevant procedural knowledge | ~1500 |
| Conversation history (last 10) | Session continuity | ~2000 |
| **Total** | | **~6300** |

This leaves 90K+ tokens for response generation and tool use loops.

**On-demand search (fallback):**

```bash
grep -r "query" threads/reflections/
```

Simple text search over reflection files. Invoked explicitly by agent when context loading is insufficient.

**Future (v2, only if needed):**

Semantic search with embeddings. Deferred unless grep proves inadequate in practice.

### Skill Matching

Skills are matched by keyword overlap between the incoming message and skill descriptions:

```ocaml
let match_skills message skills =
  let msg_words = tokenize (String.lowercase_ascii message) in
  skills
  |> List.map (fun s -> (s, keyword_overlap msg_words s.description))
  |> List.sort (fun (_, a) (_, b) -> compare b a)
  |> List.filteri (fun i _ -> i < 3)
```

This is intentionally simple. Semantic skill matching is a v2 consideration.

---

## Module Design

### Overview

| Module | Responsibility | Lines (est.) |
|--------|----------------|--------------|
| `cn_daemon.ml` | Telegram polling loop | ~50 |
| `cn_telegram.ml` | Telegram API client | ~150 |
| `cn_llm.ml` | Claude API client, response parsing | ~300 |
| `cn_context.ml` | Context builder | ~150 |
| `cn_tools.ml` | Tool dispatch (pure: `tool_call → tool_action`) | ~100 |
| `cn_runtime.ml` | Agentic loop (effectful: call LLM → dispatch → loop) | ~150 |
| **Total** | | **~900** |

### Types

```ocaml
(* ============================================================
   cn_telegram.ml — Telegram API Types
   ============================================================ *)

type config = {
  token : string;
  allowed_users : int list;
}

type user = {
  id : int;
  username : string option;
  first_name : string;
}

type message = {
  message_id : int;
  chat_id : int;
  from : user;
  text : string;
  date : int;
}

type update = {
  update_id : int;
  message : message option;
}

(* ============================================================
   cn_llm.ml — LLM Types
   ============================================================ *)

(* Model ID validated at config parse — not an enum because
   Anthropic ships new model IDs quarterly *)
type model_id = string  (* e.g. "claude-sonnet-4-20250514" *)

type role = User | Assistant

type llm_message = {
  role : role;
  content : string;
}

type tool_param = {
  name : string;
  typ : string;
  description : string;
  required : bool;
}

type tool_def = {
  name : string;
  description : string;
  parameters : tool_param list;
}

type tool_call = {
  id : string;
  name : string;
  arguments : (string * Yojson.Safe.t) list;
}

type content_block =
  | Text of string
  | ToolUse of tool_call

type stop_reason =
  | End_turn
  | Tool_use
  | Max_tokens
  | Stop_sequence

type usage = {
  input_tokens : int;
  output_tokens : int;
}

type response = {
  id : string;
  content : content_block list;
  stop_reason : stop_reason;
  usage : usage;
}

(* ============================================================
   cn_context.ml — Context Types
   ============================================================ *)

type api_request = {
  system_prompt : string;
  messages : llm_message list;   (* LLM conversation, not Telegram *)
  tools : tool_def list;
}

type loaded_context = {
  soul : string;
  user : string;
  daily_threads : string list;    (* last 3 days *)
  weekly_thread : string option;
  skills : string list;           (* matched, max 3 *)
  conversation : llm_message list;  (* last 10, role + content *)
}

(* ============================================================
   cn_runtime.ml — Runtime Types
   ============================================================ *)

type tool_result = 
  | Success of string
  | Error of string

type agent_config = {
  telegram : config;
  model : model_id;
  api_key : string;
  hub_path : string;
}
```

### Interface

```
cn agent [MODE] [OPTIONS]

MODES:
  --daemon          Run as Telegram polling daemon (long-running)
  --process         Process single message from state/input.json
  --stdio           Interactive mode for testing (read stdin, write stdout)

OPTIONS:
  --config <path>   Config file path (default: state/agent.yaml)
  --hub <path>      Hub directory (default: current directory)
  --dry-run         Process without sending response (for testing)
  --verbose         Enable debug logging

ENVIRONMENT:
  TELEGRAM_TOKEN    Bot token (required for --daemon)
  ANTHROPIC_KEY     Claude API key (required for --process)

EXAMPLES:
  # Start daemon (systemd calls this)
  cn agent --daemon

  # Process a message (daemon calls this)
  cn agent --process

  # Interactive testing
  echo "Hello" | cn agent --stdio

  # Dry run for debugging
  cn agent --process --dry-run --verbose
```

### Workflow: Message Processing

```
┌─────────────────────────────────────────────────────────────┐
│                     cn agent --process                      │
└─────────────────────────────────────────────────────────────┘
                              │
          1. Read state/input.json
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Load Context                           │
│                                                             │
│  • Read SOUL.md, USER.md                                    │
│  • Read last 3 daily threads                                │
│  • Read current weekly thread                               │
│  • Match skills by keyword                                  │
│  • Load conversation history from state/conversation.json   │
└─────────────────────────────────────────────────────────────┘
                              │
          2. Build system prompt + messages
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Call Claude API                        │
│                                                             │
│  POST https://api.anthropic.com/v1/messages                 │
│  {                                                          │
│    "model": <model_id from config>,                     │
│    "system": <system_prompt>,                               │
│    "messages": <conversation>,                              │
│    "tools": <tool_definitions>,                             │
│    "max_tokens": 8192                                       │
│  }                                                          │
└─────────────────────────────────────────────────────────────┘
                              │
          3. Parse response
                              │
                              ▼
                    ┌─────────┴─────────┐
                    │                   │
              Tool use?              Text only
                    │                   │
                    ▼                   ▼
┌───────────────────────────┐  ┌───────────────────────────┐
│     Execute Tool          │  │     Send Response         │
│                           │  │                           │
│  • Dispatch by tool name  │  │  • Telegram.send_message  │
│  • Capture output         │  │  • Log to daily thread    │
│  • Loop back to Claude    │  │  • Update conversation    │
└───────────────────────────┘  └───────────────────────────┘
```

### Tool Definitions

| Tool | Description | Maps to |
|------|-------------|---------|
| `read_file` | Read contents of a file | `Cn_ffi.Fs.read` |
| `write_file` | Write content to a file | `Cn_ffi.Fs.write` |
| `list_files` | List directory contents | `Cn_ffi.Fs.readdir` |
| `search_memory` | Search reflections (grep) | `grep -r` over threads/ |
| `run_cn` | Execute a cn subcommand | `Cn_ffi.Child_process.exec` |
| `send_peer` | Send message to CN peer | `cn send` |
| `create_thread` | Create adhoc thread | `cn adhoc` |

**No raw `exec` tool.** The LLM cannot execute arbitrary shell commands. Tool dispatch is a closed variant:

```ocaml
type tool_action =
  | Read_file of string             (* path *)
  | Write_file of string * string   (* path, content *)
  | List_files of string            (* dir *)
  | Search_memory of string         (* query *)
  | Run_cn of string list           (* cn subcommand argv *)
  | Send_peer of string * string    (* peer, content *)
  | Create_thread of string * string  (* title, body *)

let dispatch_tool hub_path = function
  | Read_file path -> Ok (Cn_ffi.Fs.read (Cn_ffi.Path.join hub_path path))
  | Run_cn argv -> Ok (Cn_ffi.Child_process.exec (String.concat " " (List.map Filename.quote argv)))
  | ...
```

This makes invalid tool calls (arbitrary shell, network, rm) unrepresentable at the type level. `SOUL.md` remains the behavioral contract, but the type boundary enforces it.

---

### FSM Integration

The runtime reuses the existing `cn_protocol.ml` actor FSM — no new state machine. The daemon-to-processor handoff maps directly onto actor transitions:

```
cn agent --daemon                    cn agent --process
─────────────────                    ──────────────────

poll → message arrives
  write state/input.json
  ─── Queue_pop ──→ InputReady
  exec --process ─── Wake ──→ Processing
                                       load context
                                       call LLM
                                       dispatch tools (loop)
                                       write response
                                     ─── Output_received ──→ OutputReady
                                       archive input + output
                                     ─── Archive_complete ──→ Idle
```

The processor is a single `Idle → InputReady → Processing → OutputReady → Idle` pass. Errors surface via `Result.t` from `actor_transition` — the same pattern already enforced in `cn_agent.ml`. No new FSM types are needed; the runtime is a new caller of the existing protocol.

```ocaml
(* cn_runtime.ml — agentic loop entry point *)
let process hub_path =
  let ( let* ) = Result.bind in
  let* _s = Cn_protocol.actor_transition Cn_protocol.Idle Cn_protocol.Queue_pop in
  let* s = Cn_protocol.actor_transition Cn_protocol.InputReady Cn_protocol.Wake in
  (* s = Processing *)
  let result = run_agent_loop hub_path in
  let* s = Cn_protocol.actor_transition s Cn_protocol.Output_received in
  (* s = OutputReady *)
  archive_conversation hub_path;
  let* _s = Cn_protocol.actor_transition s Cn_protocol.Archive_complete in
  Ok ()
```

---

## Configuration

```yaml
# state/agent.yaml

telegram:
  token: ${TELEGRAM_TOKEN}
  allowed_users:
    - 498316684  # usurobor

llm:
  provider: anthropic
  model: claude-sonnet-4-latest    # validated at startup, not compiled in
  api_key: ${ANTHROPIC_KEY}
  max_tokens: 8192

context:
  daily_threads: 3          # Load last N daily threads
  weekly_thread: true       # Load current weekly
  max_skills: 3             # Max skills to inject
  conversation_limit: 10    # Max messages in history

daemon:
  poll_interval: 1          # Seconds between polls
  poll_timeout: 30          # Long-polling timeout

logging:
  level: info
  file: /var/log/cn-agent.log
  format: json
```

### systemd Unit

```ini
# /etc/systemd/system/cn-agent.service

[Unit]
Description=cnos Agent Daemon
After=network.target

[Service]
Type=simple
User=cn
WorkingDirectory=/home/cn/hub
ExecStart=/usr/local/bin/cn agent --daemon
Restart=always
RestartSec=5
Environment=TELEGRAM_TOKEN=<token>
Environment=ANTHROPIC_KEY=<key>

[Install]
WantedBy=multi-user.target
```

---

## Migration Path

### Phase 1: Build & Test (Week 1)

| Task | Deliverable |
|------|-------------|
| Implement cn_telegram.ml | Polling + send working |
| Implement cn_llm.ml | Claude API + tool parsing |
| Implement cn_context.ml | Context loading from hub |
| Implement cn_runtime.ml | Tool dispatch loop |
| Integration test | --stdio mode works end-to-end |

### Phase 2: Parallel Operation (Week 2)

| Task | Deliverable |
|------|-------------|
| Deploy cn agent daemon | Running alongside OC |
| Route test messages | Verify response parity |
| Monitor for issues | Latency, failures, context quality |
| Fix bugs | Iterate based on real usage |

### Phase 3: Cutover (Week 3)

| Task | Deliverable |
|------|-------------|
| Switch Telegram webhook | cn agent receives all messages |
| Disable OC heartbeat | cn daemon is sole orchestrator |
| Update documentation | Reflect new architecture |
| Remove OC config | Clean break |

### Rollback Plan

1. **Keep OC config commented** — Not deleted, can be restored
2. **Environment switch** — `CN_AGENT_MODE=oc` falls back to OC relay
3. **1-command rollback** — `systemctl stop cn-agent && systemctl start openclaw`

Rollback tested before cutover.

---

## Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| Message latency | < 5s p95 | Time from Telegram receipt to response sent |
| Uptime | 99%+ | systemd + monitoring |
| Context quality | Correct artifacts loaded | Manual audit of 10 conversations |
| Tool coverage | All v1 tools functional | Integration test suite |
| Binary size | < 5MB | `ls -la cn` |
| Memory usage | < 50MB RSS | `ps aux` under load |

---

## Scope: v1 vs v2

| Feature | v1 (MCA) | v2 (Future) |
|---------|----------|-------------|
| Telegram transport | Long-polling | Webhook option |
| LLM responses | Non-streaming | Streaming |
| Context loading | Recent dailies + keyword skills | Full semantic search |
| Memory search | grep | Embedding-based |
| Media handling | Text only | Images, voice, files |
| Reactions | Not supported | Tapback support |
| Multi-model | Claude only | Model selection |

v1 targets functional parity with minimal scope. v2 features are explicitly deferred.

---

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **Keep OpenClaw** | Zero effort, already working | No ownership, coupling, opacity, fragility | Rejected — core dependency without auditability |
| **Fork OpenClaw** | Existing codebase, faster start | Python runtime, large surface area, still not native | Rejected — violates constraint 1 (pure OCaml) |
| **Wrap OC via HTTP relay** | Minimal code, OC does the work | Still dependent, extra latency, two failure domains | Rejected — adds complexity without removing dependency |
| **Native OCaml runtime** | Full ownership, single binary, reuses cn infrastructure | Must build Telegram + LLM clients | **Accepted** — tractable (~850 lines), aligns with all constraints |
| **Shell script orchestrator** | Very fast to build | Fragile, no types, hard to test, grows into a mess | Rejected — violates constraint 3 (single binary) |

---

## Open Questions

### 1. Conversation Persistence

**Question:** Where does conversation history live between messages?

**Options:**
- `state/conversation.json` — Simple, daemon manages
- `threads/conversations/<chat_id>.md` — Integrated with hub
- In-memory in daemon — Lost on restart

**Recommendation:** `state/conversation.json`, rotated daily. Daemon writes, processor reads.

### 2. Error Handling

**Question:** What happens when Claude API fails?

**Options:**
- Retry with backoff
- Return error message to user
- Queue for later processing

**Recommendation:** Retry 3x with exponential backoff, then send error message. No silent failures.

### 3. Rate Limiting

**Question:** How to handle Telegram/Claude rate limits?

**Recommendation:** Respect `Retry-After` headers. Log warnings. For sustained rate limiting, queue messages in `state/pending/`.

### 4. Multi-Hub Support

**Question:** Should one daemon support multiple hubs/agents?

**Recommendation:** Out of scope for v1. One daemon per hub. Revisit if deployment patterns require it.

---

## Appendix A: Dependency Audit

### Required OCaml Libraries

| Library | Purpose | Notes |
|---------|---------|-------|
| `cohttp-lwt-unix` | HTTP client | Telegram + Claude API calls |
| `yojson` | JSON parsing | API payloads |
| `lwt` | Async I/O | Non-blocking network |
| `tls` + `ca-certs` | HTTPS | Secure connections |

### Build Impact

| Metric | Current | With Agent |
|--------|---------|------------|
| Binary size | 2.1 MB | ~4 MB |
| Dependencies | 12 | 16 |
| Compile time | 8s | ~12s |

Still single native binary with zero runtime dependencies.

---

## Appendix B: Security Considerations

### Telegram Authentication

- `allowed_users` whitelist in config
- Messages from unknown users are logged and dropped
- No automatic responses to unknown senders

### Tool Execution

- Tools execute with agent's Unix permissions
- `SOUL.md` defines self-imposed restrictions
- Dangerous commands (rm, network, etc.) require explicit approval flow
- All tool executions logged to daily thread

### API Keys

- Stored in environment variables, not config files
- Config supports `${VAR}` expansion
- Never logged or included in error messages

### Audit Trail

- All messages logged to `threads/daily/`
- Tool executions include command + output
- Errors logged with full context (excluding secrets)

---

## References

- [Telegram Bot API — getUpdates](https://core.telegram.org/bots/api#getupdates)
- [Anthropic Claude API — Messages](https://docs.anthropic.com/claude/reference/messages)
- [cnos Protocol Specification](./PROTOCOL.md)
- [cnos CLI Reference](./CLI.md)
- [systemd Service Units](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

*Document version 3.1. For comments and iteration, contact reviewers or open a thread in the hub.*
