---
name: erixpo-init
description: Initialize erixpo in a new or existing repository. Use when the user says erixpo init, set this project up, or when AGENTS.md and documents/ are missing. Maps the repo first, classifies its domain (software, automation, knowledge, assistant, mixed), then writes AGENTS.md, wiki, PROFILE/MEMORY/USER, and .erixpo state without overwriting blindly.
license: MIT
metadata:
  author: Erixpo
  version: "0.1.0"
---

# erixpo init

Run this on a greenfield folder or on a repo that already has code.

## Steps

1. **Map.** List languages, manifests, apps, tests, docs, CI, notes, scripts, workflows. Write `documents/inventory.md`. Quote evidence. Do not guess a stack the files do not support.

2. **Classify the repo domain** (software | site | automation | research | writing | ops | assistant | mixed | unknown). Write `.erixpo/PROFILE.md`. This is what makes later sessions specialized to *this* folder.

3. **Say what you understood** in chat, short. If domain or audience is ambiguous, one question.

4. **Create project brain** if missing, using templates from `.erixpo/pack-templates/` or this pack's `templates/`:
   - `AGENTS.md` — what this project is, how to run it, what is forbidden
   - `CLAUDE.md` containing only `@AGENTS.md`
   - `documents/INDEX.md` and `documents/progress.html`
   - `.erixpo/PROFILE.md`, `MEMORY.md`, `USER.md`, `lessons.md`, empty `learnings.jsonl` / `sessions.jsonl`
   - `.erixpo/state.md` with `phase: initialized`
   - `.erixpo/stack.md` with a `check:` line (may be a real test command or a document-acceptance command)

4. **Do not overwrite** a non-trivial existing README or AGENTS.md. Propose a diff. Merge facts.

5. **README.** If there is no README, write a short honest one. If there is one, leave it unless it is empty scaffolding.

6. After init, if the user already stated a goal in the same message, return to the erixpo router with that goal. Do not wait for them to type `/erixpo` again.

## AGENTS.md must contain

- One-paragraph product truth
- Install / run / test / lint commands you actually verified or marked unverified
- Directory map
- Invariants (never commit .env, never rewrite migrations casually, etc.)
- "erixpo lives here": pointer to `documents/` and `.erixpo/`

## Anti-patterns

- Do not dump a generic Next.js AGENTS.md onto a Swift repo, a notes vault, or a personal-ops folder.
- Do not create twenty empty wiki pages.
- Do not start coding features during init unless the user explicitly said to keep going.
- Do not assume the repo is a software product.
