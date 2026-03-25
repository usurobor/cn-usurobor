# Self-Coherence Report — v3.17.0

**Issue:** #73 — Runtime Extensions Phase 1
**Branch:** `claude/review-issue-73-7yr26`
**Mode:** MCA — open op registry + subprocess host + first reference extension
**Date:** 2026-03-25

---

## 1. Acceptance Criteria Accounting

### AC1: A package can ship an extension without modifying core runtime code

**Status:** PARTIAL

**Evidence:**
- `src/agent/extensions/cnos.net.http/cn.extension.json` defines extension manifest
- `cn_extension.ml` discovers extensions from installed package layout (`extensions/<name>/cn.extension.json`)
- No core runtime code changes are needed to add a new extension — only a manifest + host binary

**Gap:** Build integration pending — `cn build` does not yet copy extensions from `src/agent/extensions/` to `packages/` output. A package cannot be shipped end-to-end without this step.

### AC2: cnos discovers installed extensions automatically at boot

**Status:** PASS

**Evidence:**
- `Cn_extension.discover ~hub_path` scans `.cn/vendor/packages/<pkg>@<ver>/extensions/<ext>/cn.extension.json`
- `Cn_extension.build_registry` runs the full lifecycle: discover → compatibility → conflict check → enablement → index
- Registry is built at context-pack time (`cn_context.ml`) and cycle start (`cn_runtime.ml`), so discovery runs on every wake and cycle
- Test: `cn_extension_test.ml` "discover: finds extension manifest" + "build_registry: full lifecycle"

### AC3: Runtime can dispatch extension-defined op kinds without core code changes

**Status:** PASS

**Evidence:**
- `cn_shell.ml` adds `Extension of string * string` variant to `op_kind`
- `parse_ops_manifest` accepts `~ext_lookup` parameter — registry lookup injected, not hardcoded
- `cn_output.ml` passes `~ext_lookup` derived from registry to `parse_ops_manifest`
- `cn_executor.ml` dispatches `Extension (kind_name, _class)` via `execute_extension_op` → `Cn_ext_host.execute_extension_op`
- `cn_orchestrator.ml` threads `~ext_registry` through `run_pass` to `execute_op`
- `cn_runtime.ml` builds registry once per cycle and passes it through the pipeline
- Adding new ops requires only a manifest entry, not code changes
- Test: `cn_extension_test.ml` "shell: extension op parsed via ext_lookup"

### AC4: Runtime Contract tells agent which extension ops exist and whether enabled

**Status:** PASS

**Evidence:**
- `cn_runtime_contract.ml` adds `extensions_installed` to cognition layer, `extensions_active` to body layer
- `Cn_capabilities.render` accepts `~ext_registry` and renders extension ops in a dedicated `### Extension Ops` section
- `cn_context.ml` builds the extension registry and passes `~ext_registry` to `gather`
- `to_json` includes `extensions_installed` in cognition and `extensions_active` in body
- `render_markdown` shows extension state (name, version, backend, status, ops)

### AC5: Extension execution is sandboxed and traced

**Status:** PARTIAL

**Evidence:**
- `cn_ext_host.ml` implements subprocess isolation (default backend)
- No ambient credentials — secrets must be injected explicitly
- `cn_executor.ml` emits `extension.op.start`, `extension.op.ok`, `extension.op.error` via `Cn_trace.gemit`
- `cn_extension.ml` emits `extension.discovered`, `extension.loaded`, `extension.rejected`, `extension.disabled`
- All events use existing structured traceability schema with component="extension"

**Gap:** Policy intersection not yet wired — domain allowlists, byte budgets, and secret injection are declared in manifests but runtime config does not yet intersect them. Sandboxing is structural (subprocess isolation) but not policy-complete.

### AC6: cn doctor validates extension compatibility and configuration

**Status:** PASS

**Evidence:**
- `cn_system.ml` adds extension health check to `run_doctor`
- Doctor builds the full registry and reports: total, enabled, rejected, disabled counts
- Rejected extensions cause doctor check to fail with details
- Doctor calls `Cn_ext_host.check_health` for each enabled extension and reports unhealthy hosts
- Compatible/disabled extensions report as healthy

### AC7: cnos.net.http proves the model by shipping http_get as first extension

**Status:** PARTIAL

**Evidence:**
- `src/agent/extensions/cnos.net.http/cn.extension.json` — complete manifest
- Defines `http_get` (observe) and `dns_resolve` (observe) ops
- Subprocess backend via `cnos-ext-http` command
- Request schemas at `schemas/http_get.json` and `schemas/dns_resolve.json`
- Engine constraint: `>=3.12.0 <4.0.0`
- Test: `cn_extension_test.ml` "build_registry: full lifecycle" verifies manifest → registry → dispatch types

**Gap:** The host binary `cnos-ext-http` does not exist in the source tree. The reference extension is specified and type-proven but not executable. End-to-end execution requires the binary to be implemented.

---

## 2. AC Summary

| # | AC | Status |
|---|-----|--------|
| AC1 | Package ships extension without core changes | **PARTIAL** — source layout exists, build integration pending |
| AC2 | Discovers at boot | **PASS** — library + wiring into context/runtime |
| AC3 | Dispatch without core changes | **PASS** — full pipeline wired (output → shell → executor → orchestrator) |
| AC4 | Runtime Contract shows extensions | **PASS** — registry built at context-pack, passed to gather |
| AC5 | Sandboxed and traced | **PARTIAL** — subprocess model + events exist, policy intersection pending |
| AC6 | Doctor validates | **PASS** — lifecycle state counting + host health check |
| AC7 | cnos.net.http proves model | **PARTIAL** — manifest + types proven, host binary missing |

---

## 3. α / β / γ Triad Scoring

### α (Structural coherence): A-

**Strengths:**
- Clean module boundaries: cn_extension (parsing/registry), cn_ext_host (subprocess protocol), cn_shell (type extension), cn_executor (dispatch)
- Backward compatible: existing tests unchanged (except gather signature), existing ops untouched
- Pure/impure boundary preserved: manifest parsing is pure, discovery isolates I/O
- Registry is a single source of truth for extension state
- Type annotations disambiguate record field access between extension_op and backend types

**Weakness:**
- The `Extension of string * string` variant in `op_kind` is less type-safe than the built-in `Observe of observe_kind` pattern — extension op classes are strings ("observe"/"effect") rather than typed variants. This is acceptable for extensibility but weaker structurally.

### β (Relational coherence): B+

**Strengths:**
- Runtime Contract, capabilities, doctor, traceability, and executor all reference the same extension registry
- Full wiring: cn_runtime builds registry → orchestrator dispatches → output parser resolves → context packer renders
- Source discipline maintained: `src/agent/extensions/` is source-of-truth, `packages/` would be generated
- Extension lifecycle states (discovered → compatible → enabled/disabled/rejected) are consistent across all consumers
- Op kind uniqueness enforced: conflicts rejected, never shadowed

**Weaknesses:**
- The subprocess host binary (`cnos-ext-http`) does not exist yet — the manifest declares it but the binary would need to be built separately. End-to-end execution isn't testable without the binary.
- Policy intersection (domain allowlists, secret injection) is declared but not enforced at runtime.
- Build integration (`cn build` copying extensions to packages/) is not implemented.

### γ (Process coherence): A

**Strengths:**
- CDD steps followed rigorously: observe → select → branch → bootstrap → gap → mode → artifacts → self-coherence
- Version directory created with manifest and self-coherence stub
- Acceptance criteria mapped to evidence with honest PASS/PARTIAL statuses
- Design doc (RUNTIME-EXTENSIONS.md v1.0.6) implemented faithfully
- 30+ tests cover parsing, compatibility, conflicts, enablement, registry, shell integration, discovery
- Review findings addressed: compile fix, wiring gaps closed, AC table corrected

---

## 4. Weakest Axis

**β** — relational coherence. The wiring between modules is now complete (registry flows through runtime → orchestrator → executor, and context → contract → capabilities). However, the host binary doesn't exist yet, policy intersection is not enforced, and build integration is missing. The architecture is proven at the type/dispatch level but not at the execution level.

---

## 5. Known Debt

1. **Subprocess host binary** (`cnos-ext-http`) — needs implementation for actual http_get/dns_resolve execution
2. **Native backend** — design allows it but implementation deferred to Phase 3
3. **Policy intersection** — the permission model is declared in manifests but runtime config for domain allowlists, byte budgets, and secret injection is not yet wired
4. **Build integration** — `cn build` does not yet copy extension content from `src/agent/extensions/` to `packages/` output

---

## 6. Verdict

Phase 1 delivers the extension architecture with 4 of 7 ACs fully met and 3 partially met. The core pipeline is wired end-to-end: registry build → op parsing → dispatch → execution → traceability. The remaining gaps are execution-level (host binary, policy intersection, build integration) rather than architectural.

**Phase 1 groundwork is landed.** The open op registry, manifest-driven discovery, subprocess host protocol, Runtime Contract integration, doctor validation with host health checks, and traceability events are all in place and wired. Remaining work (host binary, policy enforcement, build integration) is Phase 2 execution.
