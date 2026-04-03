# PLAN-v3.33.0-hub-placement-models

## Implementation Plan for Standalone and Attached Hubs

**Status:** Draft
**Implements:** docs/alpha/HUB-PLACEMENT-MODELS.md
**Issue:** #156
**Depends on:** current hub discovery, executor path resolution, Runtime Contract, package system, sync

---

## 0. Coherence Contract

### Gap

Sandboxed agents need to work inside a project checkout while keeping:

- hub state
- memory
- packages
- sync

external to the project repo's canonical history.

Current cnos still assumes a single root serves as both:

- hub root
- workspace root

That is the architectural blocker.

### Mode

MCA

### α / β / γ target

- α: explicit placement model with explicit roots
- β: align discovery, execution, sync, doctor, Runtime Contract, and package installs
- γ: make injected/sandboxed agent workflows coherent without breaking standalone mode

### Smallest coherent intervention

Do not redesign transport or package semantics. Introduce:

- placement manifest
- root split
- attached-hub backends

---

## 1. Step Order

## Step 1 — Placement manifest + resolver

### Goal

Create a first-class placement manifest and a resolver API.

### Work

Add:

- `.cn/placement.json` schema
- placement resolver module

Support:

- standalone
- attached

Return:

- `hub_root`
- `workspace_root`
- backend metadata

### Acceptance

- placement can be resolved deterministically
- absence of manifest falls back to standalone discovery
- attached mode can resolve distinct roots

---

## Step 2 — Hub discovery refactor

### Goal

Stop treating "directory containing `.cn/config`" as automatically the hub root in every case.

### Work

Refactor current hub discovery to:

1. check for placement manifest
2. if present, resolve explicit roots
3. otherwise retain current standalone behavior

### Acceptance

- attached mode no longer relies on implicit single-root discovery
- standalone behavior remains backward compatible

---

## Step 3 — Executor root split

### Goal

Make runtime operations choose the correct root explicitly.

### Work

Classify operations into:

- workspace-targeted
- hub-targeted

Route:

- fs/git/code/doc operations → `workspace_root`
- state/threads/spec/vendor/sync internals → `hub_root`

### Acceptance

- agent can work on the project repo while cnos keeps state in attached hub
- no accidental writes of hub state into the workspace tree

---

## Step 4 — Attached backend: nested clone

### Goal

Land the default attached backend.

### Work

Add init/attach flow such as:

- `cn attach --hub <git-url>` or equivalent

Initialize:

- `.cn/placement.json`
- `.cn/hub/` nested clone
- hub config under attached root

### Acceptance

- nested-clone attached hub works end to end
- sync uses the hub repo remote
- package installs go into hub root vendor paths

---

## Step 5 — Optional backend: submodule

### Goal

Support submodule as an explicit backend, not the architecture itself.

### Work

Add optional backend initialization:

- `--backend submodule`

Ensure:

- placement manifest records backend kind
- doctor validates submodule coherence
- docs explain tradeoffs vs nested clone

### Acceptance

- attached hub via submodule is supported
- parent repo can track gitlink if desired
- cnos runtime semantics are unchanged because placement abstraction hides backend details

---

## Step 6 — Runtime Contract integration

### Goal

Expose placement coherently to the agent/operator.

### Work

Add placement info to:

- body
- medium

Surface:

- mode
- hub root
- workspace root
- zone classification

### Acceptance

- attached placement appears coherently in Runtime Contract
- agent can understand what is "self/private body" vs "work medium"

---

## Step 7 — Package / vendor integration

### Goal

Make sure package installs and package truth remain anchored in the hub.

### Work

Audit/adjust package/deps logic so:

- `.cn/vendor/...` is resolved under `hub_root`
- desired/resolved/install truth still lives in the hub
- workspace repo is not mistaken for package substrate

### Acceptance

- attached mode package installs work
- wake-time truth remains local and hub-based

---

## Step 8 — Sync semantics

### Goal

Ensure sync uses hub remote, not project remote.

### Work

Update sync resolution to use:

- attached backend remote
- hub repo identity

### Acceptance

- `cn sync` in attached mode pushes/pulls hub state against hub remote
- project remote is not accidentally used

---

## Step 9 — Doctor and setup/init docs

### Goal

Make attached placement operable and inspectable.

### Work

Update:

- doctor
- setup/init/attach docs
- troubleshooting docs
- any related runtime docs

Doctor should validate:

- placement manifest
- hub root
- workspace root
- backend coherence
- remote configuration
- package/vendor layout

### Acceptance

- attached mode can be diagnosed by `cn doctor`
- docs explain nested clone vs submodule tradeoffs

---

## Step 10 — Tests

### Unit tests

- placement manifest parsing
- root resolution
- mode fallback

### Integration tests

- attached nested clone init
- attached submodule init
- workspace-targeted fs/git ops
- hub-targeted state/spec/vendor writes
- sync uses hub remote
- doctor passes in attached mode

### Acceptance

- both placement modes are reproducible and testable
- no single-root assumption remains in critical runtime paths

---

## 2. Non-goals

This plan does not include:

- multi-workspace attachment
- CI vendor/backend quirks beyond basic docs
- transport redesign
- registry redesign
- reflection/package model redesign

---

## 3. Success Criteria

This implementation line is complete when:

1. Attached mode works with distinct `hub_root` and `workspace_root`
2. Nested clone is the default attached backend
3. Submodule works as an optional backend
4. Runtime operations target the correct root
5. Hub sync uses the hub remote
6. Package installs remain hub-local
7. Runtime Contract and doctor both describe attached placement correctly
8. Standalone mode remains backward compatible

---

## 4. Summary

This plan solves the real problem behind #156: not "support submodules," but

> support attached hubs with explicit root separation

That is the smallest coherent move that makes sandboxed/injected agent workflows first-class while preserving Git-first externalized hub truth.
