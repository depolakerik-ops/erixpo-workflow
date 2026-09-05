#!/usr/bin/env bash
# Deterministic pack validation and installed-product lifecycle regressions.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
cd "$ROOT"
echo "== shell syntax and skill links =="
for f in install.sh uninstall.sh bin/erixpo check.sh adapters/*.sh scripts/*.sh tests/*.sh; do
  bash -n "$f"
done
bash tests/validate-skills.sh

echo "== version, templates, and protocol contracts =="
python3 - <<'PY'
import json, re
from pathlib import Path
version = Path('VERSION').read_text().strip()
assert re.fullmatch(r'\d+\.\d+\.\d+', version)
assert json.loads(Path('.claude-plugin/plugin.json').read_text())['version'] == version
assert all(p['version'] == version for p in json.loads(Path('.claude-plugin/marketplace.json').read_text())['plugins'])
for p in Path('skills').glob('*/SKILL.md'):
    assert f'version: "{version}"' in p.read_text(), p
    assert len(p.read_text().splitlines()) < 500, p
for name in ('plan.md', 'state.md', 'stack.md'):
    assert (Path('templates/.erixpo') / name).read_text() == (Path('templates/erixpo') / name).read_text(), f'template drift: {name}'
assert not Path('templates/.erixpo/state.yaml').exists()
for path in ('templates/.erixpo/USER.md', 'templates/.erixpo/CONSTITUTION.md', 'templates/.erixpo/classify.md', 'templates/.erixpo/test-plan.md', 'templates/PROMPT.md', 'scripts/install-pack.py', 'scripts/worktree-state.py', 'scripts/review-evidence.py', 'scripts/erixpo-runtime.py'):
    assert Path(path).is_file(), path
for key in ('check:', 'install:'):
    assert key in Path('templates/.erixpo/stack.md').read_text()
# Validate links in canonical protocol references, not just SKILL.md entrypoints.
for path in Path('skills/erixpo/references').glob('*.md'):
    for target in re.findall(r'\]\(([^)]+)\)', path.read_text()):
        if '://' in target or target.startswith(('#', 'mailto:')):
            continue
        target = target.split('#')[0]
        assert not target or (path.parent / target).exists(), (path, target)
print('metadata and templates passed')
PY

echo "== classification and research fixtures =="
python3 scripts/classify-signals.py --selftest
python3 scripts/research-scope.py --selftest
[[ "$(bash bin/erixpo research-scope --class new)" == full ]]

echo "== deterministic lifecycle and adapter tests =="
python3 -m unittest discover -s tests -p 'test_*.py' -v

echo "== Codex plugin packaging =="
python3 tests/validate-codex-plugin.py

echo "== installed-product smoke =="
bash tests/smoke.sh

echo "== behavioral evaluation fixture validation (no provider calls) =="
python3 scripts/evaluate-workflow.py --dry-run
echo "CHECK PASSED"
