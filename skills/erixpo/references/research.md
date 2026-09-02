# Research pass

If it is **building** something, live-search **this field, this year**. Field does not matter: SwiftUI, Kotlin, Windows, a Python script, an automation, a slide, an inbox pipeline. Do not start from a web template. Write `.erixpo/research.md`.

Intensity: `bin/erixpo research-scope --class <request_class> --ui <ui_change>` → `skip` | `narrow` | `full` ([intent.md](intent.md) first).

## Needed?

| Intensity | When | Do |
|---|---|---|
| **skip** | Not building: typo/fix, review, search history, learn, uninstall, docs-only | No web. |
| **narrow** | **Any build that is not a new product:** feature, auto slice, work/script/automation, UI retoken/reflow/new-screen | Official current-year docs **for this field** + 1–2 similar things (apps, repos, pipelines, posts) for *this* job. Cite URLs. |
| **full** | New product, new surface, scaffold, UI `create` / `relanguage` / `recompose` | Stack + official init + 2–3 comparables + practices + tests + judgment four lines. |

Building always researches. A “known stack” feature still gets a **narrow** pass for *that feature* in *that field* (how share-sheet is done on iOS this year, how Compose navigation is done, how pytest fixtures look now). MEMORY can shorten the search; it cannot skip it.

If intensity is `skip`, stop reading this file.

## Order (narrow and full)

1. **Repo first.** `AGENTS.md`, CONSTITUTION, PROFILE, USER, lockfiles, Xcode/Android/sln, `package.json`, `pyproject.toml`. Prefer the folder over a blog.
2. **Intent.** What they mean, `like X`, URLs ([intent.md](intent.md), [classify.md](classify.md)).
3. **Memory.** `MEMORY.md` / learnings.jsonl. `Prior learning applied` if a pitfall exists — that can downgrade full → narrow or narrow → skip.
4. **Live-search this calendar year** (not training memory, not 2019 Medium):
   - **full:** language, official scaffold ([scaffold.md](scaffold.md)), framework or none, data store or none, platform UI guide ([ui.md](ui.md), [slop.md](slop.md)), test runner ([testing.md](testing.md)), lint, deploy only if they asked to ship
   - **narrow:** official docs + similar work **in this field** (not a random web stack). Cap: a handful of searches.
5. **Comparables** (always on **full**; on **narrow** at least 1–2 similar things for this field + any `like X`):
   - User-stated `like X` always in the list
   - Steal structure/density/nav. Do not steal brand, copy, or a web kit onto native
   - **Opened, not named.** Cheap fail: a list of app names. Each hit:

```
- opened: https://… — one sentence actually learned
```

If you could not fetch: `could not open: …`. Do not invent. ([craft.md](craft.md))
6. Skill hunt (candidates only) on **full**. MCP hunt only if the worker lacks a surface (browser, simulator). List, do not install.
7. Recommend. Always: boring **official default** when it exists. Always: “do nothing extra” when a database/UI kit is optional. Always: one **non-obvious** option for *this user* ([judgment.md](judgment.md)). If it loses, write why.

## Autonomy after research

- `ask-every-slice`: 2–4 options, wait.
- `plan-then-go` / empty USER: pick the official default, write why, show the plan, wait for **go** on new work.
- `unattended` / “you pick” / “just go”: pick the official default and proceed. No optional extras. No second design system.

Cite current-year sources. If research is thin, say so — then still pick official default, do not freeze.

## research.md sections

```
## Intent
## Scope
intensity: skip | narrow | full
## Comparables
- (user-stated) …
- (found) name — url — what to steal / what not to copy
## Tools
## Outside the box
## Recommendation
## Rejected
```

Skip unused sections on a **narrow** pass. **skip** writes nothing except maybe refine-log.

## Hard rules

- Landing page does not get a database "just in case".
- Robot / embedded does not get Tailwind.
- SwiftUI / Android / Windows / macOS do not get a web scaffold unless the surface is web.
- SwiftUI app does not get Playwright as the primary test story.
- Writing / ops / assistant repos do not get a SaaS stack.
- Do not lock a stack because it was fashionable last year.
- Do not search “best app ideas 2026” for a one-line typo.
- Greenfield: official init, then slice 0 **runs** it ([scaffold.md](scaffold.md)).
- Comparables are references, not a license to clone.

If you looked for a skill or MCP and found nothing, one line in `.erixpo/refine-log.md`: what you searched, why nothing fit.
