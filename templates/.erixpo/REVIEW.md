# Review

Date:
Scope:
Tree: in-place | worktree
Branch:
Isolation id:
Check command:
Check result:
Stage-1 file: `.erixpo/REVIEW-stage1.md`

## Stage 1

Result: pass | fail
BASE:
Pairing: ran | skipped (class | ERIXPO_DOCS_ONLY | ERIXPO_SKIP_TEST_PAIRING | no git | no committed range)
Notes:

## Stage 2

Result: pass | fail
Blockers:
Should-fix:
Later:

### Visual / UI

- Change-type: none | create | relanguage | retoken | recompose | reflow | remotion | new-screen | consistency
- LANGUAGE.md / slop.md / layout.md:
- Proof: screenshot | simulator | browser | native preview | `untested: visual` (why):

## Verdict

ship | fix-blockers | keep-iterating

## Close

On ship + worktree, after the user says merge: `bin/erixpo close --id <id>` (merge + prune). `bin/erixpo merge --id <id>` is still valid.
