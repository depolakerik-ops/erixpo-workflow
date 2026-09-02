# Contributing

This pack stays small on purpose.

- New platform? Do not add `erixpo-ios`. Improve `scaffold.md`, `ui.md` mapping, `slop.md`, and `testing.md`.
- New user verb? Classify then route. Do not add a second slash command unless the flow is truly different.
- Protocols live in `skills/erixpo/references/`. Skills point; do not duplicate tables.
- Keep each SKILL.md under 500 lines.
- Folder name == `name:` frontmatter.
- One plan template: `templates/.erixpo/plan.md` and `templates/erixpo/plan.md` must stay the same richness.
- Canonical machine state file is `state.md`, not a second `state.yaml` writer.
- Version: `VERSION` is source of truth. `install.sh` reads it. `.claude-plugin/*.json` must match. Copy lands in `.erixpo/VERSION`.
- Run `bash check.sh`.
