#!/usr/bin/env python3
"""Locked, loss-averse worktree lifecycle for macOS and Linux."""
import argparse
import contextlib
import datetime
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import sys
import tempfile
import uuid


def git(root, *args, check=True):
    p = subprocess.run(['git', '-C', str(root), *args], capture_output=True, text=True)
    if check and p.returncode:
        raise RuntimeError(p.stderr.strip() or p.stdout.strip())
    return p.stdout.strip() if check else p


def atomic(path, data, mode=None):
    if path.is_symlink() or any(p.is_symlink() for p in path.parents):
        raise RuntimeError(f'refusing symlink destination: {path}')
    path.parent.mkdir(parents=True, exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix='.' + path.name, dir=path.parent)
    os.fchmod(fd, mode if mode is not None else (path.stat().st_mode & 0o777 if path.exists() else 0o644))
    try:
        with os.fdopen(fd, 'wb') as f:
            f.write(data)
            f.flush()
            os.fsync(f.fileno())
        os.replace(tmp, path)
    finally:
        if os.path.exists(tmp):
            os.unlink(tmp)


def rows_read(path):
    # Corruption is an error, never silently discard historical records.
    return [json.loads(s) for s in path.read_text().splitlines() if s.strip()] if path.exists() else []


def rows_write(path, rows):
    atomic(path, ''.join(json.dumps(r, ensure_ascii=False) + '\n' for r in rows).encode())


def branch_exists(root, branch):
    return git(root, 'show-ref', '--verify', '--quiet', 'refs/heads/' + branch, check=False).returncode == 0


def contained(root, branch):
    return git(root, 'merge-base', '--is-ancestor', branch, 'HEAD', check=False).returncode == 0


def installed_files(root):
    manifest = root / '.erixpo/install-manifest.json'
    if not manifest.is_file() or manifest.is_symlink():
        return {}
    rows = json.loads(manifest.read_text()).get('files', {})
    return {name: expected for name, expected in rows.items()
            if not Path(name).is_absolute() and '..' not in Path(name).parts}


def matches(root, name, expected):
    path = root / name
    if path.is_symlink():
        return expected == {'link': os.readlink(path)}
    if path.is_file() and not any(p.is_symlink() for p in path.parents):
        return expected == {'sha256': hashlib.sha256(path.read_bytes()).hexdigest()}
    return False


def dirty(root):
    # NUL-delimited names support spaces, tabs and newlines. All tracked changes
    # matter, including tracked metadata. Untracked metadata is reconciled below.
    owned = installed_files(root)
    for flags in [('diff', '--name-only', '-z'), ('diff', '--cached', '--name-only', '-z'),
                  ('ls-files', '--others', '--exclude-standard', '-z'),
                  ('ls-files', '--others', '--ignored', '--exclude-standard', '-z')]:
        p = subprocess.run(['git', '-C', str(root), *flags], check=True, capture_output=True)
        for raw in p.stdout.split(b'\0'):
            if raw:
                name = os.fsdecode(raw)
                if flags[0] == 'diff' or (not name.startswith('.erixpo/') and not matches(root, name, owned.get(name))):
                    raise RuntimeError(f'working tree is dirty: {root}: {name}; commit or preserve it before merge/close/prune')


def metadata_files(directory):
    if directory.is_symlink():
        raise RuntimeError(f'refusing metadata symlink: {directory}')
    if not directory.exists():
        return {}
    result = {}
    for p in directory.rglob('*'):
        if p.is_symlink():
            raise RuntimeError(f'refusing metadata symlink: {p}')
        if p.is_file():
            result[str(p.relative_to(directory))] = p.read_bytes()
        elif not p.is_dir():
            raise RuntimeError(f'refusing special metadata file: {p}')
    return result


DURABLE = ('USER.md', 'MEMORY.md', 'progress.md', 'progress.jsonl', 'sessions.jsonl', 'learnings.jsonl', 'refine-log.md')


def events_merge(parent, child):
    events, identities = [], {}
    for payload in (parent, child):
        for line in (payload or b'').decode().splitlines():
            if not line.strip():
                continue
            event = json.loads(line)
            canonical = json.dumps(event, sort_keys=True)
            key = event.get('id') or hashlib.sha256(canonical.encode()).hexdigest()
            if key in identities:
                if identities[key] != canonical:
                    raise RuntimeError(f'conflicting event id {key}')
                continue
            identities[key] = canonical
            events.append(event)
    return ''.join(json.dumps(e, ensure_ascii=False) + '\n' for e in events).encode()


def learnings_merge(baseline, parent, child):
    def parsed(payload):
        return [json.loads(line) for line in (payload or b'').decode().splitlines() if line.strip()]

    def effective(rows):
        result = {}
        for event in rows:
            key = str(event.get('key') or '').strip()
            if key:
                result[key] = event
        return result

    parent_rows, child_rows = parsed(parent), parsed(child)
    before, ours, theirs = effective(parsed(baseline)), effective(parent_rows), effective(child_rows)
    for key in set(before) | set(ours) | set(theirs):
        if ours.get(key) != before.get(key) and theirs.get(key) != before.get(key) and ours.get(key) != theirs.get(key):
            raise RuntimeError(f'conflicting learning key {key}; reconcile parent and worktree before closing')
    # Replay only child keys whose effective value should replace the parent.
    # Replaying unchanged history after a parent tombstone/deletion, or replaying
    # intermediate records when the final record is already deduplicated, can
    # otherwise resurrect an obsolete active lesson.
    replay = {key for key in theirs if theirs[key] != ours.get(key) and ours.get(key) == before.get(key)}
    selected = [event for event in child_rows
                if not str(event.get('key') or '').strip() or str(event.get('key') or '').strip() in replay]
    payload = ''.join(json.dumps(event) + '\n' for event in selected).encode()
    merged = events_merge(parent, payload)
    final = effective(parsed(merged))
    for key in sorted(replay):
        if final.get(key) != theirs[key]:
            # A deliberate reactivation may repeat an identical historic event.
            # History deduplication must not erase this new effective revision.
            merged += (json.dumps(theirs[key], ensure_ascii=False) + '\n').encode()
    return merged


def reconciliation(root, child, row):
    baseline = root / '.erixpo' / 'worktree-baselines' / row['id']
    changes = {}
    names = set(DURABLE)
    # Recipes and their status/supporting files are one durable namespace.
    # Compare each file with its isolation baseline; never infer activation.
    for directory in (baseline, child / '.erixpo', root / '.erixpo'):
        names.update('skills/' + name for name in metadata_files(directory / 'skills'))
    for name in sorted(names):
        def read(directory):
            p = directory / name
            if p.is_symlink():
                raise RuntimeError(f'refusing metadata symlink: {p}')
            return p.read_bytes() if p.exists() else None
        before, theirs, ours = read(baseline), read(child / '.erixpo'), read(root / '.erixpo')
        if theirs == before or theirs == ours:
            continue
        if name == 'learnings.jsonl':
            changes[name] = learnings_merge(before, ours, theirs)
        elif name in DURABLE and name.endswith('.jsonl'):
            changes[name] = events_merge(ours, theirs)
        elif ours == before:
            changes[name] = theirs
        else:
            raise RuntimeError(f'metadata conflict: {name}; reconcile parent and worktree before closing')
    for name, theirs in metadata_files(child / '.erixpo' / 'run-events').items():
        dest = root / '.erixpo' / 'run-events' / name
        if dest.exists() and dest.read_bytes() != theirs:
            raise RuntimeError(f'conflicting run event: {name}')
        changes['run-events/' + name] = theirs
    return changes


def preserve(root, child, row, changes):
    # Preserve all child metadata (including progress formats unknown to this
    # version) before deletion. Retry is safe after any interrupted write.
    archive = root / '.erixpo' / 'worktree-archives' / row['id']
    for name, data in metadata_files(child / '.erixpo').items():
        atomic(archive / name, data, (child / '.erixpo' / name).stat().st_mode & 0o777)
    for name, expected in installed_files(child).items():
        if name.startswith('.erixpo/') or not matches(child, name, expected):
            continue
        path = child / name
        if path.is_file() and not path.is_symlink():
            atomic(archive / 'host-files' / name, path.read_bytes(), path.stat().st_mode & 0o777)
    for name, data in changes.items():
        dest = root / '.erixpo' / name
        if data is None:
            dest.unlink(missing_ok=True)
        else:
            source = child / '.erixpo' / name
            atomic(dest, data, source.stat().st_mode & 0o777 if source.is_file() else None)


def remove(root, child):
    # Git's normal protections remain in force; remove only metadata already
    # archived, and only paths Git considers untracked (including ignored).
    removed = {}
    owned = installed_files(child)
    try:
        for args in [('--others', '--exclude-standard'), ('--others', '--ignored', '--exclude-standard')]:
            p = subprocess.run(['git', '-C', str(child), 'ls-files', *args, '-z'], check=True, capture_output=True)
            for name in p.stdout.split(b'\0'):
                if name:
                    path = child / os.fsdecode(name)
                    rel = os.fsdecode(name)
                    if not rel.startswith('.erixpo/') and not matches(child, rel, owned.get(rel)):
                        continue
                    if path.is_symlink():
                        raise RuntimeError(f'refusing untracked worktree symlink: {path}')
                    removed[path] = (path.read_bytes(), path.stat().st_mode & 0o777)
                    path.unlink()
        git(root, 'worktree', 'remove', str(child))
    except Exception:
        # A lock or newly introduced user change can make Git refuse removal.
        # Restore runtime context so the still-live worktree is usable.
        if child.exists():
            for path, (data, mode) in removed.items():
                if not path.exists():
                    atomic(path, data, mode)
        raise



def main():
    parser = argparse.ArgumentParser(description='Explicit worktree lifecycle; never auto-merge to main.')
    parser.add_argument('command', nargs='?', default='list', choices=['isolate', 'list', 'worktrees', 'status', 'merge', 'close', 'prune', 'sweep'])
    parser.add_argument('--id')
    parser.add_argument('--slug', default='run')
    for flag in ('with-env', 'porcelain', 'keep', 'keep-branch', 'no-merge', 'delete-branch', 'apply'):
        parser.add_argument('--' + flag, action='store_true')
    args = parser.parse_args()
    root = Path(git(Path.cwd(), 'rev-parse', '--show-toplevel')).resolve()
    state = root / '.erixpo'
    if state.is_symlink():
        raise RuntimeError('refusing symlink .erixpo directory')
    state.mkdir(exist_ok=True)
    registry = state / 'worktrees.jsonl'
    with contextlib.ExitStack() as locks:
        lock = locks.enter_context((state / 'worktrees.lock').open('a'))
        fcntl.flock(lock, fcntl.LOCK_EX)
        rows = rows_read(registry)
        base = root.parent / '.erixpo-worktrees'
        current = git(root, 'branch', '--show-current')
        if args.command == 'isolate':
            if (root / '.git').is_file() or not current:
                raise RuntimeError('isolate from the human checkout on a named branch')
            stamp = datetime.datetime.now().strftime('%Y%m%d-%H%M%S')
            slug = re.sub('[^a-zA-Z0-9._-]+', '-', args.slug).strip('-')[:32] or 'run'
            tag = f'{stamp}-{slug}-{uuid.uuid4().hex[:6]}'
            branch, ident = 'erixpo/' + tag, 's-' + tag
            child = base / (root.name + '-' + tag)
            row = dict(id=ident, path=str(child), branch=branch, origin_branch=current,
                       base_commit=git(root, 'rev-parse', 'HEAD'), status='creating',
                       ts=datetime.datetime.now(datetime.timezone.utc).isoformat())
            # Write intent first, so interrupted creation remains discoverable.
            rows.append(row)
            rows_write(registry, rows)
            git(root, 'worktree', 'add', '-b', branch, str(child), 'HEAD')
            excluded = {'worktrees.jsonl', 'worktrees.lock', 'worktree-baselines', 'worktree-archives', 'state.yaml', 'loop-prompt.md', '.env'}
            (child / '.erixpo').mkdir(exist_ok=True)
            for name, data in metadata_files(state).items():
                if name.split('/')[0] in excluded or name.endswith('.log'):
                    continue
                atomic(child / '.erixpo' / name, data, (state / name).stat().st_mode & 0o777)
            hosts = {'.agents', '.claude', '.cursor', '.codex', '.gemini', '.opencode', '.github', '.windsurf'}
            for name, expected in installed_files(root).items():
                if Path(name).parts[0] not in hosts or not matches(root, name, expected):
                    continue
                source, dest = root / name, child / name
                if source.is_symlink() or dest.exists():
                    continue
                atomic(dest, source.read_bytes())
                dest.chmod(source.stat().st_mode & 0o777)
            durable_names = list(DURABLE) + ['skills/' + name for name in metadata_files(child / '.erixpo/skills')]
            for name in durable_names:
                p = child / '.erixpo' / name
                if p.exists():
                    atomic(state / 'worktree-baselines' / ident / name, p.read_bytes())
            atomic(child / '.erixpo/isolation.json', json.dumps({k: row[k] for k in ('id', 'base_commit', 'origin_branch', 'branch')}).encode())
            if args.with_env and (root / '.env.example').is_file():
                atomic(child / '.env.example', (root / '.env.example').read_bytes())
            row['status'] = 'live'
            rows_write(registry, rows)
            print(f'path={child}\nid={ident}\nbranch={branch}' if args.porcelain else f'isolated {ident}\npath: {child}\nbranch: {branch}')
            return
        if args.command in ('list', 'worktrees', 'status'):
            print(git(root, 'worktree', 'list'))
            print('\n'.join(json.dumps(r) for r in rows) or '(none)')
            return
        if args.command == 'sweep':
            known = {r['path'] for r in rows}
            for row in rows:
                exists = Path(row['path']).exists()
                if not exists and row['status'] in ('live', 'creating', 'closing'):
                    print('stale: ' + row['id'])
                    if args.apply:
                        row['status'] = 'stale'
                elif exists:
                    print(f"{row['status']}: {row['id']} (inspect; close explicitly)")
                    if row['status'] == 'creating' and args.apply:
                        # Creation may have stopped before context copy; retain
                        # a recoverable status rather than claiming it is ready.
                        row['status'] = 'recovery-needed'
            if base.exists():
                for p in base.glob(root.name + '-*'):
                    if str(p) not in known:
                        print('orphan: ' + str(p))
            if args.apply:
                rows_write(registry, rows)
                git(root, 'worktree', 'prune')
                for branch in git(root, 'for-each-ref', '--format=%(refname:short)', 'refs/heads/erixpo').splitlines():
                    if branch != current and contained(root, branch):
                        git(root, 'branch', '-d', branch, check=False)
            return
        if not args.id:
            raise RuntimeError('--id required')
        row = next((r for r in rows if args.id in (r.get('id'), r.get('branch'), r.get('path'))), None)
        if row is None:
            raise RuntimeError('unknown id ' + args.id)
        child, branch = Path(row['path']), row['branch']
        if child.resolve() == root or current == branch:
            raise RuntimeError('run merge/close/prune from the human checkout')
        if row.get('origin_branch') != current:
            raise RuntimeError('switch to the recorded originating branch before merge/close/prune')
        exists = branch_exists(root, branch)
        if child.exists():
            (child / '.erixpo').mkdir(exist_ok=True)
            run_lock = locks.enter_context((child / '.erixpo/run.lock').open('a'))
            try:
                fcntl.flock(run_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise RuntimeError('worktree worker is still running; wait before merge/close/prune')
            registered = git(root, 'worktree', 'list', '--porcelain')
            if 'worktree ' + str(child) + '\n' not in registered + '\n':
                raise RuntimeError('path is not a registered worktree; inspect it')
            if git(child, 'branch', '--show-current') != branch:
                raise RuntimeError('worktree branch changed; inspect it')
            dirty(child)
            if row['status'] == 'closing':
                # Resume an interrupted metadata removal from the durable copy.
                for name, data in metadata_files(state / 'worktree-archives' / row['id']).items():
                    target = child / name[len('host-files/'):] if name.startswith('host-files/') else child / '.erixpo' / name
                    if not target.exists():
                        atomic(target, data, (state / 'worktree-archives' / row['id'] / name).stat().st_mode & 0o777)
            changes = reconciliation(root, child, row)
            metadata_files(child / '.erixpo')  # reject symlinks before any merge
        else:
            changes = {}
        landed = exists and contained(root, branch)
        if args.command == 'prune':
            if args.delete_branch and exists and not landed:
                raise RuntimeError('refusing to delete an unmerged branch')
        elif exists:
            dirty(root)
            changed = git(root, 'rev-parse', branch) != row.get('base_commit')
            if changed:
                if not child.exists():
                    if not (row['status'] == 'closing' and row.get('close_reviewed') and
                            row.get('close_head') == git(root, 'rev-parse', branch) and landed):
                        raise RuntimeError('worktree missing; cannot verify reviewed artifact')
                else:
                    helper = Path(__file__).with_name('review-evidence.py')
                    subprocess.run([sys.executable, str(helper), 'verify', '--root', str(child), '--base', row['base_commit']], check=True)
            if not landed:
                if args.no_merge:
                    raise RuntimeError('--no-merge requires the branch already contained in HEAD')
                git(root, 'merge', '--no-ff', '--no-edit', branch)
            if args.command == 'merge' or args.keep:
                if child.exists():
                    preserve(root, child, row, changes)
                row['status'] = 'merged'
                rows_write(registry, rows)
                print('merged ' + row['id'] + ' (kept worktree and branch)')
                return
        elif row['status'] not in ('closed', 'pruned', 'merged', 'closing'):
            raise RuntimeError('branch missing; inspect before pruning')
        if child.exists():
            preserve(root, child, row, changes)
            row['status'] = 'closing'
            row['close_head'] = git(root, 'rev-parse', branch) if exists else None
            row['close_reviewed'] = args.command == 'close'
            rows_write(registry, rows)
            dirty(child)
            remove(root, child)
        if exists and ((args.command == 'close' and not args.keep_branch) or args.delete_branch):
            git(root, 'branch', '-d', branch)
        row['status'] = 'pruned' if args.command == 'prune' else 'closed'
        rows_write(registry, rows)
        git(root, 'worktree', 'prune')
        if base.exists() and not any(base.iterdir()):
            base.rmdir()
        print(row['status'] + ' ' + row['id'])


if __name__ == '__main__':
    try:
        main()
    except (RuntimeError, OSError, ValueError, subprocess.CalledProcessError) as e:
        print('worktree: ' + str(e), file=sys.stderr)
        sys.exit(1)
