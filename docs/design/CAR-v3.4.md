# Cognitive Asset Resolver & Unified Package Model (v3.5.0)

**Status:** Implemented
**Date:** 2026-03-09
**Supersedes:** CAR v3.4.0 (three-layer model)
**Authors:** usurobor (design), Claude (implementation)
**Applies to:** cnos runtime, `cn setup`, `cn agent`, `cn deps`

---

## 1. Problem (unchanged from v3.4)

A fresh hub is a personal state repo: `spec/`, `threads/`, `state/`, `.cn/`.
The cognitive substrate (doctrine, mindsets, skills) must be installed locally
before wake-up. Without it, an agent wakes with no guidance.

---

## 2. What changed from v3.4 to v3.5

v3.4 had three layers: bundled core → installed packages → hub-local overrides.
This created a special case: `.cn/vendor/core/` was managed differently from
packages, and setup depended on `CN_TEMPLATE_PATH` or a sibling cnos checkout.

v3.5 eliminates both:

| v3.4 | v3.5 |
|------|------|
| Three layers (core + packages + overrides) | Two layers (packages + overrides) |
| `.cn/vendor/core/` special directory | Core is package `cnos.core` |
| `CN_TEMPLATE_PATH` for setup | Local checkout discovery or git fetch |
| Mindsets include COHERENCE | COHERENCE is doctrine, not a mindset |
| Doctrine files are skills | Doctrine is a separate always-on stratum |
| `cnos.profile.engineer` package | Profiles expand to package lists |

---

## 3. Design principles

1. **Everything cognitive is a package.** Core is `cnos.core`. Role packs are
   `cnos.eng`, `cnos.pm`. No special "bundled core" path at runtime.

2. **Profiles are NOT packages.** Profiles are setup-time presets that expand
   to package lists. `engineer` → `[cnos.core, cnos.eng]`.

3. **Core doctrine is always-on.** Loaded from `cnos.core` package, not scored,
   not bounded. Doctrine does not compete for skill slots.

4. **Wake-up is local-only.** No network during `cn agent`.

5. **Two-layer resolution:** hub override > installed package. That's it.

6. **Lockfile carries subdir.** Multiple packages may live in one git repo,
   so the lockfile stores `(source, rev, subdir)` for each entry.

---

## 4. Three cognitive strata

The context packer builds from three strata:

### Stratum 1: Core Doctrine (always-on, not scored)
- Source: `cnos.core` package `doctrine/` directory
- Files: COHERENCE.md, CAP.md, CA-CONDUCT.md, CBP.md, AGENT-OPS.md
- Loaded in fixed order, always present
- Hub overrides: `agent/doctrine/cnos.core/<file>`

### Stratum 2: Mindsets (always-on, not scored)
- Source: all installed packages `mindsets/` directories
- 9 files in deterministic order, role-file first
- Hub overrides: `agent/mindsets/<package>/<file>`

### Stratum 3: Task Skills (keyword-scored, bounded)
- Source: all installed packages `skills/` directories
- Deduplicated by `(package_name, relative_path)`
- Hub overrides: `agent/skills/<package>/...`
- Top N by keyword overlap with inbound message

---

## 5. Package model

### Source layout (cnos repo)

```
packages/
  cnos.core/
    cn.package.json
    doctrine/
      COHERENCE.md
      CAP.md
      CA-CONDUCT.md
      CBP.md
      AGENT-OPS.md
    mindsets/
      ENGINEERING.md, PM.md, WRITING.md, OPERATIONS.md,
      PERSONALITY.md, MEMES.md, THINKING.md, WISDOM.md, FUNCTIONAL.md
    skills/
      agent/agent-ops/SKILL.md, agent/configure-agent/SKILL.md, ...
      ops/inbox/SKILL.md, ops/peer/SKILL.md, ...
  cnos.eng/
    cn.package.json
    skills/
      eng/coding/SKILL.md, eng/review/SKILL.md, ...
  cnos.pm/
    cn.package.json
    skills/
      pm/follow-up/SKILL.md, pm/issue/SKILL.md, pm/ship/SKILL.md
```

### Package metadata

```json
{
  "schema": "cn.package.v1",
  "name": "cnos.core",
  "version": "1.0.0",
  "kind": "package",
  "engines": { "cnos": ">=3.4.0 <4.0.0" }
}
```

### Profile presets

```json
{
  "schema": "cn.profile.v1",
  "name": "engineer",
  "packages": [
    { "name": "cnos.core", "version": "^1.0.0" },
    { "name": "cnos.eng", "version": "^1.0.0" }
  ]
}
```

---

## 6. Manifest and lockfile

### `.cn/deps.json`

```json
{
  "schema": "cn.deps.v1",
  "profile": "engineer",
  "packages": [
    { "name": "cnos.core", "version": "^1.0.0" },
    { "name": "cnos.eng", "version": "^1.0.0" }
  ]
}
```

### `.cn/deps.lock.json`

```json
{
  "schema": "cn.deps.lock.v1",
  "packages": [
    {
      "name": "cnos.core",
      "version": "1.0.0",
      "source": "https://github.com/usurobor/cnos.git",
      "rev": "abc123...",
      "subdir": "packages/cnos.core",
      "integrity": null
    },
    {
      "name": "cnos.eng",
      "version": "1.0.0",
      "source": "https://github.com/usurobor/cnos.git",
      "rev": "abc123...",
      "subdir": "packages/cnos.eng",
      "integrity": null
    }
  ]
}
```

Note: `subdir` is required because multiple packages live in one repo.

---

## 7. Hub layout (installed)

```
.cn/
  deps.json
  deps.lock.json
  vendor/
    packages/
      cnos.core@1.0.0/
        cn.package.json
        doctrine/COHERENCE.md, CAP.md, ...
        mindsets/ENGINEERING.md, PM.md, ...
        skills/agent/agent-ops/SKILL.md, ...
      cnos.eng@1.0.0/
        cn.package.json
        skills/eng/coding/SKILL.md, ...
agent/
  doctrine/
    cnos.core/
      CAP.md               # hub-local override
  mindsets/
    cnos.core/
      ENGINEERING.md        # hub-local override
  skills/
    cnos.eng/
      eng/review/SKILL.md   # hub-local override
```

No `.cn/vendor/core/` — core is just another installed package.

---

## 8. Setup and restore

### `cn setup`

1. Write `.cn/deps.json` from profile expansion
2. Write `.cn/deps.lock.json` with pinned revs and subdirs
3. Run `cn deps restore` to install packages
4. Add `.cn/vendor/` to `.gitignore`

### `cn deps restore`

For each lock entry:
1. Check if already installed at `.cn/vendor/packages/<name>@<version>/`
2. Try local first-party source (walk up from cwd for cnos checkout)
3. Else: `git init tmp && git fetch <source> <rev> --depth=1 && git checkout <rev>`
4. Copy `<subdir>/` contents into `.cn/vendor/packages/<name>@<version>/`
5. Copy doctrine/, mindsets/, skills/, cn.package.json

No `CN_TEMPLATE_PATH`. No shell string composition. Argv-only git.

---

## 9. Validation / fail-fast

Runtime MUST fail if cnos.core is not installed or is missing required doctrine:
- COHERENCE.md
- CAP.md
- CA-CONDUCT.md
- AGENT-OPS.md

No silent "zero doctrine" wake-up.

---

## 10. Backward compatibility

### Hub overrides

Both namespaced and flat override paths are supported:
- Namespaced (new): `agent/mindsets/cnos.core/ENGINEERING.md`
- Flat (legacy): `agent/mindsets/ENGINEERING.md` → treated as cnos.core override

### Migration from v3.4

- Old `.cn/vendor/core/` is ignored by v3.5 runtime
- Running `cn setup` or `cn deps restore` installs packages fresh
- Old `cnos.profile.engineer` manifest entries should be manually updated

---

## 11. CLI surface

```
cn deps [list]         List installed packages
cn deps restore        Install from lockfile (deterministic)
cn deps doctor         Verify installed assets match lockfile
cn deps add <pkg>      Add dependency to .cn/deps.json
cn deps remove <pkg>   Remove dependency
cn deps update [pkg]   Update lockfile (v3.5.1+)
cn deps vendor         Commit vendor tree for airgapped use
```

---

## 12. Acceptance criteria

After `cn setup`, a fresh hub must have:
- cnos.core installed under `.cn/vendor/packages/cnos.core@1.0.0/`
- Core doctrine always present at wake-up
- Role-appropriate skills present
- No dependency on a nearby cnos checkout at runtime
- No network during `cn agent`
