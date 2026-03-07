# Cognitive Asset Resolver & Package System (v3.4.0)

**Status:** Draft
**Date:** 2026-03-07
**Authors:** usurobor (design), GPT (co-spec), Sigma (grounding)
**Applies to:** cnos runtime, `cn setup`, `cn agent`, `cn deps`
**Purpose:** Fix the "fresh hub has zero skills / zero mindsets" failure by introducing a local, versioned, git-native asset system.

---

## 1. Problem

Today `cn_context.ml` loads mindsets and skills from a single `hub_path`:

```ocaml
(* cn_context.ml:71 *)
let load_mindsets ~hub_path ~(role : string option) : string =
  let dir = Cn_ffi.Path.join hub_path "src/agent/mindsets" in ...

(* cn_context.ml:132 *)
let load_skills ~hub_path ~message ~(role : string option) ~n =
  let skills_dir = Cn_ffi.Path.join hub_path "src/agent/skills" in ...
```

But a fresh hub is a personal state repo: `spec/`, `threads/`, `state/`, `.cn/`.
The cognitive substrate (mindsets, skills, profile scaffolding) lives in the
`cnos` template repo under `src/agent/`.

There is no bridge:
- no package manifest
- no lockfile
- no install step
- no discovery mechanism
- no runtime asset resolver

Result: a fresh agent wakes with `spec/SOUL.md`, `spec/USER.md`, conversation
history, and an inbound message — **no mindsets, no skills, no agent-ops
guidance**.

The current workaround is documented in `AGENTS.md`:

> Update template with `cd cnos && git pull`. Your hub stays untouched.

But the runtime never *reads* the template repo at wake-up. `pack` takes one
`~hub_path`. Two repos, one resolver input.

This is not graceful degradation; it is silent incoherence.

---

## 2. Goals

1. **Local at wake-up**
   `cn agent` / `cn_runtime.process_one` MUST NOT perform any network access to resolve cognitive assets. Only local files.

2. **Versioned and lockable**
   Skills/mindsets/profiles are installed like package dependencies and pinned in a lockfile.

3. **Git-native distribution**
   Packages are fetched from git-based sources (direct repos or an index repo that points to repos).

4. **Bundled core substrate**
   Every agent always has a baseline constitution:
   - core mindsets (COHERENCE, ENGINEERING, PM, WRITING, OPERATIONS, PERSONALITY, MEMES)
   - core agent skills (especially `agent-ops`)
   - runtime ABI skills

5. **Hub-local overrides**
   A hub may override installed assets locally, but defaults must work without customization.

6. **Deterministic resolution**
   Asset lookup order is explicit and stable. Same lockfile → same packed context.

---

## 3. Non-goals

- Live package installation during inference
- Automatic network fetch during `cn agent`
- Arbitrary code execution from packages
- Full npm-style transitive dependency complexity
- Global per-user package fallback (`~/.config/...`) in v3.4

---

## 4. Core concept: Cognitive Asset Resolver (CAR)

Three asset layers, resolved bottom-up:

### Layer A — Bundled core assets

Shipped with the `cn` binary/package. Always present after `cn setup`.

**Distribution source** may be the template repo (or a release artifact).
**Runtime source** is `.cn/vendor/core/` — wake-up never reads the template
repo directly.

Contents:
- core mindsets: COHERENCE, ENGINEERING, PM, WRITING, OPERATIONS, PERSONALITY, MEMES, THINKING, WISDOM, FUNCTIONAL
- core skills: `agent/agent-ops`, `agent/configure-agent`, `agent/hello-world`, `self-cohere/`, `skill/`
- any other runtime-ABI-critical assets

### Layer B — Installed package assets

Installed into the hub from git-based packages, pinned by lockfile,
materialized locally before wake-up.

Examples:
- `cnos.eng` — engineering skills (`eng/coding`, `eng/reviewing`, etc.)
- `cnos.pm` — PM skills
- `org.acme.incident-response` — org-specific playbooks
- `org.acme.hardware-debug` — domain-specific skills

### Layer C — Hub-local overrides

Optional local files inside the hub that shadow bundled/installed assets.
These live under `agent/` in the hub root — human-managed cognitive overrides,
not source code.

Examples:
- `agent/mindsets/ENGINEERING.md` (override core)
- `agent/skills/eng/my-team/SKILL.md` (extend installed)

### Resolution order

For any asset lookup:

1. **Hub-local override** (Layer C)
2. **Installed package asset** (Layer B)
3. **Bundled core asset** (Layer A)

Bundled core provides the floor; packages enrich it; hub overrides specialize it.

---

## 5. Package model

### What a package contains

A package is a directory tree with any combination of:

| Directory    | Loaded at runtime | Purpose                    |
|-------------|-------------------|----------------------------|
| `mindsets/` | Yes               | Mindset docs               |
| `skills/`   | Yes               | Skill files (SKILL.md)     |
| `profiles/` | Setup only        | Profile templates          |
| `docs/`     | No                | Non-runtime documentation  |
| `examples/` | No                | Non-runtime examples       |

### Package identity

Each package has:

| Field           | Type    | Example                                         |
|-----------------|---------|--------------------------------------------------|
| `name`          | string  | `cnos.eng`, `org.acme.ops`                       |
| `version`       | semver  | `1.0.3`                                          |
| `source`        | URL     | `git+https://example.com/cnos-eng.git`           |
| `rev`           | string  | exact git commit hash                            |
| `integrity`     | hash    | `sha256:...`                                     |
| `engines.cnos`  | range   | `>=3.4.0 <4.0.0`                                |

### Package kinds (logical classes)

These are **logical roles**, not separate installer mechanisms:

1. **core-profile** — default role shape + default package set (e.g. `cnos.profile.engineer`)
2. **skill pack** — domain skills (e.g. `cnos.eng`, `org.acme.hardware-debug`)
3. **mindset pack** — additional doctrine (e.g. `org.acme.sre-principles`)
4. **playbook pack** — structured operational playbooks, exposed as skills
5. **org pack** — team-default combinations of skills + mindsets + profiles

A single package may contain multiple asset kinds.

---

## 6. Manifest and lockfile

### `.cn/deps.json` — desired dependencies

Human-edited (or written by `cn setup` / `cn deps add`).

```json
{
  "schema": "cn.deps.v1",
  "profile": "engineer",
  "packages": [
    { "name": "cnos.eng", "version": "^1.0.0" },
    { "name": "org.acme.incident-response", "version": "~2.4.0" }
  ]
}
```

### `.cn/deps.lock.json` — resolved dependencies

Machine-written. Pinned, deterministic. Committed to the hub repo.

```json
{
  "schema": "cn.deps.lock.v1",
  "packages": [
    {
      "name": "cnos.eng",
      "version": "1.0.3",
      "source": "git+https://example.com/cnos-eng.git",
      "rev": "abc123def456",
      "integrity": "sha256:...",
      "engines": { "cnos": ">=3.4.0 <4.0.0" }
    },
    {
      "name": "org.acme.incident-response",
      "version": "2.4.1",
      "source": "git+ssh://git.example.com/acme/incident-response.git",
      "rev": "fedcba654321",
      "integrity": "sha256:...",
      "engines": { "cnos": ">=3.4.0 <4.0.0" }
    }
  ]
}
```

---

## 7. Local install layout

Installed assets must be local to the hub, vendor-style.

### Canonical location

```
.cn/vendor/
  core/
    mindsets/
      COHERENCE.md
      ENGINEERING.md
      PM.md
      WRITING.md
      OPERATIONS.md
      PERSONALITY.md
      MEMES.md
      THINKING.md
      WISDOM.md
      FUNCTIONAL.md
    skills/
      agent/agent-ops/SKILL.md
      agent/configure-agent/SKILL.md
      agent/hello-world/SKILL.md
      ...
  packages/
    cnos.eng@1.0.3/
      skills/
        eng/coding/SKILL.md
        eng/reviewing/SKILL.md
        ...
    org.acme.incident-response@2.4.1/
      skills/
        ops/incident/SKILL.md
      profiles/
        ...
```

Notes:
- `core/` is materialized from bundled assets at setup/restore time for visibility and debugging
- Package dirs are immutable by version
- Wake-up reads only from `.cn/vendor/` + optional hub-local overrides
- `.cn/vendor/` is in `.gitignore` by default (reproducible from lockfile via `cn deps restore`)
- For airgapped or tightly pinned environments: `cn deps vendor` prepares a committed vendor tree

### Optional future optimization

A shared cache may exist later, but wake-up always resolves through the hub-local vendor tree in v3.4.

---

## 8. Git-native distribution

### Two acceptable models

**A) Direct git source**
Manifest/lockfile points directly to package repos. Simple. No indirection.

**B) Git-native index repo (recommended for discovery)**
A central index repo maps `{name, version}` → `{source, rev, integrity, metadata}`.
More npm-like for discovery, but still git-native. No registry server.

### Fetch mechanics

`cn deps restore` (or `cn deps install`):
1. Read `.cn/deps.lock.json`
2. Materialize bundled core assets into `.cn/vendor/core/`
3. For each locked package not already installed:
   a. `git init` temp dir, `git fetch <source> <rev> --depth=1`
   b. `git checkout <rev>` — the lockfile rev is authoritative, not a tag/branch
   c. If `integrity` is present, verify sha256 (optional in v3.4.0, required in v3.4.1)
   d. Copy runtime-relevant dirs (`mindsets/`, `skills/`) into `.cn/vendor/packages/<name>@<version>/`
   e. Clean up temp dir

Tags and branches can move; the lockfile pins a commit hash. Restore
must checkout that exact rev for deterministic resolution. Tags are used
during `cn deps update` (resolve phase), not during `restore` (install phase).

No network access happens outside this explicit command.

---

## 9. Runtime behavior: changes to `cn_context.ml`

### Current resolver (v3.3)

```ocaml
let load_mindsets ~hub_path ~role =
  let dir = Path.join hub_path "src/agent/mindsets" in ...

let load_skills ~hub_path ~message ~role ~n =
  let skills_dir = Path.join hub_path "src/agent/skills" in ...
```

Single source. No layering.

### Proposed resolver (v3.4)

`cn_context.ml` gains a new module dependency: `Cn_assets` (or inline).

```
load_mindsets ~hub_path ~role
  ↓
  1. scan hub-local overrides:  {hub_path}/agent/mindsets/
  2. scan installed packages:   {hub_path}/.cn/vendor/packages/*/mindsets/
  3. scan bundled core:         {hub_path}/.cn/vendor/core/mindsets/
  ↓
  merge (hub-local wins > package > core)
  ↓
  deterministic load order (all 10 core mindsets):
  COHERENCE → role-file → ENGINEERING → PM → WRITING → OPERATIONS →
  PERSONALITY → MEMES → THINKING → WISDOM → FUNCTIONAL

  Role-file inserts the active role's mindset second (e.g. if role=engineer,
  ENGINEERING is loaded at position 2; it is not duplicated later).
  All 10 are loaded if present — no "file exists but agent never sees it".
```

```
load_skills ~hub_path ~message ~role ~n
  ↓
  1. walk hub-local skills:     {hub_path}/agent/skills/**/SKILL.md
  2. walk installed packages:   {hub_path}/.cn/vendor/packages/*/skills/**/SKILL.md
  3. walk bundled core skills:  {hub_path}/.cn/vendor/core/skills/**/SKILL.md
  ↓
  merge (hub-local wins for same relative path)
  ↓
  keyword scoring + role bonus (unchanged algorithm)
  ↓
  top N
```

### Wake-up rule

`cn agent` / `process_one` MUST NOT perform network access to resolve assets.

If required core assets are not locally installed:
- Runtime fails fast with a clear error
- `cn doctor` reports missing/invalid deps
- Operator runs `cn deps restore`

### Core assets are mandatory

If core mindsets or `agent-ops` cannot be resolved locally, runtime MUST error.
No silent "zero skills" fallback.

---

## 10. Security model for packages

### Packages are content, not code

Packages may contain:
- markdown (mindset docs, skill files)
- profile metadata (JSON/YAML)

Packages MUST NOT install executable hooks or startup scripts in v3.4.

### Trust boundary

`cn deps install` is a human/operator action, not an agent action.

An agent may propose ("missing skill pack needed"), but installation is not
automatic in v3.4.

### Override rules

Core assets are protected:
- Packages may extend core cognition (add new mindsets/skills)
- Packages may not silently replace protected core assets unless explicitly allowed by config
- Hub-local overrides of core assets require explicit operator intent

### Integrity verification

On `cn deps restore`:
- If `integrity` is present in the lockfile entry, verify sha256 hash
  against fetched content. In v3.4.0, integrity is optional; v3.4.1
  makes it required.
- Reject packages where `engines.cnos` does not match running cnos version
- Log warnings for unsigned packages (future: optional signing)

---

## 11. CLI surface

### Discovery

```
cn deps search <query>         Search index for packages
cn deps info <package>         Show package metadata
cn deps list                   List installed packages
```

### Install / update

```
cn deps add <package>@<range>  Add dependency to .cn/deps.json + resolve
cn deps remove <package>       Remove dependency
cn deps update [<package>]     Update lockfile (re-resolve within ranges)
cn deps restore                Install from lockfile (deterministic)
cn deps doctor                 Verify installed assets match lockfile
cn deps vendor                 Commit vendor tree for airgapped use
```

### Optional aliases (ergonomics)

```
cn skill search    → cn deps search --kind=skill
cn skill install   → cn deps add
cn skill list      → cn deps list --kind=skill
```

The canonical model is **dependencies**, not ad hoc skills.

---

## 12. Capability discovery integration

The runtime-generated `## CN Shell Capabilities` block (v3.3.5+) SHOULD also
include a short asset summary:

```markdown
## CN Shell Capabilities

...existing capability block...

### Cognitive Assets
- profile: engineer
- core: cnos v3.4.0 (10 mindsets, 5 core skills)
- packages:
  - cnos.eng@1.0.3 (8 skills)
  - org.acme.incident-response@2.4.1 (3 skills)
- hub-local overrides: 1 mindset, 2 skills
```

This helps the agent reason about what cognition substrate is present without
guessing.

---

## 13. Migration from v3.3.x

### Phase 1: `cn setup` materializes core (backward compatible)

When `cn setup` runs on a fresh hub:
1. Materialize bundled core assets → `.cn/vendor/core/`
2. Create minimal `.cn/deps.json` with profile defaults
3. Resolve and install profile-default packages

In developer checkouts, bundled core may be sourced from the local template
repo during `cn setup` / `cn deps restore`. In production installs, core
assets are bundled with the `cn` binary/package.

### Phase 2: `cn_context.ml` uses CAR

Replace the single-source resolver with the three-layer CAR.

Runtime MUST fail fast if `.cn/vendor/` is missing or core assets cannot be
resolved. "Graceful degradation" is what caused the silent incoherence in the
first place — the whole point of CAR is to eliminate it. Backward compatibility
is handled at setup/restore time, not at wake-up time:

- `cn setup` detects v3.3 hubs, materializes `.cn/vendor/`, writes `deps.json`
- `cn deps restore` populates the vendor tree from the lockfile
- After that, `cn agent` enforces the same fail-fast rule as any new hub

### Phase 3: Full package ecosystem

Index repo, `cn deps search`, third-party packages.

### Existing hubs

A v3.3 hub with no package manifest/lockfile:
- `cn agent` fails fast with a clear error pointing to `cn setup` / `cn deps restore`
- `cn setup` detects the v3.3 layout, materializes core assets, writes default deps
- `cn deps restore` installs from the generated lockfile
- After migration, the hub follows the same rules as any new hub — no special paths

---

## 14. Implementation sketch

### New modules

| Module         | Layer | Purpose                                      |
|---------------|-------|----------------------------------------------|
| `cn_assets.ml` | 3     | CAR: three-layer asset resolver              |
| `cn_deps.ml`   | 3     | Manifest/lockfile parser, install/update logic |

### Modified modules

| Module           | Change                                                  |
|-----------------|---------------------------------------------------------|
| `cn_context.ml` | `load_mindsets` / `load_skills` delegate to `Cn_assets` |
| `cn_system.ml`  | `cn setup` materializes core + default deps             |
| `cn.ml`         | Add `cn deps` subcommand dispatch                       |
| `cn_capabilities.ml` | Add asset summary to capability block              |

### New files

| Path                   | Purpose                        |
|-----------------------|--------------------------------|
| `.cn/deps.json`        | Dependency manifest            |
| `.cn/deps.lock.json`   | Resolved lockfile              |
| `.cn/vendor/core/`     | Materialized core assets       |
| `.cn/vendor/packages/` | Installed package assets       |

---

## 15. Acceptance criteria

A freshly created hub that has run:

```
cn setup
cn deps restore
```

must wake with:
- core mindsets present and loaded in deterministic order
- core `agent-ops` skill present
- profile-selected/default packages locally installed
- no network access during `cn agent`

If `.cn/vendor/` is removed or corrupted:
- Runtime fails fast with a clear error message
- `cn doctor` explains how to restore
- `cn deps restore` re-materializes from lockfile

---

## 16. Design decisions (resolved)

1. **`cn setup` installs a default profile package automatically.**
   Yes. After `cn setup`, a new hub must be impossible to wake without baseline
   cognition. `cn setup` writes `.cn/deps.json` with the chosen profile and runs
   `cn deps restore` automatically. The zero-skills bug is not recoverable by
   "remembering another command."

2. **Install uses direct git URLs; discovery uses an index repo.**
   These are separate paths:
   - **Install:** `cn deps add git+https://...` works without an index.
   - **Discovery:** `cn deps search <query>` requires a git-native index repo.
   Direct URLs ship first; index repo is a v3.4.1 addition.

3. **Org packs declare profile defaults at setup time only.**
   Yes. An org pack may specify "our engineer profile includes X, Y, Z packages,"
   but those defaults materialize into `.cn/deps.json` / `.cn/deps.lock.json`
   during `cn setup` — not via a dynamic runtime inheritance chain. Wake-up
   remains deterministic.

4. **Flat dependencies in v3.4. No transitive resolution.**
   The resolver is already doing a lot: bundling core, materializing vendor
   assets, overlaying hub overrides, preserving deterministic ordering. Adding
   transitive resolution now would multiply complexity before the basics are
   battle-tested.

5. **Runtime never needs to know where `cnos/` lives.**
   Wake-up reads only from `.cn/vendor/` + hub-local overrides. The template
   repo is a *setup/restore-time* source, not a runtime dependency.
   - `cn setup` / `cn deps restore` materializes core assets into `.cn/vendor/core/`
   - After that, `cn agent` reads `.cn/vendor/` exclusively
   - How does setup/restore find core assets? Bundled with the installed `cn`
     binary/package. An explicit `template_path` in config is acceptable as a
     developer-checkout fallback, but is not part of the runtime contract.

6. **`.cn/vendor/` is gitignored by default; optionally committed for airgapped use.**
   Default: gitignored (reproducible from lockfile + `cn deps restore`).
   Optional: `cn deps vendor` prepares a committed vendor tree intentionally
   for airgapped or tightly pinned environments.

---

## 17. Summary

v3.4 introduces a **Cognitive Asset Resolver (CAR)**:

- **Bundled core** assets guarantee minimum cognition at wake-up
- **Installed git-native packages** provide versioned, lockable skill/mindset packs
- **Hub-local overrides** allow customization without forking
- **Wake-up is local and deterministic** — no network, no guessing
- **Discovery/install/update** happen through `cn deps`, not during inference

The root change: `cn_context.ml` stops assuming assets live at a single
`hub_path/src/agent/` and instead resolves through CAR's three layers.
