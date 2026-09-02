#!/usr/bin/env bash
# Search .erixpo sessions / learnings / worktrees. No SQLite.
set -euo pipefail

ROOT="$(pwd)"
KIND="all"
QUERY=()

usage() {
  cat <<'EOF'
Usage: scripts/session-search.sh [--root DIR] [--kind all|sessions|learnings|worktrees] [query…]
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --root) ROOT="$2"; shift 2 ;;
    --kind) KIND="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) QUERY+=("$1"); shift ;;
  esac
done

python3 - "$ROOT" "$KIND" "${QUERY[*]-}" <<'PY'
import json, os, sys, re

root, kind, query = sys.argv[1], sys.argv[2], sys.argv[3].strip().lower()
tokens = [t for t in re.split(r"\s+", query) if t]
files = {
    "sessions": os.path.join(root, ".erixpo", "sessions.jsonl"),
    "learnings": os.path.join(root, ".erixpo", "learnings.jsonl"),
    "worktrees": os.path.join(root, ".erixpo", "worktrees.jsonl"),
}
if kind == "all":
    chosen = list(files.items())
elif kind in files:
    chosen = [(kind, files[kind])]
else:
    print(f"unknown kind {kind}", file=sys.stderr)
    sys.exit(1)

def score(row, blob):
    s = 0
    if query and query in blob:
        s += 8
    for t in tokens:
        if t in blob:
            s += 2
    for f in row.get("files") or []:
        blob_f = str(f).lower()
        if query and query in blob_f:
            s += 4
        for t in tokens:
            if t in blob_f:
                s += 1
    if row.get("status") in {"retracted", "stale", "pruned"}:
        s -= 5
    return s

hits = []
for name, path in chosen:
    if not os.path.isfile(path):
        continue
    for raw in open(path, encoding="utf-8"):
        raw = raw.strip()
        if not raw:
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError:
            continue
        if name == "learnings" and row.get("status") == "retracted":
            continue
        sc = score(row, raw.lower()) if tokens else 1
        if tokens and sc <= 0:
            continue
        hits.append((sc, row.get("ts") or "", name, row))

# score desc, then timestamp desc
hits.sort(key=lambda x: (x[0], x[1] or ""), reverse=True)

if not hits:
    print("no hits")
    sys.exit(0)

for sc, ts, name, row in hits[:8]:
    if name == "sessions":
        print(
            f"Prior session: {row.get('id', '?')} — {row.get('goal', '')} "
            f"({row.get('check', '?')}, {row.get('ts', '')})"
        )
    elif name == "learnings":
        print(
            f"Prior learning applied: {row.get('key', '?')} — {row.get('insight', '')} "
            f"(confidence {row.get('confidence', '?')}, {row.get('type', '')})"
        )
    else:
        print(
            f"Live worktree: {row.get('id', '?')} — {row.get('branch', '')} "
            f"@ {row.get('path', '')} [{row.get('status', '')}]"
        )
PY
