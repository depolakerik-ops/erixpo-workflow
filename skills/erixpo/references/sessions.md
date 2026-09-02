# Sessions and search

Every finished (or abandoned) job leaves one JSONL line. Later workers search those lines instead of hoping the chat is still around.

No SQLite. No daemon. `grep` / the bundled script is enough.

## Files

| File | Role |
|---|---|---|
| `.erixpo/sessions.jsonl` | What we did |
| `.erixpo/learnings.jsonl` | What to do differently next time |
| `.erixpo/worktrees.jsonl` | Isolated checkouts still alive |
| `.erixpo/refine-log.md` | Memory edits, so a bad one can be reverted |

## Session line

```json
{"ts":"2026-09-02T16:10:00Z","id":"s-20260902-1610-checkout","track":"auto","goal":"checkout slice 3","files":["src/checkout.ts"],"check":"pass","isolation":"worktree","worktree":"../.erixpo-worktrees/app-20260902-1610-checkout","branch":"erixpo/20260902-1610-checkout","lessons":["pitfall-empty-cart"],"notes":"empty cart now returns 409"}
```

Required: `ts`, `id`, `track`, `goal`, `check` (`pass` | `fail` | `skip` | `blocked`).
Optional: `files`, `isolation`, `worktree`, `branch`, `lessons`, `notes`.
Never: tokens, passwords, contents of `.env`.

`id` is also used as the worktree id when isolated.

## When to write

- End of a slice (auto / feature / fix / work)
- Review finished (track: `review`, notes: verdict)
- Loop stopped on budget or repeated failure
- User aborted

Do not write a line for "I read the repo".

## Search

At the start of every non-trivial job, and whenever the user asks "what did we do about X":

```bash
bin/erixpo search checkout
bin/erixpo search --kind sessions empty cart
bin/erixpo search --kind learnings pitfall
```

Or follow `erixpo-search`.

Return the 3–8 best hits as:

`Prior session: <id> — <goal> (<check>, <ts>)`

`Prior learning applied: <key> — <insight>`

Do not dump the whole JSONL into the prompt.

## Ranking (script)

1. Exact phrase in `goal`, `notes`, `key`, `insight`
2. Token overlap with `files[]`
3. Recency (newer first among equals)
4. Drop `status: retracted` learnings
5. Cap 8

## Edge cases

- File missing → create empty, say "no history yet"
- Broken JSON line → skip that line, do not abort
- Query empty → last 8 sessions
- Two sessions with the same goal and `check: fail` then `pass` → show both, latest first
- Search is not a substitute for reading PROFILE / MEMORY / USER
