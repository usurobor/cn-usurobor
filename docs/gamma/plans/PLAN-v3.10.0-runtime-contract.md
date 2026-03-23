# PLAN-v3.10.0
## Wake-up Self-Model Contract

**Status:** Draft
**Date:** 2026-03-23
**Implements:** [`RUNTIME-CONTRACT-v3.10.0.md`](../../alpha/RUNTIME-CONTRACT-v3.10.0.md)
**Scope:** Replace overloaded capabilities block with structured Runtime Contract (self_model + workspace + capabilities).
**Issues:** #56

---

## 0. Coherence Contract

### Gap

The agent cannot determine its own version, packages, overrides, or workspace layout from packed context. The capabilities block is semantically overloaded.

### Mode

**MCA** — change context packing.

### Smallest coherent intervention

Factor the capabilities block into three sub-blocks. Add missing self-model fields. Persist to disk for operator inspection.

---

## 1. Compile-safe step order

### Step 1 — Define runtime_contract type

**Goal:** Define the structured contract type.

```ocaml
type package_info = {
  name : string;
  doctrine_count : int;
  mindset_count : int;
  skill_count : int;
}

type override_info = {
  doctrine : string list;
  mindsets : string list;
  skills : string list;
}

type runtime_contract = {
  cn_version : string;
  hub_name : string;
  profile : string;
  packages : package_info list;
  overrides : override_info;
  workspace_dirs : (string * string) list;
  writable : string list;
  protected : string list;
  capabilities_text : string;
}
```

#### Acceptance

Type compiles. No runtime changes yet.

---

### Step 2 — Implement gather function

**Goal:** Build the contract from runtime state.

```ocaml
val gather :
  hub_path:string ->
  config:Cn_config.config ->
  assets:Cn_assets.asset_summary ->
  peers:string list ->
  runtime_contract
```

Sources:
- `cn_version` from Cn_config or a version constant
- `hub_name` from `Filename.basename hub_path`
- `profile` from `assets.profile` or config
- `packages` from walking `.cn/vendor/packages/`
- `overrides` from walking `agent/doctrine/`, `agent/mindsets/`, `agent/skills/`
- `workspace_dirs` from checking which canonical dirs exist
- `writable`/`protected` from Cn_sandbox conventions
- `capabilities_text` from existing Cn_capabilities.render

#### Acceptance

gather produces a correct contract for a test hub.

---

### Step 3 — Implement render_markdown

**Goal:** Emit the contract as a markdown section for packed context.

```ocaml
val render_markdown : runtime_contract -> string
```

Produces the `## Runtime Contract` section with three sub-blocks.

#### Acceptance

Output is deterministic. Round-trips through parsing produce equivalent data.

---

### Step 4 — Implement to_json + write_to_disk

**Goal:** Persist the contract as structured JSON.

```ocaml
val to_json : runtime_contract -> Cn_json.t
val write : hub_path:string -> runtime_contract -> unit
```

Writes to `state/runtime-contract.json`.

#### Acceptance

JSON is valid and contains all contract fields.

---

### Step 5 — Wire into cn_context.ml

**Goal:** Replace Cn_capabilities.render call with Runtime Contract.

Replace the `Cn_capabilities.render ~assets ~peers sc` call with `Cn_runtime_contract.render_markdown contract`.

The capabilities rendering becomes a sub-block within the contract, not the top-level section.

#### Acceptance

Packed context contains `## Runtime Contract` with all three sub-blocks.

---

### Step 6 — Write contract at boot in cn_runtime.ml

**Goal:** Persist contract to disk at startup.

In the boot sequence, after assets are loaded, gather and write the contract.

#### Acceptance

`state/runtime-contract.json` exists after boot.

---

### Step 7 — Tests

#### 7.1 Unit tests (cn_runtime_contract_test.ml)

- gather produces correct contract for test hub
- render_markdown produces deterministic output
- render_markdown contains all three sub-blocks
- to_json contains all required fields
- No absolute paths in rendered markdown
- Empty overrides renders cleanly
- Multiple packages render in order

#### 7.2 Integration tests

- Packed context includes Runtime Contract section
- Existing capabilities ABI fields preserved

---

## 2. Estimated change surface

| Module | Impact |
|--------|--------|
| `cn_runtime_contract.ml` | **new** — ~200 LOC |
| `cn_context.ml` | small — replace one call |
| `cn_capabilities.ml` | none — retained as helper |
| `cn_runtime.ml` | small — write contract at boot |

---

## 3. Success criteria

1. Packed context contains `## Runtime Contract` with self_model, workspace, capabilities
2. `state/runtime-contract.json` written at boot
3. Agent can determine version, packages, overrides, layout from context alone
4. No absolute host paths in prompt-visible output
5. All existing tests pass
