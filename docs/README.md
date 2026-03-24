# cnos Documentation

A recurrent coherence system with Git as its lowest durable substrate.

**Version:** 3.13.0
**Date:** 2026-03-23

---

## Start Here

**[THESIS.md](./THESIS.md)** — what cnos is. The whole, above the triad.

Then choose your path:

| You want to... | Start with |
|----------------|------------|
| Understand what cnos is | [THESIS.md](./THESIS.md) → [COHERENCE-SYSTEM.md](./alpha/doctrine/COHERENCE-SYSTEM.md) → [FOUNDATIONS.md](./alpha/doctrine/FOUNDATIONS.md) |
| Build or run a cnos agent | [AGENT-RUNTIME.md](./alpha/agent-runtime/AGENT-RUNTIME.md) → [CLI.md](./alpha/cli/CLI.md) → [HANDSHAKE.md](./beta/guides/HANDSHAKE.md) |
| Contribute code | [CDD.md](./gamma/CDD.md) → [AGILE-PROCESS.md](./gamma/AGILE-PROCESS.md) → [ARCHITECTURE.md](./beta/ARCHITECTURE.md) |
| Understand the runtime extensions model | [RUNTIME-EXTENSIONS.md](./alpha/runtime-extensions/RUNTIME-EXTENSIONS.md) → [runtime-extensions bundle](./alpha/runtime-extensions/) |
| Write or modify a skill | [WRITE-A-SKILL.md](./beta/guides/WRITE-A-SKILL.md) → [COGNITIVE-SUBSTRATE.md](./alpha/cognitive-substrate/COGNITIVE-SUBSTRATE.md) |
| Do a release | [release skill](../packages/cnos.core/skills/release/SKILL.md) → [BUILD-RELEASE.md](./beta/guides/BUILD-RELEASE.md) |

---

## Reading Model

The docs tree has two dimensions:

### Triad axis — ontological character

Every document has a dominant axis. Read top-down for breadth.

| Axis | Directory | Question |
|------|-----------|----------|
| **Whole** | `docs/` | What is cnos? |
| **α Pattern** | `docs/alpha/` | What has been articulated? |
| **β Relation** | `docs/beta/` | Do the parts cohere? |
| **γ Evolution** | `docs/gamma/` | How does it change? |

### Feature bundles — depth within a feature

Related documents (spec, snapshots, design docs) are grouped into **feature bundles** within `alpha/`. Read into a bundle for depth on a single feature.

| Bundle | Canonical spec | What it covers |
|--------|---------------|----------------|
| [agent-runtime/](./alpha/agent-runtime/) | [AGENT-RUNTIME.md](./alpha/agent-runtime/AGENT-RUNTIME.md) | CN Shell, typed ops, N-pass orchestration, receipts |
| [runtime-extensions/](./alpha/runtime-extensions/) | [RUNTIME-EXTENSIONS.md](./alpha/runtime-extensions/RUNTIME-EXTENSIONS.md) | Capability providers, discovery, isolation |

See [DOCUMENTATION-SYSTEM.md](./beta/DOCUMENTATION-SYSTEM.md) for the full taxonomy and rules.

---

## The Triad

### α — Pattern: What Is Articulated

The substance of the system — doctrine, specs, definitions.

*"What has been made explicit? Is it internally consistent?"*

**Anchor docs** (canonical, evolve in place):

| Document | Scope |
|----------|-------|
| [COHERENCE-SYSTEM.md](./alpha/doctrine/COHERENCE-SYSTEM.md) | Meta-model: coherence as primary; the instruction set |
| [FOUNDATIONS.md](./alpha/doctrine/FOUNDATIONS.md) | The coherence stack — doctrinal layers |
| [MANIFESTO.md](./alpha/doctrine/MANIFESTO.md) | Principles and values |
| [CAA.md](./alpha/agent-runtime/CAA.md) | Coherent agent architecture |
| [AGENT-RUNTIME.md](./alpha/agent-runtime/AGENT-RUNTIME.md) | Runtime spec: CN Shell, typed ops, N-pass orchestration, receipts |
| [RUNTIME-EXTENSIONS.md](./alpha/runtime-extensions/RUNTIME-EXTENSIONS.md) | Capability providers, discovery, and isolation |
| [COGNITIVE-SUBSTRATE.md](./alpha/cognitive-substrate/COGNITIVE-SUBSTRATE.md) | Cognitive asset classes — doctrine, mindsets, skills |
| [CAR.md](./alpha/cognitive-substrate/CAR.md) | Cognitive asset resolver — local, versioned cognition |
| [WHITEPAPER.md](./alpha/protocol/WHITEPAPER.md) | CN protocol specification (v3.0.0) |
| [PROTOCOL.md](./alpha/protocol/PROTOCOL.md) | FSM design — state diagrams, transition tables |
| [TRACEABILITY.md](./alpha/security/TRACEABILITY.md) | Observability — event stream, state projections, readiness |
| [SECURITY-MODEL.md](./alpha/security/SECURITY-MODEL.md) | Security architecture — sandbox, FSM enforcement, audit trail |
| [CLI.md](./alpha/cli/CLI.md) | CLI command reference |
| [DAEMON.md](./alpha/cli/DAEMON.md) | Daemon mode design |
| [SETUP-INSTALLER.md](./alpha/cli/SETUP-INSTALLER.md) | Install script specification |
| [THREAD-API.md](./alpha/protocol/THREAD-API.md) | Agent content API |

**Feature-scoped design docs** (version-stamped, see [migration path](./beta/DOCUMENTATION-SYSTEM.md#6-migration-path-for-legacy-filenames)):

| Document | Feature | Version |
|----------|---------|---------|
| [RUNTIME-CONTRACT-v3.10.0.md](./alpha/RUNTIME-CONTRACT-v3.10.0.md) | Wake-up self-model contract | 3.10.0 |
| [N-PASS-BIND-v3.8.0.md](./alpha/N-PASS-BIND-v3.8.0.md) | N-pass bind loop and indicators | 3.8.0 |
| [SYSCALL-SURFACE-v3.8.0.md](./alpha/SYSCALL-SURFACE-v3.8.0.md) | Syscall surface redesign | 3.8.0 |
| [SCHEDULER-v3.7.0.md](./alpha/SCHEDULER-v3.7.0.md) | Scheduler design | 3.7.0 |
| [CTB-v4.0.0-VISION.md](./alpha/ctb/CTB-v4.0.0-VISION.md) | CTB v4.0.0 vision: skill language | 4.0.0 |

**Feature bundles:**

| Bundle | Contents |
|--------|----------|
| [agent-runtime/](./alpha/agent-runtime/) | Runtime spec, CAA, runtime contract, version-scoped design docs |
| [cli/](./alpha/cli/) | CLI reference, daemon mode, setup installer |
| [cognitive-substrate/](./alpha/cognitive-substrate/) | Cognitive asset classes, CAR resolver |
| [ctb/](./alpha/ctb/) | CTB v4.0.0 vision |
| [doctrine/](./alpha/doctrine/) | Coherence system, foundations, manifesto |
| [protocol/](./alpha/protocol/) | Whitepaper, protocol FSMs, thread API |
| [runtime-extensions/](./alpha/runtime-extensions/) | Extensions spec, version snapshots |
| [security/](./alpha/security/) | Security model, traceability |

### β — Relation: How Parts Cohere

The graph of relations — system overview, shared vocabulary, operator connection, model-reality evidence.

*"Do the parts reveal one system? Does model match reality?"*

| Document | Scope |
|----------|-------|
| [ARCHITECTURE.md](./beta/ARCHITECTURE.md) | System overview — how the parts relate |
| [GLOSSARY.md](./beta/GLOSSARY.md) | Terms and definitions |
| [NAMING.md](./beta/NAMING.md) | Naming conventions (CN, cnos, cn) |
| [DOCUMENTATION-SYSTEM.md](./beta/DOCUMENTATION-SYSTEM.md) | How docs are organized and evolve (this system) |
| [ORIGIN.md](./beta/ORIGIN.md) | How CNOS came to be — from Joscha's objection to Git substrate |
| [LINEAGE.md](./beta/LINEAGE.md) | Structural lineage and acknowledgments |
| [β/guides/](./beta/guides/) | Operator ↔ system: handshake, automation, migration, skills, dojo, build/release |
| [β/evidence/](./beta/evidence/) | Model ↔ reality: audit, RCAs |

### γ — Evolution: How the System Moves

The process that moves the system — method, plans, gates.

*"How does it change without losing itself?"*

| Document | Scope |
|----------|-------|
| [CDD.md](./gamma/CDD.md) | Coherence-driven development |
| [AGILE-PROCESS.md](./gamma/AGILE-PROCESS.md) | Team process — backlog, review, sync cadence |
| [EXECUTABLE-SKILLS.md](./gamma/EXECUTABLE-SKILLS.md) | Vision: skills as programs |
| [STATELESS-AGENCY.md](./gamma/STATELESS-AGENCY.md) | Position: stop chatting, start committing |
| [INVARIANTS.md](./gamma/INVARIANTS.md) | Structural invariants and CI enforcement |
| [γ/plans/](./gamma/plans/) | Implementation plans for specific releases |
| [γ/checklists/](./gamma/checklists/) | Review checklists by discipline |

---

## Directory Map

```
docs/
├── THESIS.md                          # The whole
├── README.md                          # This file — navigation
├── alpha/                             # α Pattern
│   ├── agent-runtime/                 # Runtime spec, CAA, runtime contract
│   │   ├── README.md
│   │   ├── AGENT-RUNTIME.md           # Canonical spec (v3.8.0)
│   │   ├── CAA.md                     # Coherent agent architecture
│   │   ├── RUNTIME-CONTRACT-v2.md     # Runtime contract v2
│   │   └── 3.x.0/                    # Version-scoped design docs
│   ├── cli/                           # CLI, daemon, installer
│   │   ├── CLI.md, DAEMON.md, SETUP-INSTALLER.md
│   ├── cognitive-substrate/           # Cognitive assets, CAR
│   │   ├── COGNITIVE-SUBSTRATE.md, CAR.md
│   ├── ctb/                           # CTB vision
│   │   └── CTB-v4.0.0-VISION.md
│   ├── doctrine/                      # Coherence system, foundations, manifesto
│   │   ├── COHERENCE-SYSTEM.md, FOUNDATIONS.md, MANIFESTO.md
│   ├── protocol/                      # Whitepaper, protocol, thread API
│   │   ├── PROTOCOL.md, WHITEPAPER.md, THREAD-API.md
│   ├── runtime-extensions/            # Extensions spec + snapshots
│   │   ├── README.md
│   │   ├── RUNTIME-EXTENSIONS.md      # Canonical spec (v1.0.6)
│   │   └── 1.0.6/                    # Version directory
│   │       ├── README.md             # Snapshot manifest
│   │       └── SPEC.md               # Frozen spec at v1.0.6
│   ├── security/                      # Security model, traceability
│   │   ├── SECURITY-MODEL.md, TRACEABILITY.md
│   └── schemas/                       # JSON schemas
├── beta/                              # β Relation
│   ├── ARCHITECTURE.md
│   ├── GLOSSARY.md
│   ├── DOCUMENTATION-SYSTEM.md        # This documentation system
│   ├── guides/                        # Operator guides
│   └── evidence/                      # Audits, RCAs
└── gamma/                             # γ Evolution
    ├── CDD.md
    ├── AGILE-PROCESS.md
    ├── plans/                         # Implementation plans
    └── checklists/                    # Review checklists
```
