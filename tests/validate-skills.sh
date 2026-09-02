#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
err=0
for skill in "$ROOT/skills"/*; do
  [[ -d "$skill" ]] || continue
  name="$(basename "$skill")"
  md="$skill/SKILL.md"
  if [[ ! -f "$md" ]]; then
    echo "FAIL $name: missing SKILL.md"
    err=1
    continue
  fi
  front="$(python3 - "$md" "$name" <<'PY'
import sys, re
path, expected = sys.argv[1], sys.argv[2]
text = open(path, encoding="utf-8").read()
if not text.startswith("---"):
    print("no frontmatter")
    sys.exit(2)
parts = text.split("---", 2)
if len(parts) < 3:
    print("broken frontmatter")
    sys.exit(2)
fm = parts[1]
m = re.search(r"^name:\s*([a-z0-9-]+)\s*$", fm, re.M)
if not m:
    print("missing name")
    sys.exit(2)
if m.group(1) != expected:
    print(f"name {m.group(1)!r} != folder {expected!r}")
    sys.exit(2)
if not re.search(r"^description:\s+\S", fm, re.M):
    print("missing description")
    sys.exit(2)
print("ok")
PY
)" || true
  if [[ "$front" != "ok" ]]; then
    echo "FAIL $name: $front"
    err=1
  else
    echo "ok $name"
  fi
done
exit "$err"
