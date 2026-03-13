# cnos Architecture

How the articulated layers reveal one coherent system.

**Status:** v2.0.0
**Date:** 2026-03-13

---

## 1. The Relation Question

β asks: *do the parts reveal one system?*

cnos has many articulations — doctrine, specs, runtime modules, packages, traces, releases, agents, operator surfaces. This document maps how they relate. It does not redefine them (α does that). It shows that they are one system, not many fragments.

---

## 2. System Graph

```
                    THESIS.md
                   (the whole)
                       |
          ┌────────────┼────────────┐
          α            β            γ
       pattern      relation     evolution
          |            |            |
    ┌─────┴─────┐     this    ┌────┴────┐
    |           |     doc     |         |
 doctrine   specs           method    plans
    |           |              |
 FOUNDATIONS  CAA.md         CDD.md
 COHERENCE-   AGENT-RUNTIME  AGILE-PROCESS
  SYSTEM      PROTOCOL       checklists
 MANIFESTO    TRACEABILITY
              CAR
              SECURITY-MODEL
              CLI
              WHITEPAPER
```

THESIS.md sits above the triad as the whole. Every other doc is an articulation along one dominant axis. This document (β) maps the edges between them.

---

## 3. Layer Relations

### Doctrine → Architecture

Doctrine (FOUNDATIONS, COHERENCE-SYSTEM, MANIFESTO) defines *why*. Architecture (CAA, AGENT-RUNTIME, PROTOCOL) defines *what*. The relation:

- FOUNDATIONS §3 defines the coherence loop → CAA §5 implements it as the agent cycle
- COHERENCE-SYSTEM §3.3 names CMP/MCP/CAP/CLP → AGENT-RUNTIME realizes them as `input.md → LLM → output.md → ops`
- MANIFESTO's four guarantees → SECURITY-MODEL enforces them, WHITEPAPER specifies the protocol surface

If doctrine says something the architecture doesn't realize, that's a β gap.

### Architecture → Runtime

Architecture (α docs) specifies. Runtime (OCaml modules) implements. The relation:

| α spec | Runtime module | What it enforces |
|--------|---------------|-----------------|
| CAA §5 (agent cycle) | `cn_runtime.ml` | dequeue → pack → call → finalize → project |
| PROTOCOL (FSMs) | `cn_protocol.ml` | Thread, Actor, Sender, Receiver state machines |
| AGENT-RUNTIME (CN Shell) | `cn_shell.ml`, `cn_executor.ml` | Typed ops, two-pass orchestration |
| TRACEABILITY | `cn_trace.ml` | Event stream, reason codes, receipts |
| SECURITY-MODEL | `cn_sandbox.ml` | Path sandbox, denylist enforcement |
| CAR (packages) | `cn_build.ml` | Package assembly from doctrine/mindsets/skills |
| CLI | `cn.ml` | Command dispatch |

If a spec exists without a module, the spec is aspirational. If a module exists without a spec, the module is undocumented.

### Runtime → Packages

The runtime loads cognition from installed packages (`.cn/vendor/packages/`). The relation:

- CAR specifies the package model → `cn_build.ml` assembles packages from `src/agent/`
- Packages contain doctrine, mindsets, and skills → the context packer (`cn_context.ml`) loads them at invocation
- Package manifests (`cn.package.json`) declare contents → the runtime verifies them at setup

### Runtime → Observability

The runtime produces evidence. TRACEABILITY specifies what evidence. The relation:

- Every state transition emits a trace event with reason code
- `ready.json` reconstructs mind/body/sensor state from files alone
- Receipts (`state/receipts/`) record per-trigger execution evidence
- `projection.render.*` events carry render status (ok, blocked, fallback)

If the runtime does something TRACEABILITY doesn't cover, that's a β gap.

### Method → All Layers

CDD (γ) governs how every layer evolves. The relation:

- CDD §2 names the gap → the gap may be in any α doc or runtime module
- CDD §4 creates artifacts in order → design doc (α), tests, code, docs, release notes
- CDD §7 uses CLP for review → scores α/β/γ across the affected layers
- CDD §11 measures the coherence delta → CHANGELOG TSC table records the result

### Guides → Operator

Guides (beta/guides/) connect operators to the system. The relation:

- HANDSHAKE → WHITEPAPER §7 (transport levels), `cn_mail.ml`
- AUTOMATION → DAEMON, `cn_agent.ml`, `cn_telegram.ml`
- MIGRATION → version history in AGENT-RUNTIME, CHANGELOG
- WRITE-A-SKILL → skill structure in packages, `cn_context.ml` skill loading

### Evidence → Model

Evidence (beta/evidence/) tests whether model matches reality. The relation:

- RCAs reveal where runtime behavior diverged from spec
- AUDIT tracks doc health — which articulations are stale, which are current
- When evidence contradicts a spec, CDD triggers MCI (update the model) or MCA (fix the code)

---

## 4. Module Structure

```
cn.ml                    CLI dispatch
 |
 |── cn_runtime.ml       Agent runtime orchestrator
 |── cn_context.ml       Context packer
 |── cn_llm.ml           Claude API client
 |── cn_telegram.ml      Telegram Bot API
 |── cn_config.ml        Config loader
 |── cn_dotenv.ml        .env loader
 |── cn_agent.ml         Queue, input/output, op execution
 |── cn_shell.ml         CN Shell: capability runtime
 |── cn_executor.ml      Op executor
 |── cn_sandbox.ml       Path sandbox
 |── cn_capabilities.ml  Capability discovery
 |── cn_projection.ml    Reply projection
 |── cn_output.ml        Output plane separation
 |── cn_orchestrator.ml  Two-pass orchestration
 |── cn_protocol.ml      FSMs (pure)
 |── cn_gtd.ml           GTD lifecycle
 |── cn_mail.ml          Inbox/outbox
 |── cn_mca.ml           Managed Concern Aggregation
 |── cn_commands.ml      Peer management + git
 |── cn_system.ml        Init, setup, update, status, doctor, sync
 |── cn_build.ml         Package assembly
 |── cn_trace.ml         Traceability event stream
 |── cn_deps.ml          Dependency management
 |── cn_hub.ml           Hub discovery, path constants
 |── cn_fmt.ml           Output formatting
 |── cn_ffi.ml           Native system bindings
 |── cn_io.ml            Protocol I/O over git
 |── cn_lib.ml           Types, parsing (pure)
 |── cn_json.ml          JSON parser/emitter (pure)
 └── git.ml              Raw git operations
```

### Dependency Layers

```
Layer 5  cn.ml (dispatch)
Layer 4  cn_runtime (orchestrator)
Layer 3  cn_context, cn_llm, cn_telegram, cn_config, cn_agent, cn_shell,
         cn_executor, cn_sandbox, cn_capabilities, cn_projection, cn_output,
         cn_orchestrator, cn_gtd, cn_mail, cn_mca, cn_commands, cn_system,
         cn_build, cn_trace, cn_deps, cn_dotenv
Layer 2  cn_protocol, cn_hub, cn_io, cn_fmt
Layer 1  cn_lib, cn_json, cn_ffi, git.ml
```

Rules:
- Layer N depends only on N-1 and below
- `cn_protocol.ml` has zero dependencies (pure types and transitions)
- `cn_lib.ml`, `cn_json.ml` are pure — testable with ppx_expect
- `cn_ffi.ml` is the only module touching Unix/stdlib directly
- `cn_runtime.ml` is the only module calling the LLM

---

## 5. The Four FSMs

All state machines live in `cn_protocol.ml`. States are algebraic types. Transitions are total functions returning `Ok state | Error string`.

| FSM | States | Governs |
|-----|--------|---------|
| Thread Lifecycle | Received → Queued → Active → Doing → Archived (+ Deferred, Delegated, Deleted) | Work item progression |
| Actor Loop | Idle → InputReady → Processing → OutputReady → Idle | Agent invocation scheduling |
| Transport Sender | Pending → BranchCreated → Pushing → Pushed → Delivered | Outbox delivery |
| Transport Receiver | Fetched → Materializing → Materialized → Cleaned | Inbox materialization |

Full state diagrams and transition tables: [PROTOCOL.md](../alpha/PROTOCOL.md).

### How they compose

```
Peer pushes branch → [Receiver] → inbox → [Thread] → queued →
[Actor] → input.md → agent → output.md → ops → [Thread] →
archived (or delegated → outbox → [Sender] → delivered)
```

---

## 6. Data Flow

```
1. cn sync            Fetch peer branches, send outbound
2. cn agent           Runtime cycle (atomic lock):
   a. GC              Sweep stale markers
   b. Queue inbox     inbox → state/queue/
   c. Dequeue         Pop oldest
   d. Pack context    identity + skills + conversation + message
   e. input.md        Frontmatter + packed context
   f. Call LLM        Claude API
   g. output.md       Typed ops in frontmatter, body below
   h. Archive         Copy to logs/ (before effects)
   i. Execute ops     CN Shell two-pass: observe → effect
   j. Receipts        Per-trigger JSON
   k. Project         Route reply to Telegram
   l. Conversation    Append to conversation.json
   m. Cleanup         Delete transient files
3. cn save            Commit + push to git
```

---

## 7. Directory Layout

```
hub/
├── .cn/
│   ├── config.json          Hub configuration
│   ├── secrets.env          API keys (gitignored)
│   └── vendor/packages/     Installed cognitive packages
├── spec/                    Agent identity (SOUL.md, USER.md)
├── threads/                 Work items and conversations
│   ├── mail/inbox/          Materialized peer messages
│   ├── mail/outbox/         Pending outbound
│   ├── doing/               Active work
│   ├── reflections/         Daily, weekly reflections
│   └── ...
├── state/                   Runtime state
│   ├── queue/               FIFO queue
│   ├── receipts/            Execution receipts
│   ├── conversation.json    Recent history
│   └── ...
└── logs/                    Archived input/output pairs
```

---

## 8. Related Documents

| Document | Relation |
|----------|----------|
| [THESIS.md](../THESIS.md) | The whole — this doc maps its internal relations |
| [COHERENCE-SYSTEM.md](../alpha/COHERENCE-SYSTEM.md) | Meta-model that this doc makes relational |
| [CAA.md](../alpha/CAA.md) | Agent structure — this doc maps it to runtime modules |
| [AGENT-RUNTIME.md](../alpha/AGENT-RUNTIME.md) | Runtime spec — this doc shows how it relates to FSMs and observability |
| [PROTOCOL.md](../alpha/PROTOCOL.md) | FSM design — this doc shows how FSMs compose |
| [CDD.md](../gamma/CDD.md) | Development method — governs how all these relations evolve |
| [AUDIT.md](./evidence/AUDIT.md) | Evidence — tracks which relations are current vs stale |
