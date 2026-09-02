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
- Surface: web, landing, e-shop, SaaS, desktop, mobile, script, embedded/robot, other
- Constraints: platform, language they already know, budget, offline, compliance, deadline
- Must-have vs later

Stop interviewing when you can research. Do not ask 20 questions.

## Phase B — Research

Follow `references/research.md`. Write `.erixpo/research.md` with:

- Job classification
- 2–4 viable stacks for *this year*, with tradeoffs
- UI approach that will not look like generic AI slop
- Test / simulator / browser tools that actually catch bugs for this surface
- Candidate skills (skills.sh, anthropics/skills, GitHub) — list, do not install
- Candidate MCP servers — list, do not install
- What you recommend and why

Search the live web. Do not use memorized 2024 defaults as gospel.

## Phase C — Choices

For each decision that changes architecture, give 2–4 options + "write your own".

Use a compact question UI when the host supports it. If the list is long, use a numbered list in chat.

Never decide silently between Postgres vs SQLite, SwiftUI vs web, shop vs brochure, when that choice is expensive to undo.

## Phase D — Plan

Write `.erixpo/plan.md`:

- Product in one paragraph
- Non-goals
- Chosen stack
- Slices in order (each slice has acceptance + check)
- Edge cases to handle in v1
- Suggested extras the user did **not** ask for (share, admin, i18n…) as a separate optional list

Show the plan. If you discovered extras, ask once. Then wait for **go** / approved.

Update `.erixpo/state.yaml` to `phase: planned`. On approval: `phase: approved`, then immediately load `erixpo-auto`.
