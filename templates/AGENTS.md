# AGENTS.md

_Fill this during `/erixpo init`. Delete this italic line._

## Product

[One paragraph. What this software is. Who it is for.]

## Stack

- Language / runtime:
- App surface:
- Data:
- Tests:

## Commands

```bash
# install
# dev
# test   (this is the erixpo check unless .erixpo/stack.md overrides it)
# build
# lint
```

## Layout

```
[top-level map]
documents/          wiki
.erixpo/            machine state
```

## Invariants

- Do not commit secrets or `.env`.
- Do not add dependencies or MCP servers the user did not approve.
- Update `documents/` when behaviour changes.
- "Done" means the check command exits 0.
- Unattended loops isolate in a worktree. Do not merge onto the user's branch until they say so.
- Stage-2 review is a different session from the implementer.

## erixpo

This project uses erixpo workflow. Router skill: `/erixpo`.


## Memory

This repo keeps durable memory in `.erixpo/PROFILE.md`, `.erixpo/MEMORY.md`, `.erixpo/USER.md`, and `.erixpo/learnings.jsonl`. Read them before acting. After a non-trivial job, append a learning if something verified and reusable appeared.
