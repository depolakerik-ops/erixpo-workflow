#!/usr/bin/env bash
# Isolate an erixpo run in a git worktree. Never auto-merge to main.
set -euo pipefail

ROOT="$(pwd)"
CMD="${1:-list}"
shift || true
SLUG="run"
WITH_ENV=0
DELETE_BRANCH=0
KEEP=0
KEEP_BRANCH=0
NO_MERGE=0
APPLY=0
ID=""
PORCELAIN=0

usage() {
  cat <<'EOF'
Usage: scripts/worktree.sh <command> [options]

Commands:
  isolate [--slug NAME] [--with-env] [--porcelain]
                                       create sibling worktree + branch
                                       (--porcelain prints path=/id=/branch= lines)
  list                                 print live worktrees
  merge --id ID [--keep]               merge that branch into HEAD (no push)
  prune --id ID [--delete-branch]      remove worktree
  close --id ID [--keep|--keep-branch|--no-merge]
                                       merge if needed, then drop tree + branch
  sweep [--apply]                      report leftovers; --apply cleans safe ones
  status                               list + current isolation pointer

Worktrees live at ../.erixpo-worktrees/<repo>-<stamp>-<slug>
Branches are erixpo/<YYYYMMDD>-<HHMM>-<slug>
Statuses: live | merged | closed | pruned | stale
Never auto-merge to main. Never close unless the user said merge/land/close.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --slug) SLUG="$2"; shift 2 ;;
    --with-env) WITH_ENV=1; shift ;;
    --delete-branch) DELETE_BRANCH=1; shift ;;
    --id) ID="$2"; shift 2 ;;
    --keep) KEEP=1; shift ;;
    --keep-branch) KEEP_BRANCH=1; shift ;;
    --no-merge) NO_MERGE=1; shift ;;
    --apply) APPLY=1; shift ;;
    --porcelain) PORCELAIN=1; shift ;;
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

current_branch() {
  git -C "$ROOT" rev-parse --abbrev-ref HEAD
}

tree_dirty() {
  # Untracked .erixpo/ (jsonl, logs) is machine state, not a dirty target checkout.
  [[ -n "$(git -C "$ROOT" status --porcelain --untracked-files=no)" ]]
}

is_ancestor() {
  git -C "$ROOT" merge-base --is-ancestor "$1" HEAD
}

branch_exists() {
  git -C "$ROOT" show-ref --verify --quiet "refs/heads/${1}"
}

worktrees_base() {
  printf '%s' "$(parent_dir)/.erixpo-worktrees"
}

find_line() {
  local want="$1"
  [[ -f "$(jsonl)" ]] || return 1
  python3 - "$want" "$(jsonl)" <<'PY'
import json, sys
want, path = sys.argv[1], sys.argv[2]
found = None
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        continue
    if row.get("id") == want or row.get("branch") == want or row.get("path") == want:
        found = line
if found:
    print(found)
    sys.exit(0)
sys.exit(1)
PY
}

row_get() {
  python3 -c 'import json,sys; print(json.loads(sys.argv[1]).get(sys.argv[2],""))' "$1" "$2"
}

set_jsonl_status() {
  local want="$1"
  local status="$2"
  local note="${3:-}"
  python3 - "$want" "$status" "$note" "$(jsonl)" <<'PY'
import json, os, sys
want, status, note, path = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
if not os.path.isfile(path):
    sys.exit(0)
rows = []
for line in open(path, encoding="utf-8"):
    line = line.strip()
    if not line:
        continue
    try:
        row = json.loads(line)
    except json.JSONDecodeError:
        rows.append(line)
        continue
    if row.get("id") == want or row.get("branch") == want or row.get("path") == want:
        row["status"] = status
        if note:
            row["note"] = note
        elif "note" in row:
            del row["note"]
    rows.append(json.dumps(row, ensure_ascii=False))
open(path, "w", encoding="utf-8").write("\n".join(rows) + ("\n" if rows else ""))
PY
}

require_human_checkout() {
  local path="$1" branch="$2"
  local top cur
  top="$(git -C "$ROOT" rev-parse --show-toplevel)"
  cur="$(current_branch)"
  if [[ -n "$path" && "$top" == "$path" ]]; then
    echo "you are inside the isolated worktree ($path). run merge/close from the human checkout." >&2
    exit 1
  fi
  if [[ -n "$branch" && "$cur" == "$branch" ]]; then
    echo "HEAD is $branch; run merge/close from the target branch, not the isolated branch." >&2
    exit 1
  fi
}

do_merge_branch() {
  local branch="$1"
  echo "merging $branch into $(current_branch)"
  if ! git -C "$ROOT" merge --no-ff --no-edit "$branch"; then
    echo "merge conflict; resolve in this checkout. refusing -X ours. worktree left intact." >&2
    exit 1
  fi
}

remove_worktree_path() {
  local path="$1"
  if [[ ! -e "$path" ]]; then
    git -C "$ROOT" worktree remove --force "$path" >/dev/null 2>&1 || true
    return 0
  fi
  if git -C "$ROOT" worktree remove --force "$path"; then
    return 0
  fi
  echo "refusing to rm -rf $path; not a registered git worktree. inspect it." >&2
  exit 1
}

maybe_rmdir_empty_parent() {
  local base
  base="$(worktrees_base)"
  [[ -d "$base" ]] || return 0
  if [[ -z "$(ls -A "$base" 2>/dev/null || true)" ]]; then
    rmdir "$base"
    echo "removed empty $base"
  fi
}

branch_has_worktree() {
  local b="$1" wt="" br=""
  while IFS= read -r line; do
    case "$line" in
      worktree\ *) wt="${line#worktree }" ;;
      branch\ *)
        br="${line#branch }"
        br="${br#refs/heads/}"
        if [[ "$br" == "$b" && -n "$wt" && -e "$wt" ]]; then
          return 0
        fi
        ;;
      "") wt="" ;;
    esac
  done < <(git -C "$ROOT" worktree list --porcelain)
  return 1
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
  local ts name branch base path id tag
  ts="$(stamp)"
  name="$(repo_name)"
  SLUG="$(printf '%s' "$SLUG" | tr -cs 'a-zA-Z0-9._-' '-' | sed 's/^-//;s/-$//' | cut -c1-32 | sed 's/-$//')"
  [[ -n "$SLUG" ]] || SLUG="run"
  tag="${ts}-${SLUG}"
  for n in 2 3 4 5 6 7 8 9; do branch_exists "erixpo/${tag}" || break; tag="${ts}-${SLUG}-$n"; done
  branch="erixpo/${tag}"
  id="s-${tag}"
  base="$(worktrees_base)"
  path="${base}/${name}-${tag}"
  mkdir -p "$base"
  if branch_exists "$branch"; then
    echo "branch still exists after retries: $branch" >&2
    exit 1
  fi
  git -C "$ROOT" worktree add -b "$branch" "$path" HEAD
  # .erixpo is often gitignored (machine state). Copy it so the worker has a plan,
  # but never the registry (worktrees.jsonl/state.yaml) or logs — the child gets
  # a fresh registry instead of the parent's live rows.
  if [[ -d "$ROOT/.erixpo" ]]; then
    mkdir -p "$path/.erixpo"
    if command -v rsync >/dev/null 2>&1; then
      rsync -a --exclude '*.log' --exclude '.env' --exclude 'loop-prompt.md' \
        --exclude 'worktrees.jsonl' --exclude 'state.yaml' \
        "$ROOT/.erixpo/" "$path/.erixpo/"
    else
      cp -R "$ROOT/.erixpo/." "$path/.erixpo/"
      rm -f "$path/.erixpo/"*.log "$path/.erixpo/loop-prompt.md" "$path/.erixpo/.env" \
        "$path/.erixpo/worktrees.jsonl" "$path/.erixpo/state.yaml" 2>/dev/null || true
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
    "ts": datetime.datetime.now(datetime.timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
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
  if [[ "$PORCELAIN" -eq 1 ]]; then
    printf 'path=%s\nid=%s\nbranch=%s\n' "$path" "$id" "$branch"
    return 0
  fi
  echo "isolated"
  echo "id: $id"
  echo "path: $path"
  echo "branch: $branch"
  echo "next: run the worker with ROOT=$path"
  echo "then: bin/erixpo merge --id $id   (after two-stage review; no push)"
  echo "then: bin/erixpo close --id $id   (from the human checkout; never auto-merge to main)"
}

cmd_merge() {
  [[ -n "$ID" ]] || { echo "--id required" >&2; exit 1; }
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local line branch path
  line="$(find_line "$ID")" || { echo "unknown id $ID" >&2; exit 1; }
  branch="$(row_get "$line" branch)"
  path="$(row_get "$line" path)"
  require_human_checkout "$path" "$branch"
  if ! branch_exists "$branch"; then
    echo "branch gone: $branch" >&2
    exit 1
  fi
  do_merge_branch "$branch"
  set_jsonl_status "$ID" "merged"
  echo "merged $ID"
  echo "branch: $branch"
  echo "status: merged"
  if [[ "$KEEP" -eq 1 ]]; then
    echo "kept worktree and branch"
  else
    echo "next: bin/erixpo close --id $ID"
  fi
}

cmd_prune() {
  [[ -n "$ID" ]] || { echo "--id required" >&2; exit 1; }
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local line path branch
  line="$(find_line "$ID")" || { echo "unknown id $ID" >&2; exit 1; }
  path="$(row_get "$line" path)"
  branch="$(row_get "$line" branch)"
  if [[ -d "$path" ]]; then
    git -C "$ROOT" worktree remove --force "$path"
  fi
  if [[ "$DELETE_BRANCH" -eq 1 ]]; then
    git -C "$ROOT" branch -d "$branch" || git -C "$ROOT" branch -D "$branch"
  fi
  set_jsonl_status "$ID" "pruned"
  echo "pruned $ID"
}

cmd_close() {
  [[ -n "$ID" ]] || { echo "--id required" >&2; exit 1; }
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local line path branch status contained=0
  line="$(find_line "$ID")" || { echo "unknown id $ID" >&2; exit 1; }
  path="$(row_get "$line" path)"
  branch="$(row_get "$line" branch)"
  status="$(row_get "$line" status)"
  require_human_checkout "$path" "$branch"

  if branch_exists "$branch"; then
    if is_ancestor "$branch"; then
      contained=1
    fi
  else
    if [[ "$status" == "merged" || "$status" == "closed" || "$status" == "pruned" ]]; then
      contained=1
    else
      echo "branch gone: $branch; cannot verify it landed. inspect, then prune --id $ID." >&2
      exit 1
    fi
  fi

  if [[ "$contained" -eq 0 ]]; then
    if [[ "$NO_MERGE" -eq 1 ]]; then
      echo "--no-merge only allowed if $branch is already merged or fully contained in HEAD" >&2
      exit 1
    fi
    if tree_dirty; then
      echo "working tree is dirty; refuse to merge into a checkout that may not be the intended target. commit/stash, or switch to the target branch." >&2
      exit 1
    fi
    do_merge_branch "$branch"
  else
    echo "$branch already contained in HEAD"
  fi

  if branch_exists "$branch"; then
    if ! is_ancestor "$branch"; then
      echo "$branch is not an ancestor of HEAD; refuse close (no -X ours, no merge to main)." >&2
      exit 1
    fi
  fi

  if [[ "$KEEP" -eq 1 ]]; then
    set_jsonl_status "$ID" "merged"
    echo "merged $ID (kept worktree and branch)"
    echo "path: $path"
    echo "branch: $branch"
    echo "next: bin/erixpo close --id $ID   (when you want the tree gone)"
    return 0
  fi

  local removed_wt=0 deleted_branch=0
  if [[ -e "$path" ]]; then
    remove_worktree_path "$path"
    removed_wt=1
  else
    git -C "$ROOT" worktree remove --force "$path" >/dev/null 2>&1 || true
  fi

  if [[ "$KEEP_BRANCH" -eq 0 && -n "$branch" ]] && branch_exists "$branch"; then
    git -C "$ROOT" branch -d "$branch" 2>/dev/null || git -C "$ROOT" branch -D "$branch"
    deleted_branch=1
  fi

  if [[ "$KEEP_BRANCH" -eq 1 ]]; then
    set_jsonl_status "$ID" "closed" "keep-branch"
  else
    set_jsonl_status "$ID" "closed"
  fi

  git -C "$ROOT" worktree prune
  maybe_rmdir_empty_parent

  echo "closed $ID"
  if [[ "$removed_wt" -eq 1 ]]; then
    echo "removed worktree: $path"
  else
    echo "worktree already gone: $path"
  fi
  if [[ "$KEEP_BRANCH" -eq 1 ]]; then
    echo "kept branch: $branch"
  elif [[ "$deleted_branch" -eq 1 ]]; then
    echo "deleted branch: $branch"
  else
    echo "branch already gone: $branch"
  fi
}

cmd_sweep() {
  if ! is_git; then
    echo "not a git repository" >&2
    exit 1
  fi
  local jl name base mode
  jl="$(jsonl)"
  name="$(repo_name)"
  base="$(worktrees_base)"
  if [[ "$APPLY" -eq 1 ]]; then
    mode="apply"
  else
    mode="dry"
  fi
  echo "sweep ($mode)"

  if [[ "$APPLY" -eq 1 ]]; then
    git -C "$ROOT" worktree prune
  fi

  python3 - "$jl" "$APPLY" "$base" "$name" <<'PY'
import json, os, sys
jl, apply, base, name = sys.argv[1], sys.argv[2] == "1", sys.argv[3], sys.argv[4]
known = set()
rows = []
changed = False
if os.path.isfile(jl):
    for line in open(jl, encoding="utf-8"):
        raw = line.strip()
        if not raw:
            continue
        try:
            row = json.loads(raw)
        except json.JSONDecodeError:
            rows.append(raw)
            continue
        ident = row.get("id", "?")
        path = row.get("path") or ""
        branch = row.get("branch") or ""
        status = row.get("status") or "live"
        exists = bool(path) and os.path.isdir(path)
        if path:
            known.add(os.path.abspath(path))
            if os.path.exists(path):
                known.add(os.path.realpath(path))
        if status == "live" and path and not exists:
            if apply:
                row["status"] = "stale"
                changed = True
                print(f"marked stale: {ident}  path missing: {path}")
            else:
                print(f"stale: {ident}  path missing: {path}")
        elif status == "merged" and exists:
            print(f"closeable: {ident}  merged, dir still present: {path}  (bin/erixpo close --id {ident})")
        elif status == "merged" and path and not exists:
            print(f"closeable: {ident}  merged, dir gone, branch may remain: {branch}  (bin/erixpo close --id {ident})")
        elif status in ("closed", "pruned", "stale") and exists:
            print(f"leftover: {ident}  status={status} but dir still present: {path}")
        rows.append(json.dumps(row, ensure_ascii=False))
    if changed:
        open(jl, "w", encoding="utf-8").write("\n".join(rows) + ("\n" if rows else ""))
if os.path.isdir(base):
    prefix = os.path.join(base, name + "-")
    try:
        names = os.listdir(base)
    except OSError:
        names = []
    for fn in names:
        d = os.path.join(base, fn)
        if not (os.path.isdir(d) or os.path.islink(d)):
            continue
        if not (d.startswith(prefix) or os.path.abspath(d).startswith(os.path.abspath(prefix))):
            continue
        real = os.path.realpath(d)
        absd = os.path.abspath(d)
        if real in known or absd in known:
            continue
        print(f"orphan: {d}  (under {base}/{name}-* not in worktrees.jsonl)")
PY

  local b cur
  cur="$(current_branch)"
  while IFS= read -r b; do
    [[ -n "$b" ]] || continue
    [[ "$b" == "$cur" ]] && continue
    if branch_has_worktree "$b"; then
      continue
    fi
    if git -C "$ROOT" merge-base --is-ancestor "$b" HEAD; then
      echo "dead branch: $b  (merged into HEAD, no worktree)"
      if [[ "$APPLY" -eq 1 ]]; then
        if git -C "$ROOT" branch -d "$b"; then
          echo "  deleted $b"
        else
          echo "  skip $b (git branch -d refused; not deleting unmerged)" >&2
        fi
      fi
    fi
  done < <(git -C "$ROOT" for-each-ref --format='%(refname:short)' refs/heads/erixpo)

  if [[ "$APPLY" -eq 1 ]]; then
    git -C "$ROOT" worktree prune
    maybe_rmdir_empty_parent
    echo "sweep apply done (did not merge, did not touch main, did not close live trees)"
  else
    echo "next: bin/erixpo sweep --apply   (mark stale, git worktree prune, delete dead merged erixpo/*)"
    echo "      bin/erixpo close --id <id>  (land if needed and remove a tree; never auto-merges to main)"
  fi
}

case "$CMD" in
  isolate) cmd_isolate ;;
  list|worktrees) cmd_list ;;
  merge) cmd_merge ;;
  prune) cmd_prune ;;
  close) cmd_close ;;
  sweep) cmd_sweep ;;
  status) cmd_list ;;
  -h|--help) usage ;;
  *) echo "unknown command: $CMD" >&2; usage; exit 1 ;;
esac
