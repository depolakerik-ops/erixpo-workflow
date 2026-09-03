---
name: erixpo-update
description: Refresh the erixpo pack in this project from GitHub. Use when the user says update erixpo, upgrade erixpo, there is a new erixpo update, reinstall erixpo, or refresh the workflow. Does not change product source, plans, or memory.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.2"
---

# erixpo update

Refresh **the workflow pack**, not the product.

## Do not

- Do not edit `src/`, app code, `documents/` product wiki, `.erixpo/plan.md`, `.erixpo/USER.md`, `.erixpo/PROFILE.md`, `.erixpo/CONSTITUTION.md`, `.erixpo/MEMORY.md`.
- Do not rewrite `.erixpo/classify.md` into a `work` job. Leave the product classify as it was. One `sessions.jsonl` line is enough.
- Do not run the product interview, research-scope for the app, or start auto.

## Do

1. Compare `.erixpo/VERSION` (installed) to GitHub `VERSION` on `main`:
   `https://raw.githubusercontent.com/depolakerik-ops/erixpo-workflow/main/VERSION`
2. Clone latest pack (or `git pull` if `/tmp/erixpo-workflow` exists):

```bash
git clone --depth 20 https://github.com/depolakerik-ops/erixpo-workflow /tmp/erixpo-workflow
# or: git -C /tmp/erixpo-workflow fetch && git -C /tmp/erixpo-workflow checkout main && git -C /tmp/erixpo-workflow pull
```

3. Reinstall into **this** project. Keep saved hosts:

```bash
bash /tmp/erixpo-workflow/install.sh --host auto --target "$PWD"
```

If `.erixpo/hosts.txt` lists extra agents, `--host auto` already expands from that file.

4. Prove it:
   - `cat .erixpo/VERSION` matches pack `VERSION`
   - `scripts/research-scope.py` (and other pack scripts) exist
   - product files still exist

5. Tell the user the new version. One sessions.jsonl line, track `update`.
