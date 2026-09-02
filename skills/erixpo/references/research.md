# Research pass

Do this before recommending a stack. Write `.erixpo/research.md`.

## Order

1. Read what already exists: `AGENTS.md`, `documents/`, README, lockfiles, Xcode/Android/sln projects, `package.json`, `pyproject.toml`, `Cargo.toml`, `go.mod`. Prefer the repo's reality over a blog post.
2. Classify the **repo domain** and the **request** separately. A personal-ops folder does not get a web stack. A firmware repo does not get Tailwind. Read PROFILE.md first.
3. Search the live web for that job + current year:
   - official framework docs and current default tooling
   - test runners and how the platform actually tests (Playwright vs XCTest vs pytest vs robot sim)
   - UI quality sources for that surface (Apple HIG, Fluent, Material, web accessibility)
   - known footguns
4. Skill hunt (candidates only):
   - https://skills.sh
   - https://github.com/anthropics/skills
   - GitHub topic `agent-skills`
   Record name, URL, why it might help. Do not copy it in until the user says yes.
5. MCP hunt only if the job needs a surface the worker does not have (device simulator, browser, hardware). Same rule: propose, do not install.
6. Recommend 2–4 options with a default and a reason. Include "boring official default" as one option when it exists.

## Hard rules

- Landing page does not get a database "just in case".
- Robot / embedded does not get Tailwind.
- SwiftUI app does not get Playwright as the primary test story.
- Do not lock a stack because it was fashionable last year. Check this year.
- If research is thin, say so. Guessing is worse than one more question.


## Before you recommend

Search `.erixpo/learnings.jsonl` and MEMORY.md. If a prior pitfall applies, say `Prior learning applied` and do not re-recommend the failed path.

If you looked for a skill or MCP and found nothing good, append one line to `.erixpo/memory/gaps.md` or `.erixpo/refine-log.md`: what you searched, why nothing fit. That is how the pack learns holes without installing random GitHub skills.
