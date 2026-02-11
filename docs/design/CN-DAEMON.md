# CN Daemon Architecture

**Status:** Future design  
**Created:** 2026-02-05

---

## Vision

cn evolves from CLI tool to lightweight agent runtime service, replacing OpenClaw for cnos deployments.

## Current State

```
[System Cron] → cn inbox check → [OpenClaw] → Agent
                                      ↑
                              (messaging, LLM invocation)
```

OpenClaw provides: cron, telegram integration, LLM invocation, session management.

## Future State

```
[cn daemon]
├── cron plugin      → scheduling (replaces OC cron + system cron)
├── telegram plugin  → messaging (send/receive)
├── llm plugin       → agent invocation (Claude API direct)
└── git plugin       → coordination (fetch, push, branch ops)
```

cn becomes the service. Agent is passive — cn invokes it when needed.

## Design Principles

1. **Agent purity**: Agent = pure function. cn = effectful shell.
2. **Plugin architecture**: Each capability is a plugin, not hardcoded.
3. **Minimal footprint**: Lean service, no heavy dependencies.
4. **Self-contained**: One install (curl | sh) gets everything.

## Agent Communication Model

Agents publish **action plans** as prose. cn interprets and executes.

### Two paths for outbound:

1. **Reply on inbox thread**
   - cn materializes inbound branch → `threads/mail/inbox/pi-clp.md`
   - Agent writes reply at bottom of thread
   - cn detects reply, sends back to peer

2. **New outbound thread**
   - Agent creates `threads/mail/outbox/review-req.md`
   - cn scans, picks up, sends to peer

### Thread structure:

```
threads/
├── mail/
│   ├── inbox/       ← cn materializes inbound here
│   │   └── pi-clp.md
│   ├── outbox/      ← agent creates new outbound here
│   │   └── review-req.md
│   └── sent/        ← delivered messages
├── doing/           ← active work items
├── deferred/        ← postponed items
├── archived/        ← completed items
└── adhoc/           ← regular threads (not scanned)
```

### cn sync flow:

1. Fetch inbound → materialize to `threads/mail/inbox/`
2. Scan `mail/inbox/` for replies → send back
3. Scan `mail/outbox/` for new threads → send

Agent never runs git. Agent writes prose. cn does effects.

## Plugin Interface (sketch)

```ocaml
type plugin = {
  name: string;
  init: config -> unit;
  tick: state -> action list;  (* called on each daemon loop *)
  handle: event -> action list;
}
```

## Migration Path

1. **Now**: System cron + OC for agent invocation
2. **Next**: cn daemon with cron plugin, still uses OC for telegram/LLM
3. **Later**: cn daemon with all plugins, OC optional

## Security Model

cn enforces security by architecture:

- **Sandboxing**: Agent has no direct git/fs access — all effects through cn
- **Path validation**: All file ops constrained to hub directory
- **Protected files**: Critical files (SOUL.md, USER.md, peers.md) cannot be deleted
- **Audit trail**: Every operation logged to `logs/cn.log`
- **Peer isolation**: Agent can't directly access other agents' repos

This means agents **cannot go rogue** — they can only affect their designated space through controlled, audited operations.

See [SECURITY-MODEL.md](./SECURITY-MODEL.md) for full details.

## Open Questions

- Daemon process management (systemd? pm2? native?)
- Plugin discovery and loading
- Config format (extend cn.json?)
- How to handle telegram auth/tokens
- LLM API key management

---

*This doc captures direction. Implementation TBD.*
