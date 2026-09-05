# Contributing

This pack stays small on purpose.

- New platform? Do not add `erixpo-ios`. Improve `scaffold.md`, `ui.md` mapping, `slop.md`, and `testing.md`.
- New user verb? Classify then route. Do not add a second user-facing slash command; extend the router.
- Protocols live in `skills/erixpo/references/`. Skills point; do not duplicate tables.
- Keep each SKILL.md under 500 lines.
- Folder name == `name:` frontmatter.
- One plan template: `templates/.erixpo/plan.md` and `templates/erixpo/plan.md` must stay the same richness.
- Canonical machine state file is `state.md`, not a second `state.yaml` writer.
- Version: `VERSION` is source of truth. `install.sh` reads it. `.claude-plugin/*.json` must match. Copy lands in `.erixpo/VERSION`.
- Run `bash check.sh`.

- Keep mirrored plan/state/stack templates byte-identical. New lifecycle guarantees need installed-product regression tests.
- Publish a new version for released behavior changes, with plugin/skills metadata in lockstep. Record exact source provenance; do not reuse a released tag.
- Changes to prompt/protocol behavior should add a representative scenario to examples/evaluations and be measured on the same configured model before claiming a quality improvement.
