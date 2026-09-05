#!/usr/bin/env python3
"""Transactional, ownership-aware pack installation (Python standard library only)."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile

HOSTS = ['cursor', 'claude', 'codex', 'gemini', 'opencode', 'github', 'windsurf', 'cline', 'crush', 'aider', 'hermes', 'generic', 'agents']
META = '.erixpo/install-manifest.json'
TEXT = '.erixpo/install-manifest.txt'


def digest(path):
    if path.is_symlink():
        return {'link': os.readlink(path)}
    if path.is_file():
        return {'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    return None


def safe(root, rel):
    p = Path(rel)
    if p.is_absolute() or not p.parts or '..' in p.parts or '.git' in p.parts:
        raise ValueError('unsafe path: ' + str(rel))
    target = root / p
    for parent in list(target.parents):
        if parent == root:
            break
        if parent.is_symlink():
            raise ValueError('symlink parent: ' + str(parent))
    return target


def legacy_owned(root, manifest, source):
    """Adopt only manifest-claimed bytes shipped in trusted historical commits.

    Legacy manifests record whole skill/template directories. Enumerate those
    without following links and map each candidate to a canonical pack path.
    Filenames alone never establish ownership.
    """
    trusted = json.loads((source / 'scripts/legacy-pack-hashes.json').read_text())['files']
    result = {}

    def canonical(rel):
        parts = Path(rel).parts
        if len(parts) >= 3 and parts[0] in {'.' + h for h in HOSTS} and parts[1] in ('skills', 'commands'):
            return str(Path(*parts[1:]))
        for dest, origin in [('.erixpo/pack-templates/', 'templates/'), ('.erixpo/bin/', 'bin/'),
                             ('.erixpo/scripts/', 'scripts/'), ('.erixpo/adapters/', 'adapters/')]:
            if rel.startswith(dest):
                return origin + rel[len(dest):]
        if rel == '.erixpo/VERSION':
            return 'VERSION'
        if rel.startswith(('bin/', 'scripts/', 'adapters/')):
            return rel
        return None

    def inspect(path):
        rel = str(path.relative_to(root))
        safe(root, rel)
        if path.is_symlink():
            if rel in ('bin', 'scripts') and os.readlink(path) == '.erixpo/' + rel:
                result[rel] = digest(path)
            else:
                print('preserved legacy symlink: ' + rel)
            return
        if path.is_dir():
            for child in sorted(path.iterdir()):
                inspect(child)
        elif path.is_file():
            current = digest(path)
            if current['sha256'] in trusted.get(canonical(rel), []):
                result[rel] = current
            else:
                print('preserved unknown or modified legacy file: ' + rel)

    for line in manifest.read_text().splitlines():
        rel = line.strip()
        if rel and not rel.startswith('#'):
            inspect(safe(root, rel))
    return result


def run(args):
    source = Path(args.source).resolve()
    root = Path.home() if args.globally else Path(args.target).absolute()
    # Do not install over the pack source or through a symlink target.
    if root.resolve() == Path('/'):
        raise ValueError('refusing filesystem root as target')
    if root.resolve() == source:
        raise ValueError('choose a target other than the pack source')
    for p in [root] + list(root.parents):
        if p.is_symlink():
            # macOS /tmp is a standard alias; normalize ancestors of the target.
            if p == root:
                raise ValueError('target is a symlink: ' + str(root))
    root = root.resolve()
    old = {}
    metadata = safe(root, META)
    if metadata.exists():
        old = json.loads(metadata.read_text())
        if old.get('format') != 1:
            raise ValueError('unsupported install manifest')
    legacy_manifest = safe(root, TEXT)
    if legacy_manifest.is_symlink() or (legacy_manifest.exists() and not legacy_manifest.is_file()):
        raise ValueError('unsafe text manifest')
    if legacy_manifest.is_file() and not old and not legacy_manifest.read_text().startswith('# erixpo-workflow '):
        raise ValueError('preserving unowned file: ' + TEXT)
    owned = old.get('files', {})
    if not old and legacy_manifest.is_file():
        owned = legacy_owned(root, legacy_manifest, source)
    for rel in owned:
        safe(root, rel)
    hosts = set(old.get('hosts', []))
    legacy_hosts = safe(root, '.erixpo/hosts.txt')
    if not old and legacy_hosts.is_file() and not legacy_hosts.is_symlink():
        hosts.update(line.strip() for line in legacy_hosts.read_text().splitlines()
                     if line.strip() and not line.startswith('#'))
    detected = subprocess.run(['bash', str(source / 'scripts/detect-host.sh')], cwd=root if root.is_dir() else source,
                              text=True, capture_output=True).stdout.split('\t')[0].strip() or 'generic'
    if args.detect:
        print('detected: ' + detected)
        return
    hosts.update(HOSTS if args.host == 'all' else [detected if args.host == 'auto' else args.host])
    hosts.add('agents')
    if not hosts.issubset(HOSTS):
        raise ValueError('unknown host: ' + ', '.join(hosts - set(HOSTS)))
    if not old and legacy_manifest.is_file() and legacy_hosts.is_file() and not legacy_hosts.is_symlink():
        owned['.erixpo/hosts.txt'] = digest(legacy_hosts)
    # rel -> (bytes or link target, executable, is_link); None means delete.
    changes = {}
    records = dict(owned)

    def put(rel, data, executable=False, link=False, optional=False):
        path = safe(root, rel)
        current = digest(path)
        expected = {'link': data} if link else {'sha256': hashlib.sha256(data).hexdigest()}
        if path.exists() or path.is_symlink():
            if current != owned.get(rel) and current != expected:
                if optional:
                    print('preserved unowned or modified: ' + rel)
                    return
                raise ValueError('preserving unowned or modified file: ' + rel)
        records[rel] = expected
        changes[rel] = (data, executable, link)

    def remove(rel, expected):
        path = safe(root, rel)
        if digest(path) == expected and expected is not None:
            changes[rel] = None
            records.pop(rel, None)
        elif path.exists() or path.is_symlink():
            print('preserved modified: ' + rel)
        else:
            records.pop(rel, None)

    uninstall = args.uninstall or args.purge or args.purge_docs or args.purge_worktrees
    if uninstall:
        for rel, expected in owned.items():
            remove(rel, expected)
        if not old and not legacy_manifest.is_file():
            print('No ownership manifest; preserving unowned files.')
        if args.purge_docs:
            manifest = safe(root, '.erixpo/init-manifest.txt')
            if manifest.is_file() and not manifest.is_symlink():
                retained_documents = False
                for line in manifest.read_text().splitlines():
                    rel = line.strip()
                    checksum = None
                    if '\t' in rel:
                        checksum, rel = rel.split('\t', 1)
                        if len(checksum) != 64 or any(c not in '0123456789abcdef' for c in checksum):
                            raise ValueError('invalid init manifest hash')
                    if not rel or rel.startswith('#'):
                        continue
                    path = safe(root, rel)
                    if path.is_file() and not path.is_symlink():
                        if checksum and digest(path) != {'sha256': checksum}:
                            print('preserved modified document: ' + rel)
                            retained_documents = True
                        else:
                            changes[rel] = None
                if not retained_documents:
                    changes['.erixpo/init-manifest.txt'] = None
        if args.purge_worktrees:
            base = root.parent / '.erixpo-worktrees'
            registry = safe(root, '.erixpo/worktrees.jsonl')
            if registry.is_symlink():
                raise ValueError('symlink worktree registry')
            rows = [json.loads(line) for line in registry.read_text().splitlines() if line.strip()] if registry.is_file() else []
            result = subprocess.run(['git', '-C', str(root), 'worktree', 'list', '--porcelain'], capture_output=True, text=True)
            selected = []
            for line in result.stdout.splitlines():
                if not line.startswith('worktree '):
                    continue
                wt = Path(line[9:])
                if wt.parent != base or not wt.name.startswith(root.name + '-'):
                    continue
                row = next((r for r in rows if r.get('path') == str(wt)), None)
                if row is None:
                    raise ValueError('unowned worktree; inspect before removal: ' + str(wt))
                selected.append((wt, row['id']))
            for wt, ident in selected:
                print(('DRY ' if args.dry_run else '') + 'prune owned worktree ' + ident + ': ' + str(wt))
                if not args.dry_run:
                    subprocess.run([sys.executable, str(source / 'scripts/worktree-state.py'), 'prune', '--id', ident], cwd=root, check=True)
        if args.purge:
            # --purge explicitly authorizes deleting workflow memory, including edits.
            # Preserve unrelated extras and worktree bookkeeping unless worktrees
            # were also explicitly purged.
            names = {p.name for p in (source / 'templates/.erixpo').glob('*') if p.is_file()}
            names.update(['state.md', 'loop-prompt.md', 'verification.json', 'run.lock',
                          'REVIEW-stage1.md', 'REVIEW-stage1.json', 'loop.log'])
            folders = ['run-events']
            if args.purge_worktrees:
                names.update(['worktrees.jsonl', 'worktrees.lock'])
                folders += ['worktree-baselines', 'worktree-archives']
            state = safe(root, '.erixpo')
            for name in names:
                path = safe(root, '.erixpo/' + name)
                if path.is_file() and not path.is_symlink():
                    changes['.erixpo/' + name] = None
            if state.is_dir() and not state.is_symlink():
                for path in state.glob('run-*-*-*.log'):
                    if path.is_file() and not path.is_symlink():
                        changes[str(path.relative_to(root))] = None
                for folder in folders:
                    directory = safe(root, '.erixpo/' + folder)
                    if directory.is_symlink():
                        raise ValueError('symlink state directory: ' + str(directory))
                    for path in directory.rglob('*'):
                        safe(root, str(path.relative_to(root)))
                        if path.is_file() and not path.is_symlink():
                            changes[str(path.relative_to(root))] = None
            print('Purging workflow memory; preserving unrelated extras and worktree bookkeeping unless --purge-worktrees is set.')
    else:
        def tree(src, dest):
            for path in sorted(src.rglob('*')):
                if path.is_symlink():
                    raise ValueError('source symlink is unsupported: ' + str(path))
                if path.is_file() and '__pycache__' not in path.parts and path.suffix != '.pyc':
                    put(str(Path(dest) / path.relative_to(src)), path.read_bytes(), bool(path.stat().st_mode & 0o111))
        for host in sorted(hosts):
            vendor = host if host in HOSTS[:8] else 'agents'
            tree(source / 'skills', '.' + vendor + '/skills')
            if host in ('claude', 'cursor', 'agents', 'generic', 'crush', 'aider', 'hermes'):
                tree(source / 'commands', '.' + vendor + '/commands')
        for folder, dest in [('bin', '.erixpo/bin'), ('adapters', '.erixpo/adapters'), ('scripts', '.erixpo/scripts'), ('templates', '.erixpo/pack-templates')]:
            tree(source / folder, dest)
        put('.erixpo/VERSION', (source / 'VERSION').read_bytes())
        if not old and safe(root, TEXT).is_file() and legacy_hosts.is_file() and not legacy_hosts.is_symlink():
            owned['.erixpo/hosts.txt'] = digest(legacy_hosts)
        put('.erixpo/hosts.txt', ('# installed hosts\n' + '\n'.join(sorted(hosts)) + '\n').encode())
        # Existing legacy directory links are retained without traversing them.
        for name in ('bin', 'scripts'):
            path = safe(root, name)
            target = '.erixpo/' + name
            if not path.exists() and not path.is_symlink() or digest(path) == {'link': target}:
                put(name, target, link=True, optional=True)
            elif name == 'bin' and path.is_dir() and not path.is_symlink():
                if digest(path / 'erixpo') == digest(source / 'bin/erixpo'):
                    owned['bin/erixpo'] = digest(path / 'erixpo')
                put('bin/erixpo', '#!/usr/bin/env bash\nexec "$(cd "$(dirname "$0")/.." && pwd)/.erixpo/bin/erixpo" "$@"\n'.encode(), True, optional=True)
        # Remove obsolete owned files only if unchanged.
        for rel, expected in owned.items():
            if rel not in changes:
                remove(rel, expected)

    version = (source / 'VERSION').read_text().strip()
    commit = subprocess.run(['git', '-C', str(source), 'rev-parse', 'HEAD'], capture_output=True, text=True).stdout.strip() or None
    payload = {'content_sha256': hashlib.sha256(json.dumps(records, sort_keys=True).encode()).hexdigest(), 'format': 1, 'version': version, 'commit': commit, 'source': str(source), 'hosts': sorted(hosts), 'files': records}
    changes[META] = (json.dumps(payload, indent=2, sort_keys=True).encode() + b'\n', False, False) if records else None
    changes[TEXT] = (('# erixpo-workflow ' + version + '\n' + '\n'.join(sorted(records)) + '\n').encode(), False, False) if records else None
    # Metadata must not be a directory or symlink, including on initial adoption.
    for rel in (META, TEXT):
        p = safe(root, rel)
        if p.is_symlink() or (p.exists() and not p.is_file()):
            raise ValueError('unsafe metadata path: ' + str(p))
    if args.dry_run:
        for rel, action in changes.items():
            print('DRY ' + ('remove ' if action is None else 'write ') + str(root / rel))
        return
    # Stage all bytes before touching the destination. Roll back each replacement
    # and every created directory if any later filesystem operation fails.
    made = []
    done = []
    with tempfile.TemporaryDirectory(prefix='erixpo-install-') as staging:
        staging = Path(staging)
        for i, (rel, action) in enumerate(changes.items()):
            if action and not action[2]:
                (staging / str(i)).write_bytes(action[0])
        try:
            for i, (rel, action) in enumerate(changes.items()):
                path = safe(root, rel)
                before = ('link', os.readlink(path)) if path.is_symlink() else ('file', path.read_bytes(), path.stat().st_mode) if path.is_file() else None
                if action is None and before is None:
                    continue
                missing = []
                parent = path.parent
                while not parent.exists():
                    missing.append(parent)
                    parent = parent.parent
                for parent in reversed(missing):
                    parent.mkdir()
                    made.append(parent)
                done.append((path, before))
                if action is None:
                    path.unlink()
                else:
                    # Write beside the destination so replace is atomic across devices.
                    fd, temporary = tempfile.mkstemp(prefix='.erixpo-write-', dir=path.parent)
                    os.close(fd)
                    temp = Path(temporary)
                    try:
                        if action[2]:
                            temp.unlink()
                            temp.symlink_to(action[0])
                        else:
                            shutil.copyfile(staging / str(i), temp)
                            temp.chmod(0o755 if action[1] else 0o644)
                        os.replace(temp, path)
                    finally:
                        if temp.exists() or temp.is_symlink():
                            temp.unlink()
        except BaseException:
            for path, before in reversed(done):
                if path.exists() or path.is_symlink():
                    path.unlink()
                if before:
                    if before[0] == 'link':
                        path.symlink_to(before[1])
                    else:
                        path.write_bytes(before[1])
                        path.chmod(before[2])
            for parent in reversed(made):
                parent.rmdir()
            raise
    if uninstall:
        # Prune only empty parents of removed files, never recursive user content.
        for rel in changes:
            p = (root / rel).parent
            while p != root and root in p.parents:
                try:
                    p.rmdir()
                except OSError:
                    break
                p = p.parent
    print('erixpo-workflow ' + ('removed from ' if uninstall else version + ' installed into ') + str(root))


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--source', required=True)
    parser.add_argument('--target', default=os.getcwd())
    parser.add_argument('--host', choices=['auto', 'all'] + HOSTS, default='auto')
    parser.add_argument('--global', dest='globally', action='store_true')
    for flag in ('dry-run', 'uninstall', 'purge', 'purge-worktrees', 'purge-docs', 'expand', 'detect'):
        parser.add_argument('--' + flag, action='store_true')
    args = parser.parse_args(['--uninstall' if arg in ('uninstall', '-u') else arg for arg in sys.argv[1:]])
    try:
        run(args)
    except (OSError, ValueError, subprocess.CalledProcessError) as exc:
        print('install: ' + str(exc), file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
