# Install erixpo workflow

Works with any agent that reads [Agent Skills](https://agentskills.io/specification) (`SKILL.md`). Pack version is the `VERSION` file on `main`.

## Fast path — paste this to the agent you are in

```
You are installing erixpo into THIS project only.

1. Detect which product you are (Cursor, Claude Code, Codex, Gemini CLI,
   OpenCode, Copilot, Windsurf, Cline, Crush, Aider, Devin, other).
2. Clone https://github.com/erixpo/erixpo-workflow into /tmp if needed.
3. From THIS project root run:
     bash /tmp/erixpo-workflow/install.sh --host auto
   Do NOT pass --host all. Do not create skill folders for agents that
   are not running.
4. Read .agents/skills/erixpo/SKILL.md and start with /erixpo.

If the user later opens a different agent, ask once whether to expand:
     bash /tmp/erixpo-workflow/install.sh --expand --host <that-agent>
```

## Manual

```bash
git clone https://github.com/erixpo/erixpo-workflow /tmp/erixpo-workflow
cd /path/to/your-project
bash /tmp/erixpo-workflow/install.sh --host auto
```

`--host auto` installs `.agents/skills/` plus the vendor folder for the detected host only.

## Footprint — one real folder

Engine files live only in `.erixpo/` (`bin/`, `adapters/`, `scripts/`, `pack-templates/`, `VERSION`, `hosts.txt`, manifest). `bin/` and `scripts/` at the project root are compat symlinks into `.erixpo/` so `bin/erixpo …` and `scripts/…` keep working; no top-level `adapters/` is created. Re-running install removes legacy top-level copies (pack files only, never your content) and heals the links.

`.erixpo/` is generated machine state (ceremony pages, plan, sessions, registry) plus the installed engine copy above — never commit it from a project. `install.sh --uninstall` removes pack files via the manifest; `--purge` drops `.erixpo/` itself.

## Global install

`install.sh --global` installs the same skill set for every project on the machine, into `$HOME/.<host>/skills/` (plus `.agents/skills/`) for each resolved host. Verify with `ls ~/.agents/skills/erixpo` (or the vendor folder). **Current behavior:** `--global` also performs the project installation in the current directory (or `--target`), including `.erixpo/` and compatibility links. Run it from the intended project; it is not a global-only install.

```bash
bash install.sh --detect
bash install.sh --host cursor
bash install.sh --expand --host claude
bash install.sh --host all
```

## Update through the agent

Say `update erixpo` or `there is a new erixpo update.` The agent loads `erixpo-update`: clone latest pack, `install.sh --host auto --target` this project. It must not edit product code or rewrite `classify.md`.

```bash
git clone https://github.com/erixpo/erixpo-workflow /tmp/erixpo-workflow
bash /tmp/erixpo-workflow/install.sh --host auto --target "$PWD"
cat .erixpo/VERSION
```

## Uninstall through the agent

Say `I don't want erixpo anymore.` The agent asks pack-only vs memory vs everything, then runs uninstall.sh.
