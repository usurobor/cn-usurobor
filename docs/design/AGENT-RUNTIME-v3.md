# Agent Runtime: Native cnos Agent

**Version:** 3.0.9
**Authors:** Sigma (original), Pi (CLP), Axiom (pure-pipe directive)
**Date:** 2026-02-19
**Status:** Draft
**Reviewers:** usurobor, external

---

## Patch Notes

**v3.0.9** — Fix context-window citation + future-proof wording:
- Cite Claude context windows from the canonical Context Windows doc (not Messages API)
- Note 1M-token context window availability for supported models/orgs (beta)
- Rename "Tool Loop (OpenAI's Push)" to neutral "Multi-Turn Tool-Calling"

**v3.0.8** — Add industry comparison and decision rationale:
- Add "Industry Approaches Compared" section after "Why No Tools?"
- Compare tool loop, RAG, and context stuffing patterns
- Document token economics and latency trade-offs
- Cite Anthropic's context window and caching direction
- Explain why context stuffing fits cnos's bounded, predictable context needs

**v3.0.7** — Doc-level consistency cleanup:
- Fix patch note / pseudocode mismatch: Telegram fallback is "(acknowledged)" everywhere
- Fix module table ordering: "pack → call → write → archive → resolve/execute → projection"
- Simplify Telegram fallback: prefer reply notification, else "(acknowledged)" (no internal op stringification)

**v3.0.6** — Align archival order with LOGGING.md (audit invariant):
- Fix step ordering: archive raw IO pair BEFORE executing ops (crash-safe audit trail)
- Archived output.md is always the original LLM response (pre-resolution)
- Improve Telegram fallback: prefer reply notification, then first op notification, then "(acknowledged)"
- Update pseudocode, diagrams, and "What cn Does" table to reflect archive-first ordering

**v3.0.5** — Lock body semantics contract:
- Define Body Consumption Rules: markdown body is the primary response text; frontmatter message is the brief notification
- Specify payload resolution order for `reply:` and `send:` ops (body wins over frontmatter notification)
- Add `extract_body` helper to runtime pseudocode
- Align with agent-ops SKILL.md: "if body is omitted but output.md has content below frontmatter, that content SHOULD be used as body"
- Update Telegram projection to send full body, not frontmatter notification

**v3.0.4** — Fix output contract + daemon/processor split:
- Fix blocking mismatch: output schema now matches actual `cn_lib.ml:parse_agent_op` format (key-per-op, pipe-delimited args) per `agent-ops/SKILL.md`
- Clarify daemon vs processor responsibilities (daemon enqueues; processor packs, calls LLM, writes, executes)
- Define Telegram as a projection layer: routing is a processor concern, not a new op format
- Clarify wording: "agent interface" = conceptual (input.md → output.md); LLM sees only text contents
- Normalize versioning to 3.0.x (3.0 not shipped; no minor bumps)

**v3.0.3** — Pure-pipe architecture: remove all tools, agent = `string → string`.

**v3.0.2** — Cross-doc alignment: hub paths, IO-pair archival, Claude API schema.

**v3.0.1** — CLP pass: type tightening, FSM bridge, alternatives section.

---

## Executive Summary

This document proposes a native OCaml agent runtime for cnos that replaces OpenClaw (OC) as the orchestration layer. The runtime preserves the CN security invariant:

> **Agent interface (conceptual):** `state/input.md → state/output.md`
> **LLM reality:** sees only the text contents of input.md, produces the text contents of output.md. cn performs all file I/O, network, and effect execution.

The runtime (`cn`) is responsible for:
1. Receiving Telegram messages, enqueuing, and packing `state/input.md` with all needed context
2. Invoking the LLM (single Claude API call) to transform input text → output text
3. Writing `state/output.md`, parsing frontmatter ops, and extracting the markdown body
4. Archiving the raw IO pair (`logs/input/` + `logs/output/`) — before any effects (per LOGGING.md)
5. Resolving op payloads (body wins over frontmatter notification), executing via `cn_agent.ml:execute_op`, routing Telegram replies, and advancing the actor FSM

Key design decisions:
- **Agent purity:** The LLM never touches files, commands, or network — cn does everything
- **Context packing:** cn loads all artifacts into `state/input.md` before LLM invocation
- **Op-based output:** LLM produces markdown with frontmatter ops (reply/send/defer/done/...) that cn already knows how to execute
- **Daemon stays dumb:** Trivial polling loop (~50 lines) with systemd supervision

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

But CN already has a simpler, safer model:

```
cn packs context → LLM plans → cn executes ops
```

The LLM doesn't need tools. cn can pre-load all relevant context into a single input document, and the LLM returns a plan with ops in the output. cn already parses and executes these ops (`cn_agent.ml:execute_op`).

The missing pieces are:
1. Telegram client (HTTP polling + send)
2. LLM client (Claude API, single request→response)
3. Context packer (load hub artifacts into `state/input.md`)

---

## Constraints

1. **Pure OCaml** — No Python, JavaScript, or external runtimes
2. **Minimal dependencies** — Prefer stdlib; add only essential libraries
3. **Single binary** — Native executable, zero runtime dependencies
4. **Agent purity** — LLM = pure function, cn = all effects (per SECURITY-MODEL.md)
5. **Backward compatible** — Existing hub structure unchanged, existing ops unchanged
6. **CN-native** — Reuses IO-pair archival, actor FSM, op execution — not a parallel system

---

## Architecture

### The Pure Pipe

```
Telegram          cn (body)                          LLM (brain)
─────────    ─────────────────────                ───────────────

message ──→  1. Pack state/input.md
             ┌──────────────────────┐
             │ --- (frontmatter)    │
             │ id: trigger-id       │
             │ from: telegram       │
             │ ---                  │
             │                      │
             │ ## Context           │
             │ <SOUL.md>            │
             │ <USER.md>            │
             │ <recent reflections> │
             │ <matched skills>     │
             │ <conversation>       │
             │                      │
             │ ## Message           │
             │ <user's message>     │
             └──────────────────────┘
                        │
             2. Call Claude API  ──→  LLM reads input text
                                      LLM produces output text
                                  ←──  (single request→response)
                        │
             3. Write state/output.md
             ┌──────────────────────┐
             │ --- (frontmatter)    │
             │ id: trigger-id       │
             │ reply: trigger-id|…  │
             │ ---                  │
             │                      │
             │ Here's what I think  │
             │ about your question… │
             └──────────────────────┘
                        │
             4. Parse ops, archive, execute
                • extract ops via parse_agent_op
                • archive raw IO pair (before effects)
                • resolve payloads + execute ops
                • route reply to Telegram (projection)
                • advance FSM
```

### What the LLM Sees

The LLM receives a single system prompt + user message. It does NOT see files, tools, or shell access. It sees **text** — the content of `state/input.md` assembled by cn — and produces **text** — the content of `state/output.md` with ops in frontmatter.

### What cn Does

| Step | Owner | Description |
|------|-------|-------------|
| Receive message | Daemon | Telegram long-poll, enqueue to `state/queue/` |
| Dequeue + pack context | Processor | Read queue item + hub artifacts, build `state/input.md` |
| Invoke LLM | Processor | Single Claude API call (text in → text out) |
| Write output | Processor | Write LLM response as `state/output.md` |
| Extract body | Processor | Extract markdown body below frontmatter (full payload) |
| Archive | Processor | IO-pair to `logs/input/` + `logs/output/` — before effects (per LOGGING.md) |
| Execute ops | Processor | Resolve payloads via Body Consumption Rules, execute via `cn_agent.ml:execute_op` |
| Route Telegram reply | Processor | If inbound was from Telegram, send full payload to chat (projection) |
| Advance FSM | Processor | `OutputReady → Idle` via actor transition |

### Why No Tools?

In the current doc (v3.2), the LLM had read-only tools like `read_artifact` and `search_reflections`. But:

1. **cn can pre-load everything the LLM needs.** If cn packs SOUL, USER, reflections, skills, and conversation into the input, the LLM doesn't need to go read them itself.

2. **Tools break the security boundary.** SECURITY-MODEL.md says the agent interacts with exactly two files. A tool loop means the LLM is iteratively reading the filesystem, which is the opposite of "agent sees two files."

3. **The op vocabulary already exists.** `cn_agent.ml` already parses and executes: `ack`, `done`, `fail`, `reply`, `send`, `delegate`, `defer`, `delete`, `surface`. The LLM just needs to emit these in output.md frontmatter.

4. **Simpler = more auditable.** One request, one response, one IO pair. No multi-turn tool loops to trace.

If the LLM needs information not in the packed context, that's a signal to improve context packing — not to add tools.

### Industry Approaches Compared

The industry has three main patterns for giving LLMs access to context:

**Assumptions (illustrative):**

- Packed context ≈ 6.5K tokens (see [Context Packing estimate](#context-packing) below)
- Output body ≈ 0.5–1.0K tokens typical
- Tool-loop token growth depends on number/size of tool results and whether the platform supports caching for stable prefixes
- Latency ranges are estimates based on typical API response times, not benchmarks

#### 1. Tool Loop (Multi-Turn Tool-Calling)

```
System prompt + user message
    → LLM returns tool_call
    → Execute, return result
    → LLM returns tool_call or final answer
    → Repeat until done
```

**Token flow per interaction:**

| Turn | Input | Output | Cumulative |
|------|-------|--------|------------|
| 1. Initial | ~2K | ~200 (tool call) | 2.2K |
| 2. + tool result | ~3K | ~200 (another tool) | 5.4K |
| 3. + tool result | ~4K | ~500 (answer) | 9.9K |

Each turn re-sends previous context plus new tool results. Tokens compound.

**When it wins:** Unbounded exploration (web search, code execution, dynamic API calls).

**Problems:** LLM doesn't know what it doesn't know. Multiple API round-trips add latency. Complex retry/error handling. Hard to audit.

#### 2. RAG (Retrieval-Augmented Generation)

```
User message
    → Embed query
    → Vector search → top K chunks
    → Pack chunks + query
    → Single LLM call
```

**When it wins:** Huge corpus (10K+ documents), queries vary widely.

**Problems:** Requires embeddings infrastructure, chunking strategy, retrieval tuning. Retrieval quality bottlenecks answer quality.

#### 3. Context Stuffing (This Design)

```
Pre-load everything relevant
    → Single LLM call
    → Done
```

**Token flow:**

| Turn | Input | Output | Total |
|------|-------|--------|-------|
| 1. Only turn | ~6.5K | ~500 | 7K |

**When it wins:** Bounded context (<50K tokens), consistent task domain, predictable context needs.

#### Why Context Stuffing for cnos

| Factor | cnos Reality |
|--------|--------------|
| Corpus size | ~20-30 hub files, <50K tokens total |
| Task domain | Agent ops, reflections, peer comms (consistent) |
| Context needs | Predictable (SOUL, USER, skills, recent threads) |
| Query patterns | Most queries benefit from full context |

**Cost comparison:**

| Scenario | Tool Loop | Context Stuffing |
|----------|-----------|------------------|
| Simple "hi" | ~2K (cheaper) | ~6.5K |
| Needs 1 file | ~5K | ~6.5K (similar) |
| Needs 2+ files | ~10K+ | ~6.5K (cheaper) |
| Needs skills + memory | ~15K+ | ~6.5K (cheaper) |
| **API calls** | 2-5 | **1** |
| **Latency** | 2-10s (serial) | **1-3s** |

**Platform capabilities that enable this design:**

- **Model capability trend:** Larger context windows make single-shot context packing feasible for bounded domains. Claude supports a 200K-token context window (and 1M-token beta for eligible orgs) ([Context Windows](https://docs.anthropic.com/en/docs/build-with-claude/context-windows)), far exceeding cnos's ~6.5K packed context.
- **Cost/latency lever:** Prompt caching allows reuse of an identical prompt prefix to reduce processing time and cost. Anthropic documents cache-read pricing at a significant discount, with a default TTL of 5 minutes ([Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)).
- **cnos implication:** Because cnos context is bounded and predictable, we prefer eager context packing + single LLM call over multi-turn retrieval loops. For larger or unbounded corpora, just-in-time retrieval remains the better fit.

**Decision:** Tool loops emerged when GPT-3.5 had 4K context — lazy loading was mandatory. With 200K context and prompt caching, stuffing is simpler, faster, and often cheaper. For cnos's bounded, predictable context needs, context stuffing is the right choice.

#### Prompt Caching Plan

cnos context packing produces a predictable prefix that is mostly stable across invocations:

| Segment | Stability | Cache? |
|---------|-----------|--------|
| SOUL, USER, skills, op format spec | Stable across calls | **Yes** — cache as prefix |
| Hub state (hub.md, peers, reflections) | Changes on writes only | **Yes** — cache; invalidated on hub mutation |
| Inbound message + recent conversation | Changes every call | **No** — dynamic tail |

**Implementation notes:**
- Use Anthropic's `cache_control` breakpoint after the stable prefix to mark the cache boundary
- Default TTL is 5 minutes; cnos's cron cadence (1–5 min) fits within this window
- Cache-read pricing is discounted vs. fresh input processing — for a ~5K stable prefix, this yields meaningful savings on repeated invocations
- Monitor cache hit rate via `cache_creation_input_tokens` / `cache_read_input_tokens` in API responses

---

## Op Vocabulary

The LLM expresses its decisions via ops in `state/output.md` frontmatter. The format is **key-per-op with pipe-delimited arguments** — matching `cn_lib.ml:parse_agent_op` and the existing `agent-ops/SKILL.md` spec. The `id` field is required and must match the input's trigger id.

| Op | Frontmatter | Meaning |
|----|-------------|---------|
| `ack` | `ack: <id>` | Acknowledge receipt, no action |
| `done` | `done: <id>` | Mark thread complete → Archived |
| `fail` | `fail: <id>\|<reason>` | Report failure |
| `reply` | `reply: <id>\|<message>` | Reply to thread (body = extended content) |
| `send` | `send: <peer>\|<message>` or `send: <peer>\|<message>\|<body>` | Send to peer → `threads/mail/outbox/` |
| `delegate` | `delegate: <id>\|<peer>` | Forward thread to peer |
| `defer` | `defer: <id>` or `defer: <id>\|<until>` | Postpone |
| `delete` | `delete: <id>` | Discard thread |
| `surface` | `surface: <description>` (alias: `mca:`) | Create Managed Concern |

Multiple ops are allowed in a single output. They execute in order listed.

Example output.md:

```markdown
---
id: 20260219-141209-abc123
reply: 20260219-141209-abc123|Got it, reviewing now
surface: Add retry logic to wake mechanism
---

Got it. Here's what I'll do next:

1. Review the design doc changes
2. Check alignment with the protocol spec
3. Flag any gaps

I'll have this done by end of day.
```

No new ops are needed. The LLM writes the same format that `cn out` and `cn_agent.ml` already understand.

### Body Consumption Rules

Output.md has two payload regions:

1. **Frontmatter values** — Brief notification text (pipe-delimited in op args)
2. **Markdown body** — Full response/action-plan prose (everything below the closing `---`)

The processor resolves the "full payload" for each op according to these rules:

| Op | Notification (frontmatter) | Full payload | Resolution |
|----|---------------------------|--------------|------------|
| `reply: id\|msg` | `msg` | markdown body if present, else `msg` | Body wins |
| `send: peer\|msg` | `msg` | explicit 3rd pipe segment if present, else markdown body, else `msg` | Explicit > body > notification |
| All others | frontmatter value | N/A | No body consumption |

**Why two regions?** The frontmatter notification is a one-line summary suitable for logs, queue displays, and push notifications. The markdown body is the full response — potentially multi-paragraph, with headings, lists, and code blocks. The LLM naturally writes both: a brief label in the op, and a detailed response below.

**Example:**

```markdown
---
id: trigger-123
reply: trigger-123|Here's my analysis
---

I looked at the three design docs you mentioned. Here are my findings:

1. The protocol spec is internally consistent
2. The security model needs one update (see below)
3. The logging doc matches the implementation

## Security Model Gap

The SECURITY-MODEL.md still references the old tool boundary...
```

Resolution:
- **Thread reply** gets the full body appended (everything below `---`)
- **Telegram** receives the full body
- **Log line** records the notification: "Here's my analysis"

This aligns with agent-ops SKILL.md: "If body is omitted but output.md has content below frontmatter, that content SHOULD be used as body."

**Body extraction** (pure function, belongs in `cn_lib.ml`):

```ocaml
let extract_body content =
  match String.split_on_char '\n' content with
  | "---" :: rest ->
      let rec skip = function "---" :: r -> r | _ :: r -> skip r | [] -> [] in
      let body = String.concat "\n" (skip rest) |> String.trim in
      if body = "" then None else Some body
  | _ -> None
```

**Implementation note:** `archive_io_pair` currently passes only frontmatter-parsed ops to `execute_op`. To support body fallback, the processor extracts the body once and passes it alongside each op. For `Reply`, if body is present, the full body replaces the frontmatter `msg`. For `Send`, the existing 3rd-pipe-segment takes precedence; body is the second fallback; frontmatter `msg` is the last resort.

### Telegram Routing (Projection Layer)

Telegram is not an op — it's a projection. The processor knows the inbound message came from Telegram (because `state/input.md` frontmatter says `from: telegram:<chat_id>`), so when it executes a `reply:` op, it routes the **full payload** (per Body Consumption Rules above) to Telegram. This is a processor-level routing concern, not part of the op vocabulary.

```
LLM produces: reply: trigger-id|Brief summary
              body: Full multi-paragraph response...
                ↓
Processor sees: inbound was from telegram:498316684
                ↓
Processor does: 1. execute_op Reply — appends full payload to thread
                2. Telegram.send_message chat_id full_payload
                   (full_payload = body if present, else frontmatter msg)
```

If the inbound came from a peer (not Telegram), the processor skips the Telegram send. Same op, different projection.

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

**Implication:** If the LLM frequently lacks needed context, that's a signal to improve context packing or propagation discipline — not to add retrieval tools.

### Context Packing

cn packs the following into `state/input.md` before LLM invocation:

| Artifact | Hub path | Tokens (est.) |
|----------|----------|---------------|
| Agent identity | `spec/SOUL.md` | ~500 |
| User context | `spec/USER.md` | ~300 |
| Recent daily reflections (last 3) | `threads/reflections/daily/YYYYMMDD.md` | ~1500 |
| Current weekly reflection | `threads/reflections/weekly/YYYY-WNN.md` | ~500 |
| Matched skills (top 3) | `src/agent/skills/**/SKILL.md` | ~1500 |
| Conversation history (last 10) | `state/conversation.json` | ~2000 |
| Inbound message | The Telegram message text | ~200 |
| **Total** | | **~6500** |

Token budget varies by model and context mode. The runtime should treat headroom as telemetry, not a hardcoded assumption.

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
| `cn_llm.ml` | Claude API client (single call, no tool loop) | ~200 |
| `cn_context.ml` | Context packer (builds input.md from hub artifacts) | ~200 |
| `cn_runtime.ml` | Orchestrator: pack → call → write → archive → resolve/execute → projection | ~150 |
| **Total** | | **~750** |

Note: No `cn_tools.ml`. The LLM has no tools.

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

type telegram_message = {
  message_id : int;
  chat_id : int;
  from : user;
  text : string;
  date : int;
}

type update = {
  update_id : int;
  message : telegram_message option;
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

(* No tool types. The LLM has no tools.
   It receives text and produces text. *)

type stop_reason =
  | End_turn
  | Max_tokens
  | Stop_sequence

type usage = {
  input_tokens : int;
  output_tokens : int;
}

type response = {
  id : string;
  content : string;         (* text only — no tool_use blocks *)
  stop_reason : stop_reason;
  usage : usage;
}

(* ============================================================
   cn_context.ml — Context Packing Types
   ============================================================ *)

type packed_context = {
  soul : string;                    (* spec/SOUL.md *)
  user : string;                    (* spec/USER.md *)
  daily_threads : string list;      (* threads/reflections/daily/, last 3 *)
  weekly_thread : string option;    (* threads/reflections/weekly/, current *)
  skills : string list;             (* src/agent/skills/**/SKILL.md, matched *)
  conversation : llm_message list;  (* state/conversation.json, last 10 *)
  inbound_message : string;         (* the Telegram message text *)
}

(* ============================================================
   cn_runtime.ml — Runtime Types
   ============================================================ *)

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
  --process         Process single message from state/input.md
  --stdio           Interactive mode for testing (read stdin, write stdout)

OPTIONS:
  --config <path>   Config file path (default: .cn/agent.yaml)
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
          1. Dequeue + pack context → state/input.md
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                    Build LLM Request                        │
│                                                             │
│  • System prompt from spec/SOUL.md                          │
│  • Conversation history as messages array                   │
│  • User message = packed context + inbound text             │
│  • No tools defined                                         │
└─────────────────────────────────────────────────────────────┘
                              │
          2. Single Claude API call
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      Call Claude API                        │
│                                                             │
│  POST https://api.anthropic.com/v1/messages                 │
│  {                                                          │
│    "model": <model_id from config>,                         │
│    "system": <soul + behavioral contract>,                  │
│    "messages": <conversation + packed context>,              │
│    "max_tokens": 8192                                       │
│  }                                                          │
│                                                             │
│  No "tools" field. Single request, single response.         │
└─────────────────────────────────────────────────────────────┘
                              │
          3. Write state/output.md
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                 Parse + Archive + Execute                    │
│                                                             │
│  • Extract markdown body (full payload)                     │
│  • Parse frontmatter ops from LLM response                  │
│  • Archive raw IO pair: logs/input/ + logs/output/          │
│    (BEFORE effects — per LOGGING.md audit invariant)        │
│  • Resolve payloads: body wins over frontmatter msg         │
│  • Execute resolved ops via cn_agent.ml:execute_op          │
│  • Send Telegram reply (full payload, not notification)     │
│  • Update state/conversation.json                           │
│  • Advance FSM: OutputReady → Idle                          │
└─────────────────────────────────────────────────────────────┘
```

### FSM Integration

The runtime reuses the existing `cn_protocol.ml` actor FSM — no new state machine:

```
cn agent --daemon                    cn agent --process
─────────────────                    ──────────────────

poll → message arrives
  enqueue to state/queue/
  exec --process
    ─── Queue_pop ──→ InputReady
    dequeue + pack context → state/input.md
    ─── Wake ──→ Processing
                                       build LLM request from input.md text
                                       single Claude API call
                                       write state/output.md
                                     ─── Output_received ──→ OutputReady
                                       extract body, parse ops
                                       archive raw IO pair (before effects):
                                         state/input.md  → logs/input/{trigger}.md
                                         state/output.md → logs/output/{trigger}.md
                                       resolve payloads (body wins)
                                       execute resolved ops
                                       send Telegram (full payload)
                                       clean up state files
                                     ─── Archive_complete ──→ Idle
```

```ocaml
(* cn_runtime.ml — process entry point *)
let process hub_path config =
  let ( let* ) = Result.bind in
  (* Dequeue → pack context → write state/input.md *)
  let* _s = Cn_protocol.actor_transition Cn_protocol.Idle Cn_protocol.Queue_pop in
  let queue_item = dequeue hub_path in
  let packed = Cn_context.pack hub_path queue_item in
  Cn_ffi.Fs.write (input_path hub_path) packed;
  (* InputReady → Processing: call LLM *)
  let* s = Cn_protocol.actor_transition Cn_protocol.InputReady Cn_protocol.Wake in
  let input_text = Cn_ffi.Fs.read (input_path hub_path) in
  let response = Cn_llm.call config.api_key config.model input_text in
  (* Write output.md — LLM response in key-per-op frontmatter format *)
  Cn_ffi.Fs.write (output_path hub_path) response.content;
  let* s = Cn_protocol.actor_transition s Cn_protocol.Output_received in
  (* Extract body + parse ops *)
  let body = Cn_lib.extract_body response.content in
  let output_meta = Cn_lib.parse_frontmatter response.content in
  let ops = Cn_lib.extract_ops output_meta in
  (* Archive raw IO pair BEFORE effects (per LOGGING.md audit invariant).
     Archived output is the original LLM response, pre-resolution. *)
  Cn_agent.archive_io_pair_files hub_path queue_item.trigger;
  (* Resolve payloads via Body Consumption Rules, then execute *)
  ops |> List.iter (fun op ->
    let resolved_op = resolve_payload body op in
    Cn_agent.execute_op hub_path config.name queue_item.trigger resolved_op);
  (* Telegram projection: send full payload *)
  if queue_item.from_telegram then begin
    let full_payload = match body with
      | Some b -> b
      | None ->
          (* Fallback: prefer reply notification, else acknowledged *)
          ops |> List.find_map (function
            | Cn_lib.Reply (_, msg) -> Some msg
            | _ -> None)
          |> Option.value ~default:"(acknowledged)" in
    Telegram.send_message config.telegram queue_item.chat_id full_payload
  end;
  let* _s = Cn_protocol.actor_transition s Cn_protocol.Archive_complete in
  Ok ()

(* Resolve body into op payload per Body Consumption Rules *)
and resolve_payload body = function
  | Cn_lib.Reply (id, msg) ->
      Cn_lib.Reply (id, Option.value body ~default:msg)
  | Cn_lib.Send (peer, msg, None) ->
      Cn_lib.Send (peer, msg, body)  (* body as fallback for missing 3rd segment *)
  | op -> op  (* all others: no body consumption *)
```

Note: The existing `Cn_agent.archive_io_pair` already archives before executing (per LOGGING.md). The runtime preserves this ordering: archive the raw IO pair first (crash-safe audit trail), then resolve payloads using body, then execute ops. The archived `logs/output/{trigger}.md` is always the original LLM response — payload resolution is an ephemeral execution detail. The `resolve_payload` function is the only new logic — it implements the Body Consumption Rules table above.

---

## Daemon

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
│   offset ← read state/telegram.offset                      │
│   loop:                                                     │
│     messages ← Telegram.get_updates(offset)                │
│     for msg in messages:                                    │
│       enqueue msg to state/queue/ (raw Telegram envelope)   │
│       exec "cn agent --process"                             │
│       offset ← msg.update_id + 1                            │
│       write state/telegram.offset ← offset                  │
│     sleep poll_interval                                      │
│                                                             │
│   Responsibilities: Receive, enqueue, invoke, loop          │
│   Intelligence: None                                        │
│   Context packing: None (that's the processor's job)        │
└─────────────────────────────────────────────────────────────┘
```

| Concern | Owner | Rationale |
|---------|-------|-----------|
| Process lifecycle | systemd | Battle-tested, handles crashes, logging, dependencies |
| Telegram I/O | Daemon | Poll + enqueue; isolated failure domain; trivial to restart |
| Context packing | Processor | Reads hub artifacts, builds `state/input.md` from queue item |
| LLM invocation | Processor | Single Claude API call |
| Op execution + archive | Processor | Parses output.md, executes ops, routes Telegram reply, archives IO pair |

### Idempotence

- Telegram `update_id` offset persisted to `state/telegram.offset`
- Offset only advanced after successful processing + response send
- If processor crashes mid-message, the update is reprocessed on next poll

---

## Configuration

```yaml
# .cn/agent.yaml

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
  # IO-pair audit: logs/input/ + logs/output/ (per LOGGING.md)
  # System log: stdout (captured by systemd journal)
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
| Implement cn_llm.ml | Claude API (single call, no tools) |
| Implement cn_context.ml | Context packing from hub artifacts |
| Implement cn_runtime.ml | Pack → call → write → archive → resolve/execute → projection |
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
| Op coverage | All ops functional | Integration test suite |
| Binary size | < 5MB | `ls -la cn` |
| Memory usage | < 50MB RSS | `ps aux` under load |

---

## Scope: v1 vs v2

| Feature | v1 | v2 (Future) |
|---------|-----|-------------|
| Telegram transport | Long-polling | Webhook option |
| LLM call | Single request→response | Streaming |
| Agent model | Pure pipe (no tools) | Possibly read-only tools if context packing proves insufficient |
| Context loading | Recent dailies + keyword skills | Full semantic search |
| Media handling | Text only | Images, voice, files |
| Multi-model | Claude only | Model selection |

v1 targets functional parity with minimal scope. v2 features are explicitly deferred.

**Critical v2 decision:** If context packing proves insufficient (LLM frequently lacks needed info), we may add read-only retrieval tools. But the default assumption is: pack better, not retrieve more.

---

## Alternatives Considered

| Option | Pros | Cons | Decision |
|--------|------|------|----------|
| **Keep OpenClaw** | Zero effort, already working | No ownership, coupling, opacity, fragility | Rejected — core dependency without auditability |
| **Fork OpenClaw** | Existing codebase, faster start | Python runtime, large surface area, still not native | Rejected — violates constraint 1 (pure OCaml) |
| **Wrap OC via HTTP relay** | Minimal code, OC does the work | Still dependent, extra latency, two failure domains | Rejected — adds complexity without removing dependency |
| **Native runtime with tool loop** | Familiar "agentic" pattern | Breaks CN security boundary, harder to audit, more code | Rejected (v3.2) — tools violate "agent sees two files" |
| **Native runtime, pure pipe** | Full ownership, single binary, CN-native, simplest possible | Must pre-load all context (no interactive retrieval) | **Accepted** — aligns with all constraints + security model |

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

**Recommendation:** Retry 3x with exponential backoff, then send error message to Telegram. No silent failures.

### 3. Context Packing Sufficiency

**Question:** Will pre-loading context always be enough, or will the LLM sometimes need to request additional information?

**Options:**
- Pre-load generously (more context = more tokens, less precision)
- Add read-only retrieval tools (breaks pure-pipe, but pragmatic)
- Let the LLM say "I need more info" as an op, and cn re-invokes with additional context

**Recommendation:** Start with generous pre-loading. Monitor for "insufficient context" failures. If frequent, consider option 3 (re-invocation) before option 2 (tools), since re-invocation preserves the pure-pipe boundary.

### 4. Output Format

**Question:** How reliably can the LLM produce correctly-formatted frontmatter ops?

**Recommendation:** Include the op format specification in the system prompt (from SOUL.md or the agent-ops skill). Validate frontmatter on the cn side — `cn_lib.ml:extract_ops` already ignores unrecognized keys. If no ops are extracted, fall back to `ack: <trigger-id>`. Log parse failures for monitoring.

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

This runtime preserves and enforces the CN security model (see SECURITY-MODEL.md).

### Core Invariant

The agent interface is `state/input.md → state/output.md` (conceptual). The LLM interacts with exactly zero files — it sees only text contents and produces text contents. cn performs all file I/O: packing input, writing output, parsing ops, executing effects, archiving. The LLM is a pure `string → string` function within cn's process.

### Telegram Authentication

- `allowed_users` whitelist in config
- Messages from unknown users are logged and dropped
- No automatic responses to unknown senders

### Op Validation

- Ops parsed from output.md frontmatter are validated before execution
- Invalid ops produce `Error` (not silent failure) — same as FSM transitions
- Protected files (`spec/SOUL.md`, `spec/USER.md`, `state/peers.md`) are never writable — enforced by `cn_agent.ml:execute_op`

### API Keys

- Stored in environment variables, not config files
- Config supports `${VAR}` expansion
- Never logged or included in error messages

### Audit Trail

- Every interaction archived as IO pair: `logs/input/{trigger}.md` + `logs/output/{trigger}.md` (per LOGGING.md)
- Ops extracted from output are logged before execution
- Errors logged with full context (excluding secrets)

---

## References

### cnos Internal
- [Hub Layout](../../spec/system/HUB.md) — Canonical directory structure
- [Agent Ops Skill](../../src/agent/skills/agent/agent-ops/SKILL.md) — Authoritative output.md format (key-per-op, pipe-delimited)
- [Security Model](./SECURITY-MODEL.md) — Agent sandbox, protected files, audit trail
- [Logging Architecture](./LOGGING.md) — IO-pair archival pattern
- [Daemon Architecture](./DAEMON.md) — Plugin direction (this doc is the first plugin)
- [Protocol Specification](./PROTOCOL.md) — FSM definitions
- [Architecture](../ARCHITECTURE.md) — Module layers, data flow, agent I/O protocol

### External
- [Telegram Bot API — getUpdates](https://core.telegram.org/bots/api#getupdates)
- [Anthropic Claude API — Messages](https://docs.anthropic.com/en/api/messages)
- [Anthropic Claude — Context Windows](https://docs.anthropic.com/en/docs/build-with-claude/context-windows)
- [Anthropic Claude API — Prompt Caching](https://docs.anthropic.com/en/docs/build-with-claude/prompt-caching)
- [Anthropic Cookbook — Prompt Caching](https://github.com/anthropics/anthropic-cookbook/blob/main/misc/prompt_caching.ipynb)
- [systemd Service Units](https://www.freedesktop.org/software/systemd/man/systemd.service.html)

---

*Document version 3.0.9. For comments and iteration, contact reviewers or open a thread in the hub.*
