#!/bin/sh
# cnos installer — downloads pre-built cn binary
# Usage: curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh
#
# Override install directory:
#   BIN_DIR=/usr/bin sh install.sh
#
# If /usr/local/bin requires root, use:
#   curl -fsSL ... | sudo sh

set -e

REPO="usurobor/cnos"
BIN_DIR="${BIN_DIR:-/usr/local/bin}"

# --- Prerequisites ---

if ! command -v curl >/dev/null 2>&1; then
  echo "Error: curl is required but not found"
  echo "Install it with: apt install curl / brew install curl"
  exit 1
fi

# --- Detect platform ---

OS="$(uname -s)"
ARCH="$(uname -m)"

case "$OS" in
  Linux)  PLATFORM="linux" ;;
  Darwin) PLATFORM="macos" ;;
  *)      echo "Unsupported OS: $OS"; exit 1 ;;
esac

case "$ARCH" in
  x86_64)  ARCH="x64" ;;
  aarch64) ARCH="arm64" ;;
  arm64)   ARCH="arm64" ;;
  *)       echo "Unsupported architecture: $ARCH"; exit 1 ;;
esac

TARGET="${PLATFORM}-${ARCH}"
BINARY="cn-${TARGET}"

echo "Installing cnos for ${TARGET}..."
echo "  Install directory: ${BIN_DIR}"

# --- Fetch latest release ---

LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" \
  | grep '"tag_name"' \
  | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "Error: Could not determine latest release"
  exit 1
fi

echo "  Latest release: ${LATEST}"

# --- Download binary ---

URL="https://github.com/${REPO}/releases/download/${LATEST}/${BINARY}"

if ! curl -fsSL -o "${BIN_DIR}/cn" "$URL"; then
  echo "Error: Failed to download binary"
  echo "  URL: $URL"
  if [ ! -w "$BIN_DIR" ]; then
    echo "  Hint: ${BIN_DIR} is not writable. Try: curl ... | sudo sh"
  fi
  exit 1
fi

chmod +x "${BIN_DIR}/cn"

echo ""
echo "cnos installed successfully"
echo ""
"${BIN_DIR}/cn" --version
