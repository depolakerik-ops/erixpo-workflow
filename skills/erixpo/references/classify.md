# Classify

Except for the explicit one-shot and maintenance exceptions below, every non-trivial `/erixpo` job writes `.erixpo/classify.md` **before** loading a track skill. This file is the protocol. Do not paste the schema into SKILL.md or routing.md.

Then infer meaning ([intent.md](intent.md)) and set live-search intensity:

```bash
.erixpo/bin/erixpo research-scope --class "$request_class" --ui "$ui_change"
```

`skip` → do not search the web. `narrow` / `full` → [research.md](research.md).

One-shot light work can proceed without persistent classify/init. For project or recurring work, run **init** when no populated `.erixpo/PROFILE.md` describes the project and keep the original sentence. The installed `.erixpo/` engine alone is not initialization. Pack-maintenance requests bypass product initialization.

If the template exists (`templates/.erixpo/classify.md` or `.erixpo/classify.md` empty-keyed), fill it. Do not invent extra keys.

## Schema (exact keys)

```
# Classify
ts:
repo_class: software | site | automation | research | writing | ops | assistant | mixed | unknown
request_class: init | new | feature | fix | review | ui | work | learn | search | auto | docs | uninstall | update
surface: none | web | ios | android | macos | windows | linux | tui | print | slides | mixed | other
ui_change: none | create | relanguage | retoken | recompose | reflow | remotion | new-screen | consistency
capabilities: (short: what this host/machine can actually run — Xcode, Android SDK, browser, shell-only, …)
isolation: worktree | in-place | ask
ceremony: full | standard | light
jobs:
  - <request_class>: <one-line intent>
evidence:
  - (quoted files/facts that justified repo_class and surface)
```

`request_class` is the job you are about to run (the first remaining `jobs:` entry). Remaining jobs stay in this file.

## 1. Repo

Classify **repo** from `.erixpo/PROFILE.md` + inventory evidence (lockfiles, `*.xcodeproj`, gradle, `*.sln`, `pyproject.toml`, notes, wiki, scripts). Quote those files under `evidence:`.

Do not guess a stack the files do not support. PROFILE `class` is the starting `repo_class`; inventory can correct it. See [domains.md](domains.md) for PROFILE — do not lock the router to it.

## 2. Request

Classify **request** from the user sentence. Repo class does not lock the request (a writing repo can still ask for a script).

Explicit alias in the message (`init`, `auto`, `feature`, `fix`, `review`, `docs`, `work`, `learn`, `search`, `ui`, `uninstall`, `update`) forces that `request_class` **after** you have classified repo, surface, capabilities, isolation, and ceremony.

Otherwise:

- Defect language (broken, crash, error, fail, typo, regression, "doesn't work") → `fix`
- Additive on a *known software* stack (add, implement, extra screen, extra endpoint) → `feature`
- Continue language (go, continue, keep going, resume, you have the plan) → `auto` **only** if `.erixpo/plan.md` status is `approved`
- Remove / uninstall / get rid of erixpo / "I don't want erixpo anymore" → `uninstall`
- Update / upgrade / refresh / reinstall **erixpo** / "there is a new erixpo update" → `update` (pack only; do not touch the product)
- Only docs / wiki / progress html / README → `docs`
- Remember / refine / save a skill / what did we learn → `learn`
- What did we do / find the session / search history → `search`
- New product / new platform / "I want to build" → `new`
- Non-product (automate, assistant, research this, draft, inbox, ops, "help me with" when it is not a product slice) → `work`

**Look** (do this while filling `request_class`, not by first synonym):

- "look at" / "look over" / "take a look" / "inspect" / "audit" → `review`, unless they also named theme / color / layout / mockup
- "look" + theme / spacing / font / color / animation / radius / mockup / design language / "make it consistent" → `ui`
- Bare "look" with no object → do **not** write a guessed `request_class`. One clarifying question. Never a command menu.

If both review-look and ui-look match, **ui** wins (they named a visual attribute). "look at this crash" (look-at + defect in the same noun phrase) → `fix`. Separate clauses ("redesign checkout and login is broken") → multiple `jobs:`.

## 3. Multi-intent

If the sentence contains more than one job (e.g. "redesign checkout and login is broken then keep going"), list **all** as `jobs:` in dependency order. Execute the first. Do not drop the rest.

```
jobs:
  - ui: redesign checkout
  - fix: login is broken
  - auto: keep going after those
request_class: ui
```

After the first job's check: remove or mark that job done, set `request_class` to the next entry, continue the queue or tell the user what is next. Remaining jobs in this file are not forgotten.

## 4. Surface and UI change-type

`surface` is where a human will see or touch the result. `none` if they will not. Use `other` for surfaces outside the listed examples (3D scene, animation, physical control panel), or `mixed` for multiple targets, and describe exact deliverables, runtime/platform and tools in `evidence`. These categories are routing metadata, not a list of supported projects. A framework such as Flutter, React Native or SwiftUI does not by itself establish the target platform.

For standalone graphics, film, 3D assets or physical behavior, visual output does not automatically mean application UI. Use `new` for a new project or `work` for an artifact task, set `ui_change: none` unless an interface itself changes, and apply domain-specific composition/motion/validation (domains.md).

`ui_change` only if a human will see a surface; otherwise `none`:

| Value | When |
|---|---|
| create | A surface exists and no usable design language exists; missing docs alone on an existing product does not force create (ui.md) |
| relanguage | redesign / new direction / "looks like a tutorial" / new brand |
| retoken | color, type, space, radius, palette, "calmer blue", "sharper corners" |
| recompose | layout structure, nav pattern, "sidebar to tabs", rearrange, recompose |
| reflow | breakpoints, mobile/desktop, adaptive layout, "doesn't work on small screens" |
| remotion | animation, bounce, duration, reduced-motion |
| new-screen | add a screen/page |
| consistency | drift / make it consistent |
| none | no visible change |

## 5. Capabilities

Detect from the **machine and repo**, not wishes. The bundled detector is only a starting inventory of common commands, not an exhaustive capability registry or a readiness test. Probe the actual domain tools needed (for example an authoring application, renderer, simulator, compiler or device connection), versions and a minimal usable operation. Include callable host tools/MCP and report missing capabilities honestly. Do not install or choose a different domain just because the detector lacks a tool.

Run, then paste the line into `capabilities:`:

```bash
.erixpo/bin/erixpo capabilities
# or
bash scripts/detect-capabilities.sh
```

For `request_class` / `ui_change` / the LOOK collision, run first (do not invent a first-match):

```bash
.erixpo/bin/erixpo classify look at the checkout
# or
python3 scripts/classify-signals.py "sidebar to tabs"
```

Treat the output as advisory hints. Correct them using explicit user intent and repository evidence, then fill repo/ceremony/isolation. Record the evidence for any correction; keyword matches cannot override an explicit platform or task.

If they want iOS and capabilities has no `xcodebuild`, say so here and do not pick Playwright as the iOS test story.

## 6. Ceremony

Set the field from [ceremony.md](ceremony.md). That file is the mapping. Do not invent a second one.

Quick check (ceremony.md wins on conflict): software + visible + multi-surface → `full`. Software CLI / library → `standard`. automation / script → `light`. writing / research / assistant / ops → `light` unless they asked for a product.

## 7. Isolation

- Dirty tree or unattended → `worktree`
- Tiny interactive on a clean tree → `in-place` allowed
- User said "do it here" → `in-place`
- Else → `ask`

See [worktrees.md](worktrees.md).

## 8. Skip a full write

Skip a **full** classify write only for:

- empty `/erixpo` that is clearly "continue auto on an approved plan"
- a one-line typo fix where PROFILE already exists
- **update erixpo** — do not write classify.md at all; load `erixpo-update` only.
- One-shot light work without persistent init — the request is the plan.

For other abbreviated classifications, write at least `ts`, `request_class`, and `jobs:` (one entry). Do not skip the file entirely on a non-trivial job.

## After writing

Load the track for `request_class` ([routing.md](routing.md)). Do not first-match a synonym in the sentence.
