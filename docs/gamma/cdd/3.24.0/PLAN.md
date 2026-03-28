# PLAN-v3.24.0-setup-templates

## Implementation Plan for Template Distribution via Package System

Status: Complete
Implements: #119 (cn setup uses hardcoded stubs instead of distributed templates)
Purpose: Replace hardcoded inline SOUL.md/USER.md stubs in cn_system.ml with
templates distributed through the package system as a new content class.

---

## 0. Coherence Contract

### Gap

`cn init` writes hardcoded 10-line SOUL.md and 8-line USER.md stubs instead
of the 149-line / 42-line distributed templates from `src/agent/`. The package
system distributes doctrine, mindsets, skills, and extensions -- but not agent
identity templates. Every new hub starts with a degraded soul.

CDD S3.2 (one canonical source per fact) is violated: the inline stubs are a
stale copy that never receives updates from the source of truth.

### Mode

MCA -- extend the package system with a templates source category; modify
setup to read from installed package.

### alpha / beta / gamma target

- alpha PATTERN: templates as a first-class package content class, same
  pattern as doctrine/mindsets/skills/extensions
- beta RELATION: build, package, install, and setup paths aligned -- template
  content flows from `src/agent/templates/` through `cn build` to package to
  install to `cn init`
- gamma EXIT: P0 resolved. New hubs get the full distributed SOUL.md and
  USER.md on first setup

---

## 1. Steps

### Step 1: Create template source directory

Move `src/agent/SOUL.md` to `src/agent/templates/SOUL.md`.
Move `src/agent/USER.md` to `src/agent/templates/USER.md`.

Rationale: templates need their own source category directory, same as
doctrine/, mindsets/, skills/, extensions/.

### Step 2: Declare templates in cnos.core manifest

Add `"templates": ["SOUL.md", "USER.md"]` to
`packages/cnos.core/cn.package.json` sources.

### Step 3: Extend build system

In `src/cmd/cn_build.ml`:
- Add `templates` field to `source_decl` type
- Update `parse_sources` to parse templates from manifest
- Update `copy_source` to handle templates (individual file copy mode,
  same as mindsets)
- Update `clean_package_dir` to include templates directory
- Update `check_one` to include templates in diff comparison
- Update `build_one` to copy templates
- Update `run_build` output to show templates count

### Step 4: Add read_template helper

In `src/cmd/cn_system.ml`:
- Add `read_template ~hub_path template_name` function
- Reads from installed cnos.core templates/ directory via
  `Cn_assets.find_installed_package`
- Returns `(string, string) result`: Ok content | Error reason

### Step 5: Update run_init

In `src/cmd/cn_system.ml`:
- Restructure `run_init` so SOUL.md/USER.md are written AFTER `setup_assets`
  (which installs packages), not before
- Use `read_template` to read templates from installed package
- Fall back to inline stubs if package not installed (AC3)

### Step 6: Update run_setup

In `src/cmd/cn_system.ml`:
- Populate missing spec/SOUL.md and spec/USER.md from templates
- Ensure spec/ directory exists before populating (partial hub safety)
- Never overwrite existing operator-customized content

### Step 7: Sync package build output

Run `cn build` (or manually copy) to populate
`packages/cnos.core/templates/SOUL.md` and `USER.md` from source.

### Step 8: Add tests

In `test/cmd/cn_build_test.ml`:
- Update test fixture manifest to include templates
- Add build copies templates test
- Add clean removes templates test
- Add check detects template drift test
- Add read_template positive/negative/missing path tests
- Add e2e regression tests:
  - run_setup populates missing templates
  - run_setup creates spec/ on partial hub
  - run_setup preserves operator content
  - init fallback when cnos.core not installed

### Step 9: Create canonical architecture doc

Create `docs/alpha/package-system/PACKAGE-SYSTEM.md`:
- Define the 6 content classes and copy modes
- Document the build/check/clean/install pipeline
- Document manifest schema
- Document explicit-vs-generic design rationale
- Document tradeoffs and history

### Step 10: Version bump

Bump VERSION, cn.json, cnos.core, and cnos.eng to 3.24.0.
Package content changed, so package version must advance.

---

## 2. Acceptance Criteria

| AC | Description |
|----|-------------|
| AC1 | `cn init` writes SOUL.md from installed cnos.core templates |
| AC2 | `cn init` writes USER.md from installed cnos.core templates |
| AC3 | Templates fall back to inline stubs if cnos.core not installed |
| AC4 | Templates distributed via cnos.core package |
| AC5 | `cn build` copies templates from `src/agent/templates/` to package |

---

## 3. Non-goals

- Generic/extensible content class model (deferred until 7th class creates pressure)
- True CLI integration tests for run_init/run_setup (simulated path tests sufficient)
- Registry or marketplace support for templates
