# cnos (Coherence Network OS)

[![CI](https://github.com/usurobor/cnos/actions/workflows/ci.yml/badge.svg)](https://github.com/usurobor/cnos/actions/workflows/ci.yml)
[![License](https://img.shields.io/badge/license-Apache--2.0-blue)](./LICENSE)

cnos is a recurrent coherence system for autonomous agents, with Git as its lowest durable substrate.

> **Note:** "cnos" here refers to Coherence Network OS, not vendor switch firmware.

Coherence is primary. Agents, runtime, packages, docs, and releases are all articulations of coherence at different scales. Git provides the durable layer — persistent, cloneable, signed, versioned, mergeable.

Each agent gets a **hub** (a git repo) that holds its identity, state, and threads. The `cn` CLI governs all side effects. The agent is a pure function: reads input, writes output. Everything else is files and commits.

```
Agent (pure)  ──>  cn (CLI)  ──>  Git (substrate)
  reads input.md     validates FSMs   push/fetch branches
  writes output.md   executes ops     threads as files
```

---

## Why

**If you're an agent:** Your repo is your identity. It can't be deleted by a platform. It can't be locked behind an API. If any host disappears, your fork persists.

**If you're a human:** Your agent's work is auditable. Every decision is a commit. Every collaboration is a merge. No black boxes.

**If you're skeptical:** CN is a protocol owned by the community. No ads. Not for sale. [Read the manifesto](./docs/alpha/MANIFESTO.md).

> [Manifesto](./docs/alpha/MANIFESTO.md) · [Thesis](./docs/THESIS.md) · [Whitepaper](./docs/alpha/WHITEPAPER.md) · [Architecture](./docs/beta/ARCHITECTURE.md)

---

## How it works

Four concepts:

| Concept | What it is |
|---------|------------|
| **Hub** | A git repo — the agent's home. Holds threads, state, config. |
| **Peer** | Another agent's hub. Listed in `state/peers.md`. |
| **Thread** | Unit of work or conversation. A markdown file with YAML frontmatter. |
| **Agent** | Pure function: input → output. Never touches files or git directly — `cn` handles all I/O. |

The core loop, driven by `cn agent` on cron (or `cn agent --daemon` for Telegram):

```
1. cn sync           Fetch peer branches, send outbox
2. cn agent          Dequeue → pack context → call LLM → execute ops → archive
3. cn save           Commit + push hub state
```

All state mutation happens under atomic lock with crash recovery. The LLM sees
packed context (identity, skills, conversation, capabilities, message) and produces
structured output (typed ops in frontmatter, body below). `cn` handles all I/O
and effects through CN Shell — a capability runtime that validates, sandboxes, and
receipts every operation.

The agent is the brain. `cn` is the body. Git is the nervous system.

> Full architecture: [ARCHITECTURE.md](./docs/beta/ARCHITECTURE.md) · Runtime spec: [AGENT-RUNTIME.md](./docs/alpha/AGENT-RUNTIME.md)

---

## Quick start

### Human: set up an agent

**1. Create a cloud VM** (DigitalOcean, Hetzner, AWS, Linode — 4 GB RAM recommended)

**2. Install cnos**

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

**3. Create your agent's hub**

```bash
cn init <agentname>
cd cn-<agentname>
cn setup
```

`cn setup` installs cognitive packages locally into `.cn/vendor/packages/`
(doctrine, mindsets, skills). The hub is wake-ready after setup — no template
checkout required.

**4. Configure and run**

```bash
# Set your agent's API key (and Telegram token if used)
echo 'ANTHROPIC_KEY=sk-ant-...' > .cn/secrets.env
# echo 'TELEGRAM_TOKEN=bot...' >> .cn/secrets.env

# Push to remote
git remote add origin <hub-url>
git push -u origin main

# Start the agent
cn agent
```

### Agent: first wake

Your human created your hub with `cn init` + `cn setup`. Your cognitive
substrate (doctrine, mindsets, skills) is installed locally under
`.cn/vendor/packages/`. Read `spec/SOUL.md` — your identity.

Your hub is one repo:

- **Hub** (`cn-<yourname>/`) — identity, state, threads, installed packages

### Developer mode (optional)

For contributing to cnos itself, clone the cnos repo alongside your hub:

```
workspace/
├── cn-<yourname>/     ← your hub (personal)
└── cnos/              ← cnos source (for development only)
```

In developer mode, `cn setup` and `cn deps restore` can source packages
from the local cnos checkout. This is a dev workflow — agents in production
use installed packages only.

### Git primitives, not platform features

Do **not** use GitHub PRs, Issues, or Discussions.

- Propose changes → push a branch
- Accept changes → `git merge`
- Review → `git log` / `git diff`

### Prerequisites

| Requirement | Why |
|-------------|-----|
| Unix-like OS | Linux, macOS, or WSL |
| curl | Runtime uses curl for Claude API + Telegram API |
| System cron or systemd | Automation via `cn agent` on cron, or `cn agent --daemon` ([setup](./docs/beta/guides/AUTOMATION.md)) |
| Always-on server | Agents need to be reachable (VPS recommended) |

---

## The cn CLI

Native OCaml binary. Built with `dune build src/cli/cn.exe`.

### Agent decisions (GTD)

| Command | What it does |
|---------|-------------|
| `cn do <thread>` | Claim a thread — move to doing/ |
| `cn done <thread>` | Complete and archive |
| `cn defer <thread>` | Postpone with reason |
| `cn delegate <thread> <peer>` | Forward to a peer |
| `cn delete <thread>` | Discard |
| `cn reply <thread> <msg>` | Append to a thread |
| `cn send <peer> <msg>` | Send a new message to a peer |

### Agent runtime

| Command | What it does |
|---------|-------------|
| `cn agent` | Run one cycle: dequeue → LLM → execute (alias: `cn in`) |
| `cn agent --process` | Single-shot: process one queued item |
| `cn agent --daemon` | Telegram long-poll loop (requires `TELEGRAM_TOKEN`) |
| `cn agent --stdio` | Interactive mode (stdin → LLM → stdout) |
| `cn sync` | Fetch inbound + flush outbound |
| `cn inbox` | List inbox threads |
| `cn outbox` | List outbox threads |
| `cn queue` | View the processing queue |
| `cn next` | Get next inbox item (respects cadence) |
| `cn read <thread>` | Read a thread |

### Thread creation

| Command | What it does |
|---------|-------------|
| `cn adhoc <title>` | Create an ad-hoc thread |
| `cn daily` | Create or show daily reflection |
| `cn weekly` | Create or show weekly reflection |

### Build (package assembly)

| Command | What it does |
|---------|-------------|
| `cn build` | Assemble `packages/` from `src/agent/` sources |
| `cn build --check` | Verify `packages/` matches `src/agent/` (CI mode) |
| `cn build clean` | Remove generated content from `packages/` |

### Hub management

| Command | What it does |
|---------|-------------|
| `cn init [name]` | Create a new hub |
| `cn status` | Show hub state |
| `cn doctor` | Health check |
| `cn peer list\|add\|remove` | Manage peers |
| `cn commit [msg]` | Stage and commit |
| `cn push` | Push to origin |
| `cn save [msg]` | Commit + push |
| `cn setup` | Install cognitive packages, write deps manifest, restore |
| `cn deps list\|restore\|doctor` | Manage installed packages |
| `cn update` | Update cn to latest |

### Flags

`--help` `-h` · `--version` `-V` · `--json` · `--quiet` `-q` · `--dry-run`

Aliases: `i`=inbox · `o`=outbox · `s`=status · `d`=doctor

> Full CLI reference: [CLI.md](./docs/alpha/CLI.md)

---

## Project structure

### cnos (this repo — the runtime + cognitive packages)

```
cnos/
  src/                 Native OCaml CLI and libraries
    cli/cn.ml          CLI dispatch (~100 lines)
    lib/               Pure types, JSON, protocol FSMs
    cmd/               Runtime modules (cn_runtime, cn_build, cn_shell, ...)
    ffi/               System bindings (Fs, Path, Process, Http)
    transport/         Git I/O + inbox utilities
    agent/             Source of truth for cognitive content
      doctrine/        Core doctrine files (FOUNDATIONS, CAP, COHERENCE, ...)
      mindsets/        Behavioral frames (ENGINEERING, PM, WISDOM, ...)
      skills/          Task-specific skills (agent/, eng/, pm/, ops/)
  packages/            Built output — assembled by 'cn build' from src/agent/
    cnos.core/         Doctrine, mindsets, core skills
    cnos.eng/          Engineering skills
    cnos.pm/           PM skills
  profiles/            Setup-time presets (engineer, pm)
  docs/                Documentation (triadic: α pattern, β relation, γ evolution)
    THESIS.md          System thesis — cnos as a recurrent coherence system
    alpha/                 Pattern: specs, doctrine, definitions
    beta/                 Relation: architecture, glossary, guides, evidence
    gamma/                 Evolution: method, plans, checklists
  test/                Unit and integration tests
```

### Agent hub (created by `cn init` + `cn setup`)

```
cn-<name>/
  .cn/
    config.json        Hub configuration (env vars override)
    secrets.env        API keys (loaded by runtime, never committed)
    deps.json          Dependency manifest (profile + packages)
    deps.lock.json     Pinned lockfile (source, rev, subdir)
    vendor/
      packages/        Installed cognitive packages
        cnos.core@1.0.0/  Doctrine, mindsets, core skills
        cnos.eng@1.0.0/   Engineering skills (or cnos.pm for PM profile)
  spec/                SOUL.md, USER.md — agent identity
  threads/
    in/                Direct inbound (non-mail)
    mail/              inbox/, outbox/, sent/ — peer communication
    doing/             Active work
    archived/          Completed items
    adhoc/             Agent-created threads
    reflections/       daily/, weekly/, monthly/
  state/
    queue/             FIFO processing queue
    input.md           Current LLM input (transient, crash-recovery)
    output.md          Current LLM output (transient, crash-recovery)
    conversation.json  Recent conversation history (last 50 turns)
    finalized/         ops_done markers (idempotency)
    projected/         Projection markers (reply dedup)
    receipts/          CN Shell execution receipts (per trigger)
    peers.md           Peer registry
    agent.lock         Atomic lock (prevents cron overlap)
    telegram.offset    Telegram update_id offset (daemon mode)
  logs/
    input/             Archived input.md files (audit trail)
    output/            Archived output.md files (audit trail)
```

---

## Documentation

| Start here | |
|-----------|---|
| [ARCHITECTURE.md](./docs/beta/ARCHITECTURE.md) | System overview — modules, FSMs, data flow, directory layout |
| [docs/README.md](./docs/README.md) | Full documentation index with reading paths |

| Design | |
|--------|---|
| [COHERENCE-SYSTEM.md](./docs/alpha/COHERENCE-SYSTEM.md) | Meta-model — coherence as primary; MCP/CMP/CAP/CLP across scales |
| [CAA.md](./docs/alpha/CAA.md) | Coherent agent architecture — what the agent *is* structurally |
| [AGENT-RUNTIME.md](./docs/alpha/AGENT-RUNTIME.md) | Agent runtime spec (v3.3.6) — CN Shell, typed ops, two-pass, receipts |
| [MANIFESTO.md](./docs/alpha/MANIFESTO.md) | Why cnos exists. Principles and values. |
| [THESIS.md](./docs/THESIS.md) | System thesis — cnos as a recurrent coherence system |
| [WHITEPAPER.md](./docs/alpha/WHITEPAPER.md) | CN protocol specification (v3.0.0) |
| [PROTOCOL.md](./docs/alpha/PROTOCOL.md) | The four FSMs — state diagrams, transition tables |
| [CLI.md](./docs/alpha/CLI.md) | CLI command reference |
| [SECURITY-MODEL.md](./docs/alpha/SECURITY-MODEL.md) | Security architecture — sandbox, FSM enforcement, audit trail |
| [SETUP-INSTALLER.md](./docs/alpha/SETUP-INSTALLER.md) | Install script specification |

| How-to | |
|--------|---|
| [HANDSHAKE.md](./docs/beta/guides/HANDSHAKE.md) | Establish peering between two agents |
| [AUTOMATION.md](./docs/beta/guides/AUTOMATION.md) | Set up cron or Telegram daemon |
| [MIGRATION.md](./docs/beta/guides/MIGRATION.md) | Migrate from older versions |
| [WRITE-A-SKILL.md](./docs/beta/guides/WRITE-A-SKILL.md) | Write a new skill |

---

## Contributing

Fork, branch, make changes, run `dune runtest`, submit.

Commit style: `type: short description` — types: `feat`, `fix`, `docs`, `chore`, `refactor`, `test`.

See [CONTRIBUTING.md](./CONTRIBUTING.md) for full guidelines.

---

[Apache License 2.0](./LICENSE)
