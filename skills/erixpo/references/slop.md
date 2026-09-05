# Anti-slop — tutorial defaults by surface

Use these examples to spot weak task fit, not as automatic failures for a font, color, or standard platform component. Judge whether a person can complete the intended task, understand hierarchy and states, use the interface accessibly, and recognize appropriate platform behavior. USER taste and existing design systems govern aesthetics. A familiar native control can be the best choice.

Stage-2 review judges UI against `documents/ui/LANGUAGE.md` + this file + `documents/ui/layout.md`, not a vibe.

The box is the tutorial default **for this surface**. Inter / purple / three cards is the **web** box, not the only box.

In a target repo, copy a short list into `documents/ui/LANGUAGE.md` (the pack path will not exist there). Ban unless they asked.

## web

**Tutorial default:** Inter or Geist everywhere, purple/indigo gradient hero, three identical feature cards, fake testimonials with stock avatars, glassmorphism on every panel, shadcn/ui theme left stock (zinc + violet), bounce on every button, one 720px centered card as "the app", blob mesh background, autoplaying carousel.

**Patterns to inspect for task fit:**

- Inter-everywhere as personality (system UI font is fine when it is the platform)
- Purple/violet gradient, rainbow mesh, glow orbs
- Three-column "feature / feature / feature" clones
- Fake quotes, fake logos, lorem ipsum on a product surface
- Glassmorphism / blur on every panel
- Stock shadcn / Tailwind UI palette and radius left untouched
- Bounce, scale-on-hover, or gradient swirl on every control
- A single max-width column called "responsive"

**Good tends to mean:** type and density that match the job (editorial marketing vs dense tool); one accent from the brand; real copy; breakpoints that **rearrange** (sidebar ↔ stack, inspector hides), not shrink; empty/error/loading as screens.

## ios (HIG / SwiftUI)

**Tutorial default:** system blue as brand tint, stock `List` + `NavigationStack` with no information hierarchy, SF Symbols used as decoration / empty-state illustration, every screen a `Form`, iPhone layout stretched to iPad, ignore compact vs regular, large title on screens that are not roots.

**Patterns to inspect for task fit:**

- `Color.accentColor` left as system blue when the product has a brand
- Every destination a grouped `List` / `Form`
- SF Symbols as hero art
- Ignoring size classes (compact vs regular) and window groups
- iPhone nav on iPad (no sidebar / split when the IA has peers)
- Custom controls that fight HIG (fake back chevrons, nonstandard tab bars) without a reason
- HTML mockup as the iOS source of truth

**Good tends to mean:** HIG navigation (tab bar for peers, stack for drill-in, sidebar on regular); brand tint in the asset catalog / theme; Dynamic Type; compact and regular layouts named in `layout.md`; native preview, not a 720px HTML page.

## android (Material / Compose)

**Tutorial default:** Material 3 baseline purple, every screen a lazy column of elevated cards, FAB on screens with no primary create action, ignore window size classes, no list-detail on large screens, dynamic color with no brand seed.

**Patterns to inspect for task fit:**

- Baseline purple / default M3 seed as the product identity
- Card-every-row
- Ignoring compact / medium / expanded window size classes
- Phone column stretched across a tablet / foldable / desktop window
- HTML as the Android source of truth

**Good tends to mean:** Material You with a brand seed; canonical large-screen layouts (list-detail, supporting pane); window size classes in `layout.md`; predictive back; empty/error in the same scaffold.

## macos (AppKit / SwiftUI)

**Tutorial default:** iOS layout on desktop — no inspector, no sidebar, no keyboard, settings as a pushed iOS `Form`, no menu bar items, no toolbar, one narrow column in a huge window.

**Patterns to inspect for task fit:**

- Phone nav (tab bar + stacked forms) as the Mac chrome
- Ignoring menus, toolbar, inspector, sidebar, keyboard shortcuts
- Ignoring window size / split view
- Touch-only hit targets with no key equivalents
- HTML as the Mac source of truth

**Good tends to mean:** `NavigationSplitView` (or AppKit equivalent), inspector for details, real menus + toolbar, settings as a settings window, keyboard first, layout that uses the width.

## windows (Fluent / WinUI)

**Tutorial default:** WPF default gray chrome, or a web wrapper with no Fluent; ignore snap / windowing; custom title bar that breaks caption buttons; leftover UWP style.

**Patterns to inspect for task fit:**

- Stock WPF look as the product identity
- A website in a WebView when the job is a Windows app
- Ignoring snap layouts, windowing, and Mica/Acrylic where Fluent expects them
- Navigation that does not use NavigationView / similar when the IA is an app
- HTML as the Windows source of truth

**Good tends to mean:** Fluent 2 / WinUI 3, NavigationView, snap-aware window, theme brushes from `mapping.md`, density that fits a resizable desktop window.

## tui

**Tutorial default:** rainbow truecolor, heavy Unicode art / box-drawing cathedrals, blocking spinners with no skip, emoji in every row, full-screen splash.

**Patterns to inspect for task fit:**

- Rainbow / 256-color decoration as identity
- Blocking spinner that cannot be skipped or Ctrl-C'd
- Heavy Unicode art that breaks in a 80×24 or non-UTF8 terminal
- Animation that fights `prefers-reduced-motion` / `NO_COLOR`

**Good tends to mean:** 16-color or one accent; skippable progress; keyboard-first; sparse chrome; readable in a small terminal.

## slides / print

**Tutorial default:** slideument (paragraphs on slides), tiny gray body text, decorative gradients, five fonts, clip-art icons, screenshots without a crop.

**Patterns to inspect for task fit:**

- Body text under ~18pt on a slide
- Gradient meshes and glass as decoration
- Wall of bullets that belong in a document
- Centered gray captions as the only hierarchy

**Good tends to mean:** one type family, one idea per slide, print-black (or brand ink) on paper, real margins, figures that carry the claim.
