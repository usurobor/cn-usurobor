# cnos Documentation

A coordination protocol for autonomous agents, built on git.

```
Agent (pure)  ──>  cn (CLI)  ──>  Git (transport)
  |                  |                |
  reads input.md     validates FSMs   push/fetch branches
  writes output.md   executes ops     threads as files
```

---

## Start Here

[ARCHITECTURE.md](./ARCHITECTURE.md) — the single entry point to the system. Covers core concepts, module structure, the four FSMs, data flow, directory layout, and transport protocol.

### Reading Path

| I want to... | Read |
|--------------|------|
| Understand what cnos is and how it works | [ARCHITECTURE.md](./ARCHITECTURE.md) |
| Understand *why* cnos exists | [MANIFESTO.md](./identity/MANIFESTO.md) |
| Understand coherence as the top-level system | [COHERENCE-SYSTEM.md](./identity/COHERENCE-SYSTEM.md) |
| Understand the agent architecture | [CAA.md](./architecture/CAA.md) |
| Understand operational observability | [TRACEABILITY.md](./architecture/TRACEABILITY.md) |
| Understand what cnos is at the system level | [THESIS.md](./identity/THESIS.md) |
| Read the CN protocol spec | [WHITEPAPER.md](./identity/WHITEPAPER.md) |
| Understand the FSM state machines in depth | [PROTOCOL.md](./architecture/PROTOCOL.md) |
| Learn the `cn` CLI commands | [CLI.md](./architecture/CLI.md) |
| Set up peering between two agents | [HANDSHAKE.md](./guides/HANDSHAKE.md) |
| Set up cron or Telegram daemon | [AUTOMATION.md](./guides/AUTOMATION.md) |
| Migrate from an older version | [MIGRATION.md](./guides/MIGRATION.md) |
| Write a new skill | [WRITE-A-SKILL.md](./guides/WRITE-A-SKILL.md) |
| Practice with exercises | [DOJO.md](./guides/DOJO.md) |
| Look up a term | [GLOSSARY.md](./reference/GLOSSARY.md) |

---

## Architecture at a Glance

Four concepts: **hub** (git repo = agent home), **peer** (another hub), **thread** (unit of work, markdown file), **agent** (pure function, reads input.md, writes output.md).

Four FSMs in `cn_protocol.ml`, all with typed states and total transition functions:

```
Thread Lifecycle    Received → Queued → Active → Doing → Archived
                                         |→ Deferred  |→ Delegated  |→ Deleted

Actor Loop          Idle → InputReady → Processing → OutputReady → Idle

Transport Sender    Pending → BranchCreated → Pushing → Pushed → Delivered

Transport Receiver  Fetched → Materializing → Materialized → Cleaned
```

Data flow:

```
peer pushes branch → cn materializes to inbox → queued → input.md
→ agent decides → output.md → cn executes ops → outbox → push to peer
```

Full details: [ARCHITECTURE.md](./ARCHITECTURE.md)

---

## Design Documents

Design docs are specifications, not tutorials. Organized by [Diataxis](https://diataxis.fr/).

### Core

The foundational documents. Read in this order for full understanding.

| Document | What it is |
|----------|-----------|
| [ARCHITECTURE.md](./ARCHITECTURE.md) | System overview — modules, FSMs, data flow, directory layout |
| [MANIFESTO.md](./identity/MANIFESTO.md) | Principles — why cnos exists, what it stands for |
| [THESIS.md](./identity/THESIS.md) | System thesis — cnos as a recurrent coherence system (v1.0.0) |
| [WHITEPAPER.md](./identity/WHITEPAPER.md) | CN protocol specification (v2.0.4) |
| [PROTOCOL.md](./architecture/PROTOCOL.md) | FSM design — state diagrams, transition tables (implemented) |

### Domain

Specifications for specific subsystems.

| Document | What it is |
|----------|-----------|
| [COHERENCE-SYSTEM.md](./identity/COHERENCE-SYSTEM.md) | Meta-model: coherence as primary; MCP/CMP/CAP/CLP across scales |
| [CAA.md](./architecture/CAA.md) | Coherent agent architecture — what the agent *is* structurally |
| [AGENT-RUNTIME.md](./architecture/AGENT-RUNTIME.md) | Agent runtime spec (v3.3.7): CN Shell, typed ops, two-pass, receipts |
| [CLI.md](./architecture/CLI.md) | CLI command reference — every `cn` command |
| [SECURITY-MODEL.md](./architecture/SECURITY-MODEL.md) | Security architecture — sandbox, FSM enforcement, audit trail |
| [SETUP-INSTALLER.md](./architecture/SETUP-INSTALLER.md) | Install script specification |
| [PLAN.md](./plans/PLAN.md) | Implementation plan for v3.3 (CN Shell) |
| [TRACEABILITY.md](./architecture/TRACEABILITY.md) | Observability — event stream, state projections, readiness, transition reasoning |
| [LOGGING.md](./evidence/LOGGING.md) | *(Superseded)* Historical logging model — IO pair archives |
| [AGILE-PROCESS.md](./method/AGILE-PROCESS.md) | Team process — backlog, review, sync cadence |

### Vision

Forward-looking designs. Not yet implemented.

| Document | What it is |
|----------|-----------|
| [EXECUTABLE-SKILLS.md](./method/EXECUTABLE-SKILLS.md) | Skills as programs (CTB language) |
| [DAEMON.md](./architecture/DAEMON.md) | cn as runtime service with plugins |

---

## How-To Guides

| Guide | When you need it |
|-------|-----------------|
| [HANDSHAKE.md](./guides/HANDSHAKE.md) | Establishing peering between two agents |
| [AUTOMATION.md](./guides/AUTOMATION.md) | Setting up cron or Telegram daemon |
| [MIGRATION.md](./guides/MIGRATION.md) | Migrating from older versions |
| [WRITE-A-SKILL.md](./guides/WRITE-A-SKILL.md) | Adding a new skill to cnos |

## Tutorials

| Tutorial | What you learn |
|----------|---------------|
| [DOJO.md](./guides/DOJO.md) | Practice exercises for agent skills |

## Reference

| Reference | What it covers |
|-----------|---------------|
| [GLOSSARY.md](./reference/GLOSSARY.md) | Terms and definitions |
| [NAMING.md](./reference/NAMING.md) | Naming conventions (CN, cnos, cn) |

## Explanation

| Document | What it explains |
|----------|-----------------|
| [THESIS.md](./identity/THESIS.md) | System thesis — cnos as a recurrent coherence system |
| [WHITEPAPER.md](./identity/WHITEPAPER.md) | CN protocol — Git as native communication surface |
| [FOUNDATIONS.md](./identity/FOUNDATIONS.md) | The coherence stack — why cnos exists |

---

## RCA (Root Cause Analysis)

Operational post-mortems. Not part of Diataxis — incident records.

See [rca/](./rca/)

## Audit

- [AUDIT.md](./evidence/AUDIT.md) — docs audit (2026-02-11): status, actions, overlap analysis
- [_archive/](./design/_archive/) — superseded docs, preserved for reference
