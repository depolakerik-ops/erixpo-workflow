# Changelog

## 0.6.2

- Craft bar: specialist prompt (not factory worker), no methodology narration.
- Research comparables must be **opened** URLs with one learned sentence — names-only is a fail.
- Init does not seed blank token tables. LANGUAGE.md only until the first real UI slice.
- Router loads one skill; does not preload fifteen reference files.

## 0.6.1

- `VERSION` file so agents can see there is a new pack (no more 404 on `/VERSION`).
- `/erixpo update` track: reinstall the pack from GitHub. Does **not** touch product code, plan, USER, PROFILE, or the product `classify.md`.
- Install copies `VERSION` → `.erixpo/VERSION` and chmods `scripts/*.py`.

## 0.6.0

- Classify-then-route, native scaffold, UI change-types, tests as gate, worktree close.
- Any **build** (any field) live-searches this year; skip only non-build (fix, review, learn).
