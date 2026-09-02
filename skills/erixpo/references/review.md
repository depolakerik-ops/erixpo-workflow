# Two-stage review

The implementer does not mark their own work done.

Testing protocol lives in [testing.md](testing.md). This file describes the gate.

## Stage 1 — mechanical

Run `scripts/review-stage1.sh` (or `bin/erixpo review --stage 1`). The script writes `.erixpo/REVIEW-stage1.md` and does not edit product code.

It **fails** if any of these hold:

- `check:` missing from `.erixpo/stack.md` and `AGENTS.md`
- `check:` is dummy: exact `true` / `exit 0` / `:` / `echo ok` (also `echo "ok"` / `echo OK`)
- non-dummy `check:` was not run during this review, or it exited non-zero (`bash -lc` of the line)
- secret-looking **tracked names**: `.env`, `id_rsa`, `id_ed25519`, `.pem`, `.p12` (not `example`)
- secret-looking **content**: `BEGIN PRIVATE KEY`, `AKIA`+16, `sk-` long, `ghp_` long (tracked files plus `.erixpo/sessions.jsonl` and `learnings.jsonl`)
- `TODO: implement` or `lorem ipsum` still in the tree (excludes `node_modules`, `.git`, `.erixpo`; first 20 hits)
- dummy tautology asserts anywhere in that same tree (first 10 hits). Families the script greps — **not** general `assertEquals(expected, actual)`:
  - JS `expect` of literal true (covers toBe/toEqual true)
  - Python `assert` of literal True/true, `assertTrue` of literal true/True
  - `assert (` literal true/True `)`
  - Swift `XCTAssertTrue` / `XCTAssert` of literal true/True
  - C# `Assert.True` / `Assert.IsTrue` of literal true/True
  - Rust `assert!` of literal true/True
  - `True (` literal true/True `)` with a non-alnum prefix (covers `t.True`)
  - Kotlin `shouldBe` of literal true/True
- **product files in the slice range with no test/spec file in the same range**, unless pairing is skipped
- **hard-coded hex** in slice product files that is not in `documents/ui/mapping.md` `theme_file` / `Path:` (skipped if no mapping path, docs-only, or `ERIXPO_SKIP_HEX=1`)

### Slice range

Union of paths:

1. `git diff --name-only HEAD` (working tree vs HEAD)
2. `git diff --name-only --cached`
3. If a review BASE was resolved: `git diff --name-only "${BASE}..HEAD"`

A **clean working tree still fails** when commits since BASE changed product files without a test/spec file in that union.

BASE, first hit:

1. `$ERIXPO_REVIEW_BASE` if it is a commit
2. `git merge-base HEAD origin/HEAD` if that ref exists
3. `git merge-base HEAD origin/main`
4. `git merge-base HEAD origin/master`
5. `git merge-base HEAD main` (skipped when that merge-base **is** HEAD — you are on local main)
6. `git merge-base HEAD master` (same skip)
7. else `HEAD~1` if it exists
8. else no committed range — pairing uses dirty/staged only; the script notes that

The script notes the BASE used.

Test/spec path heuristics: `*test*`, `*spec*`, `*Test*`, `*Spec*`, `*Tests*`, `*UITests*`, `tests/*`, `__tests__/*`, `*/androidTest/*`, `*_test.*`, `*.test.*`, `*.spec.*`, `*_spec.*`. Skipped as neither product nor test: `documents/*`, `*.md`, `.erixpo/*`, `AGENTS.md`, `CLAUDE.md`, `README.md`.

### Pairing skipped (noted in `REVIEW-stage1.md`)

- not a git repo
- `PROFILE` class `writing` | `research` | `ops` | `assistant`
- `ERIXPO_DOCS_ONLY=1`
- `ERIXPO_SKIP_TEST_PAIRING=1` (explicit escape; always noted when set)

Docs/non-software still skips test-file pairing. Dummy `check:` still fails.

## Stage 2 — adversarial

**Different session.** Use the `erixpo-reviewer` agent or a fresh chat that did not implement the slice. Confirm stage 1 passed first.

Attack:

- Edges (empty, invalid, denied, offline, timeout, first-run, huge input, small screen)
- Gamed tests (cannot fail, mocks the unit out of existence, harness missing, typecheck posing as tests)
- Authz holes, injection, unsafe defaults
- UI slop against `documents/ui/LANGUAGE.md` + [slop.md](slop.md) + `documents/ui/layout.md` (and mapping/tokens)
- Wiki drift; ceremony mismatch ([wiki.md](wiki.md), [ceremony.md](ceremony.md) if present)
- Merge risk against other live worktrees

Verdict: `ship` | `fix-blockers` | `keep-iterating`.

Do not merge until stage-2 says `ship` **and** the user says merge. On an isolated worktree, prefer `bin/erixpo close --id <id>` (merge + prune) after ship; `bin/erixpo merge --id <id>` is still valid.

Write `.erixpo/REVIEW.md` from the template (stage-1 pointer, visual/UI notes). Copy `documents/review-latest.md`. Do not edit product code.
