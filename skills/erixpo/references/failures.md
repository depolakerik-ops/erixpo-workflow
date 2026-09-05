# What goes wrong

Read this before claiming a slice is done, before spawning a sub-agent, and when a loop starts looping.

A failure is anything that lets the agent *say* it finished while the user still cannot use the product, or that silently damages their working tree.

## Classes

| Class | Symptom | First response |
|---|---|---|
| Isolation | Agent edits the user's dirty files / two agents share an index | Worktree. Never two writers on one checkout |
| Gate | Check is missing, always-true, or not run this turn | Refuse "done". Fix the gate |
| Loop | Same error class 3 times, or iteration cap | Stop. Learn. Ask |
| Memory | Sessions/learnings ignored or invented | Search first. Evidence or user said it |
| Review | Implementer marks own work done | Stage-2 in a different session |
| Merge | Worktree "success" never lands, or it lands but the sibling checkout/branch/jsonl row stay on disk | Explicit merge/close after review. No auto-merge to main. sweep --apply for leftovers |
| Scope | Fix becomes a rewrite; optional extras sneak in | One slice. Optional list stays optional |
| Secrets | Key in git, chat, REVIEW.md, sessions.jsonl | Stop. Purge. Rotate if it was real |
| Docs | Wiki claims a feature the code does not have | Wiki follows code, not the plan |
| Install | Skills copied into the wrong folder / pack skills edited in a target repo | Pack is immutable. Only `.erixpo/` learns |

## Isolation

- Two agents in one working tree share the index. `git add` from one eats the other's unstaged files.
- Unattended `.erixpo/bin/erixpo run` on a dirty tree will commit or overwrite human WIP.
- Worktrees do **not** copy gitignored files: `.env`, `node_modules`, `dist`, simulators, signing certs.
- Symlinking one shared `node_modules` breaks the moment a branch bumps a dependency or a native addon. Prefer a fresh install; pnpm store is the cheap case.
- Git refuses two worktrees on the same branch. Each run gets `erixpo/<date>-<slug>`.
- Not a git repo → isolation is impossible. Say so. Do not invent a fake worktree.
- Nested worktree inside another worktree → refuse.
- Crash mid-run leaves a worktree and a branch. `.erixpo/bin/erixpo sweep` finds it. `.erixpo/bin/erixpo close --id` or `.erixpo/bin/erixpo sweep --apply` is how leftovers die, not `rm -rf` of `.git`.

See [worktrees.md](worktrees.md).

## Gate (check command)

Bad gates, treat as fail:

- missing `check:` line
- `check: true`, `check: echo ok`, `check: exit 0`
- check not executed in *this* iteration
- check passed only because tests assert constants / mock the unit under test out of existence
- check is `tsc --noEmit` on a repo whose bugs are runtime
- network-flaky check used as the only gate

A slice is not done because the model typed "done".

## Loop

- Same compile error three times → stop, write a pitfall, ask. Do not burn the budget.
- Agent "fixes" by deleting the test or weakening the assertion → blocker, not a pass.
- Context window full → the *next* iteration is a fresh worker. Disk is memory. Do not paste the whole repo into chat.
- Plan still `draft` → auto does not start.
- Iteration cap hit → write `.erixpo/progress.md` with "stopped: budget", do not claim shipped.

## Memory and sessions

- Chat is not memory. If it is not in `.erixpo/` or `documents/`, the next worker will not know it.
- Invented learnings (no evidence, user did not say it) poison later runs. Do not write them.
- Searching only MEMORY.md and skipping `sessions.jsonl` loses "we already tried X and it failed".
- JSONL with secrets, tokens, private messages → delete the line, do not "edit history in place" without a refine-log note.

See [sessions.md](sessions.md).

## Review

- Same session that implemented the slice cannot be stage-2.
- Stage-1 green + stage-2 skipped = not reviewed.
- "LGTM" with empty Blockers/Should-fix and no evidence the check ran = slop review. Invalid.
- Reviewer editing product code "while I'm here" contaminates the audit trail. Use `/erixpo fix` after.

See [review.md](review.md).

## Merge and shipping

- Do not merge an isolated branch onto the user's current branch without them saying merge / ship / land / close it.
- Conflict ≠ "take ours". Stop and show the files.
- Passing check in the worktree does not prove the main checkout still builds (ignored files differ).
- Success that never lands, and success that lands but leaves the sibling checkout, `erixpo/*` branch, and jsonl row, are both merge failures. `.erixpo/bin/erixpo close --id` is how they die. `.erixpo/bin/erixpo sweep` reports leftovers; `sweep --apply` marks stale and deletes fully merged `erixpo/*` branches with no worktree. Never `rm -rf` `.git`. Never auto-merge to main. Never auto-close.

## Scope and product

- Landing page gets a SaaS stack.
- Notes vault gets Next.js.
- Optional extras (auth, analytics, share-sheet) added without asking.
- Init overwrites a real README.
- Sub-agents on overlapping files.
- Platform UI slop — the tutorial default for **this surface** ([slop.md](slop.md)), or HTML treated as iOS/Android source of truth.

## Secrets and safety

- `.env` copied into a worktree "so tests pass" and then committed.
- API keys written into `documents/` or REVIEW.md as "repro steps".
- `git add -A` after an agent dump. Always status first.

## Recovery

1. Stop the loop.
2. Write what failed in `.erixpo/progress.md` and one sessions.jsonl line with `check: fail`.
3. If the working tree is the user's: do not reset --hard. Isolate or stash only with permission.
4. If a worktree is rotten: `.erixpo/bin/erixpo close --id` (lands if needed, then drops tree + branch) or `prune` (keeps the branch unless `--delete-branch`). `.erixpo/bin/erixpo sweep --apply` for stale rows and dead merged `erixpo/*` branches. Do not `rm -rf` `.git`.
5. If a learning was wrong: `status: retracted`, do not delete the line.
6. Then `/erixpo fix` or a new plan slice. Not a rewrite of the pack skills.
