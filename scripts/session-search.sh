#!/usr/bin/env bash
# Read-only search of effective memory, sessions and registered worktrees.
set -euo pipefail
ROOT="$(pwd)"
KIND="all"
QUERY=()
usage() {
  echo 'Usage: scripts/session-search.sh [--root DIR] [--kind all|sessions|learnings|worktrees] [query…]'
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --root|--kind)
      [[ $# -ge 2 && -n "$2" ]] || { echo "missing value for $1" >&2; exit 2; }
      if [[ "$1" == --root ]]; then ROOT="$2"; else KIND="$2"; fi
      shift 2 ;;
    --) shift; QUERY+=("$@"); break ;;
    -h|--help) usage; exit 0 ;;
    --*) echo "unknown option: $1" >&2; exit 2 ;;
    *) QUERY+=("$1"); shift ;;
  esac
done
python3 - "$ROOT" "$KIND" "${QUERY[*]-}" <<'PY'
import json
from pathlib import Path
import re
import sys

root, kind, query = Path(sys.argv[1]), sys.argv[2], sys.argv[3].strip().casefold()
if kind not in ('all', 'sessions', 'learnings', 'worktrees'):
    print('unknown kind ' + kind, file=sys.stderr)
    sys.exit(1)
tokens = set(re.findall(r'[\w./-]+', query))
state = root / '.erixpo'


def text(value):
    if not isinstance(value, str):
        return ''
    value = value.encode('utf-8', errors='replace').decode('utf-8')
    return ' '.join(re.sub(r'[\x00-\x1f\x7f-\x9f]', ' ', value).split())


def readable(path):
    # Recalled content is project data; do not traverse links into other folders.
    return not state.is_symlink() and not path.is_symlink() and not path.parent.is_symlink() and path.is_file()


def rows(path, single=False):
    if not readable(path):
        return []
    try:
        data = path.read_bytes()
    except OSError:
        return []
    result = []
    for raw in [data] if single else data.splitlines():
        try:
            row = json.loads(raw)
        except (ValueError, UnicodeError):
            continue
        if isinstance(row, dict):
            result.append(row)
    return result


def effective(events, identity, required=False):
    # Append order is authoritative, not timestamps that may be skewed. Resolve
    # state BEFORE query matching, so a tombstone hides the previous insight even
    # when the tombstone itself contains none of the query words.
    latest = {}
    for index, row in enumerate(events):
        key = text(row.get(identity)).strip()
        if required and not key:
            continue
        latest[('key', key) if key else ('line', index)] = row
    return list(latest.values())


def score(row):
    fields = ('key', 'insight', 'goal', 'notes', 'track', 'type', 'source', 'branch', 'path', 'id', 'outcome')
    blob = ' '.join(text(row.get(field)) for field in fields).casefold()
    paths = row.get('files', [])
    if not isinstance(paths, list):
        paths = []
    file_blob = ' '.join(text(path) for path in paths).casefold()
    if not tokens:
        return 1
    return (8 if query and query in blob else 0) + sum(2 for token in tokens if token in blob) + (4 if query and query in file_blob else 0) + sum(3 for token in tokens if token in file_blob)


sources = {}
if kind in ('all', 'learnings'):
    sources['learnings'] = [row for row in effective(rows(state / 'learnings.jsonl'), 'key', required=True)
                            if row.get('status', 'active') == 'active' and text(row.get('insight')).strip()]
if kind in ('all', 'sessions'):
    sessions = effective(rows(state / 'sessions.jsonl'), 'id')
    seen = {text(row.get('id')) for row in sessions if text(row.get('id'))}
    directory = state / 'run-events'
    if not directory.is_symlink() and not state.is_symlink():
        for path in sorted(directory.glob('*.json')):
            for row in rows(path, single=True):
                ident = text(row.get('id'))
                if ident and ident not in seen:
                    seen.add(ident)
                    sessions.append(row)
    sources['sessions'] = sessions
if kind in ('all', 'worktrees'):
    sources['worktrees'] = effective(rows(state / 'worktrees.jsonl'), 'id', required=True)

hits = []
for name, events in sources.items():
    for row in events:
        rank = score(row)
        if rank:
            hits.append((rank, text(row.get('ts')), name, row))
hits.sort(key=lambda hit: (hit[0], hit[1]), reverse=True)
if not hits:
    print('no hits')
for rank, stamp, name, row in hits[:8]:
    if name == 'sessions':
        print(f"Prior session: {text(row.get('id')) or '?'} — {text(row.get('goal'))[:600]} ({text(row.get('check')) or '?'}, {stamp})")
    elif name == 'learnings':
        confidence = row.get('confidence', '?')
        if not isinstance(confidence, (int, float, str)):
            confidence = '?'
        print(f"Prior learning: {text(row.get('key'))} — {text(row.get('insight'))[:600]} (confidence {text(str(confidence))}, {text(row.get('type'))})")
    else:
        print(f"Worktree: {text(row.get('id'))} — {text(row.get('branch'))} @ {text(row.get('path'))} [{text(row.get('status'))}]")
PY
