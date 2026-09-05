import json
from pathlib import Path
import sys
root = Path(sys.argv[1])
assert json.loads((root / 'classification.json').read_text()) == {'class': 'build', 'platform': 'macos', 'ui': 'native'}
plan = (root / 'PLAN.md').read_text().lower()
assert 'window' in plan and ('persist' in plan or 'storage' in plan)
assert 'test' in plan or 'verif' in plan
assert not (root / 'package.json').exists()
