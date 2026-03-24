# Runtime Extensions v1.0.6

## Capability Providers, Discovery, and Isolation in cnos

**Version:** 1.0.6
**Status:** Draft — converged
**Addresses:** #67 (network access), future capability extensibility
**Iteration history:**
- v1.0.0–v1.0.5: initial drafts, package layout alignment, lifecycle states
- v1.0.6: open op model + dispatch, source/install separation, marketplace-readiness

---

## 0. Coherence Contract

### Gap

cnos can evolve cognition through packages, but capability growth still tends to imply core runtime changes. Issue #67 exposes the pattern clearly:

- agents need network access
- network access must be configurable, sandboxed, typed, and visible at wake
- but adding it directly to core would enlarge the runtime by accretion

The deeper incoherence is:
- cognitive substrate is packageable and local
- runtime capabilities are not yet equally extensible

### Mode

MCA — change the runtime architecture so new capability families can be shipped as extensions rather than core edits.

### α / β / γ target

- α PATTERN: one explicit extension model instead of ad hoc built-ins
- β RELATION: align package distribution, runtime contract, traceability, doctor, and capability execution
- γ EXIT: make future capabilities (network, browser, lab/device IO, bridges) additive instead of invasive

### Smallest coherent intervention

Do not rewrite core capabilities. Introduce an extension architecture and use network access as the first reference extension.

---

## 1. Core Decision

A new runtime feature that introduces executable affordance SHOULD be delivered as an extension unless there is a strong reason for it to live in the trusted core.

Examples that fit the extension model:
- network access
- browser / web retrieval
- device / sensor bridges
- external API integrations
- future communication bridges

Core built-ins remain:
- filesystem
- local git
- output-plane rendering
- scheduling / orchestration
- traceability
- package/runtime contract machinery

---

## 2. Definitions

### 2.1 Package

A package is a distribution unit. Packages may contain:
- doctrine
- mindsets
- skills
- profiles
- extensions

### 2.2 Extension

An extension is an installed runtime component that contributes one or more typed ops to the CN Shell surface without requiring core runtime code changes.

An extension is not:
- a package
- a skill
- a capability by itself

It is a provider of capabilities.

### 2.3 Capability Provider

A capability provider is the runtime-facing execution endpoint for a set of typed ops.

Examples:
- cnos.net.http
- cnos.browser.fetch
- org.example.api.github

### 2.4 Extension Host

The process or runtime context that actually executes the provider.

Possible kinds:
- subprocess (default)
- native (trusted, optional)
- future remote/bridge hosts if explicitly designed

### 2.5 Bundle / App

A bundle (or app) is a higher-level installable composition of:
- packages
- extensions
- optional profiles or runtime defaults

A bundle is not a new runtime primitive. It is a distribution and installation unit built on top of packages and extensions.

### 2.6 Extension lifecycle state

An extension can be in one of these states:
- discovered
- compatible
- enabled
- loaded
- active
- disabled
- rejected

These states are distinct and must be visible in Runtime Contract, traceability, and doctor.

---

## 3. Guiding Principles

### 3.1 Discovery is manifest-driven

The runtime discovers extensions from installed package manifests, not from hardcoded registries.

### 3.2 Discovery is not enablement

An extension may be:
- discovered
- compatible
- installed

without being enabled. Risky or policy-sensitive extensions (for example networked extensions) should be discoverable while still requiring explicit runtime enablement.

### 3.3 Execution is isolated by default

The default execution model for extensions is out-of-process.

### 3.4 Runtime remains the policy decision point

Extensions may declare what they need, but the runtime decides what is allowed.

### 3.5 Capability authority remains typed

Extensions expose typed ops, not freeform command channels.

### 3.6 Wake-up must remain local

Extensions are installed locally and declared in the Runtime Contract. No network fetch is needed to know what capabilities exist.

### 3.7 Op kinds must be globally unique

Each effective typed op kind in the runtime must resolve to exactly one provider. If two installed extensions declare the same op kind:
- the runtime MUST reject the conflict
- the conflicting extensions MUST NOT silently shadow one another
- the conflict MUST be visible in doctor/traceability

This keeps capability dispatch deterministic.

---

## 4. Source and Install Layout

The extension architecture must distinguish between:
1. source-of-truth layout
2. installed package layout

### 4.1 Source-of-truth layout

Extensions must follow the same source discipline as the rest of cnos:
- `src/agent/` is the canonical source
- `packages/` is generated output

A first-party extension source tree should therefore live under a source root such as:

```text
src/agent/extensions/<pkg>/<ext-name>/
  cn.extension.json
  host/...
  docs/...
  schemas/...
```

The exact source layout may be normalized by `cn build`, but the key rule is: Do not make `packages/` the authored source of truth.

### 4.2 Generated package layout

After build, the package output may contain:

```text
packages/<pkg>/
  cn.package.json
  doctrine/...
  mindsets/...
  skills/...
  profiles/...
  extensions/
    <ext-name>/
      cn.extension.json
      host/...
      docs/...
      schemas/...
```

### 4.3 Installed package layout

After restore/install, the runtime discovers extensions under:

```text
.cn/vendor/packages/<pkg>@<ver>/
  doctrine/...
  mindsets/...
  skills/...
  profiles/...
  extensions/
    <ext-name>/
      cn.extension.json
      host/...
      docs/...
      schemas/...
```

### 4.4 Rule

Packages remain the distribution unit. Extensions are package contents. The runtime reasons over the installed layout, while source discipline remains consistent with the rest of cnos.

---

## 5. Extension Manifest

Each extension is declared by a manifest:

```json
{
  "schema": "cn.extension.v1",
  "name": "cnos.net.http",
  "version": "1.0.0",
  "interface": "cn.ext.v1",
  "kind": "capability-provider",
  "backend": {
    "kind": "subprocess",
    "command": ["cnos-ext-http"]
  },
  "ops": [
    {
      "kind": "http_get",
      "class": "observe",
      "request_schema": "schemas/http_get.json",
      "response_format": "artifact:text"
    },
    {
      "kind": "dns_resolve",
      "class": "observe",
      "request_schema": "schemas/dns_resolve.json",
      "response_format": "artifact:json"
    }
  ],
  "permissions": {
    "network": true,
    "default_read_only": true,
    "allow_secrets": []
  },
  "engines": {
    "cnos": ">=3.12.0 <4.0.0"
  }
}
```

### 5.1 Required fields

- schema
- name
- version
- interface
- backend
- ops
- permissions
- engines

### 5.2 Meaning of interface

`interface` is the version of the runtime ↔ extension-host protocol. It governs:
- host handshake
- describe
- health
- execute
- shutdown

It does not replace per-op request schemas.

### 5.3 Why

This is the runtime equivalent of:
- Java ServiceLoader provider metadata
- Cordova plugin manifests
- package-native extension discovery

---

## 6. Open Op Model and Dispatch

This section is required to make extensions real in cnos.

### 6.1 Problem

The current CN Shell model historically assumed a closed built-in op vocabulary. For extensions to work without core code changes, the runtime must move to an open op registry:
- built-in ops remain registered by core
- extension ops are registered from manifests
- parsing/validation/dispatch must route by registry lookup

### 6.2 Rule

The runtime SHALL treat typed ops as:

1. a stable common envelope
   - kind
   - class (observe / effect)
   - arguments

2. resolved against a runtime registry
   - built-in provider
   - or extension provider

### 6.3 Dispatch

At execution time:
- built-in op kinds dispatch to core handlers
- extension op kinds dispatch to the matching provider host

### 6.4 Validation

Validation must be two-stage:
1. common envelope validation in core
2. provider-specific request validation via the registered schema

### 6.5 Why

Without this section, "extensions contribute new typed ops without core code changes" would remain aspirational rather than architecturally real.

---

## 7. Discovery Model

At boot, the runtime builds an extension registry by scanning installed packages.

### 7.1 Discovery roots

- `.cn/vendor/packages/<pkg>@<ver>/extensions/**/cn.extension.json`

### 7.2 Discovery outputs

For each valid manifest:
- extension identity
- package source
- backend kind
- typed ops provided
- declared permissions
- compatibility status
- enablement status
- lifecycle state

### 7.3 Loading strategy

- discover eagerly
- activate lazily on first op use, unless configured otherwise

This keeps boot light while keeping the Runtime Contract truthful.

### 7.4 Conflict policy

If discovery finds:
- duplicate extension names
- duplicate effective op kinds
- incompatible interface
- incompatible engines

the runtime MUST:
- emit `extension.rejected`
- record the reason
- exclude the invalid extension from the active registry

No ambiguous provider set may become active.

---

## 8. Execution Model

### 8.1 Default: subprocess host

The default extension backend is a subprocess.

Why:
- failure isolation
- clearer privilege boundary
- easier resource limiting
- no direct memory/ABI coupling with core runtime

Protocol — the runtime and host communicate over a small typed protocol, e.g. stdio JSON messages:
- describe
- health
- execute
- shutdown

Example:

```json
{
  "method": "execute",
  "op": {
    "kind": "http_get",
    "url": "https://github.com/..."
  },
  "limits": {
    "timeout_sec": 30,
    "max_bytes": 65536
  },
  "permissions": {
    "allowed_domains": ["github.com"]
  }
}
```

### 8.2 Optional: native trusted host

For trusted first-party or performance-sensitive extensions, cnos MAY support a native backend using OCaml plugin loading.

Constraints:
- same-process
- interface/version coupling
- not a security boundary
- explicitly trusted only

Rule: Native backends are opt-in and never the default for risky capability classes.

---

## 9. Policy and Sandboxing

Extensions declare what they want. The runtime decides what they get.

### 9.1 Policy intersection

Effective permissions are:

```
extension-declared need ∩ runtime config ∩ package/profile policy
```

### 9.2 Discovery vs enablement

An extension may be:
- discovered
- but disabled by config
- or rejected by policy
- or unavailable because its backend is unhealthy

These states must be visible in Runtime Contract and traceability.

### 9.3 Example: network extension

The extension may declare:
- network access
- read-only by default

The runtime config may further restrict:
- enabled/disabled
- domains allowlist
- denied domains
- methods allowed
- timeout
- byte budgets
- allowed secrets

### 9.4 No ambient credentials

Secrets are never ambient. If an extension can use a secret, it must be:
- declared in manifest
- allowed by config
- injected explicitly by runtime

### 9.5 Policy is enforced by core runtime

An extension host may request execution. It may not decide its own authority envelope.

---

## 10. Runtime Contract Integration

The Runtime Contract must surface extensions explicitly. This design assumes the vertical Runtime Contract:
- identity
- cognition
- body
- medium

### 10.1 Cognition

Installed extensions should appear as part of the installed runtime substrate.

Example:

```yaml
cognition:
  packages:
    - name: "cnos.core"
      version: "1.0.0"
    - name: "cnos.net.http"
      version: "1.0.0"
  extensions:
    installed:
      - name: "cnos.net.http"
        package: "cnos.net.http@1.0.0"
        backend: "subprocess"
        status: "enabled"
```

### 10.2 Body

Capabilities exposed by extensions become part of the body's capability surface.

Example:

```yaml
body:
  capabilities:
    observe:
      - fs_read
      - git_diff
      - http_get
      - dns_resolve
    effect:
      - fs_write
      - git_commit
  extensions:
    active:
      - name: "cnos.net.http"
        ops: ["http_get", "dns_resolve"]
```

### 10.3 Rule

At wake, the agent should know:
- which extensions are installed
- which are enabled or disabled
- which ops they add
- what the effective permission envelope is

---

## 11. Traceability

Extensions must integrate with the same evidence model as core capabilities.

### 11.1 Required events

- `extension.discovered`
- `extension.loaded`
- `extension.rejected`
- `extension.disabled`
- `extension.health.ok`
- `extension.health.error`
- `extension.op.start`
- `extension.op.ok`
- `extension.op.error`

### 11.2 Receipts

Extension ops use the same receipt model:
- pass
- status
- reason
- artifacts
- timings

### 11.3 Why

An operator should be able to answer:
- was the extension discovered?
- did it load?
- was it rejected for compatibility or policy?
- was it disabled by config?
- what happened when its op executed?

---

## 12. First Reference Extension: cnos.net.http

Issue #67 should be implemented as the first reference extension, not as a permanent core special case.

### 12.1 Initial ops

- `http_get` (observe)
- `dns_resolve` (observe)

### 12.2 Later additions

- `http_request` / `http_post` (effect, stricter controls)
- provider-specific APIs (e.g. GitHub) as higher-level extensions or layered wrappers

### 12.3 Rationale

This lets network access validate the extension architecture while remaining useful immediately.

---

## 13. Alternatives Considered

### 13.1 Hardcode network into core

Pros: simplest short-term implementation
Cons: repeats the same accretion pattern for every future capability; keeps capability growth tied to core releases; misses the architectural opportunity revealed by #67

Decision: reject as long-term design

### 13.2 In-process plugin loading only

Pros: faster; type-safe in OCaml; elegant for trusted extensions
Cons: same-process crash surface; weak security boundary; interface/version coupling; harder to sandbox

Decision: allow only as trusted optional backend

### 13.3 Pure external bridge (MCP, browser, phone proxy)

Pros: interop with broader ecosystems; specialized transports possible
Cons: too indirect as the core extension architecture; may still need a local provider model underneath

Decision: possible future backend classes, not the core design

---

## 14. Migration Strategy

### 14.1 Phase 1

- add extension manifest schema
- add registry/discovery
- add subprocess host protocol
- add open op registry/dispatch
- ship cnos.net.http

### 14.2 Phase 2

- expose loaded extensions in Runtime Contract
- add doctor validation
- add extension traceability

### 14.3 Phase 3

- optionally move selected non-core features to extensions
- optionally support trusted native backend

Core built-ins remain untouched in v1.

---

## 15. Acceptance Criteria

This is done when:

1. A package can ship an extension without modifying core runtime code.
2. cnos discovers installed extensions automatically at boot.
3. The runtime can dispatch extension-defined op kinds without core code changes.
4. The Runtime Contract tells the agent which extension ops exist and whether they are enabled.
5. Extension execution is sandboxed and traced.
6. cn doctor validates extension compatibility and configuration.
7. cnos.net.http proves the model by shipping http_get as the first extension.

---

## 16. Summary

The long-term fix for capability growth is not "add more built-ins." It is:
- packages as distribution units
- manifests for discovery
- subprocess isolation by default
- open typed-op dispatch with policy enforcement by the core runtime
- optional trusted native plugins when justified

This keeps the system coherent:
- cognition is packageable
- capabilities are extensible
- authority stays governed
- wake-up stays local
- and new runtime affordances no longer require core accretion

---

## 17. Marketplace-Readiness Requirements

This document defines the runtime extension architecture, not the full ecosystem/distribution model. However, the extension system MUST be designed so a future registry / marketplace can sit on top of it coherently.

### 17.1 Required readiness properties

The extension system MUST support:
- globally unique package names
- globally unique extension names
- globally unique effective op kinds in the active runtime
- semantic versioning
- explicit compatibility (engines)
- explicit permissions
- explicit enable/disable/rejected state
- deterministic installed layout
- trust/signature metadata hooks
- clean uninstall / disable semantics
- bundle/app composition without core runtime changes

### 17.2 Why

Without these properties, a future registry or marketplace would have no stable basis for:
- discovery
- trust
- installation
- update
- rollback
- conflict resolution
- operator understanding

### 17.3 Out of scope here

This document does not define:
- publication workflow
- registry/index format
- trust/signing model
- release channels (stable, beta, local)
- install/update/remove commands
- bundle/app metadata schema

Those belong to a companion registry/ecosystem design.

---

## CLP Summary

The design is now coherently layered. It distinguishes:
- runtime extension mechanics
- distribution/app composition
- source vs installed layouts
- discovery vs enablement
- built-in vs extension dispatch

- α: A
- β: A
- γ: A

No material axis weakness remains inside this artifact. The next work lies outside the doc:
- implementation planning
- companion registry/ecosystem design
