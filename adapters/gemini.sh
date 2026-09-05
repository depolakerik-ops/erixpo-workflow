#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
export ERIXPO_ROOT="$ROOT" ERIXPO_PROMPT_FILE="$PROMPT_FILE" ERIXPO_ITERATION="${3:-1}"
cd "$ROOT"
if command -v gemini >/dev/null 2>&1; then
  exec gemini -p "$(cat "$PROMPT_FILE")"
fi
echo "Gemini CLI 'gemini' not on PATH" >&2
exit 2
