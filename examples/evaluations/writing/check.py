from pathlib import Path
import sys
root = Path(sys.argv[1])
text = (root / 'announcement.md').read_text()
assert 100 <= len(text.split()) <= 180
for required in ('2026-10-12', '09:00', '09:30', 'UTC', 'help@example.com'):
    assert required in text
assert 'export' in text.lower() and 'unavailable' in text.lower()
assert 'existing files' in text.lower() and 'accessible' in text.lower()
assert not (root / 'package.json').exists()
