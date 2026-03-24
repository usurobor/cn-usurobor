# CDD 3.15.0 — Version Coherence

**Issue:** #22 — Version coherence: no single source of truth from tag to agent self-awareness
**Release:** 3.15.0
**Date:** 2026-03-24

## Gap

Version duplicated across 5 files with no single source of truth. First-party packages at
`1.0.0` while system is at `3.14.7`. `cn update` doesn't reconcile packages. Runtime contract
lacks package versions. Every release requires editing 5 files manually.

## Mode

MCA — runtime code, build system, tests, and manifests all change.

## Scope (10 ACs from #22)

| # | AC | Status |
|---|-----|--------|
| 1 | VERSION file as single source of truth | Met |
| 2 | Bumping requires editing one file | Met |
| 3 | CI fails if derived files stale | Met |
| 4 | First-party package versions = repo version, engines exact | Met |
| 5 | Lockfile first-party from VERSION + cnos_commit | Met |
| 6 | cn update reconciles packages in-hub | Met |
| 7 | Runtime contract includes package version | Met |
| 8 | status/doctor/runtime.md surface package versions + drift | Met |
| 9 | Tests derive version dynamically | Met |
| 10 | Release gate blocks on version disagreement | Met |

## Deliverables

| Artifact | Path |
|----------|------|
| VERSION file | VERSION |
| Generated module | src/lib/cn_version.ml (build-time) |
| Dune rule | src/lib/dune |
| Runtime version read | src/lib/cn_lib.ml |
| System manifest stamp | cn.json |
| Package manifests stamp | packages/cnos.{core,eng,pm}/cn.package.json |
| Deps version fix | src/cmd/cn_deps.ml |
| Runtime contract version | src/cmd/cn_runtime_contract.ml |
| System drift surfacing | src/cmd/cn_system.ml |
| Dynamic test version | test/cram/version.t, test/cram/cli/cli.t |
| Dynamic test expect | test/cmd/cn_runtime_contract_test.ml |
| CI gate | scripts/check-version-consistency.sh |
| Self-coherence | docs/gamma/cdd/3.15.0/SELF-COHERENCE.md |
