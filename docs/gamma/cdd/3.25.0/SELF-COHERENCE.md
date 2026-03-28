# Self-Coherence — v3.25.0

## Gap

Agent probes filesystem for self-knowledge (version, identity, config) despite the Runtime Contract declaring that information in packed context. Prior closure (v3.23.0) was purely instructional — no structural prevention.

## Mode

MCA — change the system to structurally prevent self-knowledge probing.

## Active Skills

- **ocaml** — hard generation constraint for type safety, pattern matching, module structure
- **testing** — hard generation constraint for invariant-first testing, negative space

## Engineering Level

**Target: L7 (system-shaping leverage)**

The change moves the boundary: self-knowledge probes are intercepted at the executor level with `contract_redirect` status. The class of failure (LLM probing filesystem for version/identity info) becomes structurally impossible — not by instruction, but by interception. Future agents on any LLM backend get this protection automatically.

## Acceptance Criteria

| # | AC | Status | Evidence |
|---|-----|--------|---------|
| 1 | `fs_read cn.json` returns `contract_redirect` | Met | Expect test: `fs_read: cn.json returns contract_redirect` |
| 2 | `fs_read` on package manifests returns `contract_redirect` | Met | Expect test: `fs_read: package manifest returns contract_redirect` |
| 3 | `fs_list` on self-knowledge dirs returns `contract_redirect` | Met | Self-knowledge check added to `execute_fs_list` |
| 4 | Legitimate reads unaffected | Met | Expect tests: `src/main.ml`, `docs/README.md`, `src` directory all return `ok` |
| 5 | Redirect reason includes RC pointer | Met | Reason string includes "Runtime Contract (Identity section)" / "(Cognition section)" |
| 6 | RC authority declaration references structural interception | Met | `cn_runtime_contract.ml` L275-281: "The runtime structurally enforces this" |

## Triad Assessment

### alpha (structural consistency)

**A** — The interceptor is structurally sound:
- `Contract_redirect` is a first-class `receipt_status` variant, not overloaded on `Denied` or `Error_status`
- Pattern matches in `cn_orchestrator.ml` are exhaustive — `Contract_redirect` is handled in all three match sites
- Self-knowledge paths are a small, explicit list in one place (`cn_executor.ml`)
- The interceptor runs after sandbox validation but before filesystem I/O — correct layering
- No field name collisions (OCaml skill section 3.1)

### beta (alignment)

**A** — Cross-surface coherence across all five observe surfaces:
- **fs_read**: self-knowledge paths return `contract_redirect` (interceptor)
- **fs_list**: self-knowledge entries filtered from child results (R2 fix)
- **fs_glob**: self-knowledge paths filtered from glob results (R2 fix)
- **git_grep**: `cn.json` and `*.package.json` added to exclusion pathspecs (R2 fix)
- **git_status/git_diff/git_log**: already use `git_observe_exclusions` which now include self-knowledge files
- The RC authority declaration references structural enforcement
- The `receipt_result_signal` in orchestrator says "[REDIRECTED: this information is in your Runtime Contract]"
- Test expectations match code behavior — 10 expect tests cover positive, negative, and membrane-hole cases
- `state/runtime-contract.json` correctly defers to sandbox denial (it's in `state/` denylist)

### gamma (process)

**A-** — Process coherence:
- CDD lifecycle followed: observe -> select -> branch -> bootstrap -> gap -> mode -> artifacts -> self-coherence
- Version bumped via VERSION-first flow: `VERSION` -> `stamp-versions.sh` -> `check-version-consistency.sh`
- Tests written alongside code (not after)
- Issue #64 reopened with rationale before fix
- R2 fixes three D-level membrane holes found in review (glob, list-child, grep)
- No OCaml toolchain available — compilation verified in CI, not locally (known limitation of this environment)

## Known Debt

- No `dune build` / `dune runtest` available locally. Compilation correctness depends on CI.
- `state/runtime-contract.json` interception noted in PLAN.md as "interceptor should catch first" but sandbox denylist correctly takes precedence. PLAN.md note is aspirational, not a bug.

## Files Changed

| File | Change |
|------|--------|
| `VERSION` | 3.24.0 -> 3.25.0 |
| `cn.json` | version stamped |
| `packages/cnos.core/cn.package.json` | version stamped |
| `packages/cnos.eng/cn.package.json` | version stamped |
| `src/cmd/cn_shell.ml` | Added `Contract_redirect` to `receipt_status` and `string_of_receipt_status` |
| `src/cmd/cn_executor.ml` | Added `self_knowledge_paths`, `self_knowledge_suffixes`, `check_self_knowledge_path`, `is_self_knowledge_path`; integrated into `execute_fs_read`, `execute_fs_list` (redirect + child filter), `execute_fs_glob` (result filter); added `cn.json`/`*.package.json` to `git_observe_exclusions` |
| `src/cmd/cn_orchestrator.ml` | Handle `Contract_redirect` in 3 pattern matches |
| `src/cmd/cn_runtime_contract.ml` | Updated authority declaration to reference structural enforcement |
| `test/cmd/cn_executor_test.ml` | 10 expect tests for self-knowledge interception (7 R1 + 3 R2 membrane tests) |
| `docs/gamma/cdd/3.25.0/` | CDD bundle: README, SELECTION, PLAN, SELF-COHERENCE |
