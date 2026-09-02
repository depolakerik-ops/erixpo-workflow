#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if command -v agent >/dev/null 2>&1; then
  exec agent -p --force "$(cat "$PROMPT_FILE")"
fi
echo "Cursor CLI 'agent' not on PATH" >&2
exit 2
