# v3.17.0 — Runtime Extensions Phase 1: Open Op Registry

**Issue:** #73 — Runtime Extensions — Capability Providers, Discovery, and Isolation
**Branch:** `claude/review-issue-73-7yr26`
**Mode:** MCA (new subsystem — extensible op dispatch)
**Prior version:** v3.16.2
**Consolidates:** #67 (network access — first reference extension)

---

## Coherence Contract

### Gap

The CN Shell op vocabulary is closed — hardcoded in `cn_shell.ml`. Adding a new capability (network access, browser, device IO) requires modifying core runtime code. Cognitive substrate is packageable and local; runtime capabilities are not equally extensible.

### Why it matters

Every new capability requires core changes. Capability growth is tied to core releases. The system cannot grow coherently. #67 (network access) has been blocked for 7 cycles because the extension architecture didn't exist.

### What fails if skipped

Agents remain network-blind. Future capabilities (API integrations, browser, device bridges) each require invasive core changes. The runtime grows by accretion rather than composition.

### Mode

**MCA** — the op registry is closed in code; it must become open. This requires new types, dispatch logic, manifest parsing, discovery, and a reference extension.

### α / β / γ target

- α PATTERN: explicit extension manifests, registry, dispatch, and lifecycle
- β RELATION: package distribution, runtime contract, traceability, and execution all describe the same extension system
- γ EXIT: future capabilities become additive, not invasive

---

## Phase 1 Scope

1. **Extension manifest schema** (`cn.extension.json`) — declares ops, backend, permissions, engines
2. **Extension registry** — manifest parsing, discovery from installed packages, conflict detection
3. **Open op dispatch** — replace closed built-in vocabulary with registry + dispatch
4. **Subprocess host protocol** — execute extension ops via stdio JSON protocol
5. **Policy intersection** — effective permissions = declared need ∩ runtime config
6. **Runtime Contract integration** — extensions visible in cognition + body layers
7. **Traceability** — `extension.*` event family
8. **First reference extension** — `cnos.net.http` providing `http_get` + `dns_resolve`

---

## Affected Files

| File | Change |
|------|--------|
| `src/cmd/cn_extension.ml` | New — manifest parsing, discovery, registry builder |
| `src/cmd/cn_ext_host.ml` | New — subprocess host protocol |
| `src/cmd/cn_shell.ml` | Open op registry, dispatch by registry lookup |
| `src/cmd/cn_executor.ml` | Extension op dispatch to subprocess host |
| `src/cmd/cn_orchestrator.ml` | Wire ext_registry through N-pass loop |
| `src/cmd/cn_runtime.ml` | Build registry per cycle, wire through pipeline |
| `src/cmd/cn_output.ml` | Wire ext_lookup into parse_ops_manifest |
| `src/cmd/cn_context.ml` | Build registry at context-pack for Runtime Contract |
| `src/cmd/cn_runtime_contract.ml` | Extensions in cognition + body layers |
| `src/cmd/cn_capabilities.ml` | Extension ops in capability declarations |
| `src/cmd/cn_trace.ml` | Extension event family |
| `src/cmd/cn_system.ml` | Doctor extension + host health checks |
| `src/agent/extensions/cnos.net.http/` | First reference extension source |
| `test/cmd/cn_extension_test.ml` | Manifest, discovery, registry, dispatch tests |

---

## Frozen Artifacts

| Artifact | File | Status |
|----------|------|--------|
| Snapshot manifest | `README.md` (this file) | complete |
| Self-coherence report | `SELF-COHERENCE.md` | stub |

---

## Acceptance Criteria

1. A package can ship an extension without modifying core runtime code
2. cnos discovers installed extensions automatically at boot
3. The runtime can dispatch extension-defined op kinds without core code changes
4. The Runtime Contract tells the agent which extension ops exist and whether enabled
5. Extension execution is sandboxed and traced
6. cn doctor validates extension compatibility and configuration
7. cnos.net.http proves the model by shipping http_get as first extension
