---
name: erixpo-init
description: Initialize erixpo in a new or existing repository. Use when the user says erixpo init, set this project up, or when AGENTS.md and documents/ are missing. Maps the repo, classifies domain AND ceremony, writes AGENTS.md, a ceremony-sized wiki, PROFILE/MEMORY/USER, CONSTITUTION, and .erixpo state without dumping empty pages or overwriting blindly.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo init

Run this on a greenfield folder or on a repo that already has code.

Read [domains.md](../erixpo/references/domains.md), [ceremony.md](../erixpo/references/ceremony.md), [scaffold.md](../erixpo/references/scaffold.md), [wiki.md](../erixpo/references/wiki.md).

## Steps

1. **Map.** List languages, manifests, apps, tests, docs, CI, notes, scripts, workflows. Write `documents/inventory.md` from evidence. Quote. Do not guess a stack the files do not support.

2. **Classify domain AND ceremony.** Write `.erixpo/PROFILE.md` (`class`, `ceremony`, `surfaces`, `one_liner`, `check`). Ceremony is `full` | `standard` | `light` — pick from [ceremony.md](../erixpo/references/ceremony.md) (class × surface × request). Do not assume software or web.

3. **Say what you understood** in chat, short. If domain, surface, or audience is ambiguous, one question.

4. **USER.md.** If USER is empty, ask **2–3** working-style questions (not 20): (1) autonomy — ask / plan-then-go / unattended; (2) platforms they actually use; (3) visual-first vs code-first, **or** test strictness (pick the one that matches this folder). Fill the USER template; do not rewrite its shape (that template is owned elsewhere). If they say "you pick" / unattended / just go, write defaults: `plan-then-go`, `harness-required`, `always-stage-2`. Empty USER is not allowed after init.

5. **Create project brain** if missing, from `.erixpo/pack-templates/` or this pack's `templates/`. Copy **only what ceremony requires**. Other templates stay in pack-templates for later promotion.

   Always:
   - `AGENTS.md` — what this folder is for, how to run it, what is forbidden
   - `CLAUDE.md` containing only `@AGENTS.md`
   - `documents/INDEX.md` trimmed to files you actually create
   - `.erixpo/PROFILE.md`, `MEMORY.md`, `USER.md`, `lessons.md`, empty `learnings.jsonl` / `sessions.jsonl`
   - `.erixpo/state.md` with `phase: initialized` (canonical; do not write job state to `state.yaml`)
   - `.erixpo/CONSTITUTION.md` — if code exists, describe the real layout; do not invent. If the folder is empty, leave the keyed template for slice 0 of new work ([scaffold.md](../erixpo/references/scaffold.md))
   - `.erixpo/stack.md` with a `check:` line: a real command, or explicitly `n/a — human accepts artifact` for light writing jobs only. Dummy `echo` / `exit 0` / `true` are fails

   Then seed wiki per [ceremony.md](../erixpo/references/ceremony.md). Seed `documents/ui/` only if ceremony is **full** or a surface is visible.

6. **Do not overwrite** a non-trivial existing README or AGENTS.md. Propose a diff. Merge facts.

7. **README.** If there is none, write a short honest one. If there is one, leave it unless it is empty scaffolding.

8. After init, if the user already stated a goal in the same message, return to the erixpo router with that goal. Do not wait for them to type `/erixpo` again.

9. Write `.erixpo/init-manifest.txt` listing every file **you created** (not files that already existed). Uninstall `--purge-docs` may only delete names on that list plus `.erixpo/`. Never list the user's pre-existing README or source.

## AGENTS.md must contain

- One-paragraph **folder** truth (not "what this software is")
- Install / run / test / lint / check commands you actually verified or marked unverified
- Directory map
- Invariants: secrets, no unapproved deps, done = check, worktrees isolate, stage-2 different session, follow `CONSTITUTION.md`, ceremony in PROFILE, no `documents/ui/` dump on non-surfaces
- Pointer to `documents/` and `.erixpo/`

Stack section is optional if class is writing / assistant / research with no runtime.

## Anti-patterns

- Generic Next.js AGENTS.md on a Swift repo, notes vault, or personal-ops folder
- Twenty empty wiki pages
- Coding features during init unless they said keep going
- Assuming the folder is a software product or that the surface is web
- `echo ok` / `exit 0` / `true` as check
