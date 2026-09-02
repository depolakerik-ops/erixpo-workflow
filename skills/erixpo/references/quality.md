# Quality bar

**Iron law (Superpowers):** no completion claim without fresh verification evidence. Identify the command or artifact that proves the claim. Run it. Read the output. Only then say it is done.

A slice is not done when the happy path renders.

## Always

- Run the project's check command from `AGENTS.md` / `.erixpo/stack.md`.
- Cover the edge cases listed in the plan for this slice.
- No dead code you just added.
- No secrets in the tree.
- Update wiki + progress when behaviour changed.

## UI (any surface)

- No generic AI look: purple gradients, inter-everywhere, three identical feature cards, fake testimonials, stock dashboard chrome — unless the user asked for that.
- Spacing, tap targets, contrast, empty states, error states, loading states.
- Keyboard / VoiceOver / screen reader on platforms that have them.
- Follow the platform guide you named in research (HIG, Fluent, Material, WCAG).

## Behaviour

- Ask: what if the user does the weird thing? Offline, empty list, huge input, expired session, permission denied, first launch.
- If you cannot test a case, write it under "untested" in `.erixpo/progress.md`. Do not pretend.

## Reviewer

Two stages. Stage 1 is mechanical (`bin/erixpo review --stage 1`). Stage 2 is a different session. The author of the slice does not rubber-stamp it.

A dummy `check:` (`exit 0`, `echo ok`) is a failed gate, not a pass.

## Isolation

Unattended loops run in a worktree. "Done" in a worktree is not landed on the user's branch until they say merge.

Read [failures.md](failures.md).
