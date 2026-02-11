#!/bin/sh
# cnos installer — native OCaml binary
# Usage: curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh

set -e

REPO="https://github.com/usurobor/cnos"
INSTALL_DIR="/usr/local/lib/cnos"
BIN_DIR="/usr/local/bin"

echo "Installing cnos..."

# Clone or pull
if [ -d "$INSTALL_DIR" ]; then
  echo "Updating existing installation..."
  cd "$INSTALL_DIR"
  git pull --ff-only
else
  echo "Cloning cnos..."
  git clone --depth 1 "$REPO.git" "$INSTALL_DIR"
  cd "$INSTALL_DIR"
fi

# Build native binary
echo "Building from source..."
if ! command -v opam >/dev/null 2>&1; then
  echo "Error: opam required. Install opam first: https://opam.ocaml.org/doc/Install.html"
  exit 1
fi
eval $(opam env)
dune build tools/src/cn/cn.exe

# Install binary
cp _build/default/tools/src/cn/cn.exe "$BIN_DIR/cn"
chmod +x "$BIN_DIR/cn"

# Create cn-cron wrapper
cat > "$BIN_DIR/cn-cron" << 'EOF'
#!/bin/sh
# cn-cron — run cn sync cycle with logging
set -e
HUB="${1:-$(pwd)}"
LOG="/var/log/cn-$(date +%Y%m%d).log"
cd "$HUB"
exec cn sync >> "$LOG" 2>&1
EOF
chmod +x "$BIN_DIR/cn-cron"

echo ""
echo "cnos installed successfully"
echo ""
echo "Commands:"
echo "  cn --help     Show help"
echo "  cn update     Update to latest"
echo ""
cn --version 2>/dev/null || echo "cn installed (run 'cn --version' to verify)"
