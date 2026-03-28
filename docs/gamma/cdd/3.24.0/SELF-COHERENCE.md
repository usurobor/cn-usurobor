## Self-Coherence -- v3.24.0

### Changes reviewed

1. `src/agent/templates/SOUL.md` -- Moved from `src/agent/SOUL.md`. Same content, now under a dedicated templates category for package distribution.
2. `src/agent/templates/USER.md` -- Moved from `src/agent/USER.md`. Same content, templates category.
3. `packages/cnos.core/cn.package.json` -- Added `"templates": ["SOUL.md", "USER.md"]` to sources.
4. `src/cmd/cn_build.ml` -- Extended `source_decl` with `templates` field. Build, check, and clean all handle the new category. Templates use individual-file copy (same as mindsets), not directory copy (skills).
5. `src/cmd/cn_system.ml` -- Added `read_template` helper (reads from installed cnos.core `templates/` directory, returns Result). `run_init` now reads SOUL.md/USER.md from installed templates after `setup_assets`, falling back to inline stubs. `run_setup` populates missing `spec/SOUL.md` and `spec/USER.md` from templates.
6. `packages/cnos.core/templates/SOUL.md`, `USER.md` -- Build output (generated from `src/agent/templates/`).
7. `test/cmd/cn_build_test.ml` -- Updated test fixture with templates in manifest. 4 new tests: build copies templates, clean removes templates, check detects template drift, template resolution positive/negative/missing paths. 4 e2e regression tests: setup populates missing templates, setup creates spec/ on partial hub, setup preserves operator content, init fallback to stubs.

### alpha (structural)

**A** -- Templates follow the exact same pattern as the existing 4 source categories (doctrine, mindsets, skills, extensions). `source_decl` gains one field. `build_one`, `check_one`, `clean_package_dir` each gain one line. `copy_source` handles templates via the individual-file path (same branch as mindsets). `read_template` returns `(string, string) result` -- three cases: Ok content, Error "not installed", Error "not found". No new abstraction -- pure extension of existing infrastructure.

### beta (relational)

**A** -- The template distribution path is fully aligned: `src/agent/templates/` -> `cn build` -> `packages/cnos.core/templates/` -> `cn deps restore` -> `.cn/vendor/packages/cnos.core@<ver>/templates/` -> `read_template` -> `spec/SOUL.md`. Each step uses existing infrastructure. `run_init` writes templates AFTER `setup_assets` (not before), ensuring the package is installed before reading. `run_setup` only populates missing files (doesn't overwrite operator customizations). Fallback stubs preserved for offline/partial-install scenarios.

### gamma (process)

**A-** -- Active skills applied: eng/ocaml (Result type for read_template, type extension for source_decl), eng/coding (single source of truth -- templates live in `src/agent/templates/`, inline stubs preserved only as fallback), eng/architecture-evolution (templates as 6th source category extends the package platform).

Cannot verify compilation (no OCaml toolchain). CI is the compilation check. The `source_decl` record change requires all existing test fixtures to include the `templates` field -- handled by adding it to the test manifest. Existing tests unaffected since `parse_string_array` returns `[]` for missing keys.
