# UI — detect, specify, then build

If the work has **no surface** (CLI-only, rename, research note, backend-only slice with no screen), skip this file and do not invent a design system.

If a human will **see or touch** something — site, app, dashboard, settings, email, slide, print, game HUD, terminal TUI — you do **not** invent pixels ad hoc.

The pivot is `documents/ui/`. That folder is the design language. Code copies it. Code does not freelance.

One home per fact:

| Fact | Home |
|---|---|
| Change-type protocol (`ui_change`) | this file |
| Banned tutorial defaults | [slop.md](slop.md) |
| Breakpoint **scale** (named tokens) | `documents/ui/tokens.md` |
| Layout grammar (nav, skeleton, compact vs regular) | `documents/ui/layout.md` |
| Token → platform theme_file | `documents/ui/mapping.md` |
| Voice / anti-slop list for **this** product | `documents/ui/LANGUAGE.md` |

Skills point here. Do not assume web.

## Detect (do this every time, including mid-feature)

Treat as UI work when any of these is true:

- The request names a screen, page, layout, button, form, animation, theme, brand, mockup, look, spacing, font, color, radius, shadow, dark mode
- Redesign, recompose, "sidebar → tabs", breakpoints, window size, size class, compact/regular, "make it consistent"
- The repo already has `documents/ui/` or visible templates/components
- The job type is landing, shop, SaaS, desktop, mobile, game, slides, print
- You are about to add or change a file a person looks at

Then load `erixpo-ui` if the language does not exist yet, or if they asked to change the language.

## Classify — set `ui_change`

After detect, set `ui_change` to **exactly one** of this enum (same names the skill dispatches on):

| `ui_change` | Means | First files | Not this |
|---|---|---|---|
| `create` | No language yet | copy templates, fill LANGUAGE + tokens + layout + mapping | skipping mockup/preview |
| `relanguage` | New direction / voice / density / brand | `LANGUAGE.md`, then tokens, layout, components, mockups/previews | a one-hex tweak |
| `retoken` | Color / type / space / radius / shadow / palette | `tokens.md` first, CHANGELOG, grep old values in `theme_file` **and** product code | special-casing one screen |
| `recompose` | Structure: nav pattern, grouping, "sidebar → tabs", rearrange hierarchy | `layout.md` + `screens.md` + components as needed | retokening; tokens usually unchanged |
| `reflow` | Breakpoints / compact vs regular / window size | `layout.md` breakpoint table, then every screen that needs a compact arrangement | a 720px HTML page pretending to be iOS |
| `remotion` | Durations, easing, what may move | `motion.md` first, then grep durations/easings | a new animation style on one page |
| `new-screen` | A surface that is not in `screens.md` | `screens.md` + mockup-or-native-preview + components row, then implement | inventing features in the mockup |
| `consistency` | Drift vs spec | audit vs tokens + layout; fix drift **or** update spec if drift is the new truth | averaging two looks silently |

**"Redesign" ≠ "change `--accent`".** If they said redesign and you only `retoken`, that is a fail. Redesign is `relanguage` (often with `recompose`). Pick the **widest** type that matches: `relanguage` > `recompose` > `reflow` > `retoken` > `remotion`. `new-screen` and `consistency` stay themselves.

Signals:

| They said | `ui_change` |
|---|---|
| new look, new brand, new voice, denser, "redesign" | `relanguage` |
| calmer blue, sharper corners, new typeface, palette | `retoken` |
| sidebar → tabs, regroup, new nav, rearrange | `recompose` |
| phone layout, iPad, window size, breakpoints, compact | `reflow` |
| less bounce, slower, no motion | `remotion` |
| add settings, extra page | `new-screen` |
| looks off, make it consistent | `consistency` |
| `documents/ui/` missing | `create` |

## Talk first (short)

Ask only what changes the look:

- Who looks at it?
- A reference they like (URL, app, PDF) — or "propose"
- Density: marketing / tool / native chrome
- Surface if not obvious (web, iOS, Android, macOS, Windows, TUI, slides, print)
- Existing kit in the repo? Use it. Do not invent a second one.

Propose **2–3 directions** + one default. At least one direction must not be the tutorial look **for this surface** ([slop.md](slop.md)). Wait unless they already said "you pick" or "just go".

Directions depend on surface, not only web aesthetics: HIG / Fluent / Material / editorial / tool / native chrome. Examples, not a locked menu: quiet editorial, dense operator console, native platform chrome, brutalist static, data tables, playful consumer.

## Before any product pixels

Create or refresh `documents/ui/`:

| File | Job |
|---|---|
| `LANGUAGE.md` | Voice, density, surface, platform guide, anti-slop list for **this** product |
| `tokens.md` | Color, type, space, radius, shadow, **breakpoint / size-class scale** — numbers |
| `layout.md` | Nav pattern, page skeleton, grid, density per breakpoint, what never moves |
| `mapping.md` | Token → CSS / SwiftUI / Compose / WinUI + `theme_file` path for this repo |
| `components.md` | Approved parts + states. New part = add here first |
| `screens.md` | Every surface + empty/error/loading/denied + compact vs regular |
| `motion.md` | What moves, how far, how long, what never animates |
| `mockups/` | Web: HTML using the **same tokens**, at least two widths. Native: see Mockups |
| `CHANGELOG.md` | Every token / layout / motion / mapping change + screens to update |

Also set `.erixpo/ui-status.md`: `draft` | `approved`.

`tokens.md` **must** include a breakpoint / size-class scale even if native uses compact/regular instead of px.

Do not implement a second screen until preview 1 exists **or** the user explicitly said skip mockups. Preview 1 is a two-width HTML mockup on web, or a native preview/screenshot (mapping.md) on native.

## Production-grade bar (not a vibe)

These are defaults. Platform guides and `USER.md` override them.

### Type

- One family for UI, optional second for display. Not three random Google fonts.
- A scale (e.g. 12 / 14 / 16 / 20 / 28 / 40) written in `tokens.md`. No magic `font-size: 17px` in a random file.
- Line-height and measure that fit the density (marketing vs table).
- Tabular numbers for data.

### Space

- A 4 or 8 point grid. Write the steps. Padding and gaps come from the scale, not "looks fine".
- Same inset on sibling cards. Same gap in a list. Inconsistency is a bug.

### Color

- Background, surface, text, muted, border, accent, danger, warning, success — named.
- Contrast: body text vs background must be readable (aim WCAG AA on platforms that care).
- Do not decorate every box with a different accent. One accent unless the brand is the product.
- Dark mode is a token set, not a later surprise, if the surface is an app people use at night.

### Shape and elevation

- **One** radius scale (e.g. 0 / 6 / 12 / full). Changing "roundness" means changing the token, then every component that uses it.
- Shadows: 0–3 levels. No new shadow per card.
- Hairline borders vs soft shadow — pick one language and keep it.

### Motion

- Duration scale (e.g. 120 / 200 / 320 ms). Easing written once.
- Motion explains a state change (open, success, error, page). It does not celebrate every click.
- Respect reduced-motion: hard cuts, no large parallax.
- List in `motion.md` what is allowed: fade, short slide, height, shared-element. Ban the rest (bounce-everywhere, infinite pulse, gradient swirl) unless the direction is playful and they approved it.

### Components

- Primary / secondary / ghost / danger buttons. One primary per view.
- Form: label, hint, error under the field, disabled.
- Empty / loading / error / permission-denied are first-class screens, not afterthoughts.
- Tap targets ~44px on touch. Keyboard focus visible on desktop.
- Do not add a new component that already exists under another name.
- Layout-sensitive parts (nav, split, tab bar) obey `layout.md`. Do not invent a second nav pattern.

### Breakpoints

- Named once in `tokens.md`. Grammar once in `layout.md`.
- No magic `@media 768` in a random file. No single 720px column as "responsive."
- Web: CSS using those named tokens. Native: adaptive stacks / size classes / window groups — **not** a 720px HTML page pretending to be iOS.

### Layout

- Grammar lives in `layout.md`. Do not freelance a new nav pattern on one screen.
- Compact and regular say what is primary and what never moves.

### Consistency

Before you ship a new screen, open `components.md` + `tokens.md` + `layout.md` and reuse. If you need a new part, add it to the spec in the same slice.

## Procedures

Same shape every time: **edit spec → changelog → previews → grep → all screens.** Do not special-case one screen unless they asked — then write the exception in `components.md` or `layout.md`.

### `retoken`

1. Edit `tokens.md` (and `motion.md` if duration/easing is involved).
2. Append `CHANGELOG.md` (`kind: token`) with what changed and which screens use it.
3. Update mockups / native previews.
4. Grep the old hex / radius / type size in `theme_file` **and** product code. Update every hit that belongs to the language.
5. Do not "just tweak this one card".

### `recompose`

1. Edit `layout.md` (nav, skeleton, grouping). Update `screens.md` rows whose hierarchy changed. Components only if a part is new or retired.
2. Append `CHANGELOG.md` (`kind: layout`).
3. Update previews at **both** compact and regular (web mockups; native preview if that is the surface).
4. Grep the old structure (nav labels, sidebar class, tab names, split containers).
5. Apply the new pattern on every screen that shares it. Tokens usually stay put.

### `reflow`

1. Edit `tokens.md` breakpoint / size-class scale if the numbers changed, then `layout.md` compact vs regular arrangements.
2. Append `CHANGELOG.md` (`kind: layout`).
3. Update every screen that needs a compact arrangement. Web mockups at both widths.
4. Grep magic widths, raw `@media`, hardcoded size-class checks.
5. All screens. Web: CSS. Native: size classes / window groups — not HTML.

### `relanguage`

Rewrite `LANGUAGE.md` (voice, density, anti-slop for this surface). Then tokens, layout, components, mockups/previews. Not a one-hex tweak. Then follow `retoken` + `recompose` greps as needed.

### `remotion`

`motion.md` first. CHANGELOG `kind: motion`. Update previews. Grep old durations / easings. Reduced-motion stays instant or short fade.

### `new-screen`

Add the screen + compact layout + regular layout + states to `screens.md`. Mockup (web, two widths) or native preview. New part → `components.md` in the same step. Then implement.

### `consistency`

Compare each visible screen to `tokens.md` + `layout.md`. List drift. Fix the code **or** update the spec if the drift is the new truth. Do not average two looks silently.

## Research

Search live docs for **this** surface and year. Do not default to "Tailwind + shadcn + purple gradient".

Write `.erixpo/research.md` `## UI`:

- Surface
- `ui_change`
- Platform guide
- Kit options + recommendation
- Breakpoints / size classes
- Empty / error / loading / denied
- What you will not do (from [slop.md](slop.md) for this surface)

## Mockups

HTML mockups are **not** the universal contract.

- **Surface web** (or docs site): `documents/ui/mockups/<screen>.html` that imports or inlines the token CSS from `tokens.md`. **At least two widths** (compact + regular) — not one 720px card. For web, that HTML is the visual contract. If the host can render images and the user asked for pictures, still keep the HTML/token mockup as source of truth — images go stale.
- **Surface ios / android / macos / windows:** do **not** treat HTML as source of truth. `mapping.md` is the contract: native `theme_file` + optional static preview (simulator screenshot, device photo, platform preview). HTML wire only if they asked **or** the host cannot preview native, and label it "wire, not production."
- No lorem ipsum unless the product is a marketing page.

## During implementation

- Tokens compile into **one** `theme_file` per platform (see `mapping.md`). Product views consume the theme, not raw hex. Hard-coded hex / radius / duration outside that file is a fail.
- Same slice as happy path: empty, error, loading, disabled when cheap. Else list as next slice. Do not ship spinner-forever.
- Contrast, targets, keyboard, screen reader on platforms that have them.
- Ban unless they asked: the tutorial default for **this** surface ([slop.md](slop.md)).

Taste in `.erixpo/USER.md` wins.
