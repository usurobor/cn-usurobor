# CAR v3.5 Implementation Plan

## Status: Implemented

This plan documents the unified package model refactor from CAR v3.4 (three-layer)
to v3.5 (two-layer, everything-is-a-package).

---

## What was done

### Step 1: Create source package layout

Created `packages/` directory with three packages:
- `packages/cnos.core/` — doctrine, mindsets, core skills
- `packages/cnos.eng/` — engineering skills
- `packages/cnos.pm/` — PM skills

Created `profiles/` with setup-time presets:
- `profiles/engineer.json` → [cnos.core, cnos.eng]
- `profiles/pm.json` → [cnos.core, cnos.pm]

### Step 2: Introduce doctrine stratum

Separated doctrine from skills/mindsets:
- COHERENCE.md moved from mindsets to `cnos.core/doctrine/`
- CAP.md, CA-CONDUCT.md, CBP.md moved from skills to `cnos.core/doctrine/`
- Created concise AGENT-OPS.md doctrine (runtime emission discipline)
- Full agent-ops/SKILL.md remains as a reference skill

### Step 3: Refactor cn_deps.ml

Removed:
- `bundled_core_source` (CN_TEMPLATE_PATH discovery)
- `materialize_core` (vendor/core materialization)

Added:
- `default_first_party_source` constant
- `subdir` field on `locked_dep` type
- `find_local_package_source` (walks up cwd for local checkout)
- `is_first_party` helper
- `restore_one` (per-package restore with subdir support)
- `lockfile_for_manifest` (generates lockfile with rev + subdir)

Changed:
- `default_manifest_for_profile` now expands to [cnos.core, cnos.eng] not cnos.profile.engineer
- `restore` no longer calls materialize_core
- `doctor` calls validate_packages instead of validate_core

### Step 4: Refactor cn_assets.ml

Removed:
- `vendor_core_path` (no more vendor/core)
- `validate_core` (replaced by validate_packages)
- Three-layer resolution (core → packages → overrides)

Added:
- `validate_packages` (checks cnos.core has required doctrine)
- `load_core_doctrine` (loads doctrine in fixed order)
- `find_installed_package` / `list_installed_packages` helpers
- Hub override paths namespaced by package
- Backward-compat flat override support

Changed:
- `asset_summary` type: `doctrine_count` + `mindset_count` replace `core_mindsets` + `core_skills`
- `load_mindsets`: two layers only, COHERENCE excluded (it's doctrine now)
- `collect_skills`: two layers only, dedup by (package_name, rel_path)
- `summarize`: counts doctrine, mindsets, per-package skills

### Step 5: Refactor cn_context.ml

- Added doctrine stratum between identity and mindsets
- System block 1 now: Identity → Doctrine → Mindsets (all cacheable)
- Calls `validate_packages` instead of `validate_core`
- Calls `load_core_doctrine` for always-on doctrine

### Step 6: Refactor cn_system.ml

- `setup_assets` no longer calls `materialize_core`
- Uses `lockfile_for_manifest` to generate lockfile with proper rev + subdir
- Doctor check uses `validate_packages`

### Step 7: Update cn_capabilities.ml

- Asset summary shows doctrine count + mindset count instead of core counts
- Hub overrides only shown if non-zero

### Step 8: Version bump

- `cn_lib.ml` version → 3.5.0
- Help text updated

---

## Files changed

| File | Change type |
|------|------------|
| `packages/cnos.core/` | New directory |
| `packages/cnos.eng/` | New directory |
| `packages/cnos.pm/` | New directory |
| `profiles/engineer.json` | New file |
| `profiles/pm.json` | New file |
| `src/cmd/cn_assets.ml` | Rewritten |
| `src/cmd/cn_deps.ml` | Rewritten |
| `src/cmd/cn_context.ml` | Modified |
| `src/cmd/cn_system.ml` | Modified |
| `src/cmd/cn_capabilities.ml` | Modified |
| `src/lib/cn_lib.ml` | Version bump + help text |
| `docs/alpha/CAR.md` | Updated to v3.5 |
