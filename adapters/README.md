# Worker adapters

Adapters accept `ROOT`, `PROMPT_FILE`, and optional iteration as positional arguments. They export `ERIXPO_ROOT`, `ERIXPO_PROMPT_FILE`, and `ERIXPO_ITERATION`, run in ROOT, and propagate exit status. `generic` uses an explicitly supplied `ERIXPO_WORKER_CMD` or an available Claude/Codex CLI.

| Adapter | Executable | Invocation style | Permission policy |
|---|---|---|---|
| claude | claude | print mode | acceptEdits with explicit tool list |
| codex | codex | exec | full-auto |
| cursor | agent | print mode | force |
| gemini | gemini | prompt | provider defaults |
| opencode | opencode | run | provider defaults |
| hermes | hermes | prompt | provider defaults |
| generic | configured shell command, or claude/codex | custom | caller/provider configuration |

These flags are implementation details, not equivalent security boundaries. A Git worktree isolates changes, not shell access or credentials. Run only in repositories and with commands you intend to authorize.

The automated suite tests invocation, prompt preservation, working directory, environment, and exit codes using fake executables. It does not certify a live provider version, model, permission interaction, tool availability, or network behavior. Before relying on unattended operation, run a small real task with your installed provider and record the version/result below or in local setup documentation.

Structured provider output and token/cost reporting are currently unavailable in the common adapter contract. Runtime iteration and wall-time limits are enforced independently. Captured logs remain local. `capabilities.json` expresses this support level without claiming live certification.
