#!/usr/bin/env bash
set -euo pipefail

# setup.sh
#
# Apply the current core specs from this CN repo to an OpenClaw workspace.
# 1) Copy canonical core spec files into openclaw/ runtime tree
# 2) Rsync openclaw/ into the OpenClaw workspace
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

echo "Syncing $SRC -> $DEST ..."
rsync -a --delete "$SRC"/ "$DEST"/
echo "Done."
