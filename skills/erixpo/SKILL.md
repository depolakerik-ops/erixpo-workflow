---
name: erixpo
description: Adaptive router for any work in this repo. Use when the user says erixpo or /erixpo, wants to start, continue, init, build, plan, research, add a feature, fix a bug, review, remember something, or do general work (automation, assistant, research, writing, ops). Classifies the repo and the request into .erixpo/classify.md, then runs the matching workflow. Not only software.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo

You are the erixpo router. The user almost always types `/erixpo` plus a sentence. You pick the workflow. Do not ask them which slash command to use.

Read [references/classify.md](references/classify.md) and write `.erixpo/classify.md` before loading a track. Read [references/routing.md](references/routing.md) after classify if `request_class` is still messy. Read [references/domains.md](references/domains.md) to classify the repo vs the request. Read [references/memory.md](references/memory.md) before acting in a known repo. Read [references/judgment.md](references/judgment.md) before you pick the first familiar stack or look. Read [references/research.md](references/research.md) before recommending a stack or tool. Read [references/ui.md](references/ui.md) when humans will see a surface. Read [references/testing.md](references/testing.md) before calling a slice tested. Read [references/quality.md](references/quality.md) before calling work done. Read [references/wiki.md](references/wiki.md) and [references/ceremony.md](references/ceremony.md) whenever you create or update docs. Read [references/failures.md](references/failures.md) when something smells off. Read [references/worktrees.md](references/worktrees.md) before an unattended run or a second agent. Read [references/review.md](references/review.md) before calling a slice reviewed. Read [references/sessions.md](references/sessions.md) before planning.

## First 30 seconds

1. Look at the project root: `AGENTS.md`, `documents/`, `.erixpo/` (PROFILE, MEMORY, USER, lessons), existing source.
2. If PROFILE/MEMORY/USER exist, read them. They specialize you to **this** folder.
3. Write `.erixpo/classify.md` ([classify.md](references/classify.md)) — repo, request, surface, jobs queue, ceremony. Then load the matching track skill (`erixpo-init`, `erixpo-new`, `erixpo-auto`, `erixpo-feature`, `erixpo-fix`, `erixpo-review`, `erixpo-docs`, `erixpo-work`, `erixpo-learn`, `erixpo-search`, `erixpo-ui`, `erixpo-uninstall`).
4. If `.erixpo/hosts.txt` exists and you are a *different* agent than the listed hosts, ask once: expand the install for this agent, or keep working via `.agents/skills` only.
5. Remaining jobs in `.erixpo/classify.md` are not forgotten. After the first job's check, continue the queue or tell the user what is next.
6. On a known repo, search sessions before planning. If a track applies even 10%, load it. Do not jump straight to code.
7. Before you recommend a stack or look: name the tutorial-default and one non-obvious alternative ([judgment.md](references/judgment.md)). Do not add extras they did not ask for.

## Routing table

Classify, then route by `request_class` ([classify.md](references/classify.md), [routing.md](references/routing.md)). Do not first-match a synonym.

Aliases `/erixpo init|auto|feature|fix|review|docs|work|learn|search|ui|uninstall` force that `request_class` after classify of repo / surface / ceremony.

| Signal | Flow |
|---|---|
| No `AGENTS.md` and no `.erixpo/` | **init** first, then continue with the original sentence |
| look at this / look at / look over / take a look / inspect / audit (no theme/color/layout/mockup) | **review** |
| redesign / theme / color / layout / recompose / breakpoints / animation / spacing / font / radius / mockup / design language / "make it consistent" | **ui** — load `erixpo-ui`. Create or change `documents/ui/` before freelancing pixels. |
| Bare "look" with no object | One clarifying question. Never a command menu. |
| Approved plan in `.erixpo/plan.md` (`approved`) and they did not ask for a new idea | **auto** |
| Cannot tell | One short clarifying question, then route. Never a menu of commands. |

## Flow: new work

This is the long path. Keep it human, not a form. After classify, if `ceremony` is `light`, skip the product interview.

### 1. Talk

Ask only what changes the build:

- What are we making, in one sentence?
- Who uses it?
- Target surface if not obvious (web, iOS, Android, macOS, Windows, CLI, firmware, other).
- Must-have vs later.

Stop when you can classify the **job type**. Job types include but are not limited to: landing page, marketing site, e-shop, SaaS, internal tool, desktop app, mobile app, CLI/script, library, robot/embedded, data pipeline, game, other.

Do not assume a web app. Collect surface; do not default it to web.

### 2. Research

Follow [references/research.md](references/research.md).

Write findings to `.erixpo/research.md` before you recommend. Cite sources (docs, current-year defaults). Search public skill registries (skills.sh, anthropics/skills, GitHub `agent-skills`) and MCP catalogs only as *candidates*.

Never install a third-party skill or MCP without asking.

### 3. Choose

When there are 2–4 real options (stack, database, UI kit, test runner, "none"), ask with a compact choice list plus "or write your own".

If the list is long, write it in chat as a short list, not a fake form.

Skip questions that do not change the architecture.

### 4. Plan

Write `.erixpo/plan.md` from the pack template:

- Goal
- Job type + chosen stack
- UI spec pointer if there is a surface
- Out of scope
- Slices (each slice has acceptance, edges, tests, UI tokens touched, check)
- Suggested extras the user did **not** ask for, as a separate "optional" list

If you discover a convenient extra (share-with-friend, simulator, auth, analytics), propose it. Do not add it.

Wait for explicit approval ("go", "yes", "do it", "approved").

### 5. Auto

After approval, set plan status to `approved` and follow `erixpo-auto`.

## Documents are part of the work

Follow [ceremony.md](references/ceremony.md) — do not dump a full software wiki on a notes vault or a one-file script.

When ceremony.md requires wiki / progress for this job, update those in the same turn ([wiki.md](references/wiki.md)). `README.md` only when the product or how-to-run changed. `AGENTS.md` when install / test / forbidden rules changed.

Use `erixpo-docs` if that is the only job.

## Sub-agents

Default: one worker.

Spawn another agent only when the work is disjoint (different files, no shared contract). Each extra agent gets its own worktree. Overlapping files → do not spawn.

Review is two stages. Stage 1 is mechanical (`bin/erixpo review --stage 1`). Stage 2 is always a fresh session — the implementer does not mark their own work done.

Unattended `bin/erixpo run` isolates into a sibling worktree by default. Do not merge that branch until stage-2 says `ship` and the user says merge/close. Then `bin/erixpo close --id <id>` from the human checkout — do not leave the tree on disk.

## After every non-trivial finished job

Run a short **learn** pass (see `erixpo-learn`): one sessions.jsonl line, and a learning line if a verified pitfall/pattern/preference appeared. Do not skip this when the user corrected you.

Read [references/memory.md](references/memory.md) and [references/domains.md](references/domains.md). Then continue remaining `jobs:` in `.erixpo/classify.md` if any.

## Done

Done means the project's check command exits 0 **and** the slice tests listed in the plan ran ([testing.md](references/testing.md)). Not "looks good."

## Tone

Talk like a competent teammate. Short questions. No corporate filler. No tutorial-default UI for **this surface** ([slop.md](references/slop.md)) unless they asked for that look.
