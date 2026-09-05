#!/usr/bin/env python3
"""Mechanical project review and artifact-bound review evidence (stdlib only)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
from datetime import datetime, timezone
import uuid

GENERATED = {'.git', 'node_modules', '__pycache__', '.venv', 'venv', 'dist', 'build', '.next', '.cache', 'vendor'}
SOURCE = {'.py', '.js', '.jsx', '.ts', '.tsx', '.swift', '.kt', '.java', '.c', '.h', '.cpp', '.cc', '.cs', '.rs', '.go', '.rb', '.php', '.sh', '.bash', '.zsh', '.css', '.scss', '.html', '.vue', '.svelte', '.dart'}
SECRET = re.compile(r'BEGIN (?:RSA |OPENSSH |EC )?PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}')
DUMMY = re.compile(r'\b(?:expect|assert|assertTrue|XCTAssertTrue|XCTAssert|Assert\.True|Assert\.IsTrue|True|shouldBe|assert!)\s*\(\s*(?:true|True)\s*\)|\bassert\s+(?:True|true)\s*(?:$|[;#])', re.M)


def git(root, *args):
    p = subprocess.run(['git', '-C', str(root), *args], stdout=subprocess.PIPE, stderr=subprocess.DEVNULL)
    return p.stdout if p.returncode == 0 else b''


def field(path, key):
    if not path.is_file():
        return ''
    match = re.search(r'^' + re.escape(key) + r':[ \t]*([^\r\n]*?)[ \t]*$', path.read_text(errors='replace'), re.M)
    return match.group(1) if match else ''


def check_command(root):
    return field(root / '.erixpo/stack.md', 'check') or field(root / 'AGENTS.md', 'check')


def owned(root):
    path = root / '.erixpo/install-manifest.txt'
    if not path.is_file():
        return []
    return [x.strip().rstrip('/') for x in path.read_text().splitlines()
            if x.strip() and not x.startswith('#') and not Path(x.strip()).is_absolute() and '..' not in Path(x.strip()).parts]


def excluded(name, entries):
    p = Path(name)
    return ('.erixpo' in p.parts or any(x in GENERATED for x in p.parts)
            or any(name == x or name.startswith(x + '/') for x in entries))


def files(root):
    entries = owned(root)
    if git(root, 'rev-parse', '--is-inside-work-tree').strip() == b'true':
        names = {os.fsdecode(x) for x in git(root, 'ls-files', '-z', '--cached', '--others', '--exclude-standard').split(b'\0') if x}
    else:
        names = set()
        for directory, dirs, fs in os.walk(root, followlinks=False):
            dirs[:] = [d for d in dirs if not excluded(str((Path(directory) / d).relative_to(root)), entries) and not (Path(directory) / d).is_symlink()]
            names.update(str((Path(directory) / f).relative_to(root)) for f in fs)
    return sorted(n for n in names if not excluded(n, entries))


def body(root, name):
    p = root / name
    # Never follow project symlinks into installed packs or outside the project.
    if p.is_symlink() or any(parent.is_symlink() for parent in p.parents if parent != root and root in parent.parents):
        return b''
    return p.read_bytes() if p.is_file() else b''


def identity(root, base):
    h = hashlib.sha256()
    for name in files(root):
        p = root / name
        h.update(os.fsencode(name) + b'\0')
        if p.is_symlink():
            h.update(b'link\0' + os.fsencode(os.readlink(p)))
        elif p.is_file():
            h.update(str(p.stat().st_mode & 0o777).encode() + b'\0' + body(root, name))
        else:
            h.update(b'missing')
        h.update(b'\0')
    return dict(base=base, head=git(root, 'rev-parse', '--verify', 'HEAD').decode().strip(), tree_digest=h.hexdigest(), check=check_command(root))


def base_for(root):
    explicit = os.environ.get('ERIXPO_REVIEW_BASE', '')
    if explicit:
        value = git(root, 'rev-parse', '--verify', explicit + '^{commit}').decode().strip()
        if not value:
            raise ValueError('ERIXPO_REVIEW_BASE is not a commit')
        return value
    marker = root / '.erixpo/isolation.json'
    if marker.is_file():
        try:
            isolation = json.loads(marker.read_text())
            branch = git(root, 'symbolic-ref', '--short', 'HEAD').decode().strip()
            if isolation.get('branch') == branch:
                value = git(root, 'rev-parse', '--verify', str(isolation['base_commit']) + '^{commit}').decode().strip()
                if not value:
                    raise ValueError('isolation base_commit is not a commit')
                return value
        except (KeyError, json.JSONDecodeError) as exc:
            raise ValueError('invalid isolation review metadata') from exc
    head = git(root, 'rev-parse', '--verify', 'HEAD').decode().strip()
    for ref in ('origin/HEAD', 'origin/main', 'origin/master', 'main', 'master'):
        value = git(root, 'merge-base', 'HEAD', ref).decode().strip()
        if value and not (value == head and ref in ('main', 'master')):
            return value
    return git(root, 'rev-parse', '--verify', 'HEAD~1').decode().strip()


def is_test(name):
    p = Path(name)
    return (any(part.lower() in ('test', 'tests', '__tests__', 'spec', 'specs', 'androidtest', 'uitests') or part.endswith(('Tests', 'UITests')) for part in p.parts[:-1])
            or bool(re.search(r'(^test[_-]|^spec[_-]|[._-](test|spec)\.|(Test|Tests|Spec)\.)', p.name)))


def atomic_json(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, name = tempfile.mkstemp(dir=path.parent)
    try:
        with os.fdopen(fd, 'w') as f:
            json.dump(value, f, indent=2)
            f.write('\n')
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def review(root):
    failures, notes = [], []
    try:
        base = base_for(root)
    except ValueError as e:
        base = ''
        failures.append(str(e))
    before = identity(root, base)
    check = before['check']
    if not check or check.strip() in ('true', 'exit 0', ':', 'echo ok', 'echo "ok"', 'echo OK', 'echo "OK"'):
        failures.append('missing or dummy check command')
    elif subprocess.run(['bash', '-c', check], cwd=root).returncode:
        failures.append('check failed in this review')
    else:
        notes.append('check exited 0 in this review')
    names = files(root)
    for name in names:
        p = Path(name)
        data = body(root, name)
        if re.search(r'(^|/)(\.env$|id_rsa(?:$|\.)|id_ed25519(?:$|\.))|\.(pem|p12)$', name) and 'example' not in p.name:
            failures.append('secret-looking file name: ' + repr(name))
        if b'\0' in data:
            continue
        text = data.decode(errors='replace')
        if SECRET.search(text):
            failures.append('secret-looking content: ' + repr(name))
        if p.suffix in SOURCE:
            if DUMMY.search(text):
                failures.append('dummy tautology assertion: ' + repr(name))
            if 'TODO: implement' in text or 'lorem ipsum' in text:
                failures.append('placeholder source content: ' + repr(name))
    for name in ('.erixpo/sessions.jsonl', '.erixpo/learnings.jsonl'):
        if SECRET.search(body(root, name).decode(errors='replace')):
            failures.append('secret-looking content: ' + name)
    changed = set()
    if git(root, 'rev-parse', '--is-inside-work-tree').strip() == b'true':
        for args in [('diff', '--name-only', '-z', 'HEAD'), ('diff', '--name-only', '-z', '--cached'), ('ls-files', '--others', '--exclude-standard', '-z')]:
            changed.update(os.fsdecode(x) for x in git(root, *args).split(b'\0') if x)
        if base:
            changed.update(os.fsdecode(x) for x in git(root, 'diff', '--name-only', '-z', base, 'HEAD').split(b'\0') if x)
    else:
        changed.update(names)
    changed = {x for x in changed if not excluded(x, owned(root))}
    klass = field(root / '.erixpo/PROFILE.md', 'class').split(' ')[0].lower()
    if klass in ('writing', 'research', 'ops', 'assistant') or os.environ.get('ERIXPO_DOCS_ONLY') == '1':
        notes.append('docs/non-software class or ERIXPO_DOCS_ONLY=1 — skipped test-file pairing')
    if os.environ.get('ERIXPO_SKIP_TEST_PAIRING') == '1':
        notes.append('ERIXPO_SKIP_TEST_PAIRING=1 — skipped test-file pairing')
    if klass not in ('writing', 'research', 'ops', 'assistant') and os.environ.get('ERIXPO_DOCS_ONLY') != '1' and os.environ.get('ERIXPO_SKIP_TEST_PAIRING') != '1':
        if any(Path(x).suffix in SOURCE and not is_test(x) for x in changed) and not any(is_test(x) and Path(x).suffix in SOURCE and (root / x).is_file() for x in changed):
            failures.append('product files changed with no test/spec file in the slice range')
    mapping = root / 'documents/ui/mapping.md'
    if mapping.is_file() and os.environ.get('ERIXPO_SKIP_HEX') != '1':
        theme = (field(mapping, 'theme_file') or field(mapping, 'path') or field(mapping, 'Path')).strip('`')
        if theme and (root / theme).is_file():
            hex_re = re.compile(r'#[0-9A-Fa-f]{3,8}\b')
            allowed = set(x.lower() for x in hex_re.findall((root / theme).read_text(errors='replace')))
            for name in changed:
                if Path(name).suffix not in SOURCE or (root / name).resolve() == (root / theme).resolve():
                    continue
                if any(x.lower() not in allowed for x in hex_re.findall(body(root, name).decode(errors='replace'))):
                    failures.append('hard-coded hex outside theme_file: ' + repr(name))
    after = identity(root, base)
    if before != after:
        failures.append('project changed during review; rerun on stable files')
    evidence = dict(after, schema=1, result='fail' if failures else 'pass', review_id=str(uuid.uuid4()), reviewed_at=datetime.now(timezone.utc).isoformat())
    atomic_json(root / '.erixpo/REVIEW-stage1.json', evidence)
    report = '\n'.join(['## Stage 1', 'Result: ' + evidence['result'], 'BASE: ' + (base or 'none'), 'Review-ID: ' + evidence['review_id'], 'Notes:', *('- ' + n for n in notes), *('- FAIL: ' + n for n in failures)]) + '\n'
    (root / '.erixpo/REVIEW-stage1.md').write_text(report)
    print(report)
    print('STAGE 1 ' + ('FAILED' if failures else 'PASSED'))
    return bool(failures)


def verify(root, base):
    try:
        e = json.loads((root / '.erixpo/REVIEW-stage1.json').read_text())
        if e.get('schema') != 1 or e.get('result') != 'pass' or not e.get('review_id') or not e.get('reviewed_at'):
            raise ValueError('missing passing stage-1 evidence')
        now = identity(root, base if base is not None else e['base'])
        if any(e.get(k) != v for k, v in now.items()):
            raise ValueError('stage-1 evidence is stale (base, HEAD, tree, or check changed)')
        if not field(root / '.erixpo/REVIEW.md', 'Reviewer'):
            raise ValueError('stage-2 Reviewer identity is required')
        if field(root / '.erixpo/REVIEW.md', 'Result') != 'ship' or field(root / '.erixpo/REVIEW.md', 'Review-ID') != e['review_id']:
            raise ValueError('stage-2 ship verdict does not match current stage-1 Review-ID')
    except (OSError, ValueError, KeyError) as exc:
        print('Review verification failed: ' + str(exc), file=sys.stderr)
        return 1
    print('Review evidence verified')
    return 0


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=('review', 'verify'))
    parser.add_argument('--root', type=Path, default=Path.cwd())
    parser.add_argument('--base')
    args = parser.parse_args()
    sys.exit(review(args.root.resolve()) if args.command == 'review' else verify(args.root.resolve(), args.base))
