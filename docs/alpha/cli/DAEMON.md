# CN Daemon Architecture

**Status:** Partially realized (v3.7.0 unified scheduler)
**Created:** 2026-02-05
**Updated:** 2026-03-12

> **See also:** [SCHEDULER-v3.7.0](SCHEDULER-v3.7.0.md) — the unified scheduler
> design that implements the core of this vision. The plugin architecture below
> remains a future direction.

---

## Vision

cn evolves from CLI tool to lightweight agent runtime service, replacing OpenClaw for cnos deployments.

## Implemented (v3.7.0)

The daemon now runs the unified protocol loop with two activity sources:

```
[cn agent --daemon]
├── exteroception  → Telegram poll (optional) → immediate drain
│   (sensor-driven)  Future: webhooks, other transports
├── interoception  → maintain_once (sync, inbox, outbox, update, review, cleanup) → bounded drain
│   (self-driven)    Periodic timer at sync_interval_sec
└── process_one    → shared processing engine (same as oneshot)
```

cn is the service. Agent is passive — cn invokes it when needed.
Telegram is optional — daemon works peer-only (interoception only).

## Original Future Vision (plugin architecture)

```
[cn daemon]
├── cron plugin      → scheduling (replaces OC cron + system cron)
├── telegram plugin  → messaging (send/receive)
├── llm plugin       → agent invocation (Claude API direct)
└── git plugin       → coordination (fetch, push, branch ops)
```

The plugin interface remains a future direction beyond v3.7.0.

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

1. ~~**Now**: System cron + OC for agent invocation~~ (completed)
2. ~~**Next**: cn daemon with cron plugin, still uses OC for telegram/LLM~~ (completed — v3.7.0)
3. **Current**: Unified scheduler — daemon and oneshot both run full protocol loop
4. **Later**: Plugin architecture for extensible transports and capabilities

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

- ~~Daemon process management~~ → systemd (documented in [AUTOMATION.md](../how-to/AUTOMATION.md))
- Plugin discovery and loading (future)
- ~~Config format~~ → `.cn/config.json` with `runtime.scheduler` block
- ~~Telegram auth/tokens~~ → `.cn/secrets.env` or env vars
- ~~LLM API key management~~ → ANTHROPIC_KEY via Cn_dotenv

---

*Original vision doc. See [SCHEDULER-v3.7.0](SCHEDULER-v3.7.0.md) for current implementation.*
