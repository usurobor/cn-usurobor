# PLAN-v3.18.0-package-system

## Implementation Plan for the Git-Native Package System

**Status:** Draft
**Implements:** docs/beta/architecture/PACKAGE-SYSTEM.md
**Depends on:** Runtime Contract v2, Runtime Extensions, Extension Registry
**Supersedes:** #73 Phase 2 selection (cbf123c) — scope expanded to full package substrate

**Purpose:** Turn the converged package-system design into an explicit, coherent implementation so cnos packages are fully Git-native, fully installed, fully surfaced at wake, and fully validated by doctor/traceability.

---

## 0. Coherence Contract

### Gap

cnos already has the beginnings of a coherent package system:

- desired state in .cn/deps.json
- resolved state in .cn/deps.lock.json
- Git-native fetch by (source, rev, subdir)
- local install roots in .cn/vendor/packages/<name>@<version>/
- runtime wake-time truth derived from local installed state

But the current implementation still behaves more like a cognitive asset installer than a complete package system. Known mismatches:

- restore copies only a hardcoded subset of package contents
- third-party package resolution is incomplete / incoherent
- integrity is modeled but not verified
- cn doctor validates presence more than full package-system truth
- package metadata source-of-truth is still split awkwardly
- runtime package resolution by name is ambiguous if multiple versions are installed
- build/install pipeline is not yet complete for profiles and extensions as package contents

### Mode

MCA — change the package system implementation.

### α / β / γ target

- α PATTERN: desired/resolved/install/wake become one explicit package system rather than a partial asset installer
- β RELATION: align package docs, lockfiles, install roots, build system, doctor, Runtime Contract, and runtime asset loading
- γ EXIT: make Runtime Extensions and future bundles/apps rest on a complete package substrate instead of a partial convention

### Smallest coherent intervention

Do not redesign Runtime Extensions or Extension Registry. Complete the package substrate beneath them.

---

## 1. Deliverables

### Code

- full-package restore semantics
- honest third-party handling
- integrity generation + verification
- deeper doctor validation
- exact-version package resolution
- build support for profiles/extensions/package contents
- clarified source-of-truth for package metadata

### Docs

- canonical package-system doc already exists
- this implementation plan
- targeted updates to:
  - Runtime Contract docs
  - doctor / traceability docs
  - package/build docs if needed

### Tests

- desired/resolved parsing
- full-package install breadth
- third-party handling or rejection
- integrity verification
- doctor package validation
- exact version resolution
- build/check/clean support for profiles/extensions

---

## 2. Step Order

### Step 1 — Make restore install full package content

#### Goal

Replace the current hardcoded subset copy with true package installation semantics.

#### Current mismatch

Remote restore currently copies only:

- doctrine/
- mindsets/
- skills/
- cn.package.json

This is insufficient for a package system that also supports:

- profiles
- extensions
- docs/schemas/other package content classes

#### Work

Refactor cn_deps.restore_one so restore installs the full declared package tree, not a special-case subset.

Implementation options:

1. Preferred: use cn.package.json + known package content classes to decide what is installable
2. Fallback: copy the whole package subtree with explicit exclusions for junk/build artifacts

#### Acceptance

- package restore installs profiles and extensions where present
- first-party and future third-party package installs materialize a complete package root
- installed root matches the package-system doc

#### Files

- src/cmd/cn_deps.ml
- tests under test/cmd/

---

### Step 2 — Make third-party source handling honest

#### Goal

Either support third-party packages correctly or reject them explicitly for now.

#### Current mismatch

Non-first-party lock entries currently use:

- empty source
- empty subdir
- and a revision derived from the first-party repo path

This is not a coherent third-party model.

#### Work

Choose one of two coherent states:

##### Option A — Explicitly unsupported for now

- reject non-first-party package entries during resolve/restore
- document this clearly
- make the error explicit and actionable

##### Option B — Implement real third-party source declaration

- extend desired state and lock generation so third-party packages carry:
  - source
  - rev
  - subdir
- resolve them against their actual Git source
- fetch and install them the same way as first-party packages

#### Recommended choice

If third-party ecosystem is not needed immediately, choose Option A first to restore coherence fast. If ecosystem work is imminent, choose Option B and land it properly.

#### Acceptance

- no fake third-party lock entries exist
- third-party behavior is either:
  - truly supported
  - or truly rejected

#### Files

- src/cmd/cn_deps.ml
- desired/resolved schema/docs if Option B
- tests

---

### Step 3 — Add integrity generation and verification

#### Goal

Make lockfile integrity real, not placeholder-only.

#### Current mismatch

Lockfile entries have integrity : string option, but generated entries set None, and restore does not verify integrity after materialization.

#### Work

- generate integrity hashes when producing lock entries
- verify integrity after fetch/materialize
- fail install/doctor if integrity does not match

#### Acceptance

- lock entries carry integrity for installable artifacts
- restore verifies integrity
- doctor can report integrity mismatches clearly

#### Files

- src/cmd/cn_deps.ml
- schemas/docs for lockfile if needed
- tests

---

### Step 4 — Strengthen cn doctor for package truth

#### Goal

Move doctor from structural presence checks to package-system consistency checks.

#### Current mismatch

Doctor currently checks:

- desired/lock existence
- installed roots exist
- cnos.core has required doctrine/mindsets

It does not yet validate:

- lock ↔ install parity deeply
- package metadata validity
- unexpected installed versions
- extension-bearing package structure
- integrity

#### Work

Teach doctor to validate:

##### Structural

- desired state parses
- resolved state parses
- installed roots exist for every lock entry
- package metadata exists and parses

##### Consistency

- installed versions match lockfile exactly
- unexpected extra package versions are reported
- package contents required by metadata are present
- extension-bearing packages contain required extension layout
- integrity matches, once Step 3 lands

#### Acceptance

Doctor can answer:

- what is installed
- what is missing
- what is extra
- what is malformed
- what has integrity mismatch
- what is inconsistent with desired/resolved state

#### Files

- src/cmd/cn_deps.ml
- possibly src/cmd/cn_system.ml
- tests

---

### Step 5 — Resolve package metadata source-of-truth

#### Goal

Make package source-of-truth explicit and non-ambiguous.

#### Current mismatch

Today:

- src/agent/... is the source of truth for package assets
- packages/<pkg>/cn.package.json is the effective source of truth for package metadata

This split may be acceptable, but it must be made coherent.

#### Work

Choose one coherent model:

##### Option A — Documented split

- keep src/agent as asset source
- keep packages/*/cn.package.json as metadata source
- document that split explicitly
- make build/check/doctor enforce it

##### Option B — Full source-native package metadata

- move package manifest source into a src/agent/... package source tree
- generate packages/*/cn.package.json into output during build

#### Recommended choice

Option B is cleaner long-term, but Option A is acceptable if explicitly codified and enforced.

#### Acceptance

- one explicit source-of-truth rule exists
- build/check/doctor reflect that rule
- no hidden ambiguity remains

#### Files

- src/cmd/cn_build.ml
- package metadata layout
- docs
- tests

---

### Step 6 — Make runtime package resolution exact-version coherent

#### Goal

Remove ambiguity if multiple versions of the same package name appear in installed roots.

#### Current mismatch

Cn_assets.find_installed_package currently picks the first directory whose basename matches a package name prefix before @.... That is ambiguous if:

- multiple versions of the same package coexist

#### Work

Choose one coherent rule:

##### Option A — Enforce one installed version per package name

- doctor/restore/build reject multi-version coexistence

##### Option B — Resolve from resolved lockfile exact version

- runtime asset lookup uses exact installed version from resolved state

#### Recommended choice

Option B is stronger and more future-proof, especially for rollback/transitional installs.

#### Acceptance

- runtime asset resolution is deterministic by exact version
- or multi-version installed roots are explicitly disallowed and enforced

#### Files

- src/cmd/cn_assets.ml
- possibly `cn_context`/runtime asset gather path
- tests

---

### Step 7 — Extend build/check/clean to full package content classes

#### Goal

Bring cn_build into parity with the package-system model.

#### Current mismatch

cn_build understands:

- doctrine
- mindsets
- skills

but the package-system and runtime-extension docs expect packages may also contain:

- profiles
- extensions
- package docs/schemas as needed

#### Work

Extend package source declarations / build assembly to include:

- profiles
- extensions
- any agreed package content classes required for first-party packages

Ensure:

- cn build
- cn build --check
- cn build clean

all understand the same content classes.

#### Acceptance

- package output is complete
- package/source drift checks cover the full package shape
- extension-bearing and profile-bearing packages build cleanly

#### Files

- src/cmd/cn_build.ml
- package manifests
- tests

---

### Step 8 — Surface package truth more explicitly in Runtime Contract

#### Goal

Make wake-time package truth complete and operator/agent-friendly.

#### Current state

Runtime Contract already surfaces package names/versions/counts in cognition.

#### Work

Ensure it also cleanly surfaces:

- installed package versions
- role in cognition
- active overrides
- extension-bearing package state
- optional provenance fields if useful:
  - source
  - channel
  - trust class

#### Acceptance

At wake, the agent can determine package truth from Runtime Contract alone without probing the filesystem.

#### Files

- src/cmd/cn_runtime_contract.ml
- tests
- docs if needed

---

### Step 9 — Traceability for package lifecycle

#### Goal

Make package install/update/remove/verification visible as operator truth.

#### Event family

Add or standardize events such as:

- package.resolved
- package.installed
- package.updated
- package.removed
- package.rejected
- artifact.verified
- artifact.integrity_mismatch

#### Acceptance

An operator can reconstruct package lifecycle transitions and failures from traces.

#### Files

- relevant package/deps modules
- traceability docs/tests

---

## Step 10 — Tests

### 10.1 Desired/resolved tests

- desired state parses
- resolved state parses
- lock generation correctness
- if third-party unsupported: explicit rejection tests
- if supported: real (source, rev, subdir) tests

### 10.2 Full package restore tests

- doctrine/mindsets/skills install
- profiles install
- extensions install
- package metadata present
- entire package root materialized correctly

### 10.3 Integrity tests

- correct integrity passes
- mismatched integrity rejects
- doctor reports mismatch

### 10.4 Doctor tests

- missing installed root
- extra installed root
- metadata malformed
- extension-bearing package malformed
- multi-version ambiguity (if disallowed)
- exact-version resolution (if supported)

### 10.5 Runtime Contract tests

- installed packages surfaced correctly
- installed versions surfaced correctly
- active overrides surfaced
- extension-bearing package info surfaced

### 10.6 Build/check/clean tests

- profiles included
- extensions included
- drift detected
- clean removes generated package content correctly

---

## 3. CI / Release Gating

Before release:

- build/check/clean tests green
- package restore/install tests green
- doctor tests green
- integrity tests green
- Runtime Contract package truth tests green

---

## 4. Non-goals

This plan does not include:

- full registry publication workflow
- marketplace/app-store UX
- arbitrary ambient runtime package install
- redesign of Runtime Extensions
- redesign of Extension Registry

Those sit above the package substrate.

---

## 5. Success Criteria

This implementation is complete when:

1. Package publication/retrieval is coherently Git-native.
2. Desired state and resolved state are explicit and deterministic.
3. Restore installs full package content, not only cognitive subsets.
4. Third-party handling is either fully supported or explicitly rejected.
5. Integrity is generated and verified.
6. Doctor validates package-system truth, not just presence.
7. Runtime wake-time package truth comes from local installed state, surfaced through Runtime Contract.
8. Extensions and bundles/apps can sit above the package system without requiring package substrate redesign.

---

## 6. Summary

This plan completes the package substrate beneath Runtime Extensions and Extension Registry.

The key moves are:

- full package install
- honest third-party handling
- integrity verification
- deeper doctor validation
- exact version resolution
- build parity for profiles/extensions
- stronger Runtime Contract package truth

That is the smallest coherent implementation that makes the package-system doc describe reality rather than aspiration.
