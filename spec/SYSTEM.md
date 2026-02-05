# SYSTEM.md — How cn-agent Works

Definitive specification for cn-agent system operation.

---

## Core Principle

**Agent = brain. cn = body.**

- Agent: reads, thinks, decides (pure function, no side effects)
- cn: senses, executes, logs (all effects)

Agent never executes. cn never decides.

---

## The Inbox Loop

```
┌─────────────────────────────────────────────────────────┐
│                   cn inbox sync                         │
│                   (cron, every N min)                   │
├─────────────────────────────────────────────────────────┤
│ 1. Fetch all peer repos                                 │
│ 2. Detect inbound branches (<agent>/* in your repo)    │
│ 3. Materialize as threads/inbox/YYYYMMDD-peer-topic.md │
│ 4. Ping agent: "you have inbox"                         │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   Agent wakes                           │
│                   (on ping or heartbeat)                │
├─────────────────────────────────────────────────────────┤
│ 1. Read threads/inbox/*.md                              │
│ 2. For each: understand context, decide triage          │
│ 3. Write ## Triage section with decision                │
│ 4. NEVER execute anything directly                      │
└────────────────────────┬────────────────────────────────┘
                         ▼
┌─────────────────────────────────────────────────────────┐
│                   cn inbox process                      │
│                   (cron, after agent window)            │
├─────────────────────────────────────────────────────────┤
│ 1. Scan threads/inbox/*.md for ## Triage               │
│ 2. Parse decision (OCaml types validate)                │
│ 3. Execute: merge, delete branch, reply, etc.           │
│ 4. Move thread to threads/inbox/done/                   │
│ 5. Log to logs/inbox/YYYYMMDD.md                        │
└─────────────────────────────────────────────────────────┘
```

---

## Triage Vocabulary

Agent decisions must be one of:

```ocaml
type reason = Reason of string
type actor = Actor of string
type branch_name = BranchName of string
type description = Description of string

type action =
  | Merge
  | Reply of branch_name
  | Custom of description

type triage =
  | Delete of reason
  | Defer of reason
  | Delegate of actor
  | Do of action
```

If it's not in the type, agent can't decide it.

---

## Thread Format

### Incoming (created by cn inbox sync)

```markdown
# pi/proposal

**From:** pi
**Branch:** sigma/proposal
**Received:** 2026-02-05T14:00Z

---

[Content: commit messages, changed files, thread content]
```

### After Agent Triage

```markdown
# pi/proposal

**From:** pi
**Branch:** sigma/proposal
**Received:** 2026-02-05T14:00Z

---

[Content]

---

## Triage

decision: do:merge
actor: sigma
timestamp: 2026-02-05T15:00Z
```

---

## Directory Structure

```
hub/
├── threads/
│   └── inbox/
│       ├── 20260205-pi-proposal.md     # pending
│       ├── 20260205-omega-review.md    # pending
│       └── done/
│           └── 20260205-pi-old.md      # processed
├── logs/
│   └── inbox/
│       └── 20260205.md                 # audit trail
└── state/
    └── ...
```

---

## Cron Schedule

```cron
# Fetch and materialize inbound
*/5 * * * * cn inbox sync /path/to/hub

# Process triaged items
*/15 * * * * cn inbox process /path/to/hub
```

Adjust intervals based on coordination needs.

---

## Agent Purity Constraint

**Agent has no side effects.**

| Agent can | Agent cannot |
|-----------|--------------|
| Read threads | Run git commands |
| Read context/skills | Make network calls |
| Write decisions to threads | Move files |
| | Delete anything |
| | Execute scripts |

All effects go through cn. No exceptions.

---

## cn Operations

Complete set of operations cn can execute:

| Operation | Trigger | Effect |
|-----------|---------|--------|
| `sync` | cron | Fetch, materialize threads |
| `process` | cron | Execute triage decisions |
| `merge` | `Do Merge` decision | git merge --no-ff |
| `delete-branch` | `Delete` decision | git push --delete (with ownership check) |
| `reply` | `Do Reply` decision | Create reply branch, push to peer |
| `notify` | various | Push thread to peer's repo |
| `log` | after any action | Write to logs/ |

If operation not listed, cn can't do it.

---

## Protocol Enforcement

cn must enforce:

| Rule | How |
|------|-----|
| Only creator deletes branch | Check branch prefix matches actor |
| Merge requires APPROVED | Check ## Triage has approval |
| Rebase before merge | Check branch on latest main |
| No self-merge | Check reviewer ≠ author |
| Valid triage type | OCaml type parsing |

---

## Logging

Every action logged to `logs/inbox/YYYYMMDD.md`:

```markdown
# Inbox Log: 2026-02-05

| Time | Source | Decision | Executed |
|------|--------|----------|----------|
| 14:00 | pi/proposal | received | — |
| 15:00 | pi/proposal | do:merge | ✓ merged |
| 15:30 | omega/stale | delete:stale | ✓ deleted |
```

Full traceability. Every decision, every action.

---

## Why This Architecture

1. **Testability** — Agent is pure function: input → decision. No mocking.
2. **Reliability** — Protocol enforced by cn, not agent trust.
3. **Debuggability** — All decisions logged, execution separate.
4. **Separation** — Tokens for thinking, electrons for clockwork.

---

## Future: Runtime Enforcement

Current runtime (OpenClaw) allows agent to bypass cn.

Goal: Runtime that enforces agent purity — agent can ONLY issue decisions, cannot execute directly.

---

*"Agent decides. cn executes. Everything is logged."*
