#!/usr/bin/env bash
# Explicit worktree lifecycle; never auto-merge to main.
set -euo pipefail
exec python3 "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/worktree-state.py" "$@"
