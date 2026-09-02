# Sub-agents

Default: **one** worker.

Spawn another agent only when:

- the work does not touch the same files
- the child has a written slice in `.erixpo/plan.md`
- the parent merges results and runs the check command

Always use a separate session for stage-2 `/erixpo review`.

Each extra agent gets its own worktree. The parent merges. Children do not merge each other. Cap concurrent trees at 3 unless `.erixpo/budget.md` says otherwise.

Do not fan out five agents "for speed" on a single module. You will fight the merge.

Read [worktrees.md](worktrees.md) and [failures.md](failures.md).
