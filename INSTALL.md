# Install erixpo workflow

Works with any agent that reads [Agent Skills](https://agentskills.io/specification) (`SKILL.md`).

## Fast path — paste this to the agent you are in

```
You are installing erixpo into THIS project only.

1. Detect which product you are (Cursor, Claude Code, Codex, Gemini CLI,
   OpenCode, Copilot, Windsurf, Cline, Crush, Aider, Devin, other).
2. Clone https://github.com/depolakerik-ops/erixpo-workflow into /tmp if needed.
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
git clone https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
cd /path/to/your-project
bash /tmp/erixpo-workflow/install.sh --host auto
```

`--host auto` installs `.agents/skills/` plus the vendor folder for the detected host only.

```bash
bash install.sh --detect
bash install.sh --host cursor
bash install.sh --expand --host claude
bash install.sh --host all
```

## Uninstall through the agent

Say `I don't want erixpo anymore.` The agent asks pack-only vs memory vs everything, then runs uninstall.sh.
