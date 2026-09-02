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

1. Read `AGENTS.md`, `.erixpo/PROFILE.md`, `.erixpo/USER.md`, `.erixpo/MEMORY.md`, `.erixpo/lessons.md`, `documents/ui/` when a surface exists, then the plan and the wiki page for this module. If a prior learning applies, say "prior learning applied: <key>" and follow it.
2. Implement **one** slice only. Do not boil the ocean. Visible work uses the tokens in `documents/ui/tokens.md`. No freelance hex / radius / motion. Missing spec on a UI slice → write the spec in this slice first (`erixpo-ui`).
3. **Tests for this slice.** Follow [testing.md](../erixpo/references/testing.md): list the cases this change created, write tests that can fail, run them. If the platform test tool is not chosen yet, research it and ask once.
4. Handle the edge cases listed for that slice. Follow [quality](../erixpo/references/quality.md) and [ui.md](../erixpo/references/ui.md) when there is a surface.
5. **Self-review the diff** (quality.md). Then update wiki + `.erixpo/progress.md` + `documents/progress.html` + `.erixpo/test-plan.md`.
6. Run `check:` from `.erixpo/stack.md`. Capture pass/fail.
7. If fail: fix that failure next. Do not start a new slice. Same class of mistake **three times** → stop, `erixpo-learn`, ask. Read [failures.md](../erixpo/references/failures.md).
8. If pass: mark the slice done, one sessions.jsonl line, learn if something verified. Pick the next slice.
9. No completion claim without fresh test/check output in this iteration.

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
