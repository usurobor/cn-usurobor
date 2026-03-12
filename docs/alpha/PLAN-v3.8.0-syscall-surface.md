# PLAN-v3.8.0-syscall-surface
## Syscall Surface Coherence — Implementation Plan

**Status:** Draft
**Implements:** `SYSCALL-SURFACE-v3.8.0.md`
**Base:** v3.6.0 (Output Plane Separation) is shipped. CN Shell typed ops, executor, orchestrator, sandbox, and capabilities are all implemented.

---

## 0. Coherence Contract

### Gap
Four ABI incoherences exist in the current shipped surface:
1. `fs_glob` advertised but returns `not_yet_implemented`
2. `git_commit` implicitly stages all (hidden compound behavior)
3. `fs_read` has no chunking (large-file observation is lossy)
4. `fs_patch` silently depends on external `patch(1)`

### Mode
**MCA** — change the runtime and executor.

### Smallest coherent intervention
Implement each of the four fixes in the executor, update types/parser/capabilities/tests, and add `cn doctor` check for `patch(1)`.

---

## 1. Current State

| Component | File | Status |
|-----------|------|--------|
| Shell types + parser | `cn_shell.ml` | Done — `Fs_glob` type exists, not executed |
| Executor dispatch | `cn_executor.ml` | Done — `fs_glob` returns `not_yet_implemented` |
| Path sandbox | `cn_sandbox.ml` | Done |
| Capabilities block | `cn_capabilities.ml` | Done — lists `fs_glob` |
| Orchestrator | `cn_orchestrator.ml` | Done |
| Doctor checks | `cn_system.ml` | Done — no `patch(1)` check |
| Shell tests | `cn_shell_test.ml` | Done |
| Executor tests | `cn_executor_test.ml` | Done — has `fs_glob: not yet implemented` test |

---

## 2. Implementation Steps

### Step 1: Add `Git_stage` to types + parser (`cn_shell.ml`)

Add `Git_stage` to `effect_kind`:

```ocaml
type effect_kind =
  | Fs_write | Fs_patch | Git_branch | Git_stage | Git_commit | Exec
```

Add parsing:
- `"git_stage"` → `Some Git_stage`
- `string_of_effect_kind Git_stage` → `"git_stage"`

**Tests:** kind parsing roundtrip for `git_stage`
**Depends on:** nothing

---

### Step 2: Implement `fs_glob` in executor (`cn_executor.ml`)

Replace the `not_yet_implemented` stub with a real implementation:

1. Extract `pattern` field (required) and `base` field (optional, default `"."`)
2. Sandbox-check the `base` path
3. Walk the directory tree under `base` matching against the glob pattern
4. Filter results through denylist (same as sandbox)
5. Return relative paths as artifact content
6. Cap results at `max_artifact_bytes_per_op`

Glob matching: implement simple glob (`*`, `**`, `?`) in pure OCaml — no external dependency.

**Tests:** basic glob, nested `**`, denylist exclusion, empty match, base path validation
**Depends on:** nothing (types already exist)

---

### Step 3: Implement `git_stage` in executor (`cn_executor.ml`)

New function `execute_git_stage`:

1. Check `apply_mode` is not `"off"`
2. Extract optional `paths` field (list of pathspecs)
3. If `paths` present: sandbox-check each, then `git add <paths>`
4. If `paths` absent: `git add -A` (stage all allowed changes)
5. Return receipt

**Tests:** stage all, stage specific paths, apply_mode off denial, path sandbox
**Depends on:** Step 1

---

### Step 4: Split `git_commit` semantics with `ops_version` gating (`cn_executor.ml`)

Modify `execute_git_commit`:

- Accept `ops_version` parameter (passed from orchestrator context)
- If `ops_version >= "3.8"`:
  - Do NOT run `git add -A` first
  - Just run `git commit -m <message>`
  - If nothing staged and `allow_empty` is false: receipt `skipped` / `nothing_staged`
- If `ops_version < "3.8"` or absent:
  - Retain current behavior (`git add -A` then `git commit`)
  - Emit receipt annotation: `legacy_git_commit_semantics`

**Tests:** new semantics (index-only), legacy semantics, nothing_staged skip, allow_empty
**Depends on:** nothing

---

### Step 5: Add chunking to `fs_read` (`cn_executor.ml`)

Modify `execute_fs_read`:

1. Extract optional `offset` (int, default 0) and `limit` (int, default max_artifact_bytes_per_op)
2. Read file, then slice: `String.sub content offset (min limit remaining)`
3. Clamp `limit` to `max_artifact_bytes_per_op`
4. Record actual byte range in artifact (as metadata or in receipt details)

**Tests:** full read (no offset/limit), partial read with offset, limit clamping, offset beyond file size
**Depends on:** nothing

---

### Step 6: Add `patch(1)` check to `cn doctor` (`cn_system.ml`)

Add a new check to `run_doctor`:

```ocaml
(match Cn_ffi.Child_process.exec "patch --version" with
 | Some v -> { name = "patch"; passed = true; value = ... }
 | None -> { name = "patch"; passed = false;
     value = "not installed (required for fs_patch)" });
```

**Tests:** manual verification (doctor is an interactive command)
**Depends on:** nothing

---

### Step 7: Update capabilities block (`cn_capabilities.ml`)

- Add `"git_stage"` to `effect_kinds_base` (between `"git_branch"` and `"git_commit"`)
- No other changes needed (fs_glob was already listed)

**Tests:** verify `git_stage` appears in rendered capabilities block
**Depends on:** Step 1

---

### Step 8: Wire `ops_version` through orchestrator (`cn_orchestrator.ml`)

Pass `ops_version` from parsed output through to executor for `git_commit` gating.

**Tests:** orchestrator passes ops_version correctly
**Depends on:** Step 4

---

### Step 9: Update all tests

- `cn_shell_test.ml`: add `git_stage` kind parsing tests
- `cn_executor_test.ml`: update `fs_glob` test, add `git_stage` tests, add `fs_read` chunking tests, add `git_commit` version-gated tests
- `cn_capabilities_test.ml` (if exists): verify `git_stage` in rendered output

**Depends on:** Steps 1–8

---

## 3. Dependency Graph

```
Step 1 (git_stage types)     ─── independent
Step 2 (fs_glob impl)        ─── independent
Step 4 (git_commit split)    ─── independent
Step 5 (fs_read chunking)    ─── independent
Step 6 (cn doctor patch)     ─── independent
Step 3 (git_stage executor)  ─── depends on Step 1
Step 7 (capabilities block)  ─── depends on Step 1
Step 8 (orchestrator wire)   ─── depends on Step 4
Step 9 (tests)               ─── depends on Steps 1–8
```

Parallelizable: Steps 1, 2, 4, 5, 6 can start simultaneously.
Critical path: 1 → 3 → 7 → 9.

---

## 4. File Change Summary

| File | Action | Est. Lines |
|------|--------|-----------|
| `src/cmd/cn_shell.ml` | Edit — add `Git_stage` kind + parsing | ~15 |
| `src/cmd/cn_executor.ml` | Edit — implement `fs_glob`, `git_stage`, chunked `fs_read`, split `git_commit` | ~150 |
| `src/cmd/cn_capabilities.ml` | Edit — add `git_stage` to effect kinds | ~2 |
| `src/cmd/cn_system.ml` | Edit — add `patch(1)` doctor check | ~8 |
| `src/cmd/cn_orchestrator.ml` | Edit — wire `ops_version` to executor | ~10 |
| `test/cmd/cn_shell_test.ml` | Edit — add `git_stage` parsing tests | ~30 |
| `test/cmd/cn_executor_test.ml` | Edit — update `fs_glob`, add chunking + staging + split commit tests | ~120 |
| **Total new/changed** | | **~335 lines** |

---

## 5. Risk Mitigation

| Risk | Mitigation |
|------|-----------|
| Glob traversal escapes sandbox | Denylist applied to each result path; base path sandbox-checked |
| `git_stage` with specific paths bypasses denylist | Sandbox-check each path before staging |
| Legacy agent breaks on new `git_commit` | `ops_version` gating preserves old behavior; warnings emitted |
| `fs_read` chunking off-by-one | Unit tests for boundary conditions (offset=0, offset=filesize, limit>remaining) |
| `patch(1)` missing at runtime | `cn doctor` warns; receipt includes `patch_tool_unavailable` if exec fails |

---

## 6. Success Criteria

1. `fs_glob` returns matching files under sandbox/budget rules
2. `git_stage` exists as a standalone effect op
3. `git_commit` commits index-only under `ops_version >= "3.8"`
4. `git_commit` retains legacy behavior for older/absent `ops_version`
5. `fs_read` supports `offset` and `limit` for chunked observation
6. `cn doctor` checks for `patch(1)` availability
7. Capabilities block includes `git_stage`
8. All existing tests pass; new tests cover all changes
