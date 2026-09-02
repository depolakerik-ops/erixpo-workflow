#!/usr/bin/env bash
set -euo pipefail
ROOT="${1:-$(pwd)}"
PROMPT_FILE="${2:-$ROOT/.erixpo/plan.md}"
cd "$ROOT"
claude -p "$(cat "$PROMPT_FILE")" --permission-mode acceptEdits --allowedTools "Bash,Read,Write,Edit,Glob,Grep"
