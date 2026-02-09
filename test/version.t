Version command shows version:

  $ node ../tools/dist/cn.js --version
  cn 2.2.10

Help shows usage:

  $ node ../tools/dist/cn.js help 2>&1 | head -3
  cn - Coherent Network agent CLI
  
  Usage: cn <command> [options]

Unknown command fails:

  $ node ../tools/dist/cn.js unknown-cmd 2>&1 | head -1
  ✗ Unknown command: unknown-cmd
