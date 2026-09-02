# Research pass

Live-search **this job, this year, this surface** — only when it is needed. Write `.erixpo/research.md`.

Agnostic: site, app, script, firmware, wiki, inbox, slide, assistant. Do not start from a web template.

Intensity: `bin/erixpo research-scope --class <request_class> --ui <ui_change>` → `skip` | `narrow` | `full` ([intent.md](intent.md) first).

## Needed?

| Intensity | When | Do |
|---|---|---|
| **skip** | Typo, rename, known-stack feature with no new API, `retoken` / `consistency`, continue auto, MEMORY already answers | Do not search. One line in refine-log if you almost searched. |
| **narrow** | One new library/API, `reflow` / `remotion` / `new-screen`, user said “like X”, work that needs a tool | Official docs for *that* thing + 1 comparable if they named a reference. Cap: a handful of searches. |
| **full** | New product, new surface, scaffold, `relanguage` / `recompose` / `create` UI | Stack + official init + comparables + practices + tests + judgment four lines. |

If intensity is `skip`, stop reading this file.

## Order (narrow and full)

1. **Repo first.** `AGENTS.md`, CONSTITUTION, PROFILE, USER, lockfiles, Xcode/Android/sln, `package.json`, `pyproject.toml`. Prefer the folder over a blog.
2. **Intent.** What they mean, `like X`, URLs ([intent.md](intent.md), [classify.md](classify.md)).
3. **Memory.** `MEMORY.md` / learnings.jsonl. `Prior learning applied` if a pitfall exists — that can downgrade full → narrow or narrow → skip.
4. **Live-search this calendar year** (not training memory, not 2019 Medium):
   - **full:** language, official scaffold ([scaffold.md](scaffold.md)), framework or none, data store or none, platform UI guide ([ui.md](ui.md), [slop.md](slop.md)), test runner ([testing.md](testing.md)), lint, deploy only if they asked to ship
   - **narrow:** only the unknown API / the named reference / the one UI change-type
5. **Comparables** (full, or narrow when they named a reference, or UI `relanguage` / `recompose`):
   - 2–3 similar products, apps, or repos **for this surface and job**, current year
   - User-stated `like X` always in the list
   - Steal structure/density/nav. Do not steal brand, copy, or a web kit onto native
   - Cite URLs
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
