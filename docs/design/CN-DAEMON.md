# CN Daemon Architecture

**Status:** Future design  
**Created:** 2026-02-05

---

## Vision

cn evolves from CLI tool to lightweight agent runtime service, replacing OpenClaw for cn-agent deployments.

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
4. **Self-contained**: One install (`npm i -g cnagent`) gets everything.

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

## Open Questions

- Daemon process management (systemd? pm2? native?)
- Plugin discovery and loading
- Config format (extend cn.json?)
- How to handle telegram auth/tokens
- LLM API key management

---

*This doc captures direction. Implementation TBD.*
