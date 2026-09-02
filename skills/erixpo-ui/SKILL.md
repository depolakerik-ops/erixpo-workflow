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

Read [ui.md](../erixpo/references/ui.md) first. Skip if there is no human-facing surface.

## Detect
Need this when LANGUAGE.md is missing and you will draw UI; user wants a new look / theme / animation / roundness / palette / type; screens drift; user said mockup or design spec.

## Create
1. Interview taste. Propose 2–3 directions. Wait unless they said you pick.
2. Research platform guide + kit.
3. Copy pack `templates/documents/ui/` into the project.
4. Fill real numbers. Write one mockup using the same tokens.
5. `.erixpo/ui-status.md` = draft, then approved on go.
6. Link INDEX.md. Record created files on init-manifest.

## Change
Edit tokens/motion/components first. CHANGELOG + mockups + grep the old value everywhere. No one-screen special case unless written as an exception.

## New screen
Row in screens.md + mockup with existing parts. New part → components.md same step. Then code.

## Never
Second kit. Hard-coded hex/radius/duration. New animation style on one page. Features in mockups the plan did not approve.
