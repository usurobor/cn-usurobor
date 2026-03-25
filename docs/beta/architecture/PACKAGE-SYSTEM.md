# Package System

## Git-Native Package Discovery, Resolution, Installation, and Wake-Time Truth in cnos

**Version:** 1.0.1
**Status:** Draft

**Purpose:** Define the package system for cnos: how packages are named, published, resolved, installed, updated, removed, surfaced to the agent at wake, and related to the Git-native substrate.

**Related:**

- docs/alpha/COGNITIVE-SUBSTRATE.md
- docs/alpha/runtime-extensions/RUNTIME-EXTENSIONS.md
- docs/beta/EXTENSION-REGISTRY.md

---

## 0. Coherence Contract

### Gap

cnos already has:

- package-shaped cognitive substrate,
- desired state in `.cn/deps.json`,
- resolved state in `.cn/deps.lock.json`,
- and installed packages under `.cn/vendor/packages/`.

But the system still lacks one canonical architecture doc that explains:

- what a package is
- why packages are Git-native
- how desired vs resolved state works
- how publication and installation relate
- what the agent sees at wake
- how packages relate to extensions, bundles/apps, and registry
- what is operator action vs runtime truth

### Mode

MCA — define the package system explicitly as a coherent architectural layer.

### α / β / γ target

- α PATTERN: one explicit package-system model instead of scattered conventions
- β RELATION: align runtime, lockfiles, install roots, registry, Runtime Contract, and operator mental model
- γ EXIT: make future extensions, bundles/apps, and marketplace surfaces sit on stable package primitives

### Smallest coherent intervention

Do not redesign Runtime Extensions or Extension Registry. Define the package system that they both sit on.

---

## 1. Core Decision

The cnos package system is Git-native.

### Canonical rule

Git is the canonical transport and source-of-truth for package publication and retrieval.

This means:

- package identity is stable over repository history
- exact installs are pinned by Git revision
- package contents are fetched and materialized from Git-backed sources
- registry/index layers may exist above this, but they do not replace Git as the canonical substrate

### Why

cnos already treats Git as the lowest durable substrate. The package system should follow the same principle.

---

## 2. What a Package Is

A package is the atomic distribution unit in cnos.

A package may contain:

- doctrine
- mindsets
- skills
- profiles
- extensions
- package metadata

A package is not:

- an agent
- a bundle/app
- a registry entry
- a capability by itself

### Package examples

- cnos.core
- cnos.eng
- cnos.pm
- future third-party packages
- future extension-bearing packages such as cnos.net.http

---

## 3. Prior Art and Why cnos Chooses This Shape

### 3.1 Cargo

Cargo separates:

- desired dependency declarations
- exact resolved lock state

This is valuable because it distinguishes:

- what the human wants
- from what the machine pinned

cnos should keep the same distinction.

### 3.2 npm

npm's lockfile records the exact tree produced by install, so later installs can reproduce it.

This is valuable because reproducibility belongs in the lock, not in memory or tribal knowledge.

### 3.3 Nix

Nix flakes pin exact inputs in `flake.lock`.

This is valuable because package resolution should produce a deterministic, inspectable, updateable resolved state.

### 3.4 Debian / apt

Debian repositories use signed metadata and a verification chain from the signed index down to package files.

This is valuable because discovery and trust should be explicit, not ambient.

### 3.5 cnos choice

cnos combines these lessons in a Git-native way:

- desired state is human-declared
- resolved state is machine-exact
- install roots are local and deterministic
- trust/signature can exist at the ecosystem layer
- runtime wakes only from local installed truth

---

## 4. The Four Package Layers

The package system has four distinct layers.

### 4.1 Source

The canonical authored source of package content.

For first-party cnos packages, source-of-truth lives in:

- `src/agent/...`

Generated package output is not the authored source.

### 4.2 Distribution

Package publication and retrieval.

Canonical transport:

- Git

Possible higher layers:

- registry/index
- channels
- signed metadata
- cache/mirror

### 4.3 Installation

Local materialization of exact package contents into installed roots.

Installed root:

- `.cn/vendor/packages/<name>@<version>/...`

### 4.4 Runtime truth

The runtime only trusts installed local state at wake.

The agent should know:

- which packages are installed
- which versions are installed
- which overrides are active
- which extensions those packages contribute

The runtime should not need network access to know any of that.

---

## 5. Desired State vs Resolved State

This is the core package-system split.

### 5.1 Desired state

What the human/operator wants.

Examples:

- profile
- requested packages
- preferred channels
- desired bundle/app installs

In current cnos, this is represented by:

- `.cn/deps.json`

### 5.2 Resolved state

What the machine pinned exactly.

This includes:

- package name
- version
- source
- exact Git revision
- subdirectory
- integrity metadata
- possibly trust/channel metadata in future

In current cnos, this is represented by:

- `.cn/deps.lock.json`

### 5.3 Rule

The runtime trusts resolved state, not desired state, at wake.

Desired state is intent. Resolved state is installed truth.

---

## 6. Package Identity

Each package should have stable identity along these axes:

- name
- version
- source
- rev
- subdir

### Why subdir matters

A single Git repo can contain multiple packages. So package identity must not assume:

- one repo = one package

### Install identity

Installed path should be deterministic:

```
.cn/vendor/packages/<name>@<version>/
```

The lockfile carries the exact source/revision/subdir needed to populate that root.

---

## 7. Publication Model

### 7.1 Canonical publication

Canonical package publication is Git publication.

A package is published when:

- its source exists in a Git-backed source,
- a revision is addressable,
- and its package metadata is valid.

### 7.2 Registry is optional above publication

A registry/index may make discovery easier, but does not replace Git as the underlying publication truth.

### 7.3 First-party default

For first-party packages, the default source may be the cnos Git repository with a package subdirectory.

That is a convenience rule, not the only possible source model.

---

## 8. Installation Model

### 8.1 Resolve

Take desired state and produce exact resolved state.

### 8.2 Fetch

Fetch the exact (source, rev, subdir) from Git.

### 8.3 Verify

Verify:

- lockfile coherence
- package metadata
- optional integrity/trust metadata

### 8.4 Materialize

Copy package contents into:

- `.cn/vendor/packages/<name>@<version>/...`

### 8.5 Activate

Installed packages become part of the Runtime Contract and wake-time substrate.

### 8.6 Update

Updating means:

- re-resolve desired state against publication/registry inputs
- write a new resolved state
- materialize new installed roots

### 8.7 Remove

Remove a package only if:

- desired state no longer requires it
- and no installed bundle/app or dependency path still references it

### 8.8 Rollback

Rollback restores a previous resolved state and reinstall set.

---

## 9. Agent Discovery at Wake

An agent should never have to discover installed packages by probing the filesystem.

### The Runtime Contract must surface

- installed package names
- installed versions
- package role in cognition
- active overrides
- extension-bearing package state where relevant

### Rule

Agent-visible package truth comes from the Runtime Contract, not from ad hoc file reads.

This keeps:

- wake-up local
- self-model coherent
- token use lower
- authority surfaces cleaner

---

## 10. Agent-Requested Installation

By default, package installation is not an ambient runtime behavior.

### Base rule

The runtime should not let an agent arbitrarily install packages from the network during a normal task loop.

### Why

Installation changes the substrate itself. That is a higher-governance action than normal capability use.

### Coherent path

If agent-requested package installation is later allowed, it should happen through a governed package-management surface, for example:

- explicit operator approval
- explicit allowlist policy
- explicit trust/channel policy
- traceability + doctor integration

Until then:

- the agent can discover installed packages at wake
- the operator or automation performs install/update/remove

---

## 11. Relationship to Runtime Extensions

Extensions are package contents.

This means:

- a package may ship no extensions
- a package may ship one or more extensions
- extension discovery happens from installed package roots

So the package system is the substrate on which Runtime Extensions operate.

Packages answer:

- what is installed

Extensions answer:

- what new runtime affordances those installed packages contribute

---

## 12. Relationship to Bundles / Apps

Bundles/apps are not runtime primitives. They are install-time compositions of packages.

A bundle/app may express:

- a set of packages
- optional profile defaults
- optional extension-bearing packages
- optional operator-facing metadata

So the layering is:

1. package
2. extension
3. bundle/app
4. registry

That keeps the package system clean and reusable.

---

## 13. Relationship to Registry / Marketplace

The package system must be ready for a registry/app ecosystem, but not depend on it.

### Registry role

- discovery
- trust
- channels
- update metadata
- bundle/app metadata

### Runtime role

- local install roots
- local wake-time truth
- local package/extension discovery

### Rule

A registry must not be required for wake.

---

## 14. Install Roots, Caches, and Local State

### Installed roots

- `.cn/vendor/packages/<name>@<version>/...`

### Optional bundle roots

- `.cn/vendor/bundles/<name>@<version>/...`

### Optional cache roots

- fetched registry metadata cache
- fetched Git artifact cache

### Rule

The runtime reasons over installed roots, not caches.

---

## 15. Trust and Integrity

The package system should support trust/integrity hooks, even if the full registry model is above it.

### Minimum future-ready fields

- source
- exact revision
- integrity hash
- publisher/signature metadata hooks

### Why

This allows:

- deterministic installs
- auditability
- future signed registry layers
- operator trust policy

---

## 16. Doctor and Traceability

### cn doctor should validate

- desired state syntax
- resolved state syntax
- installed roots vs lockfile
- package metadata validity
- extension-bearing package structure where relevant

### Traceability should emit

- package resolved
- package installed
- package removed
- package updated
- package rejected
- artifact verified

This gives operators:

- package truth
- install lifecycle truth
- failure visibility

---

## 17. Tradeoffs

### Why Git-native is right

**Pros:**

- aligns with cnos thesis
- durable history
- exact revisions
- branch/tag/rev semantics already understood
- no new special publication substrate required

**Cons:**

- package resolution/discovery UX is rougher without a registry
- install tooling must understand subdirs and lock discipline
- third-party discovery is harder without a higher-level index

### Why desired/resolved split is right

**Pros:**

- deterministic installs
- easy rollback
- honest distinction between intent and machine state

**Cons:**

- more files
- lock maintenance discipline required

### Why wake-time local truth is right

**Pros:**

- robust to network loss
- clear authority
- cheaper prompt context
- cleaner self-model

**Cons:**

- registry visibility is not live at wake
- install/update is a separate lifecycle step

---

## 18. Acceptance Criteria

This package-system design is complete when:

1. Package publication is defined as Git-native by default.
2. Desired state and resolved state are explicitly separated.
3. Installed roots are deterministic and local.
4. Runtime wake-time package truth comes from local installed state, surfaced through the Runtime Contract.
5. Extensions are clearly modeled as package contents.
6. Bundle/app and registry layers fit above the package system without changing the runtime package substrate.
7. cn doctor and traceability can validate and explain package install state coherently.

---

## 19. Summary

The cnos package system should be:

- Git-native
- desired/resolved
- locally installed
- wake-time local
- extension-ready
- registry-ready

The key model is:

1. **Source** — authored package content
2. **Distribution** — Git-native publication
3. **Installation** — local deterministic materialization
4. **Runtime truth** — wake from installed local state

That is the most coherent package-system shape for cnos.
