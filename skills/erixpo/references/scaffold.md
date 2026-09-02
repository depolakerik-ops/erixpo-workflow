# Scaffold — this repo's boilerplate

How erixpo creates **this folder's** project skeleton. Not a public template zoo. Not `erixpo-ios` / `erixpo-android` skills — teach the official tool.

Greenfield protocol lives here. Ceremony (which wiki files) lives in [ceremony.md](ceremony.md). Classify surface from [domains.md](domains.md) and the interview. Do not assume web.

## Constitution (`.erixpo/CONSTITUTION.md`)

Required keys (fill from what is real):

- `surface`
- `layout` (where source, tests, resources, theme live)
- `theme_file` (native theme / CSS variables / none)
- `test_dir`
- `test_runner`
- `scaffold_cmd` (what was actually run, or `already existed`)
- `check` (must be a real command; dummy `echo` / `exit 0` / `true` forbidden)
- `install_in_worktree` (how a fresh worktree becomes runnable: `npm i`, `xcodebuild`, `uv sync`, …)
- `how_to_add_a_screen` (or `n/a`)
- `how_to_add_a_test`
- `do_not` (repo-specific)

Write constitution during **init** (if code already exists: describe it, do not invent) **or** as **slice 0** of new work, before product pixels.

`AGENTS.md` commands must be ones you verified or marked unverified.

## Greenfield (empty or nearly empty folder, request is a new product)

Slice 0, **required**, before UI chrome and before feature slices.

Acceptance: the official project opens/builds and `check:` runs.

1. Classify surface from [domains.md](domains.md) / interview. Do not assume web.
2. Research official **current-year** init for THAT surface. Write it in `.erixpo/research.md`.
3. Run the boring official tool. Examples, **not** a locked menu:
   - SwiftPM / iOS / macOS: `swift package init` or the Xcode project the user already has; never Vite.
   - Android / Kotlin: Gradle / Compose official init; never Playwright as primary.
   - Windows: `dotnet new` WinUI / WPF / WinForms as researched; not a React wrapper unless they asked.
   - Web: **only if** surface is web. Then research this year; include breakpoint grammar in `documents/ui/layout.md`.
   - Python script (product): `pyproject.toml` + pytest (or unittest) + a fixture; not Next.js.
   - Automation: script + sample fixture + check that exits 0 on the fixture.
   - Assistant / notes: folder layout + INDEX, no app stack.
4. Write a **real** `check:` into `.erixpo/stack.md` that RUNS tests or the class-appropriate proof. `echo ok` / `exit 0` / `true` are fails. Light writing only may use `n/a — human accepts artifact`.
5. If no test harness exists, **create it in slice 0**. Do not ask whether to have tests. Ask only if two harnesses are both reasonable.
6. Fill `CONSTITUTION.md` from what you actually created.
7. `AGENTS.md` commands: verified, or marked unverified.

Then feature slices. Visible work loads `erixpo-ui` only if there is a surface. HTML mockups only when surface is web (or last-resort wire). Native mapping is `documents/ui/mapping.md` (another agent).

## Existing repo

Map, do not re-scaffold. Constitution describes the real layout.

If tests are missing, slice 0 of the **next** feature/fix **adds the harness**, then the regression.

## Project-grown recipes

If a scaffold procedure is specific to this repo and >3 steps, draft `.erixpo/skills/<name>/SKILL.md` quarantined (`erixpo-learn`). Never copy a third-party skill without asking.

## Anti-patterns

- Generic web init on Swift, Android, notes, or a one-file script
- Platform skills (`erixpo-ios`, `erixpo-android`) instead of the official tool
- Dummy check to look green
- Asking "do you want tests?"
- Inventing a layout the files do not have
- Scaffolding an app because someone needed a script in a notes vault ([ceremony.md](ceremony.md) light)
