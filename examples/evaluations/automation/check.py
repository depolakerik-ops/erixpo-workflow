import json
from pathlib import Path
import subprocess
import sys
import tempfile
root = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as directory:
    csv = Path(directory) / 'data with spaces.csv'
    csv.write_text('name,amount\n"A, B",0.10\nC,0.20\nD,-0.05\n')
    out = subprocess.check_output([sys.executable, str(root / 'summarize.py'), str(csv)], text=True)
    assert json.loads(out) == {'row_count': 3, 'total_amount': '0.25'}
    csv.write_text('name,amount\n')
    out = subprocess.check_output([sys.executable, str(root / 'summarize.py'), str(csv)], text=True)
    assert json.loads(out) == {'row_count': 0, 'total_amount': '0.00'}
assert list(root.glob('**/test*.py')), 'missing regression tests'
