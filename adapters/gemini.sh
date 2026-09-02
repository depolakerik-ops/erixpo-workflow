#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if command -v gemini >/dev/null 2>&1; then
  exec gemini -p "$(cat "$PROMPT_FILE")"
fi
echo "Gemini CLI 'gemini' not on PATH" >&2
exit 2
