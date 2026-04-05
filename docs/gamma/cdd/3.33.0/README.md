## CDD Bootstrap -- v3.33.0

**Issue:** #158 -- Redesign install.sh to match tsc v0.3.0 installer pattern
**Branch:** claude/execute-issue-144-cdd-O6Rl3
**Parent:** ad896ce (main)
**Mode:** MCA (targeted rewrite)
**Level:** L7 -- boundary move: installer becomes product surface

### Gap

The current `install.sh` is a bootstrap hack with 6 structural defects:
non-atomic download (corrupts installed binary on failure), no download
validation (accepts HTML error pages as binaries), non-actionable errors,
no cleanup on failure, no NO_COLOR/TTY awareness, and UX that doesn't
match the CLI it installs.

The tsc v0.3.0 installer solves all 6 problems. This is a direct port
of that pattern to cnos, preserving cnos-specific platform matrix.

### Acceptance Criteria

- AC1: Failed/interrupted download never corrupts an installed binary
- AC2: Downloads < 1 MB are rejected with actionable error
- AC3: Every error message includes cause, fix steps, and rerun command
- AC4: Temp files are cleaned up on exit/interrupt/failure
- AC5: NO_COLOR and non-TTY suppress ANSI color
- AC6: Unsupported platform/arch fails with explicit message + build-from-source instructions
- AC7: Success output uses checkmark symbols matching tsc installer UX
- AC8: `cn --version` runs after install to verify

### Design

Direct port of tsc v0.3.0 `install.sh` with these cnos-specific adaptations:

| tsc | cnos | Rationale |
|-----|------|-----------|
| `BINARY_NAME="tsc"` | `BINARY_NAME="cn"` | Different binary name |
| Linux x86_64 only | Linux x64/arm64, macOS x64/arm64 | cnos publishes 4 targets |
| `REPO="usurobor/tsc"` | `REPO="usurobor/cnos"` | Different repo |
| Build from source: `make setup && make build` | Build from source: `dune build` | Different build system |

The structure is identical: UX helpers -> cleanup trap -> prerequisites ->
platform detection -> fetch latest release -> download to temp -> size check ->
atomic install -> verify.

### Plan

1. Rewrite install.sh following tsc pattern exactly
2. Verify all 8 ACs are met by code inspection
3. Write SELF-COHERENCE.md
4. Commit, push, create PR
