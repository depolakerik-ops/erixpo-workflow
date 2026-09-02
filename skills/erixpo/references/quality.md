# Quality bar

**Iron law:** no completion claim without fresh verification evidence. Identify the command or artifact that proves the claim. Run it. Read the output. Only then say it is done.

A slice is not done when the happy path renders.

## Always (software or not)

- Run the project's `check:` from `.erixpo/stack.md` / `AGENTS.md`.
- Tests for **this slice** ran, following [testing.md](testing.md) — not only `check:` when `check:` is dummy or typecheck-only.
- Cover the edge cases listed for this slice.
- Self-review the diff before you call it done (below).
- No dead code you just added. No secrets.
- Update wiki + progress when behaviour changed ([wiki.md](wiki.md); [ceremony.md](ceremony.md) if present).

## In-slice self-review

After the tests go green, **before the next slice**:

1. Read your own diff. Would a stranger understand it?
2. Did you implement something that was on the optional extras list? Revert it unless they approved it.
3. Does the wiki claim a feature the diff does not contain?
4. Dummy `check:` (`true`, `exit 0`, `:`, `echo ok`) is a fail.
5. Note leftover risks in `.erixpo/progress.md` under untested.

This is not stage-2 review. Stage 2 is still a **different session** ([review.md](review.md)).

## UI

Follow [ui.md](ui.md) if there is a surface. Honor the classified **change-type** (retoken / recompose / reflow / relanguage / remotion). No AI-slop look unless they asked for it ([slop.md](slop.md), `documents/ui/layout.md`).

- `documents/ui/` exists before a second visible screen.
- Change-type respected: recompose / reflow / relanguage load `erixpo-ui` with that type — do not only retoken.
- No hard-coded hex / radius / duration outside the `theme_file` / token file.
- New component listed in `components.md` in the same slice.
- Token change → `CHANGELOG.md` + mockups + grep old value.
- Empty / error / loading treated as screens, not afterthoughts.

## Judgment

If the slice is greenfield or visible: you wrote the four "Outside the box" lines in research or the plan ([judgment.md](judgment.md)). You did not add unrequested extras.

## Behaviour

What if empty, invalid, offline, expired, permission denied, first launch, huge input? If you cannot test it, write `untested` — do not pretend.
