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
| `--uninstall` | Remove the pack this script installed |
| `--purge` | Also delete `.erixpo` memory / plan / sessions |
| `--purge-worktrees` | Also prune sibling `../.erixpo-worktrees/*` |

## What install.sh does

1. Resolves the erixpo-workflow source directory.
2. Copies each `skills/*` folder into project skill dirs.
3. Writes `.erixpo/install-manifest.txt` listing every path it copied.
4. It does **not** write `AGENTS.md` or `documents/` into the target. That is `/erixpo init`.

## Uninstall

Tell the agent:

```
Uninstall erixpo from this project. Run bash /tmp/erixpo-workflow/uninstall.sh
(or bash /tmp/erixpo-workflow/install.sh --uninstall). Do not delete AGENTS.md,
documents/, README, or source.
```

Or from the project root:

```bash
bash /tmp/erixpo-workflow/uninstall.sh
bin/erixpo uninstall
```

Default uninstall removes only what install copied. It keeps product files and `.erixpo` memory.

```bash
bash /tmp/erixpo-workflow/install.sh --uninstall --purge
bash /tmp/erixpo-workflow/install.sh --uninstall --purge --purge-worktrees
```

`--global` on uninstall removes the same skill names from home-dir skill folders.

Claude Code plugin users also run `/plugin uninstall erixpo-workflow@erixpo` if they installed the plugin.
