#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
if ! command -v codex >/dev/null 2>&1; then
  echo "Codex CLI 'codex' not on PATH" >&2
  exit 2
fi
exec codex exec --full-auto "$(cat "$PROMPT_FILE")"
