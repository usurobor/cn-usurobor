#!/usr/bin/env bash
set -euo pipefail

# setup.sh
#
# Apply the current core specs from this CN repo to an OpenClaw workspace.
# 1) Copy canonical core spec files into openclaw/ runtime tree
# 2) Commit and push any spec changes in this repo
# 3) Rsync openclaw/ into the OpenClaw workspace
#
# Usage:
#   OPENCLAW_WORKSPACE=/path/to/workspace ./setup.sh
# or:
#   ./setup.sh /path/to/workspace
#
# Default workspace (when not provided): /root/.openclaw/workspace

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC="$ROOT_DIR/openclaw"
DEST_DEFAULT="/root/.openclaw/workspace"
DEST="${OPENCLAW_WORKSPACE:-${1:-$DEST_DEFAULT}}"

cd "$ROOT_DIR"

echo "Syncing core specs into openclaw/ ..."
for name in SOUL USER USER-ROLE AGENTS HEARTBEAT TOOLS; do
  src="spec/core/${name}.md"
  if [[ -f "$src" ]]; then
    cp "$src" "openclaw/${name}.md"
  fi
done

# Stage and commit any spec/core changes so the CN repo matches runtime
if git diff --quiet spec/core openclaw; then
  echo "No spec/core changes to commit."
else
  echo "Committing updated core specs to CN repo ..."
  git add spec/core openclaw
  git commit -m "Update core specs and apply to OpenClaw workspace" || echo "Nothing to commit."
  git push || echo "Warning: git push failed; check your remote and credentials."
fi

echo "Syncing $SRC -> $DEST ..."
rsync -a --delete "$SRC"/ "$DEST"/
echo "Done."
