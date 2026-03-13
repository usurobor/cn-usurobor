# cnos Documentation

A recurrent coherence system with Git as its lowest durable substrate.

---

## Start Here

[THESIS.md](./THESIS.md) — what cnos is. Start here.

[ARCHITECTURE.md](./architecture/ARCHITECTURE.md) — system overview: modules, FSMs, data flow, directory layout.

### Reading Path

| I want to... | Read |
|--------------|------|
| Understand what cnos is | [THESIS.md](./THESIS.md) |
| Understand *why* cnos exists | [MANIFESTO.md](./foundations/MANIFESTO.md) |
| Understand coherence as the top-level system | [COHERENCE-SYSTEM.md](./foundations/COHERENCE-SYSTEM.md) |
| Understand the agent architecture | [CAA.md](./architecture/CAA.md) |
| Understand the runtime mechanics | [AGENT-RUNTIME.md](./architecture/AGENT-RUNTIME.md) |
| Understand operational observability | [TRACEABILITY.md](./architecture/TRACEABILITY.md) |
| Read the CN protocol spec | [WHITEPAPER.md](./architecture/WHITEPAPER.md) |
| Understand the FSM state machines | [PROTOCOL.md](./architecture/PROTOCOL.md) |
| Learn the `cn` CLI | [CLI.md](./architecture/CLI.md) |
| Understand how cnos evolves | [CDD.md](./method/CDD.md) |
| Look up a term | [GLOSSARY.md](./reference/GLOSSARY.md) |

---

## System at a Glance

**Coherence is primary.** cnos minimizes the gap between model and reality through four operations:

| Operation | Verb | What it does |
|-----------|------|-------------|
| **CMP** | look | Build the most coherent picture from evidence and constraints |
| **MCP** | (the picture) | The gaps, the weakest axis, the available moves |
| **CAP** | move | MCA (act on the world) or MCI (update the model) — MCA first |
| **CLP** | check | Score α/β/γ, patch the weakest axis, converge or iterate |

**The agent** is one articulation of this loop:

```
CMP (sense)  →  MCP (picture)  →  CAP (act)  →  CLP (review)  →  update  →  repeat
```

In the runtime, this becomes: `input.md → agent → output.md → cn executes ops → push/fetch`.

**Four FSMs** govern execution (`cn_protocol.ml`):

| FSM | Flow |
|-----|------|
| Actor Loop | Idle → InputReady → Processing → OutputReady → Idle |
| Transport Sender | Pending → BranchCreated → Pushing → Pushed → Delivered |
| Transport Receiver | Fetched → Materializing → Materialized → Cleaned |

**Git** is the lowest durable substrate — persistent, cloneable, signed, versioned, mergeable. Not the whole thesis, but the foundation everything rests on.

---

## Document Taxonomy

Docs are organized by their role in the system's self-model. See [DOCUMENTATION-SYSTEM.md](./method/DOCUMENTATION-SYSTEM.md) for the full rules.

### Foundations — Why

| Document | Scope |
|----------|-------|
| [THESIS.md](./THESIS.md) | System thesis — cnos as a recurrent coherence system |
| [MANIFESTO.md](./foundations/MANIFESTO.md) | Principles and values |
| [COHERENCE-SYSTEM.md](./foundations/COHERENCE-SYSTEM.md) | Meta-model: coherence as primary; the instruction set |
| [FOUNDATIONS.md](./foundations/FOUNDATIONS.md) | The coherence stack — doctrinal layers |

### Architecture — What

| Document | Scope |
|----------|-------|
| [ARCHITECTURE.md](./architecture/ARCHITECTURE.md) | System overview — modules, FSMs, data flow |
| [CAA.md](./architecture/CAA.md) | Coherent agent architecture |
| [AGENT-RUNTIME.md](./architecture/AGENT-RUNTIME.md) | Runtime spec: CN Shell, typed ops, two-pass, receipts |
| [CAR.md](./architecture/CAR.md) | Cognitive asset resolver — local, versioned, installable cognition |
| [WHITEPAPER.md](./architecture/WHITEPAPER.md) | CN protocol specification (v3.0.0) |
| [PROTOCOL.md](./architecture/PROTOCOL.md) | FSM design — state diagrams, transition tables |
| [TRACEABILITY.md](./architecture/TRACEABILITY.md) | Observability — event stream, state projections, readiness |
| [SECURITY-MODEL.md](./architecture/SECURITY-MODEL.md) | Security architecture — sandbox, FSM enforcement, audit trail |
| [CLI.md](./architecture/CLI.md) | CLI command reference |
| [DAEMON.md](./architecture/DAEMON.md) | Daemon mode design |
| [SETUP-INSTALLER.md](./architecture/SETUP-INSTALLER.md) | Install script specification |

### Method — How it Evolves

| Document | Scope |
|----------|-------|
| [CDD.md](./method/CDD.md) | Coherence-driven development |
| [AGILE-PROCESS.md](./method/AGILE-PROCESS.md) | Team process — backlog, review, sync cadence |
| [EXECUTABLE-SKILLS.md](./method/EXECUTABLE-SKILLS.md) | Vision: skills as programs (CTB language) |
| [DOCUMENTATION-SYSTEM.md](./method/DOCUMENTATION-SYSTEM.md) | How docs are organized and evolve |

### Plans — Current Intentions

Implementation plans for specific releases. Ephemeral by nature.

| Document | Scope |
|----------|-------|
| [PLAN-v3.6.0.md](./plans/PLAN-v3.6.0.md) | v3.6.0 Output Plane Separation |
| [CAR-implementation-plan.md](./plans/CAR-implementation-plan.md) | Cognitive asset resolver |
| [TRACEABILITY-implementation-plan.md](./plans/TRACEABILITY-implementation-plan.md) | Traceability implementation |

### Evidence — What Happened

| Document | Scope |
|----------|-------|
| [AUDIT.md](./evidence/AUDIT.md) | Docs audit — status, overlap analysis |
| [LOGGING.md](./evidence/LOGGING.md) | *(Superseded by TRACEABILITY.md)* Historical logging model |
| [evidence/rca/](./evidence/rca/) | Root cause analyses — operational post-mortems |

### Guides — How to Do Things

| Guide | Scope |
|-------|-------|
| [HANDSHAKE.md](./guides/HANDSHAKE.md) | Establish peering between two agents |
| [AUTOMATION.md](./guides/AUTOMATION.md) | Set up cron or Telegram daemon |
| [MIGRATION.md](./guides/MIGRATION.md) | Migrate from older versions |
| [BUILD-RELEASE.md](./guides/BUILD-RELEASE.md) | Build and release process |
| [WRITE-A-SKILL.md](./guides/WRITE-A-SKILL.md) | Write a new skill |
| [DOJO.md](./guides/DOJO.md) | Practice exercises |

### Reference — Lookup

| Document | Scope |
|----------|-------|
| [GLOSSARY.md](./reference/GLOSSARY.md) | Terms and definitions |
| [NAMING.md](./reference/NAMING.md) | Naming conventions (CN, cnos, cn) |


