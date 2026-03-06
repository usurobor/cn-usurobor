# Build, Release, Deploy

End-to-end process for cnos binaries.

## Overview

```
Source (git) → Build (dune) → Release (GitHub) → Install (curl)
```

| Stage | Where | What |
|-------|-------|------|
| Source | `usurobor/cnos` repo | OCaml code in `src/` |
| Build | GitHub Actions | `dune build` on tag push |
| Release | GitHub Releases | Binary artifacts attached |
| Install | User machine | `install.sh` downloads from Releases |

## Local Development

```bash
# Setup (once)
opam switch create cnos 4.14.1
opam install dune ppx_expect ppxlib mdx

# Build
eval $(opam env)
dune build src/cli/cn.exe

# Binary location
_build/default/src/cli/cn.exe

# Run tests
dune runtest
```

## Release Process

### 1. Version Bump

Update the version string in **two** files:

```bash
# src/lib/cn_lib.ml
let version = "3.3.0"

# test/cram/version.t (expected output line)
cn 3.3.0
```

Verify both match:
```bash
grep 'let version' src/lib/cn_lib.ml
grep 'cn ' test/cram/version.t
```

### 2. Update CHANGELOG

Add entry to `CHANGELOG.md` with version, date, coherence grades, and changes.

### 3. Write Release Notes (feature releases only)

For minor/major releases, create `RELEASE.md` at repo root:

```markdown
# v3.3.0 — CN Shell

Summary of what shipped and why it matters.

### Added
- ...

### Changed
- ...
```

The release workflow uses `RELEASE.md` as GitHub Release body if it exists. If not, release notes are auto-generated from commit messages (fine for patches).

`RELEASE.md` is committed with the release and lives in the repo — delete it after the release is published or leave it as a record until the next release overwrites it.

### 4. Commit and Tag

```bash
git add -A
git commit -m "release: v3.3.0 — <short description>"
git tag v3.3.0
git push origin main --tags
```

### 5. CI Builds Automatically

Tag push triggers `.github/workflows/release.yml`:
- Builds on three platforms: `linux-x64`, `macos-x64`, `macos-arm64`
- Runs tests on each platform
- Creates GitHub Release with binaries attached (`cn-linux-x64`, `cn-macos-x64`, `cn-macos-arm64`)
- Release notes auto-generated from commits

### 6. Verify Release

```bash
gh release view v3.3.0 -R usurobor/cnos
```

Or: https://github.com/usurobor/cnos/releases

### 7. Deploy to Agents

After release is published, update running agents:

```bash
# Via install script (downloads latest release binary)
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh

# Restart daemon if running
systemctl restart cn.service
```

## User Installation

### Via install script (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

Detects platform (`uname -s` / `uname -m`), downloads correct binary to `/usr/local/bin/cn`.

Override install directory:
```bash
BIN_DIR=/usr/bin sh install.sh
```

If `/usr/local/bin` requires root:
```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sudo sh
```

### Direct download

```bash
# Latest
curl -LO https://github.com/usurobor/cnos/releases/latest/download/cn-linux-x64
chmod +x cn-linux-x64
sudo mv cn-linux-x64 /usr/local/bin/cn

# Specific version
curl -LO https://github.com/usurobor/cnos/releases/download/v3.3.0/cn-linux-x64
```

### From source

```bash
git clone https://github.com/usurobor/cnos
cd cnos
opam install dune ppx_expect ppxlib mdx
eval $(opam env)
dune build src/cli/cn.exe
sudo cp _build/default/src/cli/cn.exe /usr/local/bin/cn
```

## CI Configuration

### CI (push/PR to main): `.github/workflows/ci.yml`

Runs on `ubuntu-latest` only. Build + tests + smoke test.

### Release (tag push): `.github/workflows/release.yml`

Triggered by tags matching `v*`. Builds on all three platforms, runs tests, creates GitHub Release with binary artifacts.

Both workflows use `TMPDIR` isolation + `-j 1` to prevent ppx_expect temp file races.

## Versioning

Semver: `MAJOR.MINOR.PATCH`

All releases get tags. Binary releases for minor/major only.

| Change type | Tag | Binary release | Who gets it |
|-------------|-----|----------------|-------------|
| Patch (bugfix) | Yes | No | Source builders |
| Minor (features) | Yes | Yes | All users |
| Major (breaking) | Yes | Yes | All users |

Users on `install.sh` receive minor/major updates automatically. Patch releases require building from source or waiting for the next minor.

## Troubleshooting

### Release didn't trigger

Check tag was pushed:
```bash
git tag -l
git push origin --tags
```

### Binary download fails

Check release exists:
```bash
gh release list -R usurobor/cnos
```

### Wrong binary for platform

Check install.sh platform detection:
```bash
uname -s  # OS: Linux or Darwin
uname -m  # Arch: x86_64, aarch64, or arm64
```

### Tests fail in release CI

ppx_expect can race on temp files under parallel execution. See `ci.yml` for the `TMPDIR` isolation + `-j 1` fix. Apply the same to `release.yml` if needed.

---

## Background: Binary Storage

Binaries are **not** stored in the git repo.

| What | Where |
|------|-------|
| Source code | Git repo |
| Built binaries | GitHub Releases (blob storage) |

**Why:**
- Binaries are ~2MB × 3 platforms = 6MB per release
- Git isn't designed for binary versioning
- Releases API is the standard pattern
