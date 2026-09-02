# Install erixpo workflow

Works with any agent that reads [Agent Skills](https://agentskills.io/specification) (`SKILL.md`).

## Fast path — tell the agent

Paste this:

```
Clone https://github.com/depolakerik-ops/erixpo-workflow into /tmp if needed.
From THIS project root run: bash /tmp/erixpo-workflow/install.sh
Then read skills/erixpo/SKILL.md (now at .agents/skills/erixpo/SKILL.md)
and start with /erixpo init or /erixpo plus my request.
```

## Manual

```bash
git clone https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
cd /path/to/your-project
bash /tmp/erixpo-workflow/install.sh
```

Flags:

| Flag | Meaning |
|---|---|
| `--global` | Install into `~/.agents/skills` and sibling home dirs |
| `--target DIR` | Install into DIR instead of the current directory |
| `--dry-run` | Print destinations only |

## What install.sh does

1. Resolves the erixpo-workflow source directory.
2. Copies each `skills/*` folder into:
   - `.agents/skills/<name>/` (canonical)
   - `.claude/skills/<name>/`
   - `.cursor/skills/<name>/`
   - `.codex/skills/<name>/`
   - `.github/skills/<name>/`
3. Prints next steps. It does **not** write `AGENTS.md` or `documents/` into the target. That is `/erixpo init`.

`--global` uses the same names under `$HOME`.

## Claude Code plugin (optional extra)

```
/plugin marketplace add depolakerik-ops/erixpo-workflow
/plugin install erixpo-workflow@erixpo
```

Skills still work if you only ran `install.sh`. The plugin is convenience for Claude Code users.

## After install

In the target project:

```
/erixpo
```

If the repo has no `AGENTS.md` yet, the router runs init first.

## Uninstall

Delete the copied skill folders under `.agents/skills`, `.claude/skills`, `.cursor/skills`, `.codex/skills`, and `.github/skills`.
