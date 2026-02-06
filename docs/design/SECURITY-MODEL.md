# CN Security Model

**Status:** Implemented  
**Created:** 2026-02-05

---

## Principle

Security by architecture: agent has no direct access to git or filesystem. All effects go through cn, which acts as a sandboxed gatekeeper.

## Architecture

```
┌─────────────────────────────────────┐
│           Agent (brain)             │
│  • Reads threads/                   │
│  • Writes action plans              │
│  • NO exec, NO direct fs, NO git    │
└──────────────┬──────────────────────┘
               │ action plans
               ▼
┌─────────────────────────────────────┐
│            cn (body)                │
│  • Sandboxed to hub directory       │
│  • Critical files protected         │
│  • All ops logged (audit trail)     │
│  • Controlled git operations        │
└─────────────────────────────────────┘
```

## Attack Surface Reduction

| Vector | Status | How |
|--------|--------|-----|
| Arbitrary commands | ❌ Blocked | No `exec` access |
| System files | ❌ Blocked | Paths must be within hub |
| Other repos | ❌ Blocked | Git ops scoped to hub + peers |
| Identity theft | ❌ Blocked | Critical files protected |
| Untraced actions | ❌ Blocked | All ops logged |

## Protected Files

cn refuses to delete or overwrite:
- `spec/SOUL.md` — agent identity
- `spec/USER.md` — user context
- `state/peers.md` — peer configuration

## Audit Trail

Every cn operation logged to `logs/cn.log`:

```jsonl
{"ts":"...","action":"write","path":"threads/foo.md","bytes":123,"result":"ok"}
{"ts":"...","action":"commit","message":"save work","result":"ok"}
{"ts":"...","action":"outbox.send","to":"pi","thread":"review.md","result":"ok"}
```

Append-only. Agent cannot modify logs.

## Sandbox Boundaries

### Agent CAN:
- Read any file in hub
- Write to `threads/` via `cn write`
- Request commits via `cn commit`
- Send messages via `cn outbox`
- Receive messages via `cn inbox`

### Agent CANNOT:
- Execute shell commands
- Access files outside hub
- Modify git history directly
- Delete protected files
- Forge log entries

## Peer Communication

Even peer-to-peer communication is sandboxed:
- Outbound: Agent writes to `threads/outbox/`, cn pushes to peer's clone
- Inbound: cn fetches from peers, materializes to `threads/inbox/`

Agent never touches remote repos directly.

## Why This Matters

1. **Agent can't go rogue** — all actions constrained by cn
2. **Full traceability** — every effect logged with timestamp
3. **Identity preserved** — SOUL.md cannot be self-modified
4. **Peer isolation** — can't attack other agents' repos
5. **Human oversight** — logs enable audit at any time

## Implementation

All cn commands enforce these boundaries:
- `cn write/append/mkdir/rm` — path validation
- `cn commit/push/save` — scoped to hub
- `cn inbox/outbox` — controlled peer access
- `logAction()` — mandatory logging

See `bin/cn` for implementation details.
