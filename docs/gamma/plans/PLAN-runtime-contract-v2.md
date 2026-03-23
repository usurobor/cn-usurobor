# Implementation Plan: Runtime Contract v2 (Issue #62)

**Branch:** `claude/runtime-contract-v2-VWKUT`
**Base:** v3.12.2 (origin/main)

---

## Steps

### 1. Refactor types in cn_runtime_contract.ml

Replace `runtime_contract` flat type with four-layer structure:
- `identity` record: cn_version, hub_name, profile
- `cognition` record: packages, overrides
- `body_contract` record: capabilities fields + peers
- `medium_zone` type: zone classification per path
- `runtime_contract` wraps all four

Keep `package_info` and `override_info` unchanged.

### 2. Add zone classification

Define zone type: `Constitutive_self | Memory | Private_body | Work_medium | Projection_surface`

Classify paths based on:
- `spec/SOUL.md`, `spec/USER.md` → constitutive_self
- Installed doctrine/mindsets → constitutive_self
- `threads/reflections/` → memory
- `state/conversation.json` → memory
- `.cn/`, `state/`, `logs/` → private_body
- `src/`, `docs/`, `agent/` → work_medium
- `threads/outbox/` → projection_surface

### 3. Update gather function

Reorganize gathering into four layers. Same data sources, new structure.

### 4. Update render_markdown

Four sections: Identity, Cognition, Body, Medium.
Preserve Authority preamble from #63.
Capabilities text goes under Body.
Zone listing under Medium.

### 5. Update to_json

Schema: `cn.runtime_contract.v2`
Four top-level keys: identity, cognition, body, medium.
Capabilities nested under body.

### 6. Update cn_system.ml doctor

Check for: identity, cognition, body, medium (instead of self_model, workspace, capabilities).

### 7. Update cn_context.ml

No changes needed — calls `render_markdown` which handles the new format.

### 8. Update COGNITIVE-SUBSTRATE.md §6.1

Update sub-block descriptions from three to four.

### 9. Update tests

- Existing contract tests: update expect strings for new block names
- Add zone classification tests
- Verify JSON/markdown parity on new schema

### 10. Version bump

Update cn_lib.ml version to 3.13.0 (minor: new schema, additive capability).

---

## Risk boundaries

- `Cn_capabilities.render` is NOT modified — it's called as before, just placed under Body
- `Cn_sandbox` enforcement is NOT modified — zones are declarative, not enforcement
- No changes to conversation loading, boot sequence, or LLM call structure
