---
name: erixpo-auto
description: Autonomous build loop for an approved erixpo plan. Use when the user says erixpo auto, go, continue, keep building, or when .erixpo/plan.md is approved. Implements one slice per iteration, updates the wiki, runs the project check command, repeats until the check passes or the budget is hit.
license: MIT
metadata:
  author: Erixpo
  version: "0.1.0"
---

# erixpo auto

This is the build phase. No more product interview unless a slice is blocked on a decision.

## Preconditions

- `.erixpo/plan.md` exists and status is `approved` (or the user just said "go" on the plan you showed).
- `AGENTS.md` exists. If not, run init first.
- A check command is written in `.erixpo/stack.md` or `AGENTS.md`. If missing, infer from the repo and confirm once.
- Isolation: if the tree is dirty or this is `bin/erixpo run`, isolate first (`bin/erixpo isolate` / [worktrees.md](../erixpo/references/worktrees.md)). Do not chew the user's WIP.
- Search `.erixpo/sessions.jsonl` for this module before coding.

## Loop

For each slice in the plan, until check is green or you hit the iteration cap (default 20, or `.erixpo/budget.md`):

1. Read `AGENTS.md`, `.erixpo/PROFILE.md`, `.erixpo/USER.md`, `.erixpo/MEMORY.md`, `.erixpo/lessons.md`, then the plan and the wiki page for this module. If a prior learning applies, say "prior learning applied: <key>" and follow it.
2. Implement **one** slice only. Do not boil the ocean.
3. Handle the edge cases listed for that slice. Follow [quality](../erixpo/references/quality.md) if that file is installed; otherwise apply the quality bar: empty/error/loading states, no AI-slop UI, no secrets.
4. Update wiki + `.erixpo/progress.md` + `documents/progress.html` in the same turn.
5. Run the check command from the `check:` line in `.erixpo/stack.md`. Capture pass/fail.
6. If fail: fix that failure next. Do not start a new slice. If the same class of mistake repeats **three times**, stop, follow `erixpo-learn`, and ask. Do not burn the budget. Read [failures.md](../erixpo/references/failures.md).
7. If pass: mark the slice done. If the slice taught the repo something non-obvious, follow `erixpo-learn` for one row. Append one line to `.erixpo/sessions.jsonl`. Pick the next slice.
8. Before claiming done: run the check command again and read the output. No completion claims without fresh evidence.

Stop and ask only when:

- a product decision was not in the plan
- the check cannot be run
- you would need to add a dependency or MCP the user did not approve
- iteration cap reached

## After the plan is green

Write a short delivery note in chat and in `.erixpo/progress.md`. Suggest two-stage `/erixpo review` as the next human action (stage 1 mechanical, stage 2 a fresh session). If this ran in a worktree, do **not** merge until review says `ship` and they say merge. Do not silently start extra features from the optional list.

## CLI

If `bin/erixpo` is on PATH in this project, you may run:

```bash
bin/erixpo run --max 20
```

That is the same loop driven from outside the chat. Prefer it when the user wants to walk away.
