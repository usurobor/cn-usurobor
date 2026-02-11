#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NO_COLOR=1 exec "$SCRIPT_DIR/../_build/default/tools/src/cn/cn.exe" "$@"
