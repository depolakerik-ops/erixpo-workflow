#!/usr/bin/env bash
# Mechanical gate and artifact-bound evidence. Python is part of the CLI contract.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$SCRIPT_DIR/review-evidence.py" review "$@"
