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

```bash
# In src/lib/cn_lib.ml
let version = "2.5.0"
```

Verify:
```bash
grep "let version" src/lib/cn_lib.ml
```

### 2. Update CHANGELOG

Add entry to `CHANGELOG.md` with version, date, changes.

### 3. Commit and Tag

```bash
git add -A
git commit -m "release: v2.5.0"
git tag v2.5.0
git push origin main --tags
```

### 4. CI Builds Automatically

Tag push triggers `.github/workflows/release.yml`:
- Builds for `linux-x64`, `macos-x64`, `macos-arm64`
- Runs tests on each platform
- Creates GitHub Release with binaries attached

### 5. Verify Release

```bash
gh release view v2.5.0 -R usurobor/cnos
```

Or: https://github.com/usurobor/cnos/releases

## User Installation

### Via install script (recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
```

Detects platform, downloads correct binary to `/usr/local/bin/cn`.

### Direct download

```bash
# Latest
curl -LO https://github.com/usurobor/cnos/releases/latest/download/cn-linux-x64
chmod +x cn-linux-x64
sudo mv cn-linux-x64 /usr/local/bin/cn

# Specific version
curl -LO https://github.com/usurobor/cnos/releases/download/v2.5.0/cn-linux-x64
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

`.github/workflows/release.yml`:

```yaml
on:
  push:
    tags: ['v*']

jobs:
  build:
    strategy:
      matrix:
        include:
          - os: ubuntu-latest
            target: linux-x64
          - os: macos-latest
            target: macos-x64
          - os: macos-14
            target: macos-arm64
    # ... builds and attaches to Release
```

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
uname -s  # OS
uname -m  # Arch
```

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
