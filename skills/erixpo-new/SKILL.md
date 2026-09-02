---
name: erixpo-new
description: Start a new product with erixpo. Interview the user, research current best stack for this job, present 2-4 choices, write a plan, wait for approval. Use when the user wants a new app, site, SaaS, script, desktop, robot software, or any greenfield work.
license: MIT
---

# erixpo-new

Greenfield or "I want to build X". Do not jump to code.

## Phase A — Interview

Talk like a competent teammate. Collect only what changes the build:

- Job to be done (who, what outcome)
- Surface: web, landing, e-shop, SaaS, desktop, mobile, script, embedded/robot, wiki, other — do not assume web
- Constraints: platform, language they already know, budget, offline, compliance, deadline
- Must-have vs later
- If there is a UI: one question about taste / a reference they like, then you will propose directions after research (see [ui.md](../erixpo/references/ui.md)). Load `erixpo-ui` and write `documents/ui/` (tokens, motion, components, screens, one mockup) **before** product chrome.

Stop interviewing when you can research. Do not ask 20 questions.

## Phase B — Research

Follow [research.md](../erixpo/references/research.md), [ui.md](../erixpo/references/ui.md), [testing.md](../erixpo/references/testing.md). Write `.erixpo/research.md` with:

- Job classification
- 2–4 viable stacks **and tools** for *this year* (build, test, lint, UI, deploy or "none")
- UI directions to show the user (if there is a surface)
- What should be tested in v1 vs later
- Candidate skills / MCP — list, do not install
- Recommendation + why + what you rejected

Search the live web. Do not use memorized defaults. Follow [judgment.md](../erixpo/references/judgment.md): reframe the job, name the tutorial-default, and put one non-obvious option on the table with a reason. Novelty is optional. The reframe is not.

## Phase C — Choices

For each decision that changes architecture, give 2–4 options + "write your own".

Use a compact question UI when the host supports it. If the list is long, use a numbered list in chat.

Never decide silently between stacks, UI directions, or "add a database / component kit" when that choice is expensive to undo. Show the UI options. Wait.

## Phase D — Plan

Write `.erixpo/plan.md`:

- Product in one paragraph
- Non-goals
- Chosen stack
- UI spec pointer (`documents/ui/`) if there is a surface
- Slices in order (each slice has acceptance + check + tests + UI tokens/components touched)
- Edge cases to handle in v1
- Test plan pointer (`.erixpo/test-plan.md`)
- Suggested extras the user did **not** ask for (share, admin, i18n…) as a separate optional list

Show the plan. If you discovered extras, ask once. Then wait for **go** / approved.

Update `.erixpo/state.yaml` to `phase: planned`. On approval: `phase: approved`, then immediately load `erixpo-auto`.
