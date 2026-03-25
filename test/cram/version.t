Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"
  $ CNOS_VERSION=$(cat ../../VERSION | tr -d '\n')

Version command shows version and commit derived from VERSION file:

  $ ACTUAL=$($CN --version)
  $ echo "$ACTUAL" | grep -q "^cn $CNOS_VERSION " && echo "version ok" || echo "MISMATCH: got '$ACTUAL' expected 'cn $CNOS_VERSION (...)'"
  version ok

Help shows usage:

  $ $CN help 2>&1 | head -3
  cn - Coherent Network agent CLI
  
  Usage: cn <command> [options]

Unknown command fails:

  $ $CN unknown-cmd 2>&1 | head -1
  ✗ Unknown command: unknown-cmd
