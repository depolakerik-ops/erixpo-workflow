# Routing rules

Use this when `/erixpo` input is messy.

## Priority (first match wins)

1. Missing project brain (`AGENTS.md` absent and `.erixpo/` absent) → init, keep the original user sentence for after init.
2. Explicit alias in the message: init, auto, feature, fix, review, docs, work, learn, search, ui, uninstall.
2b. Look / theme / mockup / design language / spacing / font / color / animation / radius / "make it consistent" → **ui** (`erixpo-ui`). Write or change `documents/ui/` first.
3. Memory language: remember, don't do that again, save this as a skill, what did we learn → learn.
3b. History language: what did we do, find the session, prior run, search history → search.
4. Defect language: broken, crash, error, fail, typo, regression, "doesn't work" → fix.
5. Audit language: review, audit, inspect, look at, quality, slop, dead code → review.
6. Additive language on a known *software* stack: add, implement, extra screen, extra endpoint → feature.
7. Continue language: go, continue, keep going, resume, you have the plan → auto.
8. Remove / uninstall / get rid of erixpo / "I don't want erixpo anymore" → **uninstall** (`erixpo-uninstall`). Ask pack-only vs memory vs everything. Never delete product source.
9. Non-product work: automate, assistant, research this, draft, inbox, ops, "help me with" when it is not a product slice → work.
10. Otherwise → if PROFILE domain is software, new work. If PROFILE is assistant/knowledge/automation, work. If unknown, one question.

## Do not

- Do not show a command menu.
- Do not run research for a one-line typo fix.
- Do not run the full new-product interview for "add a logout button" when `documents/` already names the stack.
- Do not start auto if the plan is still `draft`.
- Do not start auto on a dirty human checkout without isolate or an explicit "do it here".
- Do not uninstall by deleting the whole project. Load `erixpo-uninstall` and ask.
- Do not install skills into every vendor folder. Detect the current agent. Expand later if they switch CLI.
