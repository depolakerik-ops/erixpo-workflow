#!/usr/bin/env bash
# File ownership and transactional install logic live in the portable Python helper.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
exec python3 "$ROOT/scripts/install-pack.py" --source "$ROOT" "$@"
