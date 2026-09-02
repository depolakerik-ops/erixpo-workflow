# Two-stage review

The implementer does not mark their own work done.

## Stage 1 — mechanical

Run `scripts/review-stage1.sh` (or `bin/erixpo review --stage 1`).

Fail if:

- `check:` missing, or matches `true` / `exit 0` / `echo ok`
- check command was not run during this review
- secret-looking tracked files (`.env`, `id_rsa`, `BEGIN PRIVATE KEY`, `AKIA`)
- `TODO: implement` or `lorem ipsum` still in the tree

Writes `.erixpo/REVIEW-stage1.md`. Does not edit product code.

## Stage 2 — adversarial

**Different session.** Use the `erixpo-reviewer` agent or a fresh chat that did not implement the slice.

Look for happy-path-only, authz holes, tests that cannot fail, UI slop, wiki drift, scope creep.

Verdict: `ship` | `fix-blockers` | `keep-iterating`.

Do not merge a worktree until stage-2 says `ship` and the user says merge.
