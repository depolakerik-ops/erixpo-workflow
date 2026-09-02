---
name: erixpo-ui
description: Create or change the project design language. Use when the work has a visible surface, the user mentions look, layout, color, type, spacing, animation, radius, mockup, theme, or consistency, or when documents/ui/ is missing before pixels. Writes tokens, components, screens, motion, mockups. Token changes propagate; do not freelance one screen.
license: MIT
metadata:
  author: Erixpo
  version: "0.5.0"
---

# erixpo ui

The design language lives in `documents/ui/`. That folder is the pivot. Implementation copies it.

Read [ui.md](../erixpo/references/ui.md) first. Skip this skill if there is no human-facing surface.

## Detect

Need this skill when:

- `documents/ui/LANGUAGE.md` is missing and you are about to draw UI
- User wants a new look, theme, animation style, roundness, palette, type
- Screens already drift from each other
- User said mockup, wireframe, design spec, design system

## Create (first time)

1. Interview only what changes the look (audience, reference, density, existing kit). Propose 2–3 directions + default. Wait unless they said you pick.
2. Research the platform guide and kit ([ui.md](../erixpo/references/ui.md), [research.md](../erixpo/references/research.md)).
3. Copy templates from the pack `templates/documents/ui/` into the project's `documents/ui/`.
4. Fill real numbers. No "TBD purple".
5. Write at least one mockup for the primary screen (`documents/ui/mockups/`). Use the same tokens.
6. Set `.erixpo/ui-status.md` to `draft`. Show the language + mockup. On "go" / "yes" / "approved", set `approved`.
7. Link `documents/INDEX.md` → `ui/LANGUAGE.md`.
8. Add `documents/ui/` paths you created to `.erixpo/init-manifest.txt` if this is still init.

Do not start product chrome until `draft` exists. `approved` is preferred; "just go" allows draft + first slice together.

## Change (user moved the pivot)

Examples: "less round", "darker", "slower motion", "different font", "this button on every screen".

1. Name the token or component. Edit `tokens.md` / `motion.md` / `components.md` first.
2. Append `CHANGELOG.md` (what, why, screens).
3. Update mockups.
4. Grep the old value in product code. Update every hit that belongs to the language.
5. Do not special-case one screen unless they explicitly want an exception — then write the exception in `components.md`.

## New screen

1. Add the screen + states to `screens.md`.
2. Mock it with existing components. New part → add to `components.md` in the same step.
3. Then implement.

## Consistency audit

When they say it looks off, or before a review of UI work:

- Compare each visible screen to `tokens.md` (type scale, space, radius, color, motion).
- List drift. Fix drift or update the spec if the drift is the new truth.
- Do not "average" two looks silently.

## Never

- Second design system next to an existing kit
- Hard-coded hex / radius / duration outside the token file
- Ship a new animation style on one page
- Invent features in mockups that the plan did not approve
- Skip empty / error / loading if those states exist in the product
