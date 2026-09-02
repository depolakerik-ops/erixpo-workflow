---
name: erixpo-feature
description: Add a feature to an existing erixpo-managed project. Use when the user says erixpo feature or wants to add something to a known stack. Short interview, update the plan and wiki, then build with the same quality bar. Does not re-research the whole stack unless the feature forces it.
license: MIT
metadata:
  author: Erixpo
  version: "0.1.0"
---

# erixpo feature

The stack is already known. Do not restart the whole product interview.

## Steps

1. Read `AGENTS.md`, `documents/INDEX.md`, `.erixpo/stack.md`.
2. Ask only what this feature needs (who it's for, must-have behaviour, anything it must not break).
3. If the feature implies new infrastructure (first database, first payments, first simulator), do a **narrow** research pass and ask before adding it.
4. Write a short feature plan into `.erixpo/plan.md` (or a sibling `.erixpo/features/<slug>.md`) with slices, edge cases, and optional extras.
5. Get approval if the change is more than a couple of files. Tiny adds can proceed after you restate the plan in one paragraph.
6. Build like auto: one slice, wiki update, check, next.
7. Update README only if a user-facing capability or run step changed.
