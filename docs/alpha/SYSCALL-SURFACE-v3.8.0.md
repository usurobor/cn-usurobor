# SYSCALL-SURFACE-v3.8.0
## CN Shell Syscall Surface Coherence Amendment

**Status:** Draft
**Version:** 3.8.0
**Scope:** Tighten the CN Shell ABI where the current surface is misleading, overly implicit, or too lossy for real workflows.
**Related:** `AGENT-RUNTIME.md`, `PLAN-v3.6.0.md`, `TRACEABILITY.md`

---

## 0. Coherence Contract

### Gap
The current syscall surface is mostly coherent, but has four notable edge incoherences:

1. `fs_glob` is advertised but not implemented.
2. `git_commit` implicitly stages everything, which breaks name honesty and composability.
3. `fs_read` is bounded but not chunkable, making large-file observation lossy.
4. `fs_patch` depends on `patch(1)` while neighboring `fs_*` ops are pure/runtime-local, creating a hidden reliability asymmetry.

### Mode
**MCA** — change the system surface itself.

### α / β / γ target
- **α PATTERN:** make the syscall ABI honest and orthogonal
- **β RELATION:** align capabilities docs, live capability blocks, and executor behavior
- **γ EXIT:** preserve a minimal, extensible surface that can grow without special cases

### Smallest coherent intervention
- make advertised observe ops real or remove them
- split implicit multi-step git behavior into explicit ops
- add bounded chunking to file reads
- document, not hide, the `fs_patch` execution model

---

## 1. Problem Statement

The current CN Shell surface is architecturally sound:

- observe/effect split is clean
- naming is predictable (`fs_*`, `git_*`, `exec`)
- policy gating is consistent

But some edges weaken the coherence of the ABI:

- the runtime claims capabilities it does not truly provide
- one op (`git_commit`) does more than its name says
- one observe op (`fs_read`) cannot express iterative inspection
- one effect op (`fs_patch`) has a hidden external dependency

These are not architectural failures. They are **ABI honesty and composability failures**.

---

## 2. Decisions

## 2.1 `fs_glob` becomes a real shipped op

### Decision
`fs_glob` remains part of the observe ABI and MUST be implemented in v3.8.0.

It MUST NOT be advertised in a release unless it is executable.

### Fields
- `pattern` (required)
- `base` (optional, default `"."`)

### Semantics
- operate only within the path sandbox
- results are returned as relative paths
- denylisted and escaped paths are excluded
- bounded by artifact/result limits

### Rationale
Removing it would also be coherent, but implementing it is the smaller and more useful intervention.
Glob is a natural observe primitive and already appears in the advertised capability surface.

---

## 2.2 Split `git_commit` into explicit staging and commit

### Decision
Introduce a new effect op:

- `git_stage`

and change the meaning of:

- `git_commit`

### New semantics

#### `git_stage`
Stages changes into the index.

Fields:
- `paths` (optional list of pathspecs)
- if omitted, stage all allowed changes under the runtime's path exclusions

#### `git_commit`
Commits the **current index only**.

Fields:
- `message` (required)
- `allow_empty` (optional, default `false`)

### Why
The current `git_commit` is really "stage-all-and-commit," which is not honest in the name and prevents finer-grained workflows.

Splitting it restores orthogonality:
- staging is one action
- committing is another

### Empty-index behavior
If `git_commit` is called with nothing staged and `allow_empty` is false:
- no commit is created
- receipt:
  - `status: skipped`
  - `reason: nothing_staged`

---

## 2.3 Backward compatibility for `git_commit`

### Decision
Use `ops_version` to preserve old behavior during a compatibility window.

#### For `ops_version < "3.8"` or absent
`git_commit` MAY retain legacy semantics:
- internally expand to:
  1. `git_stage` (all allowed changes)
  2. `git_commit`

Runtime MUST emit:
- a warning event / receipt annotation that legacy `git_commit` semantics were used

#### For `ops_version >= "3.8"`
`git_commit` means:
- **commit currently staged changes only**

### Rationale
This avoids breaking older agents immediately while making the new ABI honest and forward-clean.

---

## 2.4 Add chunking to `fs_read`

### Decision
`fs_read` gains optional chunking fields:

- `offset` (optional, default `0`)
- `limit` (optional, default runtime-chosen bounded limit)

### Semantics
- `offset` counts bytes in the target file
- `limit` requests bytes from that point
- runtime may clamp `limit` to budget
- receipts/artifacts must record the actual byte range returned

### Rationale
This keeps the vocabulary small while making file observation composable.
Large files should not force agents into lossy one-shot reads or awkward `exec` workarounds.

---

## 2.5 Keep `exec` as argv-based and special

### Decision
No change.

`exec` remains:
- `argv`-based
- allowlisted
- env-scrubbed
- structurally different from named-field fs/git ops

### Rationale
This specialness is justified.
The point of `exec` is raw command structure without shell interpolation.

---

## 2.6 Keep `fs_patch` for now, but make its reliability class explicit

### Decision
No semantic change in v3.8.0.

`fs_patch` remains an effect op, but the runtime/docs MUST explicitly say whether it:
- depends on external `patch(1)`
- or uses an internal patch applier

### v3.8.0 requirement
If `patch(1)` is still required:
- `cn doctor` MUST check it
- receipts MUST make patch execution failure explicit
- docs MUST call out the dependency

### v3.8.1 target
Replace external dependency with an internal patch applier if practical.

### Rationale
This is a reliability asymmetry, but not an ABI design blocker.

---

## 2.7 Defer destructive / remote-expanding ops

### Explicitly deferred
These are NOT part of v3.8.0:

- `fs_delete`
- `fs_rename`
- `git_push`

### Rationale
They are not required to make the current surface coherent.
They also introduce heavier governance, credentials, and recovery questions.

---

## 3. Revised ABI Table

### Observe ops (v3.8.0)
| Kind         | Fields                         | Notes |
|--------------|--------------------------------|-------|
| `fs_read`    | `path`, `offset?`, `limit?`    | Chunkable read |
| `fs_list`    | `path`                         | Directory listing |
| `fs_glob`    | `pattern`, `base?`             | Implemented in v3.8.0 |
| `git_status` | —                              | Working tree status |
| `git_diff`   | `rev`                          | Diff for revision range |
| `git_log`    | `rev`, `max`                   | Commit log |
| `git_grep`   | `query`, `path?`               | Search repo |

### Effect ops (v3.8.0)
| Kind         | Fields                         | Notes |
|--------------|--------------------------------|-------|
| `fs_write`   | `path`, `content`              | Write file |
| `fs_patch`   | `path`, `unified_diff`         | Patch file; dependency must be explicit |
| `git_branch` | `name`                         | Create branch |
| `git_stage`  | `paths?`                       | New in v3.8.0 |
| `git_commit` | `message`, `allow_empty?`      | Commits current index only in `ops_version >= "3.8"` |
| `exec`       | `argv`, `stdin?`               | Opt-in + allowlisted |

---

## 4. Keep / Split / Defer Table

| Surface item | Decision | Reason |
|--------------|----------|--------|
| `fs_read` | **Keep, extend** | Add chunking instead of new op |
| `fs_list` | **Keep** | Already coherent |
| `fs_glob` | **Keep + implement** | ABI honesty |
| `git_status` | **Keep** | Already coherent |
| `git_diff` | **Keep** | Already coherent |
| `git_log` | **Keep** | Already coherent |
| `git_grep` | **Keep** | Already coherent |
| `fs_write` | **Keep** | Pure/runtime-local |
| `fs_patch` | **Keep, document** | Reliability asymmetry acknowledged |
| `git_branch` | **Keep** | Already coherent |
| `git_commit` | **Split / redefine** | Remove hidden staging side effect |
| `git_stage` | **Add** | Needed for explicit composition |
| `exec` | **Keep as special** | `argv` form is correct and safe |
| `fs_delete` | **Defer** | Stronger governance needed |
| `fs_rename` | **Defer** | Stronger governance needed |
| `git_push` | **Defer** | Remote policy + credentials boundary |

---

## 5. Capability Discovery Changes

The live capabilities block MUST reflect the actual shipped surface.

### Required changes
- `fs_glob` may only be listed if it is implemented
- `git_stage` must be included once added
- `git_commit` description should reflect index-only semantics for `ops_version >= "3.8"`

### Versioning
Because `git_stage` is a new effect op and `git_commit` semantics change in a versioned way, this is a **minor version** update.

`ops_version: "3.8"` is the transition point.

---

## 6. Receipts / Events

### New or revised receipt reasons
- `nothing_staged`
- `legacy_git_commit_semantics`
- `glob_limit_exceeded` (if relevant)
- existing policy/sandbox reasons remain unchanged

### Traceability
The runtime SHOULD emit enough detail for operators to answer:
- was `git_commit` using legacy or new semantics?
- was `fs_read` truncated or chunked?
- did `fs_glob` match zero files or hit limits?
- did `fs_patch` fail because the external tool was unavailable?

---

## 7. Migration

### Existing agents / prompts
Agents already using:
- `git_commit` without `git_stage`

continue to work under:
- missing `ops_version`
- or `ops_version < "3.8"`

But they should receive warnings and gradually migrate.

### New guidance
From `ops_version >= "3.8"` onward:
- use `git_stage`
- then `git_commit`

### Documentation updates required
- `AGENT-RUNTIME.md`
- live capability block examples
- `agent-ops/SKILL.md`
- any syscall surface tables in design docs

---

## 8. Non-goals

This amendment does **not**:
- add destructive file ops
- add remote push
- redesign receipts
- change the sandbox model
- change the no-tool-loop / bounded two-pass model
- alter sink-safe rendering

It is a surface-coherence refinement, not a runtime rewrite.

---

## 9. Success Criteria

The amendment is successfully implemented when:

1. `fs_glob` either:
   - works under sandbox/budget rules, or
   - is absent from the advertised ABI

2. `git_commit` no longer hides implicit staging in the new ABI
3. `git_stage` exists and composes cleanly with `git_commit`
4. large-file observation can be expressed with `fs_read(offset, limit)`
5. the live capability block, docs, and executor all describe the same surface

---

## 10. Summary

v3.8.0 is not about expanding the shell dramatically.
It is about making the existing shell **honest, orthogonal, and composable**.

The two most important changes are:
- make `fs_glob` real
- make staging explicit

Everything else follows from those principles.
