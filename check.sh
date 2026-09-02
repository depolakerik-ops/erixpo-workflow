#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
fail=0
echo "== bash -n =="
bash -n install.sh || fail=1
bash -n bin/erixpo || fail=1
bash -n check.sh || fail=1
for f in adapters/*.sh scripts/*.sh; do
  [[ -f "$f" ]] || continue
  bash -n "$f" || fail=1
done
bash -n tests/validate-skills.sh || fail=1
bash -n tests/smoke.sh || fail=1
echo "== skill frontmatter =="
bash tests/validate-skills.sh || fail=1
echo "== templates =="
grep -q '^check:' templates/.erixpo/stack.md || fail=1
grep -q '^install:' templates/.erixpo/stack.md || fail=1
echo "== smoke =="
bash tests/smoke.sh || fail=1
if [[ "$fail" -ne 0 ]]; then echo CHECK FAILED; exit 1; fi
echo CHECK PASSED
