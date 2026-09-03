# AGENTS.md

How to work on **erixpo-workflow itself**.

## What this is
Portable skill pack + installer + outer-loop CLI. Adaptive to the folder it is installed into — not only software, not only web.

## Check

```bash
bash check.sh
```

That runs bash syntax, skill frontmatter, adapter contract, template presence, VERSION lockstep (plugin + marketplace + every `skills/*/SKILL.md`), v0.6 protocol files, `close`/`sweep`/`isolate` presence, classify fixtures, UI token templates, and `tests/smoke.sh`.

## Layout
- `skills/` — what gets installed into other repos (one folder per track skill, each with `SKILL.md`)
- `templates/` — what `/erixpo init` copies into the *target* repo (ceremony decides which pages); includes the hidden `templates/.erixpo/` ceremony set (`stack.md` with `check:`/`install:`, `USER.md`, `CONSTITUTION.md`, `classify.md`, `plan.md`, `research.md`, … — assert with `ls -a` since dotfiles hide from plain `ls`)
- `bin/` + `adapters/` — outer loop (`run`, `review --stage 1`, `close`, `sweep`, `isolate`)
- `skills/erixpo/references/` — protocols (classify, scaffold, ceremony, ui, slop, testing, worktrees, …)
- `commands/` + `agents/` — the single user-facing slash command (`erixpo.md`) and reviewer agent
- `scripts/` + `tests/` + `examples/` + `references/` — helpers, smoke/contract tests, sample ceremony, shared judgment notes (top-level `references/` holds relocation stubs only; canonical copies live in `skills/erixpo/references/`)

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
