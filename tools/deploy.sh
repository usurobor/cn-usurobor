#!/usr/bin/env bash
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/openclaw"
DEST="/root/.openclaw/workspace"

echo "Syncing $SRC -> $DEST ..."
rsync -a --delete "$SRC"/ "$DEST"/
echo "Done."
