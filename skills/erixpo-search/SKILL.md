---
name: erixpo-search
description: Search prior erixpo sessions, learnings, and worktrees in this repo. Use when the user says what did we do, find the session, search memory, prior run, or at the start of a non-trivial job before planning. Reads .erixpo/*.jsonl only. Does not change product code.
license: MIT
metadata:
  author: Erixpo
  version: "0.3.0"
---

# erixpo search

Chat is gone. JSONL is not.

Read [sessions.md](../erixpo/references/sessions.md).

## Do

1. Run:

```bash
bin/erixpo search --kind all <query>
```

If the CLI is missing, grep `.erixpo/sessions.jsonl`, `.erixpo/learnings.jsonl`, and `.erixpo/worktrees.jsonl` yourself.

2. Show 3–8 hits, newest first among equals:

```
Prior session: s-… — <goal> (pass|fail, ts)
Prior learning applied: <key> — <insight>
Live worktree: <id> — <branch> @ <path>
```

3. If a hit changes what you will do, say so in one line. Then route back to the original job (fix / feature / auto / review). Search is not a destination.

## Empty query

User said `/erixpo search` or "what did we do last". Print the last 8 sessions and any live worktrees.

## Do not

- Do not dump the whole file
- Do not invent sessions that are not on disk
- Do not write secrets that someone accidentally logged — redact and offer prune via `erixpo-learn`
- Do not treat search as a substitute for reading PROFILE / MEMORY / USER
