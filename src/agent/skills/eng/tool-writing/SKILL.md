# Tool Writing

Standards for mechanical scripts in `tools/`.

## When

- Task is mechanical
- No judgment required
- AI would burn tokens on clockwork

## Principles

- Zero runtime deps (bash, git, coreutils, jq)
- NO_COLOR support
- Prereq checks (fail fast)
- Idempotent (safe to re-run)
- Machine-readable output
- `set -euo pipefail`

## Template

```bash
#!/bin/bash
# tool-name.sh — description
# Usage: ./tools/tool-name.sh [args]
# Exit: 0=success, 1=error, 2=no-op

set -euo pipefail

if [[ -n "${NO_COLOR:-}" ]]; then
  RED="" GREEN="" RESET=""
else
  RED='\033[0;31m' GREEN='\033[0;32m' RESET='\033[0m'
fi

check_prereqs() {
  command -v git &>/dev/null || { echo "Missing: git" >&2; exit 1; }
}

main() {
  check_prereqs
  # logic
  echo -e "${GREEN}✓${RESET} Done"
}

main "$@"
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | Success |
| 1 | Error |
| 2 | No-op (already done) |
