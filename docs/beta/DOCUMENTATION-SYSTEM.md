# Documentation System

How the docs/ tree is organized and how documents evolve.

**Version:** 3.13.0
**Date:** 2026-03-23

---

## 1. Taxonomy

The docs tree has two dimensions:

1. **Triad axis** — every document has a dominant ontological character (α, β, γ)
2. **Feature bundle** — related documents across classes are grouped by the feature they serve

### 1.1 Triad axis

| Directory | Axis | Question it answers |
|-----------|------|-------------------|
| (root) | The whole | What is cnos? (`THESIS.md`) How to read these docs? (`README.md`) |
| `alpha/` | **Pattern** | What has been articulated? Doctrine, specs, definitions, protocol. |
| `beta/` | **Relation** | Do the parts reveal one system? System overview, vocabulary, guides, evidence. |
| `gamma/` | **Evolution** | How does it change? Method, plans, checklists. |

### 1.2 Feature bundles

A feature bundle groups all documents that belong to a single feature or subsystem. A bundle lives as a subdirectory within its dominant axis (usually `alpha/`).

Structure:
```
docs/alpha/<feature-name>/
├── README.md           # Bundle index: what this feature is, reading order, document map
├── v1.0.0/             # Frozen snapshot for v1.0.0
│   ├── README.md
│   └── SPEC.md
├── v1.0.6/             # Frozen snapshot for v1.0.6
│   ├── README.md
│   └── SPEC.md
└── (other bundle-local docs if needed)
```

The canonical spec for a bundled feature may live either:
- **Inside the bundle** as `docs/alpha/<feature-name>/SPEC.md`, or
- **At the alpha root** as `docs/alpha/<FEATURE-NAME>.md` (legacy placement, see §6)

A bundle's README.md always links to the canonical spec regardless of placement.

### 1.3 Root-level documents

- **THESIS.md** — the whole, above the triad. Always the entry point.
- **README.md** — reading guide, navigation, and feature bundle index.

---

## 2. Document classes

### 2.1 Whole

The thesis. Sits above the triad. One document: `THESIS.md`.

### 2.2 Canonical spec

Evolves in place. Never forked into versioned copies at the same level. The single source of truth for its scope.

- Keep a version and date in the header
- Accumulate patch notes or version history internally
- Snapshot to version directories at release boundaries (see §4)

Examples: AGENT-RUNTIME.md, RUNTIME-EXTENSIONS.md, COGNITIVE-SUBSTRATE.md, COHERENCE-SYSTEM.md, CAA.md.

### 2.3 Feature README

The index document for a feature bundle. Lives at `docs/alpha/<feature>/README.md`.

- Lists every document in the bundle
- Provides reading order
- Links to the canonical spec, snapshots, and related plans
- Updated whenever the bundle's contents change

### 2.4 Feature-scoped design doc

A design document scoped to a specific version or feature iteration. These are created when a release introduces substantial new behavior that warrants a dedicated design narrative.

- Filename encodes scope: `<FEATURE>-v<VERSION>.md` or `<FEATURE>-<SCOPE>.md`
- Lives at `alpha/` root (legacy) or inside a feature bundle
- Not canonical — the canonical spec absorbs the design after implementation ships

Examples: N-PASS-BIND-v3.8.0.md, RUNTIME-CONTRACT-v3.10.0.md, SYSCALL-SURFACE-v3.8.0.md.

### 2.5 Reference document

Stable lookup material. Updated when terminology or conventions change, not per release.

Examples: GLOSSARY.md, NAMING.md.

### 2.6 Guide

Task-oriented procedures connecting operator to system. Lives in `beta/guides/`.

Examples: AUTOMATION.md, HANDSHAKE.md, TROUBLESHOOTING.md.

### 2.7 Plan

Implementation plan for a specific release or subsystem. Lives in `gamma/plans/`.

- Filename encodes scope: `PLAN-vX.Y.Z.md` or `NAME-implementation-plan.md`
- Ephemeral — relevant during implementation, archived after

### 2.8 Evidence

Audits, RCAs, and model↔reality assessments. Lives in `beta/evidence/`.

### 2.9 Version directory

A version directory groups all frozen artifacts for a single release milestone. Lives directly inside the feature bundle as `v<MAJOR>.<MINOR>.<PATCH>/`.

```
docs/alpha/<feature>/v1.0.6/
├── README.md      # Required: snapshot manifest
├── SPEC.md        # Frozen canonical spec at this version
├── DESIGN.md      # Design narrative (if one existed for this version)
└── ...            # Any other version-scoped artifacts
```

- Directory name is the version number: `v1.0.6/`, `v3.8.0/`, etc.
- Version directories are frozen by repository policy. After creation, their contents MUST NOT be modified in later commits. Corrections MUST be published as a new version directory or an explicit superseding note in the feature root README
- Each version directory MUST contain a `README.md` describing the snapshot and the canonical doc(s) published for that version
- Additional version-scoped artifacts (design narratives, migration notes) MAY be included

---

## 3. Versioning rules

### Single version lineage

All documents in the cnos repository use **cnos release versions**. There is no independent per-document version lineage.

The `Version:` header in every document records the **cnos release in which the document was last substantively changed**. A document at `Version: 3.13.0` means "this document was last updated as part of cnos v3.13.0."

This rule eliminates version-alignment confusion. "What does cnos v3.13.0 look like?" answers everything — specs, governance, runtime, docs — with one version number.

### When a document's version advances

A document's version advances to the current cnos release version when:

| Change type | Advances version? |
|-------------|-------------------|
| Wording, examples, typos | Yes (next patch release) |
| New section, additive capability | Yes (next minor release) |
| Scope change, structural rewrite | Yes (next minor or major release) |
| No change in a release | No — version stays at the last release that touched it |

### Version directories

Version directories inside feature bundles use the cnos release version, not a document-local version. Example: `docs/alpha/agent-runtime/v3.8.0/` — not `v2.0.0/`.

### Supersession

When a canonical document is fully replaced, the new document's version is the cnos release in which it first appears. It does not restart at 1.0.0.

Do not maintain parallel versions of the same document in active directories.

### Legacy versions

Some existing documents carry pre-cnos-aligned version numbers (e.g., THESIS 1.0.0, COHERENCE-SYSTEM 1.0). These will be re-versioned to cnos release numbers when next substantively updated. No retroactive bulk rename is required.

### Frozen legacy snapshots

Version directories created before the single-lineage rule MAY retain their historical version numbers (e.g., `runtime-extensions/v1.0.6/`). These are frozen artifacts — renaming them would violate the freeze contract (§4). The legacy version number in a frozen snapshot directory name records the version under which that snapshot was originally published, not a current cnos release version. New version directories MUST use cnos release versions.

---

## 4. Version directory rules

### When to create a version directory

Create a version directory inside a feature bundle when:
- A minor or major release ships that changes the spec
- The spec is referenced by a released runtime version
- A feature-scoped design doc is produced for that version

### Where version directories live

Version directories live directly inside the feature bundle:
```
docs/alpha/<feature>/vX.Y.Z/
```

If the feature does not yet have a bundle directory, create one when the first version directory is needed.

### What goes inside

A version directory is a frozen snapshot of that feature bundle's published artifact set for that version. The feature root contains the current canonical documents. Version directories are historical records only and never replace the feature root as the latest source of truth.

Each version directory MUST contain:

| File | Purpose |
|------|---------|
| `README.md` | Snapshot manifest: what this version shipped, why, and an explicit enumeration of the canonical files included in this snapshot |
| Canonical doc(s) | Frozen copy of the canonical spec (`SPEC.md`, etc.) published for this version |

Each version directory MAY also contain:

| File | When to include |
|------|----------------|
| `DESIGN.md` | Design narrative for this version's changes |
| Other | Any version-scoped artifact (migration notes, issue summary, etc.) |

Version directories are frozen by repository policy. After creation, their contents MUST NOT be modified in later commits. Corrections MUST be published as a new version directory or an explicit superseding note in the feature root README. Legacy flat filenames (e.g., `v1.0.6.md`) MUST be mapped in the feature root README (see §6).

---

## 5. Feature bundle rules

### The bundle contract

**Every feature bundle has `README.md` as the navigation entrypoint and names exactly one canonical spec as the normative source of truth.**

The canonical spec may live at `alpha/<feature>/SPEC.md` (bundle-local) or at `alpha/<FEATURE-NAME>.md` (legacy root placement). Either is valid; the README.md must link to it unambiguously.

### When to create a bundle

Create a feature bundle when a feature has:
- A canonical spec, AND
- At least one snapshot OR at least one feature-scoped design doc

Single-document features (e.g., SECURITY-MODEL.md) do not need a bundle.

### Bundle structure

```
docs/alpha/<feature-name>/
├── README.md            # Required: bundle index, names the canonical
├── v1.0.6/              # Version directory: frozen snapshot for v1.0.6
│   ├── README.md
│   └── SPEC.md
├── v3.8.0/              # Version directory: frozen snapshot for v3.8.0
│   ├── README.md
│   ├── DESIGN.md
│   └── SYSCALL-SURFACE.md
└── ...
```

Each version directory is a frozen snapshot of that version's published artifact set (see §4). The feature root holds the current canonical; version directories are historical records only. No intermediate `versions/` layer needed.

### Bundle README requirements

- Feature name and one-sentence purpose
- **Which document is the canonical spec** (by name and path)
- Document map: every file in the bundle, with one-line description
- Reading order for new readers
- Link to related plans in `gamma/plans/`

---

## 6. Migration path for legacy filenames

Several documents in `docs/alpha/` use version-stamped filenames at the root level. These predate the feature bundle system.

### Legacy version-stamped files

| File | Class | Migration target |
|------|-------|-----------------|
| `N-PASS-BIND-v3.8.0.md` | Feature-scoped design doc | `alpha/agent-runtime/` bundle |
| `RUNTIME-CONTRACT-v3.10.0.md` | Feature-scoped design doc | `alpha/agent-runtime/` bundle |
| `SYSCALL-SURFACE-v3.8.0.md` | Feature-scoped design doc | `alpha/agent-runtime/` bundle |
| `SCHEDULER-v3.7.0.md` | Feature-scoped design doc | `alpha/agent-runtime/` bundle |
| `CTB-v4.0.0-VISION.md` | Vision doc | Stays at root (cross-cutting) |

### Legacy plans at alpha root

| File | Migration target |
|------|-----------------|
| `PLAN-v3.7.0.md` | `gamma/plans/` |
| `PLAN-v3.8.0-syscall-surface.md` | `gamma/plans/` |

### What stays, what moves

- **Canonical specs stay at their current root paths.** `alpha/AGENT-RUNTIME.md` and `alpha/RUNTIME-EXTENSIONS.md` remain where they are. Bundle READMEs link to them. No moved notices needed.
- **Snapshots move into version directories in their owning bundle.** The Runtime Extensions snapshot moved from `alpha/versions/runtime-extensions/v1.0.6.md` to `alpha/runtime-extensions/v1.0.6/SPEC.md`. Version history now lives with the feature it belongs to.
- **Feature-scoped design docs are not moved in this version.** They are documented in the table above. Future migration: move into the owning bundle's version directory (e.g., `N-PASS-BIND-v3.8.0.md` → `agent-runtime/v3.8.0/DESIGN.md`), leave a one-line moved-notice at the old path.
- **Legacy plans at alpha root are not moved in this version.** Future migration: move to `gamma/plans/`.
- New documents MUST follow the bundle/placement rules above.
- A moved-notice is a file that says: `Moved to <new-path>. This file will be removed in a future release.`

---

## 7. Placement rules

When adding a new document, ask: **what is its dominant ontological character?**

1. **Does it articulate substance?** (doctrine, spec, definition, protocol) → `alpha/`
2. **Does it define relation?** (how parts connect, vocabulary, operator connection, model↔reality evidence) → `beta/`
3. **Does it govern movement?** (method, process, plans, gates) → `gamma/`

Within each axis:
- `α/<feature>/` — feature bundle (when the feature qualifies per §5)
- `β/guides/` — task-oriented procedures (operator ↔ system relation)
- `β/evidence/` — audits, RCAs (model ↔ reality relation)
- `γ/plans/` — ephemeral implementation plans
- `γ/checklists/` — release gate verification

If it doesn't fit any axis, the taxonomy may need to evolve — but update this document before creating new structure.

---

## 8. CI validation

The following invariants should be enforced by CI:

- Every feature bundle directory has a README.md that names exactly one canonical spec
- Version directories match `v[0-9]*` and contain only `.md` files
- No canonical spec has a version-stamped filename (flag as legacy if found)
- `SPEC.md` in a version directory matches the canonical spec at that tagged version (advisory)

---

## 9. Relationship to the coherence loop

The docs tree is itself an articulation of coherence. Its structure is triadic: α (pattern), β (relation), γ (evolution). Feature bundles add a second dimension: the feature surface.

The reading order for CMP:

1. `THESIS.md` — the whole
2. `README.md` — navigation and bundle index
3. `alpha/` — what has been articulated? (follow feature bundles for depth)
4. `beta/` — do the parts cohere?
5. `gamma/` — how does it move?

This is the MCP formation sequence. If a document disrupts this order — if a reader must cross axes to form a coherent picture — the document is probably on the wrong axis.
