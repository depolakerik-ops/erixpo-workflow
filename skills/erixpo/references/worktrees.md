# Worktree isolation

Each unattended run, and any second agent, gets its own Git worktree and branch. The human's checkout stays theirs.

## When

| Situation | Isolate? |
|---|---|
| `.erixpo/bin/erixpo run` (leave-the-room loop) | Yes, default |
| Second agent / parallel slice | Yes, required |
| Interactive `/erixpo` on a clean tree, tiny fix | Optional |
| Interactive `/erixpo` on a **dirty** tree | Yes, or ask once |
| No git repository | Cannot. Warn. Stay in place only if they say so |
| User said "do it here" | Stay. Record `isolation: in-place` in state |

## Layout

Sibling of the repo, never inside it:

```
parent/
  my-app/                         ← human checkout
  .erixpo-worktrees/
    my-app-20260902-1530-checkout/
```

Branch: `erixpo/<YYYYMMDD>-<HHMM>-<slug>`

State in the **human** repo:

```
.erixpo/worktrees.jsonl
```

Statuses: `live` | `merged` | `closed` | `pruned` | `stale`

## Commands

```bash
.erixpo/bin/erixpo isolate --slug checkout
.erixpo/bin/erixpo worktrees
.erixpo/bin/erixpo merge --id <id>
.erixpo/bin/erixpo merge --id <id> --keep
.erixpo/bin/erixpo prune --id <id>
.erixpo/bin/erixpo prune --id <id> --delete-branch
.erixpo/bin/erixpo close --id <id>
.erixpo/bin/erixpo close --id <id> --keep
.erixpo/bin/erixpo close --id <id> --keep-branch
.erixpo/bin/erixpo close --id <id> --no-merge
.erixpo/bin/erixpo sweep
.erixpo/bin/erixpo sweep --apply
.erixpo/bin/erixpo run --isolate
.erixpo/bin/erixpo run --no-isolate
```

| Command | What |
|---|---|
| `isolate [--slug] [--with-env]` | Sibling tree + `erixpo/<stamp>-<slug>` branch. jsonl `live`. Refuses nested worktrees and `.env` copy. |
| `merge --id` | `--no-ff --no-edit` into current HEAD. jsonl `merged`. No push. No worktree remove. Next is `close --id` unless `--keep`. |
| `prune --id` | Clean-source removal with metadata preservation. Branch stays unless safely contained and `--delete-branch` was requested. jsonl `pruned`. |
| `close --id` | Merge if needed, verify ancestor, remove tree, delete branch, jsonl `closed`, `git worktree prune`, rmdir empty parent. |
| `close --keep` | Merge if needed, jsonl `merged`, keep dir + branch. |
| `close --keep-branch` | Remove tree, keep branch, jsonl `closed` (`note: keep-branch`). |
| `close --no-merge` | Allowed only if the branch is already merged or fully contained in HEAD. |
| `sweep` | Dry report: stale live rows, closeable merged rows, orphans, dead `erixpo/*` branches. |
| `sweep --apply` | Mark stale, `git worktree prune`, delete fully merged `erixpo/*` with no worktree, rmdir empty parent. Does **not** merge, close live trees, delete unmerged branches, or touch main. |

Close and sweep run from the human checkout, never from inside the isolated tree. Never auto-merge to main. Never auto-close unless the user said merge / land / close (or ran `close` / `sweep --apply`).

## Merge

1. Changed branches require artifact-matched stage-1 pass and stage-2 ship evidence; see [review.md](review.md). Empty unchanged trees can close without review.
2. Show `git log --oneline <base>..<branch>` and the check result.
3. Merge from the original checkout into its recorded originating branch. A different current branch is refused. No push. No deletion of WIP.
4. On conflict: stop. Do not `-X ours`.
5. After a successful merge the jsonl row is `merged`. The sibling checkout and `erixpo/*` branch still exist until `close --id`.
6. `close --id` is how machines stay clean. `--keep` lands without deleting. `--keep-branch` drops the checkout and keeps the branch.

Unattended loops never auto-merge to main and never auto-close.

## Persistence and recovery

Registry writes use a cross-process lock and atomic replacement. Isolation records originating branch/base in the registry and child isolation.json; state.md is canonical. Verified owned skill files are copied for host discovery. Uncommitted product files are not copied from the human checkout.

Close/merge/prune refuse staged, unstaged, untracked, or ignored user files and active run locks. Unchanged owned pack files are recognized by hash. Changed installed skills are user work and are preserved. Clean up generated dependencies explicitly before close if they remain ignored files in the tree.

Before removal, the lifecycle archives child metadata under `.erixpo/worktree-archives/<id>/`, merges append-only sessions/learnings and immutable run-events, and reconciles mutable USER/MEMORY/progress against the isolation baseline. Conflicting edits or duplicate event IDs with different content stop cleanup. Interrupted closing records can be retried; inspect missing legacy origin metadata rather than guessing a merge destination.

An explicit prune removes a clean abandoned checkout but retains unmerged commits on its branch. It does not silently force-delete an unmerged branch. Sweep never closes live trees automatically.
