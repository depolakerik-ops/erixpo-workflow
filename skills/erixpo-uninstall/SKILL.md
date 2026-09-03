---
name: erixpo-uninstall
description: Remove the erixpo workflow from this project after asking what to keep. Use when the user says they do not want erixpo anymore, uninstall erixpo, remove the workflow, get rid of these skills, or stop using /erixpo. Never delete product source without asking.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.2"
---

# erixpo uninstall

The user wants erixpo gone. This is a conversation, then a script. Do not start deleting files yourself.

## 1. Confirm

One sentence: you will remove the workflow, not their app.

## 2. Ask once — three choices

1. **Pack only** — skills, `/erixpo` command, `bin/erixpo`, adapters, scripts. Keep `documents/`, `AGENTS.md`, and `.erixpo` memory.
2. **Pack + memory** — also delete `.erixpo/`. Keep the wiki and source.
3. **Everything erixpo added** — pack + `.erixpo/` + isolated worktrees. Then one extra yes/no: also delete `documents/` and `AGENTS.md`/`CLAUDE.md`? Default **no**. Never delete application source, `.env`, or git history.

If they already said wipe it, restate option 3 and wait for yes.

## 3. Run the script

```bash
bash /tmp/erixpo-workflow/install.sh --uninstall --target "$PWD"
bash /tmp/erixpo-workflow/install.sh --uninstall --purge --target "$PWD"
bash /tmp/erixpo-workflow/install.sh --uninstall --purge --purge-worktrees --target "$PWD"
bash /tmp/erixpo-workflow/install.sh --uninstall --purge --purge-worktrees --purge-docs --target "$PWD"
```

`--purge-worktrees` is the bulk path when leaving erixpo. While still using the pack, leftover trees are `bin/erixpo sweep` (report), `bin/erixpo sweep --apply` (stale + dead merged branches), or `bin/erixpo close --id`.

## 4. Hard rules

- Do not `rm -rf` the project.
- Do not delete `src/`, app code, `.env`, or `.git`.
- After the script exits, list what is gone and what is left.
