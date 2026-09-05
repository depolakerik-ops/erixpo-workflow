# Ceremony — how much wiki this job gets

One home for the mapping. Skills point here. Do not copy twenty empty pages. A Python script does not get a SaaS wiki.

`PROFILE.ceremony` is `full` | `standard` | `light`. Pick it from **class × surface × request**. User override in PROFILE wins after you say what you understood.

When ceremony **upgrades**, copy the newly required files from `.erixpo/pack-templates/`. Do not downgrade silently.

## Domain adaptation

For projects outside the example rows, apply domains.md: choose ceremony by complexity, coordination and verification needs. Standalone graphics/3D/animation normally use standard source/asset, research, plan and validation/export records; a one-shot artifact can remain light. Full research does not automatically mean full app documentation. Robotics/embedded projects add hardware interfaces, simulation and validation records as needed. Create application UI specs only when an interface exists. The rows below are defaults, not a domain allowlist.

## How to pick (first match)

1. One-shot notes, rename, file-into-folder, summarize, "just this paragraph" → **light**.
2. Class is `writing` | `research` | `ops` | `assistant` | `automation` and the request is **not** a new product → **light**.
3. New **product** (or class `software` | `site`) with a human-visible surface — especially multi-breakpoint web or native app (iOS, Android, Windows, macOS, desktop), game, or TUI-as-the-product → **full**.
4. New product that is CLI, library, backend-only, API, or a **single-script product** → **standard**.
5. Feature / fix / ship on a repo that already has `PROFILE.ceremony` → keep it, unless this request **adds** a visible surface (then upgrade).
6. `mixed`: classify the **request's** surface, not the folder's history.
7. Script **inside** a notes/ops repo (helper, not a product) → **light** harness, not standard, not an app.

## Table

| class | surface | request | ceremony |
|---|---|---|---|
| software, site | web (multi-breakpoint), ios, android, windows, macos, desktop, game, tui-as-product | new-product, feature, ship | full |
| site | web landing / docs site / shop / SaaS UI | new-product, feature, ship | full |
| software | cli, library, backend, api | new-product, feature, ship | standard |
| software | single-script **product** | new-product, feature | standard |
| software, site | (PROFILE already set) | fix, small feature | PROFILE.ceremony |
| automation | script, folder pipeline | work, helper-script | light |
| writing, research, ops, assistant | notes, wiki, inbox | any non-product | light |
| any | notes, inbox | one-shot | light |
| any | (none yet) | new-product + visible surface | full |
| any | (none yet) | new-product + CLI/script product | standard |
| mixed | use the request's surface | use the request | that row |

## Artifacts

For a one-shot light artifact, use the current request as the plan and deliver the artifact with its evidence; do not require init, a constitution, USER interview, or persistent files. Create persistent context when the user asks to initialize the folder, work recurs, or a handoff requires it. The always list below applies to explicit initialization and recurring work.

Init copies **only** these from pack-templates. Everything else stays in `.erixpo/pack-templates/` until ceremony upgrades. Rewrite `documents/INDEX.md` so it links only files that exist.

### Always (every ceremony, including light)

- `AGENTS.md`, `CLAUDE.md` (`@AGENTS.md`)
- `documents/INDEX.md` (short for light)
- `documents/inventory.md` — from the map, evidence only; omit on a truly empty greenfield if there is nothing to quote
- `.erixpo/PROFILE.md`, `MEMORY.md`, `USER.md`, `lessons.md`, `learnings.jsonl`, `sessions.jsonl`
- `.erixpo/state.md` (canonical; not `state.yaml`)
- `.erixpo/CONSTITUTION.md` (keyed; fill in init if code exists, else slice 0)
- `.erixpo/stack.md` with a real `check:` — or `n/a — human accepts artifact` for **light writing only**

MEMORY / USER are required even for light.

### full

Software/site with a human-visible surface (especially multi-breakpoint or native).

- `documents/INDEX.md`, `PRODUCT.md`, `STACK.md`, `DECISIONS.md` **when a choice exists**, module pages **as they appear**, `progress.html` only after the first real slice
- **No empty `ARCHITECTURE.md`.** Write it when there are modules in the code, not at init.
- `documents/ui/LANGUAGE.md` only at init (voice + surface + anti-slop). Copy tokens/layout/mapping/mockups **in the first UI slice when numbers are real**. Blank token tables are not a design system ([craft.md](craft.md)).
  - Web: two-width HTML mockups using those numbers.
  - Native: `mapping.md` + theme_file. Not HTML as source of truth.
- `.erixpo/research.md`, rich `plan.md`, `test-plan.md`, `CONSTITUTION.md`
- Test harness + per-slice tests (harness in slice 0 if missing)
- Stage-2 review on ship ([review.md](review.md))

### standard

CLI, library, backend-only, single-script product.

- `documents/INDEX.md`, `STACK.md`, `DECISIONS.md` **if a choice was made**, `progress.md` (`.erixpo/progress.md`; `documents/PROGRESS.md` if you keep a human copy)
- **No** `documents/ui/` unless a TUI or docs site appears (then upgrade or add that surface)
- `.erixpo/research.md` (stack + test), `plan.md`, `test-plan.md`, `CONSTITUTION.md`
- Harness + tests
- `ARCHITECTURE.md` **only if** there are already >1 modules
- Stage-2 required before merging an isolated branch or claiming a reviewed software ship (review.md); no wiki dump. Light artifact delivery uses its domain-appropriate check and self-review

### light

Automation, writing, research, ops, assistant, one-shot notes.

- `documents/INDEX.md` (short), the artifact itself, PROFILE check
- **No** `ARCHITECTURE.md`, **no** `documents/ui/`, **no** `progress.html` required
- `plan.md` may be short: goal, slices, check
- Tests = PROFILE check and/or one fixture script
- If they need a script here: tiny Python/shell harness (script + sample fixture + check that exits 0 on the fixture). Not an app.

## Wiki during a slice

Every behaviour-changing slice updates wiki **as this file requires**. See [wiki.md](wiki.md).

- `progress.html` only if ceremony is full **or** the file already exists.
- Do not invent architecture the code does not have.
- Do not create empty `ARCHITECTURE.md` for light jobs.

## Init rule

Init MUST NOT copy twenty empty wiki pages. Seed the ceremony set only. Promote from pack-templates later if the job grows a surface.
