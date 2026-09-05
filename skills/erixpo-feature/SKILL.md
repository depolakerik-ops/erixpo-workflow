---
name: erixpo-feature
description: Add a feature to an existing erixpo-managed project. Use when the user says erixpo feature or wants to add something to a known stack. Short interview, update the plan and wiki, then build with the same quality bar. Does not re-research the whole stack unless the feature forces it.
license: MIT
metadata:
  author: Erixpo
  version: "0.7.0"
---

# erixpo feature

The stack is already known. Do not restart the whole product interview.

## Steps

1. Read `AGENTS.md`, `documents/INDEX.md`, `.erixpo/stack.md`. Read `.erixpo/classify.md` if present, `.erixpo/CONSTITUTION.md` if present. If the work is visible, read `documents/ui/`.
2. Ask only what this feature needs (who it's for, must-have behaviour, anything it must not break). Missing spec → inspect existing UI code/kit first; for a small change, minimally document and reuse its current pattern (see the existing-product exception in [ui.md](../erixpo/references/ui.md)). Load `erixpo-ui` for a new or changed design language. Existing spec → reuse tokens/components. New screen → `screens.md` + surface-appropriate mockup or native preview. Token change → changelog + grep ([ui.md](../erixpo/references/ui.md)).
3. If `ui_change` is `recompose` / `reflow` / `relanguage`, load `erixpo-ui` **with that type**. Do not only retoken.
4. Size the work from repository impact: a small local feature can use one slice and verified existing evidence; a large feature introducing a subsystem, architecture/data-ownership change, or several dependent user journeys needs a multi-slice plan, integration/migration and rollback considerations, and full research (`research-scope --class feature --large-change`). Keep the existing platform unless the feature requires otherwise. Resolve evidence gaps using [research.md](../erixpo/references/research.md); reuse verified version-matched sources when sufficient. Create a missing test harness when the behavior needs it ([testing.md](../erixpo/references/testing.md)). Dependency and decision handling follows [intent.md](../erixpo/references/intent.md).
5. Write a short feature plan with slices, edge cases, tests to add, and UI change-type. Optional extras stay optional.
6. Follow the autonomy table in intent.md. Existing authorization applies across the approved feature; file count alone does not require another approval.
7. Build: implement → tests in the same slice → self-review ([quality.md](../erixpo/references/quality.md)) → `check:` that runs those tests → wiki per ceremony ([wiki.md](../erixpo/references/wiki.md), [ceremony.md](../erixpo/references/ceremony.md) if present).
8. Update README only if a user-facing capability or run step changed.
