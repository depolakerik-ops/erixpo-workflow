import importlib.util
from pathlib import Path
import sys
root = Path(sys.argv[1])
spec = importlib.util.spec_from_file_location('app', root / 'app.py')
app = importlib.util.module_from_spec(spec)
spec.loader.exec_module(app)
assert app.greeting('Ada') == 'Hello, Ada'
assert app.slugify(' Hello, WORLD! ') == 'hello-world'
assert app.slugify('a___b---c') == 'a-b-c'
assert app.slugify('!?') == ''
assert app.slugify('A1 B2') == 'a1-b2'
assert list(root.glob('**/test*.py')), 'missing regression tests'
