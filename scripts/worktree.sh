#!/usr/bin/env bash
# Isolate an erixpo run in a git worktree. Never auto-merge to main.
set -euo pipefail

ROOT="$(pwd)"
CMD="${1:-list}"
shift || true
SLUG="run"
WITH_ENV=0
DELETE_BRANCH=0
ID=""

usage() {
  cat <<'EOF'
Usage: scripts/worktree.sh <command> [options]

Commands:
  isolate [--slug NAME] [--with-env]   create sibling worktree + branch
  list                                 print live worktrees
  merge --id ID                        merge that branch into HEAD (no push)
  prune --id ID [--delete-branch]      remove worktree
  status                               list + current isolation pointer

Worktrees live at ../.erixpo-worktrees/<repo>-<stamp>-<slug>
Branches are erixpo/<YYYYMMDD>-<HHMM>-<slug>
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug) SLUG="$2"; shift 2 ;;
    --with-env) WITH_ENV=1; shift ;;
    --delete-branch) DELETE_BRANCH=1; shift ;;
    --id) ID="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown: $1" >&2; usage; exit 1 ;;
  esac
done

is_git() {
  git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

repo_name() {
  basename "$(git -C "$ROOT" rev-parse --show-toplevel)"
}

state_dir() {
  mkdir -p "$ROOT/.erixpo"
  printf '%s' "$ROOT/.erixpo"
}

jsonl() {
  printf '%s' "$(state_dir)/worktrees.jsonl"
}

stamp() {
  date +%Y%m%d-%H%M
}

parent_dir() {
  dirname "$(git -C "$ROOT" rev-parse --show-toplevel)"
}

find_line() {
  local want="$1"
  [[ -f "$(jsonl)" ]] || return 1
  python3 - "$want" "$(jsonl)" <<'PY'
import json, sys
want, path = sys.argv[1], sys.argv[2]
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        continue
    if row.get("id") == want or row.get("branch") == want or row.get("path") == want:
        print(line)
        sys.exit(0)
sys.exit(1)
PY
}

cmd_list() {
  echo "git worktrees:"
  if is_git; then
    git -C "$ROOT" worktree list
  else
    echo "(not a git repo)"
  fi
  echo
  echo "erixpo worktrees.jsonl:"
  if [[ -f "$(jsonl)" ]]; then
    cat "$(jsonl)"
  else
    echo "(none)"
  fi
}

cmd_isolate() {
  if ! is_git; then
    echo "not a git repository; isolation is impossible" >&2
    exit 1
  fi
  if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null && [[ -f "$ROOT/.git" ]]; then
    # .git is a file → this checkout is already a worktree
    echo "already inside a worktree. isolate from the human checkout instead." >&2
    exit 1
  fi
  local ts name branch base path id
  ts="$(stamp)"
  name="$(repo_name)"
  SLUG="$(printf '%s' "$SLUG" | tr -cs 'a-zA-Z0-9._-' '-' | sed 's/^-//;s/-$//')"
  [[ -n "$SLUG" ]] || SLUG="run"
  branch="erixpo/${ts}-${SLUG}"
  id="s-${ts}-${SLUG}"
  base="$(parent_dir)/.erixpo-worktrees"
  path="${base}/${name}-${ts}-${SLUG}"
  mkdir -p "$base"
  if git -C "$ROOT" show-ref --verify --quiet "refs/heads/${branch}"; then
    echo "branch already exists: $branch" >&2
    exit 1
  fi
  git -C "$ROOT" worktree add -b "$branch" "$path" HEAD
  # .erixpo is often gitignored (machine state). Copy it so the worker has a plan.
  if [[ -d "$ROOT/.erixpo" ]]; then
    mkdir -p "$path/.erixpo"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude '*.log' --exclude '.env' --exclude 'loop-prompt.md' \
        "$ROOT/.erixpo/" "$path/.erixpo/"
    else
      cp -R "$ROOT/.erixpo/." "$path/.erixpo/"
      rm -f "$path/.erixpo/"*.log "$path/.erixpo/loop-prompt.md" 2>/dev/null || true
    fi
  fi
  if [[ "$WITH_ENV" -eq 1 && -f "$ROOT/.env.example" ]]; then
    cp "$ROOT/.env.example" "$path/.env.example"
  fi
  if [[ "$WITH_ENV" -eq 1 && -f "$ROOT/.env" ]]; then
    echo "refusing to copy .env (secrets). use --with-env only for .env.example" >&2
  fi
  python3 - "$id" "$path" "$branch" "$(jsonl)" <<'PY'
import json, sys, datetime
id, path, branch, dest = sys.argv[1:]
row = {
    "ts": datetime.datetime.utcnow().strftime("%Y-%m-%dT%H:%M:%SZ"),
    "id": id,
    "path": path,
    "branch": branch,
    "status": "live",
}
with open(dest, "a", encoding="utf-8") as f:
    f.write(json.dumps(row, ensure_ascii=False) + "\n")
PY
  if [[ -f "$ROOT/.erixpo/state.yaml" ]]; then
    {
      echo "isolation: worktree"
      echo "worktree_id: $id"
      echo "worktree_path: $path"
      echo "worktree_branch: $branch"
    } >> "$ROOT/.erixpo/state.yaml"
  fi
  echo "isolated"
  echo "id: $id"
  echo "path: $path"
  echo "branch: $branch"
  echo "next: run the worker with ROOT=$path"
  echo "then: bin/erixpo merge --id $id   (after two-stage review)"
}

cmd_merge() {
  [[ -n "$ID" ]] || { echo "--id required" >&2; exit 1; }
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local line branch
  line="$(find_line "$ID")" || { echo "unknown id $ID" >&2; exit 1; }
  branch="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["branch"])' "$line")"
  echo "merging $branch into $(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
  git -C "$ROOT" merge --no-ff --no-edit "$branch"
}

cmd_prune() {
  [[ -n "$ID" ]] || { echo "--id required" >&2; exit 1; }
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local line path branch
  line="$(find_line "$ID")" || { echo "unknown id $ID" >&2; exit 1; }
  path="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["path"])' "$line")"
  branch="$(python3 -c 'import json,sys; print(json.loads(sys.argv[1])["branch"])' "$line")"
  if [[ -d "$path" ]]; then
    git -C "$ROOT" worktree remove --force "$path"
  fi
  if [[ "$DELETE_BRANCH" -eq 1 ]]; then
    git -C "$ROOT" branch -d "$branch" || git -C "$ROOT" branch -D "$branch"
  fi
  python3 - "$ID" "$(jsonl)" <<'PY'
import json, sys
want, path = sys.argv[1], sys.argv[2]
rows = []
if not __import__("os").path.isfile(path):
    sys.exit(0)
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        rows.append(line)
        continue
    if row.get("id") == want:
        row["status"] = "pruned"
    rows.append(json.dumps(row, ensure_ascii=False))
open(path, "w", encoding="utf-8").write("\n".join(rows) + ("\n" if rows else ""))
PY
  echo "pruned $ID"
}

case "$CMD" in
  isolate) cmd_isolate ;;
  list|worktrees) cmd_list ;;
  merge) cmd_merge ;;
  prune) cmd_prune ;;
  status) cmd_list ;;
  -h|--help) usage ;;
  *) echo "unknown command: $CMD" >&2; usage; exit 1 ;;
esac
