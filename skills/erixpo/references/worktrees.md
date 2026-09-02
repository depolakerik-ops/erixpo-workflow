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

## Commands

```bash
bin/erixpo isolate --slug checkout
bin/erixpo worktrees
bin/erixpo merge --id <id>
bin/erixpo prune --id <id>
bin/erixpo run --isolate
bin/erixpo run --no-isolate
```

## Merge

1. Stage-1 + stage-2 review must exist unless the user skips review in writing.
2. Show `git log --oneline <base>..<branch>` and the check result.
3. Merge into the branch the user is on. No push. No delete of their WIP.
4. On conflict: stop. Do not `-X ours`.

Unattended loops never auto-merge to main.
