# Runtime Contract v2 — Vertical Self-Model (Issue #62)

**Status:** Design
**Depends on:** #63 (contract authority — shipped v3.12.2)
**Enables:** #65 (communications design)

---

## 1. Problem

The Runtime Contract v1 (issue #56) solved the "agent must not probe for self-knowledge" problem with three flat blocks: self_model, workspace, capabilities. But it treats all filesystem paths uniformly — the agent can't distinguish:

- Its constitutive identity (SOUL.md, doctrine) from its working memory (reflections)
- Its private runtime internals (.cn/, state/) from legitimate work surfaces (src/, docs/)
- Communication channels (outbox, peers) from storage

The agent must infer these boundaries through probing, which is exactly what the contract was supposed to eliminate.

## 2. Design

Replace the flat three-block contract with a **four-layer vertical self-model**:

### 2.1 Identity — "Who am I?"

| Field | Source |
|-------|--------|
| `cn_version` | `Cn_lib.version` |
| `hub_name` | `Filename.basename hub_path` |
| `profile` | `assets.profile` or `"engineer"` |

### 2.2 Cognition — "What shapes my thinking?"

| Field | Source |
|-------|--------|
| `installed_packages` | Package inventory with doctrine/mindset/skill counts |
| `active_overrides` | Hub-local overrides by category |

### 2.3 Body — "What can my body do?"

| Field | Source |
|-------|--------|
| `capabilities` | observe/effect kinds, apply_mode, exec_enabled, budgets |
| `peers` | Known peer names for coordination ops |

Capabilities move under body — they describe the runtime's physical abilities, not the agent's identity or world.

### 2.4 Medium — "What world do I inhabit?"

Replaces the flat `workspace` block with **zone-classified paths**:

| Zone | Meaning | Paths |
|------|---------|-------|
| `constitutive_self` | Identity substrate — cannot be modified by agent | `spec/SOUL.md`, `spec/USER.md`, installed doctrine, installed mindsets |
| `memory` | Temporal record — agent's reflections and conversation | `threads/reflections/`, `state/conversation.json` |
| `private_body` | Runtime internals — opaque to agent | `.cn/`, `state/` (except conversation.json), `logs/` |
| `work_medium` | Legitimate work surfaces | `src/`, `docs/`, `agent/` |
| `projection_surface` | Communication channels | `threads/outbox/`, peer sync surfaces |

## 3. Migration Mapping

| v1 | v2 |
|----|-----|
| `self_model.cn_version` | `identity.cn_version` |
| `self_model.hub_name` | `identity.hub_name` |
| `self_model.profile` | `identity.profile` |
| `self_model.installed_packages` | `cognition.installed_packages` |
| `self_model.active_overrides` | `cognition.active_overrides` |
| `workspace.directories` | `medium.zones` (classified) |
| `workspace.writable` | Derived from zone classification |
| `workspace.protected` | Derived from zone classification |
| `capabilities` | `body.capabilities` |
| `peers` | `body.peers` |

## 4. JSON Schema

```json
{
  "schema": "cn.runtime_contract.v2",
  "identity": {
    "cn_version": "3.13.0",
    "hub_name": "my-agent",
    "profile": "engineer"
  },
  "cognition": {
    "installed_packages": [...],
    "active_overrides": { "doctrine": [], "mindsets": [], "skills": [] }
  },
  "body": {
    "capabilities": {
      "observe": [...],
      "effect": [...],
      "apply_mode": "branch",
      "exec_enabled": false,
      "max_passes": 5,
      "budgets": { ... }
    },
    "peers": ["sigma"]
  },
  "medium": {
    "zones": [
      { "path": "spec/SOUL.md", "zone": "constitutive_self" },
      { "path": "threads/reflections/", "zone": "memory" },
      { "path": ".cn/", "zone": "private_body" },
      { "path": "src/", "zone": "work_medium" },
      { "path": "threads/outbox/", "zone": "projection_surface" }
    ]
  }
}
```

## 5. Markdown Rendering

```markdown
## Runtime Contract

**Authority:** [preserved from #63]

### Identity
cn_version: 3.13.0
hub_name: my-agent
profile: engineer

### Cognition
installed_packages:
  - cnos.core (6 doctrine, 2 mindsets, 0 skills)
  - cnos.eng (0 doctrine, 0 mindsets, 3 skills)
active_overrides: 0 (none)

### Body
[capabilities block — observe/effect/budgets]
peers: sigma

### Medium
constitutive_self: spec/SOUL.md, spec/USER.md
memory: threads/reflections/
private_body: .cn/, state/, logs/
work_medium: src/, docs/, agent/
projection_surface: threads/outbox/
```

## 6. Doctor Validation (v2)

Check for four top-level keys: `identity`, `cognition`, `body`, `medium`.

## 7. Invariant (preserved)

After wake, the agent MUST be able to answer from packed context alone:
- Who am I? → identity
- What shapes my thinking? → cognition
- What can my body do? → body
- What world do I inhabit? → medium

## 8. Non-goals

- No changes to `Cn_capabilities.render` internals (just moved under body)
- No changes to sandbox enforcement (Cn_sandbox is the execution-time guard)
- No schema migration for existing `state/runtime-contract.json` files (overwritten on next wake)
