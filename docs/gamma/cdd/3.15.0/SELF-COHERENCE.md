# Self-Coherence Report — v3.15.0

**Issue:** #22 — Version coherence
**Author:** Claude (CDD pipeline)
**Date:** 2026-03-24

## Pipeline Compliance

| Step | Status | Evidence |
|------|--------|----------|
| §1.4 Branch | Done | `claude/review-agent-runtime-docs-LyUlu` (transport-assigned name) |
| §1.5 Pre-flight | Done | Version 3.15.0 > latest tag v3.14.4 and > untagged release v3.14.7, no branch/PR conflicts |
| §4.0 Bootstrap | Done | `docs/gamma/cdd/3.15.0/README.md` — first commit |
| §4.1 Design doc | Done | Issue #22 body is the design (detailed 9-phase design) |
| §4.2 Coherence contract | Done | PR description + README AC table |
| §4.3 Plan | Done | Issue #22 File Changes section = implementation plan |
| §4.4 Tests | Done | Cram + ppx_expect tests updated to dynamic version |
| §4.5 Code | Done | 17 files changed across 6 modules |
| §4.5.1 AC self-check | Done | All 10 ACs verified in commit message |
| §4.5.2 Multi-format parity | Done | Runtime contract markdown + JSON both read package_info.version |
| §4.6 Docs | Done | CHANGELOG updated |
| §4.7 Release notes | Done | CHANGELOG TSC entry |
| §4.8 Self-coherence | This file |

## Triadic Assessment

- **α A** — Internal consistency: VERSION → dune rule → cn_version.ml → Cn_lib.version. All consumers read from one chain. CI gate validates the chain. No parallel version sources remain.
- **β A** — Alignment: issue #22 design → code changes match 1:1. All 10 ACs have corresponding code. Package manifests, lockfile, runtime contract, status, doctor, runtime.md all updated together.
- **γ A** — Evolution: future version bumps require editing one file. CI prevents drift. The version-tax problem (#22 names) is permanently eliminated.

## AC Coverage

| # | AC | Status | Evidence |
|---|-----|--------|----------|
| 1 | VERSION as single source | Met | `VERSION` file, `src/lib/dune` rule, `cn_lib.ml:708` reads `Cn_version.version` |
| 2 | One-file bump | Met | Only `VERSION` needs editing; manifests stamped at release |
| 3 | CI fails on stale | Met | `scripts/check-version-consistency.sh` — verified passing |
| 4 | First-party = repo version | Met | `packages/cnos.{core,eng,pm}/cn.package.json` at 3.15.0, `engines.cnos: "3.15.0"` |
| 5 | Lockfile from VERSION+commit | Met | `cn_deps.ml:lockfile_for_manifest` uses `Cn_lib.version` + `Cn_lib.cnos_commit` |
| 6 | cn update reconciles in-hub | Met | `cn_system.ml:reconcile_packages` rewrites locks + restores + updates runtime |
| 7 | Runtime contract package version | Met | `package_info.version` field, rendered in markdown (`@version`) and JSON |
| 8 | Status/doctor/runtime.md drift | Met | `update_runtime` writes packages+drift, `run_status` per-package, `run_doctor` coherence check |
| 9 | Tests dynamic | Met | Cram: compare vs `$CNOS_VERSION` from file. Expect: compare vs `Cn_lib.version` |
| 10 | Release gate | Met | `scripts/check-version-consistency.sh` exits 1 on mismatch |

## Known Coherence Debt

- Branch name deviates from §1.4 convention (transport-assigned suffix, should be `claude/3.15.0-22-version-coherence`) — cosmetic, no functional impact. Cannot rename with open PR.
- `cn build --check` does not yet validate VERSION consistency (scripts/check-version-consistency.sh is standalone) — follow-up for #58
- Package version extraction (`package_info.version`) relies on `@` separator in installed directory name. No fallback if convention changes — acceptable for v1, revisit if install layout changes.
- CHANGELOG not yet frozen into version dir (canonical copy is authoritative)

## Checklist

- [x] All 10 ACs accounted for
- [x] No hardcoded version literals in test expectations
- [x] CI gate script verified passing
- [x] Multi-format parity (markdown + JSON render same package version)
- [x] CHANGELOG TSC entry written
