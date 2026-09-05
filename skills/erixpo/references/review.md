# Two-stage review

Implementation and independent review have separate responsibilities. [testing.md](testing.md) defines development verification.

## Stage 1

Commit completed source, then run `.erixpo/bin/erixpo review --stage 1` in the tree being reviewed. The helper writes human notes to `.erixpo/REVIEW-stage1.md` and machine evidence to `.erixpo/REVIEW-stage1.json`.

The gate executes the configured check and inspects project files, including untracked files. It excludes hash-owned pack paths, local engine state, generated/vendor directories, and does not follow symlinks. It flags secret-looking content/names, obvious placeholder source and tautology assertions, product changes without a test path, and theme drift when configured. These are heuristics; passing does not establish full correctness or security.

Evidence contains `schema`, `result`, `base`, `head`, `tree_digest`, `check`, `review_id`, and `reviewed_at`. Base comes from an explicit `ERIXPO_REVIEW_BASE`, isolation metadata, or a Git merge-base fallback. Files changing during the check invalidate the review. Changing the base, HEAD, project bytes/modes, or check command afterward makes it stale.

Document exceptions: `ERIXPO_DOCS_ONLY`, `ERIXPO_SKIP_TEST_PAIRING`, and `ERIXPO_SKIP_HEX` are scoped escape hatches, not proof that omitted checks ran. Non-software still needs artifact-appropriate verification. Human-acceptance-only writing stays interactive.

## Stage 2

Use a fresh session that did not implement the change. Confirm stage 1 passed, inspect the diff and evidence, and test meaningful edges: empty, invalid, denied, offline, timeout, first-run, large inputs. Review tests for real assertions, assess UI against task/platform/accessibility requirements, and check docs and merge risks.

Write these **top-level fields** in `.erixpo/REVIEW.md`:

```
Result: ship
Review-ID: <review_id from the current REVIEW-stage1.json>
Reviewer: <independent session or reviewer identifier>
```

Use `fix-blockers` or `keep-iterating` instead of `ship` if needed. Record evidence and limitations below those fields. Do not copy a prior Review-ID onto a new review without performing the review. The identity binding detects stale artifacts; it is not a cryptographic authentication of who reviewed them.

If review requires edits, implement and commit them, rerun stage 1, then review the new artifact. Keep detailed review output under `.erixpo/`; writing a tracked summary after stage 1 changes the artifact and requires another check.

## Landing

A changed isolated branch can merge/close only with matching stage-1 pass and stage-2 ship evidence. The user must separately authorize close/merge. Close checks the original destination branch and source cleanliness, preserves memory, then removes the worktree. An unchanged empty isolated tree can close without review. No worker auto-merges or closes its own tree.
