#!/bin/sh
# cnos installer - git-only, no npm registry
# Usage: curl -fsSL https://raw.githubusercontent.com/usurobor/cnos/main/install.sh | sh

set -e

REPO="https://github.com/usurobor/cnos"
INSTALL_DIR="/usr/local/lib/cnos"
BIN_DIR="/usr/local/bin"

echo "Installing cnos..."

# Check for node
if ! command -v node >/dev/null 2>&1; then
  echo "Error: node is required. Install Node.js first."
  exit 1
fi

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

# Check if pre-built dist exists, otherwise build
if [ -f "tools/dist/cn.js" ]; then
  echo "Using pre-built distribution..."
else
  echo "Building from source..."
  if ! command -v opam >/dev/null 2>&1; then
    echo "Error: opam required for building. Install pre-built release or install opam."
    exit 1
  fi
  eval $(opam env)
  npm install --ignore-scripts
  npm run build
fi

# Create wrapper script
cat > "$BIN_DIR/cn" << 'EOF'
#!/bin/sh
exec node /usr/local/lib/cnos/tools/dist/cn.js "$@"
EOF
chmod +x "$BIN_DIR/cn"

# Create cn-cron wrapper
cat > "$BIN_DIR/cn-cron" << 'EOF'
#!/bin/sh
# cn-cron - Run cn sync cycle with logging
set -e
HUB="${1:-$(pwd)}"
LOG="/var/log/cn-$(date +%Y%m%d).log"
cd "$HUB"
exec cn sync >> "$LOG" 2>&1
EOF
chmod +x "$BIN_DIR/cn-cron"

echo ""
echo "✓ cnos installed successfully"
echo ""
echo "Commands:"
echo "  cn --help     Show help"
echo "  cn update     Update to latest"
echo ""
cn --version 2>/dev/null || echo "cn installed (run 'cn --version' to verify)"
