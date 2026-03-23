# RUNTIME-CONTRACT-v3.10.0
## Wake-up Self-Model Contract

**Status:** Draft
**Version:** 3.10.0
**Date:** 2026-03-23
**Authors:** usurobor
**Scope:** Define a first-class Runtime Contract emitted at every wake, replacing the overloaded capabilities block with three structured sub-blocks: self_model, workspace, and capabilities.
**Issues:** #56

---

## 0. Coherence Contract

### Gap

The current runtime emits a single "CN Shell Capabilities" block that carries three semantically distinct jobs:
- **affordance**: what the runtime can do (observe/effect kinds, budgets)
- **instruction**: how the model should emit ops (syntax examples, formatting rules)
- **partial self-description**: package counts, profile, peer names

This means the agent cannot determine its own version, hub layout, installed packages, active overrides, or workspace structure from packed context alone. Pi v3.11.0 had to probe the filesystem for basic self-knowledge — a coherence failure.

### Mode

**MCA** — change the runtime context packing to emit a complete self-model.

### α / β / γ target

- **α PATTERN:** one structured contract with typed sub-blocks, not a markdown blob doing three jobs
- **β RELATION:** the agent's self-knowledge matches the runtime's actual state; no probing needed
- **γ EXIT:** adding new self-model fields is a contract addition, not a capabilities-block hack

### Smallest coherent intervention

Keep:
- Cn_context.pack as the entry point
- existing capabilities rendering for ABI declaration
- existing asset discovery and package resolution

Change only:
- factor the capabilities block into three sub-blocks: self_model, workspace, capabilities
- add the missing fields (version, hub name, directory layout, override details)
- emit a structured Runtime Contract section in packed context
- persist to state/runtime-contract.json for operator inspection

---

## 1. Core Decision

The runtime SHALL emit a structured Runtime Contract at every wake, replacing the overloaded capabilities block.

### 1.1 Three sub-blocks

**self_model** — who the agent is:
- `cn_version`: runtime binary version
- `hub_name`: hub directory name (not absolute path)
- `profile`: effective runtime role from config (maps to issue #56's `identity_role`; derived from package profile rather than SOUL.md prose)
- `installed_packages`: list of {name, version, skill_count}
- `active_overrides`: {doctrine: [...], mindsets: [...], skills: [...]}

**workspace** — what world the agent inhabits:
- `root`: "." (hub-relative)
- `directories`: {identity, overrides, reflections, state, packages, docs, src}
- `writable`: paths the agent may write to
- `protected`: paths denied by sandbox

**capabilities** — what the runtime can do:
- `observe`: list of observe op kinds
- `effect`: list of effect op kinds (when enabled)
- `apply_mode`, `exec_enabled`, `exec_allowlist`
- `max_passes`, budgets
- `peers`: known peer names

### 1.2 Invariant

After wake, the agent MUST be able to answer from packed context alone:
- What version am I?
- What packages do I have?
- What overrides are active?
- What directories exist and which are writable?
- What can my runtime do?

If the agent must probe the filesystem for any of these, the runtime contract is incomplete.

### 1.3 No raw host paths

The contract exposes hub-relative logical roots, not absolute host paths. The agent does not need `/home/axiom/.config/cn/agents/pi` to reason coherently.

---

## 2. Emission Format

The Runtime Contract is emitted as a markdown section in packed context:

```markdown
## Runtime Contract

### Self Model
cn_version: 3.10.0
hub_name: pi
profile: engineer
installed_packages: cnos.core (12 doctrine, 4 mindsets, 0 skills), cnos.eng (0 doctrine, 0 mindsets, 24 skills)
active_overrides: 1 skill override (agent/skills/cnos.eng/eng/review/SKILL.md)

### Workspace
root: .
identity: spec/ (SOUL.md, USER.md)
overrides: agent/ (doctrine/, mindsets/, skills/)
reflections: threads/reflections/ (daily/, weekly/)
state: state/ (artifacts/, receipts/)
packages: .cn/vendor/packages/
docs: docs/
src: src/
writable: src/**, docs/**, agent/**, threads/**
protected: .cn/**, state/receipts/**, state/artifacts/**, logs/**

### Capabilities
observe: fs_read, fs_list, fs_glob, git_status, git_diff, git_log, git_grep
effect: fs_write, fs_patch, git_branch, git_stage, git_commit
apply_mode: branch
exec_enabled: false
max_passes: 5
budgets: max_artifact_bytes=131072, max_artifact_bytes_per_op=16384, max_observe_ops=10, max_total_ops=32
peers: sigma
```

### 2.1 Why markdown, not JSON

The packed context is markdown for the LLM. Emitting JSON inside markdown adds parsing complexity for the model. Structured key-value markdown is readable by both the model and operators.

### 2.2 Deterministic ordering

All fields are emitted in a fixed order for prompt-cache stability.

---

## 3. Persistence

The same data is also written to `state/runtime-contract.json` as structured JSON for:
- operator inspection
- cn doctor validation
- traceability reference
- test assertions

---

## 4. Module Impact

### 4.1 New module: cn_runtime_contract.ml

Gathers all self-model data from:
- Cn_config (version, profile, shell config)
- Cn_assets (packages, overrides)
- Cn_sandbox (writable/protected paths)
- hub directory existence checks

Exposes:
- `type runtime_contract` — structured record
- `val gather` — build contract from runtime state
- `val render_markdown` — emit for packed context
- `val to_json` — emit for state/runtime-contract.json

### 4.2 Modified: cn_context.ml

Replace the `Cn_capabilities.render ~assets ~peers sc` call with `Cn_runtime_contract.render_markdown contract`.

### 4.3 Modified: cn_capabilities.ml

Retain as a helper for the capabilities sub-block rendering. No longer the top-level emitter.

### 4.4 Modified: cn_runtime.ml

Write `state/runtime-contract.json` at boot.

---

## 5. Acceptance Criteria

1. `Cn_context.pack` emits a `## Runtime Contract` section with self_model, workspace, and capabilities sub-blocks.
2. The agent can determine its version, packages, overrides, workspace layout, and capabilities from packed context alone.
3. `state/runtime-contract.json` is written at boot and contains the same data.
4. No absolute host paths appear in the prompt-visible contract.
5. Existing capabilities ABI (observe/effect kinds, budgets, examples) is preserved.
6. Deterministic field ordering for prompt-cache stability.

---

## 6. Non-goals

- No changes to the N-pass bind loop
- No changes to the FSM
- No new op kinds
- No changes to capability authority
- No structured output / tool_use changes (that's #52)

---

## 7. Summary

v3.10.0 replaces the overloaded capabilities block with a first-class Runtime Contract:
- **self_model** — version, hub, packages, overrides
- **workspace** — directory layout, writable/protected paths
- **capabilities** — observe/effect ABI, budgets, constraints

The result: probing for self-knowledge becomes a contract bug, not normal behavior.
