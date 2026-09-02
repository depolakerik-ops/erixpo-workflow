---
name: erixpo-learn
description: Self-improvement for this repo. Use when the user says remember this, what did we learn, refine, skillify, search memory, prune learnings, or after a finished erixpo job. Writes typed learnings, updates MEMORY.md and USER.md, may promote a procedure into a project skill. Never silently changes the immutable pack skills.
license: MIT
metadata:
  author: Erixpo
  version: "0.2.0"
---

# erixpo learn

This is how the workflow gets smarter **in this repository**. Chat history is not memory. Disk is.

Read [memory rules](../erixpo/references/memory.md) first.

## Files (create if missing, from pack templates)

```
.erixpo/PROFILE.md         what THIS repo is for
.erixpo/MEMORY.md          bounded project facts (keep under ~80 lines)
.erixpo/USER.md            how THIS human wants to work here
.erixpo/learnings.jsonl    append-only typed learnings
.erixpo/sessions.jsonl     one line per finished job
.erixpo/refine-log.md      evidence + rollback notes
.erixpo/skills/<name>/     project-grown SKILL.md (quarantined until approved)
```

The pack skills under `skills/erixpo*` are **immutable**. You may only mutate `.erixpo/`.

## Modes

| User said | Mode |
|---|---|
| remember this / don't forget / we always… | **capture** |
| what did we learn / search memory / prior learning | **search** |
| refine / extract learnings / after a green slice | **refine** |
| turn this into a skill / skillify / /learn this folder | **promote** |
| prune / forget that / that learning is wrong | **prune** |
| empty or just `/erixpo learn` | **review** (show top learnings + offer prune/promote) |

## Capture

Write **one** JSONL line to `.erixpo/learnings.jsonl`:

```json
{"ts":"2026-09-02T16:00:00Z","track":"fix","type":"pitfall","key":"short-kebab-key","insight":"one sentence","confidence":8,"source":"user-stated","files":["path"],"status":"active"}
```

Fields:
- `type`: pattern | pitfall | preference | architecture | tool | operational | domain | taste
- `source`: observed | user-stated | inferred
- `confidence`: 1–10. user-stated starts at 9. inferred starts at 4. observed+verified starts at 7.
- `status`: active | quarantined | stale | retracted

Also patch `.erixpo/MEMORY.md` or `.erixpo/USER.md` **only if** the fact will still matter next month. Keep those files short. Replace a stale line rather than appending forever.

Log the edit in `.erixpo/refine-log.md`: trigger, file, before→after one-liner, how to revert.

## Search

1. Read MEMORY.md, USER.md, PROFILE.md.
2. Grep `learnings.jsonl` for the query and for the files being touched.
3. Return the hits as:
   `Prior learning applied: <key> — <insight> (confidence N, source)`
4. Do not dump the whole file into chat.

## Refine (after a finished job)

Do this at the end of auto / feature / fix / work / review when something non-trivial happened.

1. Append one `sessions.jsonl` line: date, track, goal, check result, lesson keys.
2. If a new pitfall or pattern was **verified** (check ran, or user confirmed), append one learning.
3. Same mistake twice → type `pitfall`, confidence +2, and add **one line** to `AGENTS.md` under Invariants if it is a hard rule.
4. User correction ("no, we don't do it that way") → type `preference` or `pitfall`, source `user-stated`.
5. Smallest edit. Never rewrite MEMORY.md from scratch.

If nothing new was learned, write that in refine-log and stop. Empty refine is allowed.

## Promote (project skill)

Only when a procedure would take more than three steps next time **and** it is specific to this repo.

1. Draft `.erixpo/skills/<kebab-name>/SKILL.md` with frontmatter `name` + `description` (when to use it).
2. Status starts **quarantined**. Tell the user. Do not load it as a default until they say go, or it has been used successfully three times (then flip status to active in refine-log).
3. Never copy a third-party GitHub skill into `.erixpo/skills/` without asking.

`/erixpo learn this folder` (Hermes-style): read the named directory of docs/code, distill a quarantined project skill, cite sources in the skill body.

## Prune

- Retract a learning the user says is wrong (`status: retracted`, keep the line for history).
- Mark stale if every `files[]` path is gone.
- Decay: inferred learnings unused for a long time drop confidence. Below 3 → stale.
- MEMORY.md / USER.md: delete lines that would not change behavior if removed.

## Hard rules

- Evidence or user statement. No invented memories.
- No secrets in memory files.
- No silent promotion of skills or MCP servers.
- Do not grow MEMORY.md past ~80 lines. Prune first.
- Show "Prior learning applied" when a learning actually changed what you did.
