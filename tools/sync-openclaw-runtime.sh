#!/usr/bin/env bash
set -euo pipefail

# Sync canonical specs from spec/ into both the openclaw/ runtime tree and
# the workspace root (for tools/OpenClaw that expect files at root).
# This does NOT touch memory/state; it only updates config-style files.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

for name in SOUL USER USER-ROLE AGENTS ENGINEERING IDENTITY HEARTBEAT TOOLS; do
  src="spec/${name}.md"
  if [[ -f "$src" ]]; then
    cp "$src" "openclaw/${name}.md"
    cp "$src" "${name}.md"
  fi
done

echo "Synced spec/ → openclaw/ and workspace root runtime files."