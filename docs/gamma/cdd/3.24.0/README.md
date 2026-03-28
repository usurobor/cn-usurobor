## v3.24.0 -- P0: distribute agent templates via package system (#119)

**Issue:** #119
**Branch:** claude/3.24.0-119-setup-templates
**Mode:** MCA
**Active skills:** eng/ocaml, eng/coding, eng/architecture-evolution

### Gap

`cn init` writes hardcoded 10-line SOUL.md and 8-line USER.md stubs instead of the distributed templates from `src/agent/`. The package system distributes doctrine, mindsets, skills, and extensions -- but not agent identity templates. Every new hub starts with a degraded soul.

### Coherence contract

- **alpha target:** Templates as a first-class package source category, same pattern as doctrine/mindsets/skills/extensions
- **beta target:** Build, package, install, and setup paths aligned -- template content flows from `src/agent/templates/` through `cn build` -> package -> install -> `cn init`
- **gamma target:** P0 resolved. New hubs get the full distributed SOUL.md and USER.md on first setup

### Acceptance criteria

| AC | Description | Evidence |
|----|-------------|----------|
| AC1 | `cn init` writes SOUL.md from installed cnos.core templates | Template read from `.cn/vendor/packages/cnos.core@*/templates/SOUL.md` |
| AC2 | `cn init` writes USER.md from installed cnos.core templates | Template read from `.cn/vendor/packages/cnos.core@*/templates/USER.md` |
| AC3 | Fallback to inline stubs if package not installed | `read_template` returns stub when cnos.core not found |
| AC4 | Templates distributed via cnos.core package | `cn.package.json` declares `"templates": [...]` |
| AC5 | `cn build` copies templates to package directory | `source_decl.templates` field, `copy_source` handles category |

### Deliverables

- `src/agent/templates/SOUL.md` -- template source (moved from `src/agent/SOUL.md`)
- `src/agent/templates/USER.md` -- template source (moved from `src/agent/USER.md`)
- `packages/cnos.core/cn.package.json` -- `templates` source list added
- `src/cmd/cn_build.ml` -- `templates` field in `source_decl`, build/check/clean support
- `src/cmd/cn_system.ml` -- `read_template` helper, `run_init` updated
- `test/cmd/cn_cmd_test.ml` or `test/cmd/cn_system_test.ml` -- template resolution tests
- `docs/gamma/cdd/3.24.0/SELF-COHERENCE.md` -- self-coherence report
