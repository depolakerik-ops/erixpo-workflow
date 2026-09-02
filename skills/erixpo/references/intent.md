# Intent — understand the human, then act

Do this **before** a product interview and **before** live-search. Classify is the job type. This file is *what they mean*.

The workflow is autonomous when USER autonomy is `plan-then-go` or `unattended`: infer, research only if needed, pick the boring official default, show the plan. Ask only when the guess would be expensive to undo.

## Infer first (do not open with questions)

From the **sentence + this folder** (PROFILE, USER, CONSTITUTION, inventory, classify.md):

| Guess | Evidence |
|---|---|
| Job in one sentence | Their words, reframed ([judgment.md](judgment.md)) |
| Surface | Sentence, lockfiles, USER platforms, capabilities |
| `like` / references | URLs, app names, “like Linear”, “like Apple Settings”, attached files |
| Must-have vs later | What they named vs what a tutorial would add |
| Hard nos | USER.md, MEMORY.md, “don’t”, “no accounts”, “offline” |
| Research intensity | [research.md](research.md) / `bin/erixpo research-scope` |

Write those guesses into `.erixpo/classify.md` evidence and, on a full pass, `.erixpo/research.md` `## Intent`.

If the guess is good enough to research or to do the slice, **do not ask**. Say one line: “Building X on Y for Z. Stop me if that’s wrong.”

## Ask at most one question

Ask only if **one** of these is still missing and it changes the architecture:

- Surface still unknown (web vs iOS vs script vs notes) **and** files do not decide it
- They named two contradictory jobs and classify could not split `jobs:`
- A choice is expensive to undo (new database, new platform, new design language) **and** USER is `ask-every-slice`

Never a form. Never a command menu. Never “which slash command”.

## Extract references

Treat as a reference (do not ignore):

- `https://…`
- “like X” / “similar to X” / “as in X”
- An attached screenshot, PDF, or app name

Put them in research.md `## Comparables` as **user-stated**. Then live-search 1–2 more only if intensity is `narrow` or `full`. User-stated wins over a fashionable extra.

## Autonomy

| USER | After infer |
|---|---|
| `ask-every-slice` | Show the guess. Wait. |
| `plan-then-go` | Infer → research if needed → write plan → wait for **go** on new work; tiny feature/fix: restate one paragraph and go |
| `unattended` / they said “you pick” / “just go” | Infer → research if needed → pick official default → execute. Still no optional extras. Still tests. |

Empty USER → same as `plan-then-go` ([memory.md](memory.md)).

## Dynamic to anything

The job might not be an app. Infer *that*:

- “file these PDFs” → work, light, no stack
- “a script that renames invoices” → automation, tiny harness
- “SwiftUI app like Things” → new, surface ios, comparables include Things, not a website
- “make checkout calmer” → ui retoken, **narrow** research (color/type for this surface this year), not a new stack
- Any **build** (app, script, automation, screen) → research **this field**. Field never licenses skipping.

Wrong surface is the failure mode. Prefer one clarifying question over a web scaffold on a native job.
