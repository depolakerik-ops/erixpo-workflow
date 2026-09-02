# Worktree isolation

Each unattended run, and any second agent, gets its own Git worktree and branch. The human's checkout stays theirs.

## When

| Situation | Isolate? |
|---|---|
| `bin/erixpo run` (leave-the-room loop) | Yes, default |
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
bin/erixpo isolate --slug checkout
bin/erixpo worktrees
bin/erixpo merge --id <id>
bin/erixpo merge --id <id> --keep
bin/erixpo prune --id <id>
bin/erixpo prune --id <id> --delete-branch
bin/erixpo close --id <id>
bin/erixpo close --id <id> --keep
bin/erixpo close --id <id> --keep-branch
bin/erixpo close --id <id> --no-merge
bin/erixpo sweep
bin/erixpo sweep --apply
bin/erixpo run --isolate
bin/erixpo run --no-isolate
```

| Command | What |
|---|---|
| `isolate [--slug] [--with-env]` | Sibling tree + `erixpo/<stamp>-<slug>` branch. jsonl `live`. Refuses nested worktrees and `.env` copy. |
| `merge --id` | `--no-ff --no-edit` into current HEAD. jsonl `merged`. No push. No worktree remove. Next is `close --id` unless `--keep`. |
| `prune --id` | `worktree remove --force`. Branch stays unless `--delete-branch`. jsonl `pruned`. |
| `close --id` | Merge if needed, verify ancestor, remove tree, delete branch, jsonl `closed`, `git worktree prune`, rmdir empty parent. |
| `close --keep` | Merge if needed, jsonl `merged`, keep dir + branch. |
| `close --keep-branch` | Remove tree, keep branch, jsonl `closed` (`note: keep-branch`). |
| `close --no-merge` | Allowed only if the branch is already merged or fully contained in HEAD. |
| `sweep` | Dry report: stale live rows, closeable merged rows, orphans, dead `erixpo/*` branches. |
| `sweep --apply` | Mark stale, `git worktree prune`, delete fully merged `erixpo/*` with no worktree, rmdir empty parent. Does **not** merge, close live trees, delete unmerged branches, or touch main. |

Close and sweep run from the human checkout, never from inside the isolated tree. Never auto-merge to main. Never auto-close unless the user said merge / land / close (or ran `close` / `sweep --apply`).

## Merge

1. Stage-1 + stage-2 review must exist unless the user skips review in writing.
2. Show `git log --oneline <base>..<branch>` and the check result.
3. Merge into the branch the user is on. No push. No delete of their WIP.
4. On conflict: stop. Do not `-X ours`.
5. After a successful merge the jsonl row is `merged`. The sibling checkout and `erixpo/*` branch still exist until `close --id`.
6. `close --id` is how machines stay clean. `--keep` lands without deleting. `--keep-branch` drops the checkout and keeps the branch.

Unattended loops never auto-merge to main and never auto-close.
