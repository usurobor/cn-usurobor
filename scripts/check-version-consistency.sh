#!/usr/bin/env bash
# check-version-consistency.sh — CI gate for version coherence (#22)
#
# Verifies that all version-stamped files agree with the VERSION file.
# Exit 0 if all consistent, exit 1 on any mismatch.

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
VERSION=$(cat "$REPO_ROOT/VERSION" | tr -d '\n')
ERRORS=0

check() {
  local file="$1" actual="$2" label="$3"
  if [ "$actual" != "$VERSION" ]; then
    echo "FAIL: $label — got '$actual', expected '$VERSION' (in $file)"
    ERRORS=$((ERRORS + 1))
  else
    echo "  ok: $label = $VERSION"
  fi
}

echo "Checking version consistency against VERSION=$VERSION"
echo ""

# 1. cn.json system manifest
CN_JSON_VER=$(python3 -c "import json; print(json.load(open('$REPO_ROOT/cn.json'))['version'])" 2>/dev/null || echo "PARSE_ERROR")
check "cn.json" "$CN_JSON_VER" "cn.json version"

# 2. Package manifests
for pkg in cnos.core cnos.eng cnos.pm; do
  PKG_FILE="$REPO_ROOT/packages/$pkg/cn.package.json"
  if [ -f "$PKG_FILE" ]; then
    PKG_VER=$(python3 -c "import json; print(json.load(open('$PKG_FILE'))['version'])" 2>/dev/null || echo "PARSE_ERROR")
    check "$PKG_FILE" "$PKG_VER" "$pkg version"

    ENGINE_VER=$(python3 -c "import json; print(json.load(open('$PKG_FILE'))['engines']['cnos'])" 2>/dev/null || echo "PARSE_ERROR")
    check "$PKG_FILE" "$ENGINE_VER" "$pkg engines.cnos"
  else
    echo "FAIL: $PKG_FILE not found"
    ERRORS=$((ERRORS + 1))
  fi
done

# 3. cn_lib.ml should NOT contain a hardcoded version string
CN_LIB="$REPO_ROOT/src/lib/cn_lib.ml"
if grep -q 'let version = "' "$CN_LIB"; then
  HARDCODED=$(grep 'let version = "' "$CN_LIB" | head -1 | sed 's/.*"\(.*\)"/\1/')
  echo "FAIL: cn_lib.ml has hardcoded version '$HARDCODED' — should read from Cn_version.version"
  ERRORS=$((ERRORS + 1))
else
  echo "  ok: cn_lib.ml reads version from generated module"
fi

echo ""
if [ "$ERRORS" -gt 0 ]; then
  echo "FAILED: $ERRORS version inconsistencies found"
  echo "Fix: run 'scripts/stamp-versions.sh' to rewrite manifests from VERSION, then commit."
  exit 1
else
  echo "PASSED: all version-stamped files agree with VERSION=$VERSION"
  exit 0
fi
