---
name: erixpo-review
description: Two-stage review of an erixpo project or slice. Use when the user says erixpo review, audit the code, check quality, find edge cases, dead code, UI slop, or platform compliance. Stage 1 is mechanical. Stage 2 is adversarial in a different session. Writes .erixpo/REVIEW.md. Does not change product code.
license: MIT
metadata:
  author: Erixpo
  version: "0.3.0"
---

# erixpo review

Two stages. The implementer does not mark their own work done.

Read [review.md](../erixpo/references/review.md) and [failures.md](../erixpo/references/failures.md). If the slice ran in a worktree, read [worktrees.md](../erixpo/references/worktrees.md) and review **that** tree.

## Scope

If the user named files or a feature, stay there. Otherwise review what changed since the last review (`git log`, `.erixpo/progress.md`, last `sessions.jsonl` line). If that is empty, review the core flow only.

Search sessions first (`/erixpo search` or `erixpo-search`) so you do not re-raise a finding already fixed.

## Stage 1 — mechanical

Run, do not skip:

```bash
bin/erixpo review --stage 1
# or
bash scripts/review-stage1.sh
```

If the script is not on disk yet, do the same checks by hand: run the real `check:` command, reject dummy gates, reject empty diffs on a "done" slice, reject secrets, reject `TODO: implement` / lorem / skipped tests in the diff, reject wiki pages that claim missing features.

Write the Stage 1 section. If stage 1 fails, stop. Do not start stage 2 on a lied gate.

## Stage 2 — adversarial

Different session. If *this* session implemented the slice, spawn `erixpo-reviewer` or tell the user to open a new chat and run `/erixpo review` there.

Look for:

- Edge cases missing from the happy path (empty, error, permission, offline, first-run, huge input, small screen)
- Dead code and unused deps you are sure about
- Tests that cannot fail / tests that were gamed
- UI slop and platform-guide violations
- Accessibility and empty/error/loading states
- Security: secrets, authz holes, injection, unsafe defaults
- Docs drift
- Merge risk against other live worktrees

## Output

Write `.erixpo/REVIEW.md` and `documents/review-latest.md` using the template in [review.md](../erixpo/references/review.md).

Verdict is one of: `ship` | `fix-blockers` | `keep-iterating`.

Do not edit product code in this skill. Offer `/erixpo fix` for blockers after they say go. If the work lived in a worktree, offer `bin/erixpo merge --id <id>` only on `ship`.
