#!/usr/bin/env bash
# Repo-level check for erixpo-workflow itself.
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

echo "== adapter contract (ROOT first, PROMPT_FILE second) =="
python3 - <<'PY' || fail=1
from pathlib import Path
root = Path("adapters")
bad = []
for p in sorted(root.glob("*.sh")):
    text = p.read_text()
    if 'ROOT="${1:-$(pwd)}"' not in text and "ROOT=\"${1:-$(pwd)}\"" not in text:
        if 'ROOT="${1:-$(pwd)}"' not in text.replace("'", '"'):
            if 'ROOT="${1:' not in text:
                bad.append(f"{p.name}: ROOT is not $1")
    if "PROMPT_FILE=" in text and 'PROMPT_FILE="${2:' not in text and "PROMPT_FILE=\"${2:" not in text:
        if 'PROMPT_FILE="${2' not in text:
            bad.append(f"{p.name}: PROMPT_FILE is not $2")
if bad:
    print("\n".join(bad))
    raise SystemExit(1)
print("ok adapters")
PY

echo "== templates have check: and install: =="
grep -q '^check:' templates/.erixpo/stack.md || { echo "stack.md missing check:"; fail=1; }
grep -q '^install:' templates/.erixpo/stack.md || { echo "stack.md missing install:"; fail=1; }
[[ -f templates/documents/ui/tokens.md ]] || { echo "missing UI token template"; fail=1; }
[[ -f templates/documents/ui/layout.md ]] || { echo "missing UI layout template"; fail=1; }
[[ -f templates/documents/ui/mapping.md ]] || { echo "missing UI mapping template"; fail=1; }
[[ -f skills/erixpo-ui/SKILL.md ]] || { echo "missing erixpo-ui skill"; fail=1; }

echo "== v0.6 protocol files =="
for f in \
  skills/erixpo/references/classify.md \
  skills/erixpo/references/scaffold.md \
  skills/erixpo/references/ceremony.md \
  skills/erixpo/references/slop.md \
  skills/erixpo/references/ui.md \
  skills/erixpo/references/testing.md \
  skills/erixpo/references/worktrees.md \
  templates/PROMPT.md \
  templates/.erixpo/USER.md \
  templates/.erixpo/CONSTITUTION.md \
  templates/.erixpo/classify.md \
  templates/.erixpo/plan.md \
  templates/erixpo/plan.md
do
  [[ -f "$f" ]] || { echo "missing $f"; fail=1; }
done
grep -q 'bin/erixpo close' bin/erixpo || { echo "bin/erixpo missing close"; fail=1; }
grep -q 'erixpo-ui' install.sh || { echo "install.sh SKILL_NAMES missing erixpo-ui"; fail=1; }
# plan templates must both mention scaffold / tests / UI change-type
grep -q 'scaffold' templates/.erixpo/plan.md || { echo "rich plan missing scaffold"; fail=1; }
grep -q 'scaffold' templates/erixpo/plan.md || { echo "templates/erixpo/plan.md drifted (missing scaffold)"; fail=1; }
grep -q 'relanguage | retoken | recompose | reflow' templates/.erixpo/plan.md || { echo "plan missing ui_change enum"; fail=1; }
grep -q 'relanguage | retoken | recompose | reflow' templates/erixpo/plan.md || { echo "templates/erixpo/plan.md missing ui_change enum"; fail=1; }
grep -q 'create | relanguage | retoken' skills/erixpo/references/classify.md || { echo "classify.md missing create ui_change"; fail=1; }
grep -q 'look at' skills/erixpo/references/classify.md || { echo "classify.md missing look-at → review"; fail=1; }

echo "== classify fixtures =="
python3 scripts/classify-signals.py --selftest || fail=1
[[ -f scripts/detect-capabilities.sh ]] || { echo "missing detect-capabilities.sh"; fail=1; }
bash scripts/detect-capabilities.sh >/dev/null || fail=1
grep -q 'classify-signals.py' install.sh || { echo "install.sh missing classify-signals.py"; fail=1; }

echo "== smoke =="
bash tests/smoke.sh || fail=1

if [[ "$fail" -ne 0 ]]; then
  echo "CHECK FAILED"
  exit 1
fi
echo "CHECK PASSED"
