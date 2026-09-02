#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if command -v hermes >/dev/null 2>&1; then
  exec hermes -p "$(cat "$PROMPT_FILE")"
fi
echo "Hermes CLI 'hermes' not on PATH" >&2
exit 2
