---
name: erixpo-ui
description: Create or change the project design language. Use when the work has a visible surface, the user mentions look, layout, breakpoints, color, type, spacing, animation, radius, mockup, theme, redesign, recompose, or consistency, or when documents/ui/ is missing before pixels. Classifies ui_change and dispatches (relanguage/retoken/recompose/reflow/remotion/new-screen/consistency). Writes tokens, layout, mapping, components, screens, motion, surface-appropriate previews. HTML mockups are for web; native uses mapping.md.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo ui

The design language lives in `documents/ui/`. That folder is the pivot. Implementation copies it.

Read [ui.md](../erixpo/references/ui.md) first (change-type protocol). Read [slop.md](../erixpo/references/slop.md) for this surface. Skip this skill if there is no human-facing surface. Do not assume web.

## Detect

Need this skill when:

- `documents/ui/LANGUAGE.md` is missing and you are about to draw UI
- User wants a new look, theme, animation style, roundness, palette, type, layout, breakpoints, redesign, recompose, "make it consistent"
- Screens already drift from each other
- User said mockup, wireframe, design spec, design system

After detect, set `ui_change` to the enum in [ui.md](../erixpo/references/ui.md):

`create` | `relanguage` | `retoken` | `recompose` | `reflow` | `remotion` | `new-screen` | `consistency`

Branch below. **"Redesign" ≠ `retoken`.** If they said redesign and you only change a hex, that is a fail. Never `retoken` when they asked to `recompose`.

## Create (first time)

`ui_change=create`

1. Infer look from USER + `like X` ([intent.md](../erixpo/references/intent.md)). Ask at most one question (reference or density) if still empty. Propose 2–3 directions + default for **this surface**. One must not be the tutorial look ([slop.md](../erixpo/references/slop.md)). Wait unless they said you pick / unattended.
2. Live-search **this year**: platform guide + **comparables** (2–3 similar apps on this surface, plus user-stated references). Intensity `full` ([research.md](../erixpo/references/research.md)). Write `.erixpo/research.md` Intent, Comparables, `## UI`.
3. Copy templates from the pack `templates/documents/ui/` into the project's `documents/ui/` (includes `layout.md` and `mapping.md`).
4. Fill real numbers. No "TBD purple". Include the breakpoint / size-class scale in `tokens.md`.
5. Write `layout.md` (nav, skeleton, compact vs regular) and `mapping.md` (`theme_file` path for this repo + token map).
6. Previews appropriate to surface:
   - web / docs site: HTML mockup using the same CSS variables as tokens, **at least two widths** (compact + regular)
   - ios / android / macos / windows: `mapping.md` is the contract; optional native preview/screenshot. HTML wire only if they asked or the host cannot preview native — label it "wire, not production."
7. Set `.erixpo/ui-status.md` to `draft`. Show the language + preview. On "go" / "yes" / "approved", set `approved`.
8. Link `documents/INDEX.md` → `ui/LANGUAGE.md`.
9. Add `documents/ui/` paths you created to `.erixpo/init-manifest.txt` if this is still init.

Do not start product chrome until `draft` exists. `approved` is preferred; "just go" allows draft + first slice together.

## Change (user moved the pivot)

Dispatch on `ui_change`. Full procedures live in [ui.md](../erixpo/references/ui.md). Same shape: **edit spec → changelog → previews → grep → all screens.**

### `relanguage`

New direction / voice / density / brand. Live-search comparables first (`research-scope --class ui --ui relanguage` → full). Rewrite `LANGUAGE.md` (anti-slop for this surface). Then tokens, layout, components, previews. Not a one-hex tweak.

### `retoken`

Color / type / space / radius / shadow / palette. Edit `tokens.md` first. CHANGELOG `kind: token`. Update previews. Grep the old value in `theme_file` **and** product code. Do not special-case one screen.

### `recompose`

Structure: nav pattern, grouping, "sidebar → tabs", rearrange hierarchy. Edit `layout.md` + `screens.md` + components as needed. Tokens usually unchanged. Never treat this as `retoken`.

### `reflow`

Breakpoints / compact vs regular / window size. Edit `layout.md` breakpoint table, then every screen that needs a compact arrangement. Web: CSS from named tokens. Native: adaptive stacks / size classes / window groups — not a 720px HTML page pretending to be iOS.

### `remotion`

`motion.md` first. CHANGELOG `kind: motion`. Grep durations / easings. Reduced-motion stays instant or short fade.

### `new-screen`

`screens.md` row (compact + regular + states) + mockup-or-native-preview + `components.md` row if a part is new, then implement.

### `consistency`

Audit vs `tokens.md` + `layout.md`. Fix drift or update the spec if drift is the new truth. Do not average two looks silently.

## Never

- Second design system next to an existing kit
- Hard-coded hex / radius / duration outside the token `theme_file` (`documents/ui/mapping.md`)
- Ship a new animation style on one page
- Invent features in mockups that the plan did not approve
- Skip empty / error / loading if those states exist in the product
- HTML as iOS / Android / macOS / Windows source of truth
- `retoken` when they asked to `recompose` or `relanguage`
