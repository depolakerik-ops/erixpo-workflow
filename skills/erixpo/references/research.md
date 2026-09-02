# Research pass

Do this before recommending tools, a stack, or a UI kit. Write `.erixpo/research.md`.

Agnostic: the job might be a site, an app, a script, firmware, a wiki, an inbox pipeline, a slide deck. Research *that* job. Do not start from a web template.

## Order

1. Read what already exists: `AGENTS.md`, `documents/`, README, lockfiles, Xcode/Android/sln, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`, Makefiles. Prefer the repo over a blog post.
2. Classify **repo domain** and **request** separately. Read PROFILE.md.
3. Live-search this year for each decision that would be expensive to undo:
   - language / runtime
   - app framework or "none"
   - data store or "none"
   - UI kit / platform guide (see [ui.md](ui.md))
   - test runner and how this surface is actually tested (see [testing.md](testing.md))
   - lint/format/typecheck
   - build / package / deploy if they asked to ship
   - official docs + current default tooling + known footguns
4. Skill hunt (candidates only): skills.sh, anthropics/skills, GitHub `agent-skills`. List, do not install.
5. MCP hunt only if the worker lacks a needed surface (browser, simulator, hardware). Propose, do not install.
6. Recommend 2–4 options with a default and a reason. Always include "boring official default" when it exists. Always include "do nothing extra" when a database/UI kit/SaaS is optional. Always include one **non-obvious** option that could win *for this user* ([judgment.md](judgment.md)). If it loses, write why.

## Tools section in research.md

```
## Tools
- Build:
- Test:
- Lint:
- UI:
- Deploy:
- Why these and not the fashionable alternative:
```

Cite current-year sources. If research is thin, say so.

## Hard rules

- Landing page does not get a database "just in case".
- Robot / embedded does not get Tailwind.
- SwiftUI app does not get Playwright as the primary test story.
- Writing / ops repos do not get a SaaS stack.
- Do not lock a stack because it was fashionable last year.
- Search MEMORY.md / learnings.jsonl first. `Prior learning applied` if a pitfall exists.

If you looked for a skill or MCP and found nothing, one line in `.erixpo/refine-log.md`: what you searched, why nothing fit.
