---
name: erixpo-feature
description: Add a feature to an existing erixpo-managed project. Use when the user says erixpo feature or wants to add something to a known stack. Short interview, update the plan and wiki, then build with the same quality bar. Does not re-research the whole stack unless the feature forces it.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo feature

The stack is already known. Do not restart the whole product interview.

## Steps

1. Read `AGENTS.md`, `documents/INDEX.md`, `.erixpo/stack.md`. Read `.erixpo/classify.md` if present, `.erixpo/CONSTITUTION.md` if present. If the work is visible, read `documents/ui/`.
2. Ask only what this feature needs (who it's for, must-have behaviour, anything it must not break). Missing spec → load `erixpo-ui` and write it. Existing spec → reuse tokens/components. New screen → `screens.md` + mockup before code. Token change → changelog + grep ([ui.md](../erixpo/references/ui.md)).
3. If `ui_change` is `recompose` / `reflow` / `relanguage`, load `erixpo-ui` **with that type**. Do not only retoken.
4. Research **only if needed** (`bin/erixpo research-scope --class feature`). Known stack + no new API → skip. New library/API or they said “like X” → **narrow** live-search ([research.md](../erixpo/references/research.md)). Relanguage/recompose → full comparables. If the test harness is missing, **create it** ([testing.md](../erixpo/references/testing.md)) — do not ask whether to have tests. New dependency: ask unless USER is unattended / they said you pick — then official default and record why.
5. Write a short feature plan with slices, edge cases, tests to add, and UI change-type. Optional extras stay optional.
6. Get approval if the change is more than a couple of files. Tiny adds: one-paragraph restatement, then go.
7. Build: implement → tests in the same slice → self-review ([quality.md](../erixpo/references/quality.md)) → `check:` that runs those tests → wiki per ceremony ([wiki.md](../erixpo/references/wiki.md), [ceremony.md](../erixpo/references/ceremony.md) if present).
8. Update README only if a user-facing capability or run step changed.
