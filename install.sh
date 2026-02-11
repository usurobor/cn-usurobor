#!/bin/sh
# cnos installer — downloads pre-built binary
# Usage: curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh

set -e

REPO="usurobor/cnos"
BIN_DIR="/usr/local/bin"

# Detect platform
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

# Get latest release tag
LATEST=$(curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/')

if [ -z "$LATEST" ]; then
  echo "Error: Could not determine latest release"
  exit 1
fi

echo "Latest release: ${LATEST}"

# Download binary
URL="https://github.com/${REPO}/releases/download/${LATEST}/${BINARY}"
echo "Downloading ${BINARY}..."

if ! curl -fsSL -o "${BIN_DIR}/cn" "$URL"; then
  echo "Error: Failed to download binary"
  echo "URL: $URL"
  exit 1
fi

chmod +x "${BIN_DIR}/cn"

echo ""
echo "✓ cnos installed successfully"
echo ""
"${BIN_DIR}/cn" --version
