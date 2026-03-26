#!/usr/bin/env bash
# stamp-versions.sh — Rewrite version-stamped files from the VERSION file.
#
# This is the "derive from source" half of version coherence (#22).
# check-version-consistency.sh is the "validate" half.
#
# Usage: scripts/stamp-versions.sh
#   Reads VERSION, rewrites cn.json and packages/*/cn.package.json.
#   Run this after editing VERSION, then commit the result.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -f "$REPO_ROOT/VERSION" ]; then
  echo "ERROR: VERSION file not found at $REPO_ROOT/VERSION"
  exit 1
fi

VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n')

if [ -z "$VERSION" ]; then
  echo "ERROR: VERSION file is empty"
  exit 1
fi

echo "Stamping version $VERSION into manifests..."

# Use sed for in-place replacement to preserve formatting exactly.
# Each file has a known structure — we replace only the version values.

# 1. cn.json — "version": "X.Y.Z"
CN_JSON="$REPO_ROOT/cn.json"
if [ -f "$CN_JSON" ]; then
  OLD=$(python3 -c "import json; print(json.load(open('$CN_JSON'))['version'])" 2>/dev/null || echo "?")
  sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$CN_JSON"
  echo "  cn.json: $OLD → $VERSION"
fi

# 2. Package manifests — "version" and "cnos" inside "engines"
for pkg in cnos.core cnos.eng; do
  PKG_FILE="$REPO_ROOT/packages/$pkg/cn.package.json"
  if [ -f "$PKG_FILE" ]; then
    OLD_VER=$(python3 -c "import json; print(json.load(open('$PKG_FILE'))['version'])" 2>/dev/null || echo "?")
    OLD_ENG=$(python3 -c "import json; print(json.load(open('$PKG_FILE'))['engines']['cnos'])" 2>/dev/null || echo "?")
    # Replace "version": "..." (first occurrence — the package version, not engines)
    sed -i "s/\"version\": \"[^\"]*\"/\"version\": \"$VERSION\"/" "$PKG_FILE"
    # Replace "cnos": "..." inside engines block
    sed -i "s/\"cnos\": \"[^\"]*\"/\"cnos\": \"$VERSION\"/" "$PKG_FILE"
    echo "  $pkg: version $OLD_VER → $VERSION, engines.cnos $OLD_ENG → $VERSION"
  else
    echo "  WARN: $PKG_FILE not found"
  fi
done

echo ""
echo "Done. Run 'scripts/check-version-consistency.sh' to verify, then commit."
