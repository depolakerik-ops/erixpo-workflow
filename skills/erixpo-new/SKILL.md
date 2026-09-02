---
name: erixpo-new
description: Start a new product with erixpo. Interview the user (surface is mandatory, never default to web), research current best stack for this job, present 2-4 choices, write a plan with slice 0 scaffold when the folder has no project, wait for approval. Use when the user wants a new app, site, SaaS, script, desktop, mobile, robot software, wiki, assistant, or any greenfield work.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo-new

Greenfield or "I want to build X". Do not jump to code.

Read [domains.md](../erixpo/references/domains.md), [ceremony.md](../erixpo/references/ceremony.md), [scaffold.md](../erixpo/references/scaffold.md), [judgment.md](../erixpo/references/judgment.md).

## Phase A — Interview

Talk like a competent teammate. Collect only what changes the build:

- Job to be done (who, what outcome)
- **Surface (mandatory):** desktop, mobile (iOS / Android), Windows, macOS, web, landing, e-shop, SaaS, script, embedded, wiki, assistant, other. **Do not default to web.** Ask if missing.
- Constraints: platform, language they already know, budget, offline, compliance, deadline
- Must-have vs later
- If there is a **visible** surface: one question about taste / a reference they like, then propose directions after research ([ui.md](../erixpo/references/ui.md)). Load `erixpo-ui` **only if there is a surface**. Write `documents/ui/` before product chrome. HTML mockups only when surface is web (or last-resort wire). Native uses `documents/ui/mapping.md` (another agent — do not fake it).

Stop interviewing when you can research. Do not ask 20 questions.

If the folder has **no project** (empty or nearly empty): the plan's **slice 0 is scaffold** ([scaffold.md](../erixpo/references/scaffold.md)). Acceptance: official project opens/builds and `check:` runs. Before UI chrome and before feature slices.

## Phase B — Research

Follow [research.md](../erixpo/references/research.md), [ui.md](../erixpo/references/ui.md) if a surface, [testing.md](../erixpo/references/testing.md). Write `.erixpo/research.md` with:

- Job classification + proposed ceremony (`full` | `standard` | `light`)
- 2–4 viable stacks **and tools** for *this year* (build, test, lint, UI, deploy or "none")
- Official current-year init command for THIS surface (slice 0)
- UI directions to show the user (if there is a surface)
- What should be tested in v1 vs later
- Candidate skills / MCP — list, do not install
- Recommendation + why + what you rejected
- Judgment four lines ([judgment.md](../erixpo/references/judgment.md)): default everyone would pick, reframe of the job, non-obvious option, what we will not do even though a tutorial would

Search the live web. Do not use memorized defaults. Novelty is optional. The reframe is not.

## Phase C — Choices

For each decision that changes architecture, give 2–4 options + "write your own".

Use a compact question UI when the host supports it. If the list is long, use a numbered list in chat.

Never decide silently between stacks, UI directions, or "add a database / component kit" when that choice is expensive to undo. Show the UI options. Wait.

## Phase D — Plan

Write `.erixpo/plan.md` from the rich template (same content as pack `templates/erixpo/plan.md`):

- Product in one paragraph
- **Ceremony** field
- Non-goals
- Chosen stack
- **Slice 0 scaffold** if greenfield (acceptance = official project opens/builds and check runs)
- UI spec pointer (`documents/ui/`) if there is a surface; **UI change-type** per slice
- Slices in order (each slice has acceptance + **Tests to add** + UI tokens/components touched + check that **runs tests**)
- Edge cases to handle in v1
- Test plan pointer (`.erixpo/test-plan.md`)
- Suggested extras the user did **not** ask for as a separate optional list

Show the plan. If you discovered extras, ask once. Then wait for **go** / approved.

Update `.erixpo/state.md` (not `state.yaml`) to `phase: planned`. On approval: `phase: approved`, then immediately load `erixpo-auto`.
