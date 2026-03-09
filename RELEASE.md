# v3.4.0 — Cognitive Asset Resolver

Fresh hubs now wake with the full cognitive substrate. No more silent incoherence — mindsets, skills, and agent-ops guidance are materialized at setup time and resolved at wake-up through a three-layer system.

## What's new

**2 new modules**, zero new runtime dependencies:

| Module | Purpose |
|--------|---------|
| `cn_assets` | Three-layer asset resolver: core → packages → hub-local overrides |
| `cn_deps` | Dependency manifest, lockfile, materialize/restore pipeline |

**Three-layer resolution:**
- **Layer A: Core** — bundled cognitive substrate (`.cn/vendor/core/`): mindsets, skills, agent-ops
- **Layer B: Packages** — installed dependencies (`.cn/vendor/packages/`): role-specific skill packs
- **Layer C: Hub-local** — personal overrides (`agent/mindsets/`, `agent/skills/`): highest priority

**`cn deps` commands:** `list`, `restore`, `doctor`, `add <pkg>`, `remove <pkg>`, `update`, `vendor`

**Wake-ready hubs:** `cn init` and `cn setup` materialize assets automatically. `cn_context.pack` fails fast if core assets are missing rather than silently packing an empty prompt.

**Cognitive Assets block:** The capabilities section now includes an asset summary so the agent knows its cognitive substrate composition on every wake-up.

## Upgrade

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
cn setup   # materializes assets in existing hubs
```

## Full changelog

See [CHANGELOG.md](https://github.com/usurobor/cnos/blob/main/CHANGELOG.md#v340-2026-03-09) for details.
