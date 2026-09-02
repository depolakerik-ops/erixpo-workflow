# UI — detect, specify, then build

If the work has **no surface** (CLI-only, rename, research note, backend-only slice with no screen), skip this file and do not invent a design system.

If a human will **see or touch** something — site, app, dashboard, settings, email, slide, print, game HUD, terminal TUI — you do **not** invent pixels ad hoc.

The pivot is `documents/ui/`. That folder is the design language. Code copies it. Code does not freelance.

## Detect (do this every time, including mid-feature)

Treat as UI work when any of these is true:

- The request names a screen, page, layout, button, form, animation, theme, brand, mockup, look, spacing, font, color, radius, shadow, dark mode
- The repo already has `documents/ui/` or visible templates/components
- The job type is landing, shop, SaaS, desktop, mobile, game, slides, print
- You are about to add or change a file a person looks at

Then load `erixpo-ui` if the language does not exist yet, or if they asked to change the language.

## Talk first (short)

Ask only what changes the look:

- Who looks at it?
- A reference they like (URL, app, PDF) — or "propose"
- Density: marketing / tool / native chrome
- Existing kit in the repo? Use it. Do not invent a second one.

Propose **2–3 directions** + one default. At least one direction must not be the tutorial look (Inter / purple / three cards / untouched component-kit theme). Wait unless they already said "you pick" or "just go".

Directions are examples, not a locked menu: quiet editorial, dense operator console, native HIG/Fluent/Material, brutalist static, data tables, playful consumer.

## Before any product pixels

Create or refresh `documents/ui/`:

| File | Job |
|---|---|
| `LANGUAGE.md` | Voice, density, what "good" means here, anti-slop list |
| `tokens.md` | Color, type, space, radius, shadow, motion — numbers |
| `components.md` | Approved parts + states. New part = add here first |
| `screens.md` | Every surface + empty/error/loading/denied |
| `motion.md` | What moves, how far, how long, what never animates |
| `mockups/` | Clickable or static HTML using the **same tokens** |
| `CHANGELOG.md` | Every token/language change + screens to update |

Also set `.erixpo/ui-status.md`: `draft` | `approved`.

Do not implement a second screen until mockup 1 exists **or** the user explicitly said skip mockups.

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

### Consistency

Before you ship a new screen, open `components.md` + `tokens.md` and reuse. If you need a new part, add it to the spec in the same slice.

If the user changes a token ("sharper corners", "calmer blue", "less bounce"):

1. Edit `tokens.md` / `motion.md` first.
2. Append `CHANGELOG.md` with what changed and which screens use it.
3. Update mockups.
4. Update every implementation that referenced the old value. Grep the old hex / radius / duration.
5. Do not "just tweak this one card".

## Research

Search live docs for **this** surface and year. Do not default to "Tailwind + shadcn + purple gradient".

Write `.erixpo/research.md` `## UI`:

- Surface
- Platform guide
- Kit options + recommendation
- Empty / error / loading / denied
- What you will not do

## Mockups

Prefer `documents/ui/mockups/<screen>.html` that imports or inlines the token CSS from `tokens.md`. The mockup is the visual contract.

If the host can render images and the user asked for pictures, still keep the HTML/token mockup as source of truth — images go stale.

No lorem-ipsum marketing blocks unless the product is a marketing page.

## During implementation

- Tokens live in one place in code (CSS variables, theme file, Swift palette). Hard-coded hex in a random widget is a fail.
- Same slice as happy path: empty, error, loading, disabled when cheap. Else list as next slice. Do not ship spinner-forever.
- Contrast, targets, keyboard, screen reader on platforms that have them.
- Ban unless they asked: Inter-everywhere dashboard, three identical feature cards, fake testimonials, rainbow gradients, glassmorphism on every panel, autoplaying motion.

Taste in `.erixpo/USER.md` wins.
