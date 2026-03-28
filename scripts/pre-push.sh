#!/usr/bin/env bash
# pre-push.sh -- Pre-push validation gate for cnos.
#
# Usage: scripts/pre-push.sh [--install]
#   --install  Install as .git/hooks/pre-push
#
# Checks (in order):
#   1. dune build         -- compilation (produces cn binary)
#   2. dune runtest       -- tests pass
#   3. cn build --check   -- package/source sync (uses binary from step 1)
#   4. VERSION parity     -- branch VERSION matches origin/main
#
# Exit: 0=all pass, 1=failure
#
# Issue: #117

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

if [[ -n "${NO_COLOR:-}" ]]; then
  RED="" GREEN="" DIM="" RESET=""
else
  RED='\033[0;31m' GREEN='\033[0;32m' DIM='\033[0;90m' RESET='\033[0m'
fi

ok()   { echo -e "${GREEN}ok${RESET}  $1"; }
fail() { echo -e "${RED}FAIL${RESET}  $1"; }
info() { echo -e "${DIM}....${RESET}  $1"; }

# --- Install mode ---
if [[ "${1:-}" == "--install" ]]; then
  hook=".git/hooks/pre-push"
  mkdir -p .git/hooks
  cat > "$hook" << 'HOOK'
#!/usr/bin/env bash
# Installed by scripts/pre-push.sh --install
exec "$(git rev-parse --show-toplevel)/scripts/pre-push.sh"
HOOK
  chmod +x "$hook"
  echo "Installed pre-push hook at $hook"
  exit 0
fi

# --- Opam environment ---
if command -v opam &>/dev/null && ! command -v dune &>/dev/null; then
  eval "$(opam env 2>/dev/null)" || true
fi

# --- Prereq checks (only dune and git -- cn comes from dune build) ---
check_prereqs() {
  local missing=0
  for cmd in dune git; do
    if ! command -v "$cmd" &>/dev/null; then
      fail "missing: $cmd"
      missing=1
    fi
  done
  [[ $missing -eq 0 ]] || exit 1
}

# --- Gate checks ---
errors=0
build_ok=false

gate_build() {
  info "dune build"
  if dune build 2>&1; then
    ok "dune build"
    build_ok=true
  else
    fail "dune build"
    errors=$((errors + 1))
  fi
}

gate_test() {
  info "dune runtest"
  if dune runtest 2>&1; then
    ok "dune runtest"
  else
    fail "dune runtest"
    errors=$((errors + 1))
  fi
}

gate_package_sync() {
  if [[ "$build_ok" != "true" ]]; then
    fail "cn build --check (skipped: dune build failed)"
    errors=$((errors + 1))
    return
  fi

  local cn_bin=""
  if [[ -f "_build/default/src/cli/cn.exe" ]]; then
    cn_bin="_build/default/src/cli/cn.exe"
  else
    fail "cn binary not found after dune build"
    errors=$((errors + 1))
    return
  fi

  info "cn build --check"
  if $cn_bin build --check 2>&1; then
    ok "cn build --check"
  else
    fail "cn build --check (run: cn build)"
    errors=$((errors + 1))
  fi
}

gate_version_parity() {
  local branch
  branch="$(git rev-parse --abbrev-ref HEAD)"
  if [[ "$branch" == "main" ]]; then
    ok "VERSION parity (on main, skip)"
    return
  fi

  local branch_version main_version

  branch_version="$(cat VERSION 2>/dev/null || echo '')"
  if [[ -z "$branch_version" ]]; then
    fail "VERSION file missing on branch"
    errors=$((errors + 1))
    return
  fi

  info "fetching origin/main for VERSION check"
  if ! git fetch origin main --quiet 2>/dev/null; then
    fail "VERSION parity (cannot fetch origin/main -- offline or no remote)"
    errors=$((errors + 1))
    return
  fi

  main_version="$(git show origin/main:VERSION 2>/dev/null || echo '')"
  if [[ -z "$main_version" ]]; then
    fail "VERSION parity (no VERSION on origin/main)"
    errors=$((errors + 1))
    return
  fi

  if [[ "$branch_version" == "$main_version" ]]; then
    ok "VERSION parity ($branch_version)"
  else
    local sorted
    sorted="$(printf '%s\n%s\n' "$main_version" "$branch_version" | sort -V | head -1)"
    if [[ "$sorted" == "$branch_version" && "$branch_version" != "$main_version" ]]; then
      fail "VERSION regression: branch=$branch_version < origin/main=$main_version (rebase needed)"
      errors=$((errors + 1))
    else
      ok "VERSION parity (branch=$branch_version >= origin/main=$main_version)"
    fi
  fi
}

# --- Main ---
main() {
  echo "pre-push gate (#117)"
  echo ""
  check_prereqs
  gate_build
  gate_test
  gate_package_sync
  gate_version_parity
  echo ""
  if [[ $errors -gt 0 ]]; then
    fail "$errors check(s) failed -- push blocked"
    exit 1
  else
    ok "all checks passed"
    exit 0
  fi
}

main "$@"
