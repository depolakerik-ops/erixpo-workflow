#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if ! command -v claude >/dev/null 2>&1; then
  echo "Claude Code CLI 'claude' not on PATH" >&2
  exit 2
fi
exec claude -p "$(cat "$PROMPT_FILE")" --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep"
