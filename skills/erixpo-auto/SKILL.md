---
name: erixpo-auto
description: Autonomous build loop for an approved erixpo plan. Use when the user says erixpo auto (or go/continue/keep building about an approved .erixpo/plan.md). Same quality bar as bin/erixpo run (templates/PROMPT.md). One slice per iteration with tests, UI spec, self-review, check, wiki per ceremony. USER.md autonomy wins; tests are not optional.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.2"
---

# erixpo auto

This is the build phase. No more product interview unless a slice is blocked on a decision.

Interactive `/erixpo auto` and unattended `bin/erixpo run` use the **same** quality bar. The worker prompt is `templates/PROMPT.md` — specialist, not factory ([craft.md](../erixpo/references/craft.md)). USER.md taste and autonomy win. Tests still run. Do not narrate the workflow in chat.

## Preconditions

- `.erixpo/plan.md` exists and status is `approved` (or the user just said "go" on the plan you showed).
- `AGENTS.md` exists. If not, run init first.
- A check command is written in `.erixpo/stack.md` or `AGENTS.md`. If missing, infer from the repo and confirm once.
- Isolation: if the tree is dirty or this is `bin/erixpo run`, isolate first (`bin/erixpo isolate` / [worktrees.md](../erixpo/references/worktrees.md)). Do not chew the user's WIP.
- Search `.erixpo/sessions.jsonl` for this module before coding.
- `.erixpo/classify.md` exists with `request_class` and `jobs:`. If missing, run `bin/erixpo classify <sentence>` and write the file **before** product code.
- If `USER.md` still has empty autonomy / test / review lines, write defaults: `plan-then-go`, `harness-required`, `always-stage-2`. Do not skip tests because USER was blank.
- Run `bin/erixpo capabilities` and paste into classify `capabilities:` if that field is empty.

## Loop

Read [memory.md](../erixpo/references/memory.md) inject order, then USER.md, and obey it.

Until check is green or you hit the iteration cap (default 20, or `.erixpo/budget.md`):

0. Read `AGENTS.md`, `.erixpo/PROFILE.md`, `.erixpo/USER.md`, `.erixpo/MEMORY.md`, `.erixpo/lessons.md`, `CONSTITUTION.md` if present, `classify.md` if present, `documents/ui/` if a surface exists. Grep `.erixpo/learnings.jsonl` for files you will touch. If a learning applies: `Prior learning applied: <key>`. Then read testing.md, quality.md; ui.md if a surface; ceremony.md / slop.md / scaffold.md if present.
1. Read the plan, `documents/` as ceremony requires, git status. Search sessions.
2. If check already passes AND the current slice is done (plan status): stop (interactive: delivery note below; unattended: print `ERIXPO_DONE` and exit).
3. Do THE SINGLE next incomplete slice. Greenfield and constitution missing, or slice 0 scaffold still open → scaffold before product chrome (`scaffold.md` if present in pack-templates or skills). **Each build slice** gets a **narrow** live-search for *this slice in this field* this year (official docs + similar work). Do not re-research the whole stack. Do not skip because the stack is “already known.” Typo-only fix slices may skip. Pick official default unless USER is `ask-every-slice`.
4. Missing test harness → create it this slice. Do not ask permission to have tests. Follow [testing.md](../erixpo/references/testing.md). `harness-required` in USER.md is the default bar; `best-effort` still writes tests when a runner exists.
5. Write/update tests for this slice. Run `check:` from `.erixpo/stack.md`. Read the output. No success claim without that evidence. Check must run tests, not only typecheck, unless constitution says otherwise.
6. If a surface: follow `documents/ui/` and `ui_change` in classify.md (relanguage / retoken / recompose / reflow / remotion). Missing spec → `erixpo-ui` first. No freelance hex. No HTML-as-iOS. No tutorial slop. Visual-first / mockups fields in USER.md specialize when to mock; they do not license skipping the spec.
7. Self-review the diff ([quality.md](../erixpo/references/quality.md)). No optional extras. Empty / error / loading when cheap. Then wiki per ceremony + `.erixpo/progress.md` (not a forced `progress.html` / `ARCHITECTURE.md` on light ceremony).
8. If check fails: fix only that failure. Same class of mistake twice → append a learning. Three times → stop, `erixpo-learn`, do not burn the budget. Read [failures.md](../erixpo/references/failures.md).
9. Commit real progress on THIS branch only. Never merge onto the user's main. Never close or prune a worktree from the worker.
10. Interactive + `ask-every-slice`: stop and show. Interactive + `plan-then-go` or `unattended`: next slice. Unattended CLI worker: **exit** — the outer loop restarts you.

No completion claim without fresh test/check output in this iteration.

Stop and ask only when:

- a product decision was not in the plan **and** USER is `ask-every-slice` (otherwise: narrow research, official default, record why)
- the check cannot be run
- you would need to add a dependency or MCP the user did not approve **and** USER is `ask-every-slice`
- iteration cap reached

Do **not** stop to ask "may I add tests?"

## After the plan is green

Write a short delivery note in chat and in `.erixpo/progress.md`. Suggest two-stage `/erixpo review` as the next human action (stage 1 mechanical, stage 2 a fresh session). `skip-tiny` in USER.md may skip stage-2 on a tiny diff; `always-stage-2` never does.

If this ran in a worktree, do **not** merge. After stage-2 says `ship` **and** they say close/merge, tell them:

```bash
bin/erixpo close --id <id>
```

Do not start optional extras. Do not close/prune the worktree yourself.

## CLI

If `bin/erixpo` is on PATH in this project, you may run:

```bash
bin/erixpo run --max 20
```

That is the same loop driven from outside the chat. Prefer it when they walk away or USER.md autonomy is `unattended`. The worker prompt is `templates/PROMPT.md` — it must match this skill.
