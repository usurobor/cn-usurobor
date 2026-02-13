Setup:

  $ chmod +x cn.sh
  $ CN="$(pwd)/cn.sh"

Version command shows version:

  $ $CN --version
  cn 2.4.4

Help shows usage:

  $ $CN help 2>&1 | head -3
  cn - Coherent Network agent CLI
  
  Usage: cn <command> [options]

Unknown command fails:

  $ $CN unknown-cmd 2>&1 | head -1
  ✗ Unknown command: unknown-cmd
