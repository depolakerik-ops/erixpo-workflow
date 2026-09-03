#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if ! command -v opencode >/dev/null 2>&1; then
  echo "opencode CLI 'opencode' not on PATH" >&2
  exit 2
fi
exec opencode run "$(cat "$PROMPT_FILE")"
