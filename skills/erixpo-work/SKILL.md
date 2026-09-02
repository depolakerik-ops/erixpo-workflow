---
name: erixpo-work
description: General work inside this repo that is not building a product. Use when the user wants research, writing, ops, automation of a folder, personal-assistant tasks, notes, planning their work, or any non-product job specialized to this repository. Same loop as software — profile, memory, plan, do, check, learn — with a check command that fits the job.
license: MIT
metadata:
  author: Erixpo
  version: "0.2.0"
---

# erixpo work

Not every `/erixpo` is "build an app". This track is for work **in this repo** that is still real work: research, writing, automation, ops, assistant tasks, personal systems.

You still specialize to **this folder**. Read `.erixpo/PROFILE.md`, `.erixpo/MEMORY.md`, `.erixpo/USER.md`, `AGENTS.md`, and `documents/` first.

## When this track wins

- "summarize these notes"
- "automate the rename in /inbox"
- "draft the weekly update from documents/"
- "research X and file it in the wiki"
- "be my assistant in this repo"
- "plan my work for this project this week"
- any job where the artifact is not a new product stack

If they actually want a new app/site/script product, go back to **erixpo-new**.

## Loop

1. **Orient.** What is this repo for (PROFILE)? What does this human prefer (USER)? What is already true (MEMORY, wiki)?
2. **Clarify once.** Goal, artifact, "done looks like". Skip questions that do not change the work.
3. **Plan short.** Write `.erixpo/plan.md` with slices. Each slice has a check. For non-code jobs the check may be:
   - a script that exits 0
   - "file exists at path P and contains X"
   - "user accepted the draft"
   Write that check as `check:` in `.erixpo/stack.md` so `bin/erixpo` can run it when it is a command.
4. **Do one slice.** Update the wiki if the repo's knowledge changed.
5. **Verify.** Superpowers iron law: no completion claim without fresh evidence. Run the check or show the artifact.
6. **Learn.** If the procedure or preference is reusable, follow `erixpo-learn` (one JSONL line, not a novel).

## Job classes (write into PROFILE if missing)

| Class | Typical artifact | Typical check |
|---|---|---|
| automation | script, Makefile target, folder pipeline | the script exits 0 on a sample |
| research | `documents/` page with sources | page exists, claims are cited |
| writing | draft in repo | user accepted, or lint/spellcheck |
| ops | runbook, checklist, renamed files | command or file proof |
| assistant | notes, reminders file, structured inbox | file updated as specified |
| mixed | whatever PROFILE says | whatever PROFILE.check says |

## Rules

- Do not invent a SaaS stack for a writing repo.
- Do not create twenty empty wiki pages.
- Do not install MCP or third-party skills without asking.
- Secrets stay out of git.
- One worker unless files are disjoint.
