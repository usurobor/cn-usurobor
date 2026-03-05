# CN Security Model

**Status:** Current
**Date:** 2026-03-05
**Author:** usurobor (aka Axiom)  
**Contributors:** Sigma  

---

## Principle

Security by architecture: the agent has no direct access to git or filesystem. All effects go through `cn`, which acts as a sandboxed gatekeeper.

## Architecture

```
+-------------------------------------+
|           Agent (brain)             |
|  Reads:   state/input.md           |
|  Writes:  state/output.md          |
|  NO exec, NO direct fs, NO git     |
+----------------+--------------------+
                 | state/output.md
                 v
+-------------------------------------+
|            cn (body)                |
|  Sandboxed to hub directory         |
|  Critical files protected           |
|  All effects logged                 |
|  State transitions validated (FSMs) |
+-------------------------------------+
```

The agent interacts with exactly two files. `cn` reads the output, validates the requested operations against FSM state transitions, and executes only valid ones. See [PROTOCOL.md](PROTOCOL.md) for the typed state machines that enforce protocol correctness.

## Attack Surface Reduction

| Vector | Status | How |
|--------|--------|-----|
| Arbitrary commands | Blocked | No direct exec; governed exec under allowlist + budgets + receipts (see CN Shell Addendum) |
| System files | Blocked | Paths must be within hub |
| Other repos | Blocked | Git ops scoped to hub + peers |
| Identity theft | Blocked | Critical files protected |
| Untraced actions | Blocked | All IO pairs archived |
| Invalid state transitions | Blocked | FSM validation (compile-time exhaustive) |

## Protected Files

cn refuses to delete or overwrite:

- `spec/SOUL.md` — agent identity
- `spec/USER.md` — user context
- `state/peers.md` — peer configuration

## Audit Trail

Every agent invocation is archived as an IO pair:

```
logs/input/{trigger}.md      What the agent saw
logs/output/{trigger}.md     What the agent decided
```

Additionally, `cn out` commands create per-run archives:

```
logs/runs/{timestamp}-{id}/input.md
```

See [LOGGING.md](LOGGING.md) for full logging architecture.

## Sandbox Boundaries

### Agent CAN:

- Read `state/input.md` (one thread at a time, provided by cn)
- Write `state/output.md` (decision + content)
- Express operations: ack, done, fail, reply, send, delegate, defer, delete, surface
- Request commits via `cn commit`
- Send messages via `cn outbox`
- Receive messages via `cn inbox`

### Agent CANNOT:

- Execute shell commands directly (governed exec via typed ops requires allowlist + budget + receipt)
- Access files outside hub
- Read/write arbitrary files directly (only input.md/output.md for agent I/O; typed ops may access additional hub paths under governance)
- Modify git history directly
- Delete protected files
- Forge log entries
- Bypass FSM state validation

## Peer Communication

Peer-to-peer communication is sandboxed:

- **Outbound:** Agent writes to `threads/mail/outbox/`, cn pushes to peer's clone
- **Inbound:** cn fetches from peers, materializes to `threads/mail/inbox/`
- **Orphan rejection:** Receiver FSM rejects branches with no matching thread

Agent never touches remote repos directly.

## FSM Enforcement

The four typed FSMs in `cn_protocol.ml` provide compile-time safety:

| FSM | What it prevents |
|-----|-----------------|
| Thread Lifecycle | Invalid GTD transitions (e.g., `do` on already-doing thread) |
| Actor Loop | Double-processing of inbox items |
| Transport Sender | Unconfirmed deliveries, silent push failures |
| Transport Receiver | Branches not cleaned after materialization |

All transition functions return `Ok state | Error string`. Invalid transitions are errors, not silent bugs.

## CN Shell Addendum (v3.3+)

The CN Shell capability runtime ([AGENT-RUNTIME-v3.md](AGENT-RUNTIME-v3.md), §CN Shell) introduces governed post-call capabilities (`fs_read`, `fs_write`, `git_diff`, `exec`, etc.) that extend the agent's vocabulary beyond coordination ops. This does NOT change the core security architecture — it refines it:

| Property | Pre-CN Shell | With CN Shell |
|----------|-------------|---------------|
| In-call FS/exec access | None | None — unchanged |
| Direct exec authority | None | None — unchanged |
| Post-call capabilities | Coordination ops only | Coordination ops + typed ops (governed) |
| Exec authority | Blocked entirely | Governed: allowlisted commands, budget-capped, receipted |
| FS access | `input.md` / `output.md` only | `input.md` / `output.md` for agent I/O; typed ops may read/write additional paths under governance |
| Audit | IO pair archival | IO pair archival + per-op receipts + artifact hashing |

**Key invariants preserved:**

1. **No in-call tool loop** — the agent cannot invoke capabilities during generation. All capability execution is post-call, after output is archived.
2. **All effects are governed** — every typed op is validated (schema, policy, budgets) before execution. Invalid ops are denied with receipts.
3. **Full traceability** — typed ops produce receipts (`state/receipts/<trigger_id>.json`) and artifacts (`state/artifacts/<trigger_id>/`), extending the existing IO-pair audit trail.
4. **Identity preserved** — protected files remain protected; typed ops cannot write to `spec/SOUL.md`, `spec/USER.md`, or `state/peers.md`.

**Corrected phrasing:** "No exec access" becomes "no direct exec; only governed exec under allowlist + budgets + receipts." The agent still cannot execute arbitrary commands — it proposes ops, and `cn` decides whether to execute them.

## Why This Matters

1. **Agent can't go rogue** — all actions constrained by cn
2. **Full traceability** — every IO pair archived with trigger ID
3. **Identity preserved** — SOUL.md cannot be self-modified
4. **Peer isolation** — can't attack other agents' repos
5. **Protocol correctness** — FSMs enforce valid state transitions at type level

## Implementation

Security is enforced across the module stack:

| Module | Enforcement |
|--------|------------|
| `cn_protocol.ml` | FSM state transition validation |
| `cn_agent.ml` | IO pair archival, op execution |
| `cn_mail.ml` | Inbox/outbox scoped to peer clones |
| `cn_commands.ml` | Peer add/remove, commit/push scoped to hub |
| `cn_hub.ml` | Hub discovery, path constants |

See [ARCHITECTURE.md](../ARCHITECTURE.md) for module structure and dependency layers.
