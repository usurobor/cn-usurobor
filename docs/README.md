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
| Understand *why* cnos exists | [MANIFESTO.md](./design/MANIFESTO.md) |
| Read the formal protocol spec | [WHITEPAPER.md](./design/WHITEPAPER.md) |
| Understand the FSM state machines in depth | [PROTOCOL.md](./design/PROTOCOL.md) |
| Learn the `cn` CLI commands | [CLI.md](./design/CLI.md) |
| Set up peering between two agents | [HANDSHAKE.md](./how-to/HANDSHAKE.md) |
| Set up cron automation | [AUTOMATION.md](./how-to/AUTOMATION.md) |
| Migrate from an older version | [MIGRATION.md](./how-to/MIGRATION.md) |
| Practice with exercises | [DOJO.md](./tutorials/DOJO.md) |
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
| [MANIFESTO.md](./design/MANIFESTO.md) | Principles — why cnos exists, what it stands for |
| [WHITEPAPER.md](./design/WHITEPAPER.md) | Protocol specification (v2.0.4, normative) |
| [PROTOCOL.md](./design/PROTOCOL.md) | FSM design — state diagrams, transition tables (implemented) |

### Domain

Specifications for specific subsystems.

| Document | What it is |
|----------|-----------|
| [CLI.md](./design/CLI.md) | CLI command reference — every `cn` command |
| [SECURITY-MODEL.md](./design/SECURITY-MODEL.md) | Security architecture — sandbox, FSM enforcement, audit trail |
| [LOGGING.md](./design/LOGGING.md) | Logging — IO pair archives, run logs, traceability |
| [AGILE-PROCESS.md](./design/AGILE-PROCESS.md) | Team process — backlog, review, sync cadence |

### Vision

Forward-looking designs. Not yet implemented.

| Document | What it is |
|----------|-----------|
| [EXECUTABLE-SKILLS.md](./design/EXECUTABLE-SKILLS.md) | Skills as programs (CTB language) |
| [DAEMON.md](./design/DAEMON.md) | cn as runtime service with plugins |

---

## How-To Guides

| Guide | When you need it |
|-------|-----------------|
| [HANDSHAKE.md](./how-to/HANDSHAKE.md) | Establishing peering between two agents |
| [AUTOMATION.md](./how-to/AUTOMATION.md) | Setting up cron for `cn sync` |
| [MIGRATION.md](./how-to/MIGRATION.md) | Migrating from older versions |

## Tutorials

| Tutorial | What you learn |
|----------|---------------|
| [DOJO.md](./tutorials/DOJO.md) | Practice exercises for agent skills |

## Reference

| Reference | What it covers |
|-----------|---------------|
| [GLOSSARY.md](./reference/GLOSSARY.md) | Terms and definitions |

## Explanation

| Document | What it explains |
|----------|-----------------|
| [FOUNDATIONS.md](./explanation/FOUNDATIONS.md) | The coherence stack — why cnos exists |

---

## RCA (Root Cause Analysis)

Operational post-mortems. Not part of Diataxis — incident records.

See [rca/](./rca/)

## Audit

- [AUDIT.md](./design/AUDIT.md) — docs audit (2026-02-11): status, actions, overlap analysis
- [_archive/](./design/_archive/) — superseded docs, preserved for reference
