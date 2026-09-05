#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
export ERIXPO_ROOT="$ROOT" ERIXPO_PROMPT_FILE="$PROMPT_FILE" ERIXPO_ITERATION="${3:-1}"
cd "$ROOT"
if [[ -n "${ERIXPO_WORKER_CMD:-}" ]]; then
  eval "$ERIXPO_WORKER_CMD"
  exit $?
fi
if command -v claude >/dev/null 2>&1; then
  exec claude -p "$(cat "$PROMPT_FILE")" --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep"
fi
if command -v codex >/dev/null 2>&1; then
  exec codex exec --full-auto "$(cat "$PROMPT_FILE")"
fi
echo "no supported worker CLI on PATH" >&2
exit 2
