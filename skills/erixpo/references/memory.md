# Memory and self-improvement

Chat is not memory. The repo is.

## Layers

| Layer | File | Job | Bound |
|---|---|---|---|
| Identity of the repo | `.erixpo/PROFILE.md` | What this folder is for | short |
| Project facts | `.erixpo/MEMORY.md` | Conventions, quirks, tool gotchas | ~80 lines |
| Human | `.erixpo/USER.md` | Adaptation engine: how this person wants to work *here* | ~40 lines |
| Typed lessons | `.erixpo/learnings.jsonl` | pattern/pitfall/preference/… | append-only |
| Sessions | `.erixpo/sessions.jsonl` | what we did | append-only |
| Loop notes | `.erixpo/lessons.md` | mistakes this run already made | short |
| Procedures | `.erixpo/skills/` | project-grown SKILL.md | quarantined first |
| Immutable | pack `skills/erixpo*` | the methodology | never edit in a target repo |

Inspired by Hermes (USER vs MEMORY vs skills), Prime `/refine` (smallest evidence-backed edit + rollback), GSTACK `/learn` (typed JSONL + inject), GSD `LEARNINGS.md` + `STATE.md`, BMAD memlog. Implemented as files so any agent can read them.

## Inject at the start of every job

Before acting, read in this order:

1. `AGENTS.md`
2. `.erixpo/PROFILE.md`
3. `.erixpo/USER.md`
4. `.erixpo/MEMORY.md`
5. `CONSTITUTION.md` if present (repo root or `.erixpo/`)
6. Grep `.erixpo/learnings.jsonl` for the files you are about to touch and for the job class
7. `classify.md` if present (`.erixpo/` or pack-templates)
8. Then the plan / wiki

When a learning changes what you do, say:

`Prior learning applied: <key> — <insight>`

## USER.md specializes the run

USER.md is not a biography. Its fields change behavior:

| Field | Effect |
|---|---|
| Autonomy | `ask-every-slice` pause after each green slice; `plan-then-go` keep slicing after approval; `unattended` same quality bar, prefer `bin/erixpo run` |
| Platforms | Build for what they actually use. Do not add a surface they do not have |
| Visual | `visual-first` → spec/mockup before chrome; `code-first` still follows `documents/ui/` when there is a surface |
| Mockups | `required` / `skip-if-said` / `never` |
| Test strictness | `harness-required` create a harness; `best-effort` still write tests when a runner exists. Never skip tests as a courtesy |
| Review | `always-stage-2` / `skip-tiny` |
| Taste, hard nos | Win over ui.md defaults |

## Write rules

- Evidence from this repo, or the user said it.
- One insight per JSONL line. No essays.
- Patch MEMORY/USER. Do not rewrite.
- Log every refine in `.erixpo/refine-log.md` so a bad memory can be reverted.
- No secrets, tokens, or private messages.
- Prune a line that would not change behavior if deleted (BMAD test).
- Do not invent memories about `CONSTITUTION.md` or `classify.md`. Follow those files; do not fictionalize them.

## Quarantine

New project skills in `.erixpo/skills/` start quarantined. Load them only after the user says go, or after three successful uses recorded in refine-log.
