# Comprehensive Audit: cn-agent

**Date:** 2026-02-06
**Version:** v2.1.0
**Scope:** Full codebase — OCaml source, tests, docs, skills, mindsets, specs, configs
**Method:** Every file read and assessed against FUNCTIONAL.md, OCaml SKILL.md, and project conventions

---

## Executive Summary

| Dimension | Grade | Notes |
|-----------|-------|-------|
| **No JS outside dist** | A | PASS — only `tools/dist/{inbox,peer-sync}.js` exist |
| **FUNCTIONAL.md compliance** | C+ | Multiple violations: `ref`, `with _ ->`, `begin...end`, `if`/`else` chains |
| **OCaml skill compliance** | B- | Duplicated FFI modules, missing tool READMEs, type alias misuse |
| **Test quality** | B | Pure libs well-tested; FFI/main modules and executor untested |
| **Code duplication** | D | String helpers, FFI modules, peer parsing, action types all duplicated |
| **Documentation currency** | C | 4 docs cite stale versions (v1.2–v1.6 vs v2.1.0 actual) |
| **Skills structure** | C+ | 4 duplicate skill pairs (root/ vs eng/), 1 misplaced deprecated skill |
| **Build/packaging** | D | `dist/cn.js` missing; `.gitignore` conflicts with packaging expectations |
| **Architecture coherence** | A- | Design docs excellent; agent purity well-specified but not runtime-enforced |
| **Overall** | B- | Strong conceptual design; significant code-level and build-level issues |

---

## 1. JavaScript Audit: No JS Outside /dist

**Verdict: PASS**

| Location | JS Files | Status |
|----------|----------|--------|
| `tools/src/` | 0 | All OCaml (.ml) |
| `tools/test/` | 0 | All OCaml (.ml) |
| `bin/` | 0 | Shell script only |
| `skills/` | 0 | Markdown only |
| `docs/` | 0 | Markdown only |
| Root | 0 | No .js, .mjs, .cjs |
| `tools/dist/` | 2 | `inbox.js` (716KB), `peer-sync.js` (634KB) — legitimate build artifacts |

**Critical gap:** `dist/cn.js` does **not** exist. `bin/cn` references `$SCRIPT_DIR/../dist/cn.js` and `package.json` has `bundle:cn` targeting `dist/cn.js`, but this file was never built or committed. The main CLI entry point is non-functional.

**Build path inconsistency:**
- `package.json` scripts output to `dist/` (root level)
- Committed artifacts are in `tools/dist/` (different path)
- `.gitignore` ignores `dist/` (matches both `dist/` and `tools/dist/`)
- OCaml SKILL.md says "Bundled `.js` committed to `tools/dist/`"
- `package.json` `files` field references `dist/` for npm packaging

These are contradictory. The build, gitignore, and packaging expectations are misaligned.

---

## 2. FUNCTIONAL.md Compliance Audit

FUNCTIONAL.md prescribes: pattern matching over conditionals, pipelines over sequences, immutable over mutable, Option over exceptions, types that prevent invalid states, small composable functions, fold/recursion over loops, total functions.

### 2.1 Red Flag: `ref` usage

| File | Lines | Code | Fix |
|------|-------|------|-----|
| `inbox.ml` | 226–227 | `let processed = ref 0` / `let skipped = ref 0` | `List.fold_left` returning `(processed, skipped)` tuple |

```ocaml
(* Current — violates "Immutable over Mutable" *)
let processed = ref 0 in
let skipped = ref 0 in
threads |> List.iter (fun t -> ... incr processed ...);
Printf.printf "Processed: %d | Skipped: %d" !processed !skipped

(* Preferred — fold *)
let (processed, skipped) =
  threads |> List.fold_left (fun (p, s) t ->
    match process_thread t with
    | true -> (p + 1, s)
    | false -> (p, s + 1)
  ) (0, 0)
```

### 2.2 Red Flag: `with _ ->` blanket exception catch

| File | Lines | Code |
|------|-------|------|
| `cn.ml` | 51–52 | `let exec_in ~cwd cmd = try ... with _ -> None` |
| `cn.ml` | 55–56 | `let exec cmd = try ... with _ -> None` |
| `peer_sync.ml` | 35–36 | `let run_cmd cmd = try ... with _ -> None` |
| `inbox.ml` | 43–44 | `let run_cmd cmd = try ... with _ -> None` |
| `inbox.ml` | 105–107 | `with _ -> ... false` |
| `inbox.ml` | 171–189 | `read_decision_from_thread ... try ... with _ -> None` |
| `inbox.ml` | 191–204 | `extract_branch_from_thread ... try ... with _ -> None` |
| `cn_actions_exec.ml` | 38, 55–90 | Every action execution wrapped in `with _ ->` |
| `inbox_lib.ml` | 160 | `try String.sub ... with _ -> entry.timestamp` |

**Count: 12+ occurrences across 5 files.** This is the single most pervasive FUNCTIONAL.md violation. The prescribed fix is `Option`/`Result`:

```ocaml
(* Current *)
let exec cmd = try Some (exec_sync cmd opts) with _ -> None

(* Preferred — match exception specifically *)
let exec cmd =
  match exec_sync cmd opts with
  | result -> Some result
  | exception Js.Exn.Error _ -> None
```

### 2.3 Red Flag: `if`/`else` chains instead of pattern matching

| File | Lines | Code |
|------|-------|------|
| `cn.ml` | 91 | `if has_config \|\| has_peers then Some dir else ...` |
| `cn.ml` | 196 | `if not (Fs.exists outbox_dir) then ...` |
| `cn.ml` | 283 | `if not (Fs.exists inbox_dir) then None` |
| `cn.ml` | 400, 567, 778 | Similar `if not (Fs.exists ...)` patterns |
| `cn.ml` | 615–618 | `if Fs.exists hub_dir then begin ... end` |

FUNCTIONAL.md says: use pattern matching. These should be:

```ocaml
(* Current *)
if not (Fs.exists outbox_dir) then print_endline (ok "Outbox clear")
else ...

(* Preferred *)
match Fs.exists outbox_dir with
| false -> print_endline (ok "Outbox clear")
| true -> ...
```

### 2.4 Red Flag: `begin...end` imperative blocks

| File | Lines |
|------|-------|
| `cn.ml` | 163–168, 267–277, 567–570, 615–618, 729–732, 745–748, 778–819 |

`begin...end` is imperative sequencing. FUNCTIONAL.md prescribes pipelines. Many of these contain sequential `Fs.ensure_dir`; `Fs.write`; `Fs.unlink` chains that are inherently effectful at boundaries (acceptable) but should at minimum avoid mixing with control flow logic.

### 2.5 Red Flag: Partial functions

| File | Line | Code | Risk |
|------|------|------|------|
| `cn.ml` | 234 | `Option.get p.clone` | Throws on None |
| `cn_lib.ml` | 205 | `List.hd` (in `derive_name`) | Throws on empty list (commented "safe" but not proven by types) |
| `cn.ml` | 471 | `List.hd` (in `run_send`) | Throws on empty list |
| `cn.ml` | 159, 849 | `List.tl` | Throws on empty list |

FUNCTIONAL.md prescribes total functions. Use `List.hd` → `match ... with x :: _ -> Some x | [] -> None`.

### 2.6 Red Flag: `let _ = ...` ignoring results

| File | Lines | Code |
|------|-------|------|
| `cn.ml` | 128, 244, 245, 250–253, 434, 690–692 | `let _ = Child_process.exec_in ...` |
| `cn.ml` | 851 | `let _ = flags in` (flags parsed but never used — dead code) |

Ignoring `string option` return from shell commands silently swallows errors.

### 2.7 Summary of FUNCTIONAL.md Compliance

| Prescription | Source Files | _lib Files | Tests |
|-------------|-------------|-----------|-------|
| Pattern matching over conditionals | C | A | A |
| Pipelines over sequences | C | A- | A |
| Immutable over mutable | D (inbox.ml) | A | A |
| Option over exceptions | D | B | A |
| Types prevent invalid states | B | A | A |
| Small composable functions | C (cn.ml 900 lines) | A | A |
| Fold/recursion over loops | B | A | A |
| Total functions | C | B | A |

**_lib files are clean.** The violations concentrate in the FFI/main modules (`cn.ml`, `inbox.ml`, `peer_sync.ml`, `cn_actions_exec.ml`).

---

## 3. OCaml Skill Checklist

From `skills/eng/ocaml/SKILL.md`:

| Checklist Item | Status | Notes |
|---------------|--------|-------|
| Types with semantic wrappers | PARTIAL | `inbox_lib.ml` has `Reason`, `Actor`, `BranchName`, `Description` (excellent). `cn_actions.ml` uses type aliases `branch = string` (no safety — just aliases, not distinct types) |
| No wildcard `_` matches | FAIL | 12+ `with _ ->` catches across 5 files |
| Pure functions in `_lib.ml` | PASS | All `_lib.ml` files are pure |
| FFI bindings in main `.ml` only | PASS | FFI properly isolated in `cn.ml`, `inbox.ml`, `peer_sync.ml` |
| ppx_expect tests for parsing/formatting | PASS | All pure modules tested |
| Bundled `.js` committed to `tools/dist/` | PARTIAL | `inbox.js` and `peer-sync.js` committed; `cn.js` missing |
| README in tool directory | FAIL | Only `tools/src/peer-sync/README.md` exists; `cn/`, `inbox/`, `actions/` have none |

---

## 4. Code Duplication

### 4.1 String Helpers (3 copies)

`prefix`/`starts_with`, `strip_prefix`, `non_empty` are duplicated across:
- `cn_lib.ml` (lines 18–33)
- `inbox_lib.ml` (lines 192–202)
- `peer_sync_lib.ml` (lines 4–13)

Different naming: `cn_lib` uses `starts_with ~prefix`, others use `prefix ~pre`.

**Fix:** Extract shared `Cn_common` library.

### 4.2 FFI Modules (3 copies)

`Process`, `Fs`, `Path`, `Child_process` are duplicated across:
- `cn.ml` (lines 13–61) — most complete version
- `inbox.ml` (lines 16–38) — subset
- `peer_sync.ml` (lines 10–31) — subset

**Fix:** Extract shared `Cn_ffi` module.

### 4.3 Peer Parsing (3 copies)

`parse_peers`, `derive_name`, `make_peer` are duplicated across:
- `cn_lib.ml` (lines 268–282) — richest version with `peer_info` record
- `inbox_lib.ml` (lines 206–229) — simpler `peer` record
- `peer_sync_lib.ml` (lines 16–43) — simpler `peer` record

### 4.4 Sync Result Types (2 copies)

`sync_result`, `report_result`, `collect_alerts`, `format_alerts` are duplicated across:
- `inbox_lib.ml` (lines 231–279)
- `peer_sync_lib.ml` (lines 33–73)

### 4.5 Parallel Action Type Systems

Two independent action type hierarchies:
- `inbox_lib.ml`: `atomic_action` type (lines 286–305)
- `cn_actions.ml`: `action` type (lines 9–28)

Both represent the same concept (git/file/log operations) but are not unified. `inbox_lib.ml` even has the comment: "Uses Cn_actions_lib types when integrated; for now, returns action descriptions."

### 4.6 Result Type Shadowing

`cn_actions.ml` line 30: `type result = Ok | Error of string` shadows OCaml's stdlib `result` type. Confusing and prevents using the standard `Result` module.

---

## 5. Architecture Assessment

### 5.1 Strengths

- **Pure/impure separation is correctly implemented.** All `_lib.ml` files are pure, testable without FFI. This is the right pattern.
- **Exhaustive variant types** in `cn_lib.ml` for commands, cadences, triage — compiler catches missing cases.
- **Wrapper types** in `inbox_lib.ml` (`Reason of string`, `Actor of string`) — real type safety.
- **Roundtrippable serialization** — `triage_of_string` ↔ `string_of_triage` tested.
- **Pipeline style** used consistently in `_lib.ml` files.
- **Agent purity model** is well-conceived (agent = brain, cn = body).

### 5.2 Weaknesses

- **cn.ml is monolithic** (900 lines) — should be split into modules (inbox_ops, outbox_ops, git_ops, init, doctor, etc.).
- **Shell injection risk** persists in all FFI modules:
  ```ocaml
  Printf.sprintf "cd %s && git branch -r | grep 'origin/%s/'" hub_path peer_name
  ```
  Any crafted `peer_name` with shell metacharacters (`;`, `|`, `` ` ``) could inject commands. This is mitigated by `peer_name` coming from `state/peers.md` (not user input), but defense-in-depth demands escaping.
- **Agent purity specified but not enforced** — SYSTEM.md (lines 229–232) admits current runtime allows bypass.

### 5.3 Build System

| Component | Status |
|-----------|--------|
| `dune build` | Untested (no `_build/` directory present) |
| `dune runtest` | Untested |
| `npm run bundle:cn` | Would produce `dist/cn.js` but hasn't been run |
| `npm run bundle:inbox` | Produces `dist/inbox.js` (but committed copy is in `tools/dist/`) |
| CI (ci.yml) | Builds `@peer-sync` target; uses `master` branch (should be `main`) |
| CI | Tests Node 18/20/22 but `.nvmrc` pins 20, `package.json` says `>=18` |

---

## 6. Test Quality

### 6.1 Coverage

| Module | Test File | Lines | Coverage | Quality |
|--------|-----------|-------|----------|---------|
| `cn_lib.ml` | `cn_test.ml` | 188 | Good | All parsing, flags, frontmatter, peers, cadence tested |
| `inbox_lib.ml` | `inbox_test.ml` | 418 | Excellent | Triage roundtrips, log formatting, action generation, git commands |
| `peer_sync_lib.ml` | `peer_sync_test.ml` | 120 | Good | All pure functions tested |
| `cn_actions.ml` + `compose` | `cn_actions_test.ml` | 84 | Good | All compositions tested |
| `cn.ml` (900 lines) | **none** | 0 | **None** | FFI module untested |
| `inbox.ml` (312 lines) | **none** | 0 | **None** | FFI module untested |
| `peer_sync.ml` (94 lines) | **none** | 0 | **None** | FFI module untested |
| `cn_actions_exec.ml` (116 lines) | **none** | 0 | **None** | Executor untested |

**1,322 lines of FFI/main code have zero tests.** The pure libraries are well-tested, but the effectful modules — where most bugs would surface — are untested. This is partially expected (testing FFI requires Node.js), but integration tests should exist.

### 6.2 Test Quality Notes

- Tests use ppx_expect correctly with clear expected output
- Roundtrip testing (parse → serialize → parse) is excellent in `inbox_test.ml`
- Edge cases tested: empty inputs, invalid commands, missing frontmatter
- `inbox_test.ml` is the gold standard — all other test files should aspire to its coverage

---

## 7. Documentation Audit

### 7.1 Version Currency

| Document | Claims | Actual | Severity |
|----------|--------|--------|----------|
| `SECURITY.md` | v1.4.x | v2.1.0 | CRITICAL |
| `ROADMAP.md` | v1.6.0 | v2.1.0 | CRITICAL |
| `docs/GLOSSARY.md` | v1.4.0 | v2.1.0 | HIGH |
| `docs/DOJO.md` | v1.2.3 | v2.1.0 | HIGH |
| `docs/MIGRATION.md` | v1.6.0 | v2.1.0 | MEDIUM |
| `state/context.md` | v1.0.0 | v2.1.0 | MEDIUM |
| `state/hub.md` | v1.0.0 | v2.1.0 | MEDIUM |
| `state/peers.md` | v1.0.0 | v2.1.0 | MEDIUM |

### 7.2 Documentation Strengths

- Design docs (`docs/design/`) are excellent — 15 well-written architecture documents
- CHANGELOG.md is comprehensive with TSC coherence grading per release
- RCA docs are proper blameless post-mortems
- CN-WHITEPAPER.md is a rigorous protocol specification
- Cross-referencing between docs is accurate

### 7.3 Documentation Gaps

- **CONTRIBUTING.md** references `npm test` but needs OCaml contribution guidance
- **CN-LOGGING.md** shows JavaScript example instead of OCaml
- **GLOSSARY.md** still describes deprecated `memory/` and `state/practice/` as current
- **SYSTEM.md** has internal contradiction: lines 154–166 say agent "cannot" execute, lines 229–232 admit it can
- **AGENTS.md** forbids GitHub PRs/Issues but project lives on GitHub

---

## 8. Skills Audit

### 8.1 Duplicate Skills (4 pairs)

| Root Skill | Lines | Canonical (eng/) | Lines | Root is % shorter |
|------------|-------|-----------------|-------|-------------------|
| `skills/design/` | 65 | `skills/eng/design/` | 175 | 63% |
| `skills/ocaml/` | 94 | `skills/eng/ocaml/` | 241 | 61% |
| `skills/rca/` | 55 | `skills/eng/rca/` | 166 | 67% |
| `skills/review/` | 48 | `skills/eng/review/` | 161 | 70% |

The root-level versions are simplified quick-references missing critical content (templates, examples, checklists). They should either be deleted (consolidated into eng/) or clearly labeled as quick-references.

### 8.2 Misplaced Deprecated Skill

`skills/peer-sync/SKILL.md` (3 lines, deprecated) should be in `skills/_deprecated/peer-sync/`.

### 8.3 Cross-Reference Errors

`skills/eng/coding/SKILL.md` line 187 references `skills/ocaml/` but should reference `skills/eng/ocaml/`.

### 8.4 Healthy Skills (11)

star-sync, adhoc-thread, audit, inbox, peer, reflect, ship, tool-writing, ux-cli + all 5 eng/ canonical skills.

---

## 9. Configuration Issues

| Item | Issue |
|------|-------|
| CI branch | `ci.yml` triggers on `master`, should be `main` |
| Node version | `.nvmrc` = 20, `package.json` = `>=18`, CI tests 18/20/22 |
| `@peer-sync` target | CI builds it but it's undocumented |
| opam constraint | Redundant `"dune" {>= "3.8" & >= "3.0"}` (auto-generated) |

---

## 10. Recommendations for Improving OCaml Code Quality

### 10.1 Extract shared modules

```
tools/src/common/
  cn_common.ml      — prefix, strip_prefix, non_empty, derive_name
  cn_ffi.ml         — Process, Fs, Path, Child_process (shared FFI)
  cn_ffi_lib.ml     — run_cmd wrappers returning Option
```

This eliminates 3x duplication of string helpers, FFI modules, and peer parsing.

### 10.2 Replace `with _ ->` with specific exception matching

```ocaml
(* Instead of *)
let exec cmd = try Some (exec_sync cmd opts) with _ -> None

(* Use *)
let exec cmd =
  match exec_sync cmd opts with
  | result -> Some result
  | exception Js.Exn.Error _ -> None
```

This makes bugs visible instead of silently swallowing them.

### 10.3 Replace `ref` with fold

In `inbox.ml` `run_flush`, replace the `ref`-based counter with a fold:

```ocaml
let (processed, skipped) =
  threads |> List.fold_left (fun (p, s) thread_path ->
    match process_and_execute thread_path with
    | Ok -> (p + 1, s)
    | Skip -> (p, s + 1)
  ) (0, 0)
```

### 10.4 Use Result instead of bool for action execution

```ocaml
(* Instead of *)
let execute_action ~hub_path action : bool = ...

(* Use *)
type exec_result = Done | Failed of string
let execute_action ~hub_path action : exec_result = ...
```

### 10.5 Split cn.ml into modules

The 900-line monolith should become:

```
cn_inbox_ops.ml    — inbox_check, inbox_process, materialize_branch
cn_outbox_ops.ml   — outbox_check, outbox_flush, send_thread
cn_git_ops.ml      — run_commit, run_push
cn_gtd_ops.ml      — gtd_delete, gtd_defer, gtd_delegate, gtd_do, gtd_done
cn_init.ml         — run_init
cn_doctor.ml       — run_doctor
cn.ml              — main dispatch only (~50 lines)
```

### 10.6 Unify action types

Merge `inbox_lib.atomic_action` and `cn_actions.action` into a single type hierarchy. Remove the `result = Ok | Error of string` shadow.

### 10.7 Use proper wrapper types in cn_actions.ml

Replace type aliases with actual wrapper types:

```ocaml
(* Instead of *)
type branch = string  (* provides zero type safety *)

(* Use *)
type branch = Branch of string
```

### 10.8 Add shell escaping

For any shell command constructed via string interpolation, escape arguments:

```ocaml
let shell_escape s =
  "'" ^ Js.String.replaceByRe ~regexp:[%mel.re "/'/g"] ~replacement:"'\\''") s ^ "'"

let exec_git ~cwd args =
  let cmd = "git " ^ String.concat " " (List.map shell_escape args) in
  exec_in ~cwd cmd
```

---

## 11. Prioritized Action Items

### P0 — Blockers

1. **Build `dist/cn.js`** — Main CLI entry point is non-functional without it
2. **Resolve `dist/` vs `tools/dist/` path inconsistency** — Align package.json scripts, .gitignore, and committed artifacts
3. **Update SECURITY.md** — Stale version (v1.4.x) is a security communication risk

### P1 — High Priority

4. **Extract shared OCaml modules** (cn_common, cn_ffi) to eliminate 3x duplication
5. **Replace all `with _ -> None`** with specific exception matching (12+ occurrences)
6. **Replace `ref`/`incr` in inbox.ml** with fold
7. **Update ROADMAP.md** — Claims v1.6.0, actual is v2.1.0
8. **Consolidate or deprecate 4 duplicate skill pairs**
9. **Update CI** to trigger on `main` not `master`

### P2 — Medium Priority

10. **Split cn.ml** (900 lines) into focused modules
11. **Unify `atomic_action` and `action` types** across inbox_lib and cn_actions
12. **Add shell argument escaping** for all `Printf.sprintf` shell commands
13. **Update GLOSSARY.md, DOJO.md, MIGRATION.md** version references
14. **Add THINKING.md** to required mindsets list in AGENTS.md
15. **Move `skills/peer-sync/`** to `skills/_deprecated/peer-sync/`
16. **Fix cross-references** in `skills/eng/coding/SKILL.md`

### P3 — Polish

17. **Add READMEs** to `tools/src/cn/`, `tools/src/inbox/`, `tools/src/actions/`
18. **Replace type aliases** in cn_actions.ml with proper wrapper types
19. **Add integration tests** for FFI modules (cn.ml, inbox.ml, peer_sync.ml)
20. **Replace `begin...end` blocks** with pipeline style where possible
21. **Replace `if`/`else` patterns** with pattern matching on bool
22. **Align Node version** across .nvmrc, package.json, CI

---

## Appendix: Files Audited

### OCaml Source (14 files, ~2,730 lines)
- `tools/src/cn/cn.ml` (900), `cn_lib.ml` (377), `dune`
- `tools/src/inbox/inbox.ml` (312), `inbox_lib.ml` (383), `dune`
- `tools/src/peer-sync/peer_sync.ml` (94), `peer_sync_lib.ml` (74), `dune`
- `tools/src/actions/cn_actions.ml` (50), `cn_actions_compose.ml` (46), `cn_actions_exec.ml` (116), `dune`

### OCaml Tests (8 files, ~810 lines)
- `tools/test/cn/cn_test.ml` (188), `dune`
- `tools/test/inbox/inbox_test.ml` (418), `dune`
- `tools/test/peer-sync/peer_sync_test.ml` (120), `dune`
- `tools/test/actions/cn_actions_test.ml` (84), `dune`

### Documentation (33 files)
- Root: README.md, CHANGELOG.md, CONTRIBUTING.md, CODE_OF_CONDUCT.md, LICENSE, SECURITY.md, ROADMAP.md
- docs/: HANDSHAKE.md, AUTOMATION.md, APHORISMS.md, MIGRATION.md, GLOSSARY.md, FOUNDATIONS.md, DOJO.md
- docs/design/: AGENT-MODEL.md, CN-ACTIONS.md, CN-LOGGING.md, CN-MANIFESTO.md, CN-EXECUTABLE-SKILLS.md, ACTOR-MODEL-DESIGN.md, CN-WHITEPAPER.md, CN-DAEMON.md, SECURITY-MODEL.md, CN-PROTOCOL.md, CN-CLI.md, AGILE-PROCESS.md, THREAD-API.md, THREADS-MODEL.md, THREADS-UNIFIED.md, INBOX-ARCHITECTURE.md
- docs/rca/: README.md, 20260205-branch-deletion-violation.md, 20260205-coordination-failure.md

### Skills (23 SKILL.md files)
- Root skills: star-sync, adhoc-thread, audit, configure-agent, design, hello-world, inbox, ocaml, peer, peer-sync, reflect, rca, review, self-cohere, ship, tool-writing, ux-cli
- eng/: coding, design, ocaml, rca, review
- _deprecated/: daily-routine

### Mindsets (9 files)
- COHERENCE.md, ENGINEERING.md, FUNCTIONAL.md, MEMES.md, OPERATIONS.md, PERSONALITY.md, PM.md, THINKING.md, WRITING.md

### Specs (6 files)
- AGENTS.md, HEARTBEAT.md, SOUL.md, SYSTEM.md, TOOLS.md, USER.md

### State (4 files)
- README.md, context.md, hub.md, peers.md

### Config (9 files)
- package.json, dune-project, cn_agent.opam, .editorconfig, .gitignore, .nvmrc, bin/cn, .github/workflows/ci.yml, .github/workflows/release.yml

**Total: ~100 files audited**

---

*Audited by Claude on 2026-02-06 against FUNCTIONAL.md, skills/eng/ocaml/SKILL.md, and project conventions.*
