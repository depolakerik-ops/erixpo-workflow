# AGENTS.md

How to work on **erixpo-workflow itself**.

## What this is
Portable skill pack + installer + outer-loop CLI. Adaptive to the folder it is installed into — not only software, not only web.

## Check

```bash
bash check.sh
```

That runs bash syntax, skill frontmatter, adapter contract, template presence, and `tests/smoke.sh`.

## Layout
- `skills/` — what gets installed into other repos
- `templates/` — what `/erixpo init` copies into the *target* repo (ceremony decides which pages)
- `bin/` + `adapters/` — outer loop (`run`, `review --stage 1`, `close`, `sweep`)
- `skills/erixpo/references/` — protocols (classify, scaffold, ceremony, ui, slop, testing, worktrees)

## Isolation
Unattended loops use `bin/erixpo isolate`. After stage-2 `ship` and the user says close, `bin/erixpo close --id` merges and removes the tree. `sweep` finds leftovers. Session history lives in `.erixpo/sessions.jsonl`.

## Forbidden
- Do not add a second user-facing slash command. Extend the router.
- Do not add `erixpo-ios` / `erixpo-android`. Deepen research + scaffold + slop references.
- Do not hardcode a web/React stack. Research is live. HTML mockups are for web surfaces.
- Do not commit secrets.
- Do not rewrite skills into vendor-specific formats.
- Do not auto-merge a worktree onto main.
- Do not leave merged worktrees on disk; close them.
