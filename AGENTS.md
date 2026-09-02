# AGENTS.md

How to work on **erixpo-workflow itself**.

## What this is
Portable skill pack + installer + outer-loop CLI for an adaptive software factory.

## Check
There is no product test suite yet. Before you ship a change:

```bash
bash -n install.sh
bash -n bin/erixpo
bash -n adapters/*.sh
# every skill folder name must match SKILL.md name:
python3 - <<'PY'
import os, re, sys
root = "skills"
ok = True
for name in sorted(os.listdir(root)):
    skill = os.path.join(root, name, "SKILL.md")
    if not os.path.isfile(skill):
        print("missing", skill); ok = False; continue
    text = open(skill).read()
    m = re.search(r"^name:\s*(\S+)", text, re.M)
    if not m or m.group(1) != name:
        print("name mismatch", name, m.group(1) if m else None); ok = False
print("ok" if ok else "fail")
sys.exit(0 if ok else 1)
PY
```

## Layout
- `skills/` — what gets installed into other repos
- `templates/` — what `/erixpo init` copies into the *target* repo
- `bin/` + `adapters/` — outer loop
- `references/` — loaded on demand by skills

## Isolation
Unattended loops use `bin/erixpo isolate`. Review is two-stage. Session history lives in `.erixpo/sessions.jsonl`.

## Forbidden
- Do not add a second user-facing slash command. Extend the router.
- Do not hardcode a web/React stack. Research is live.
- Do not commit secrets.
- Do not rewrite skills into vendor-specific formats.
- Do not auto-merge a worktree onto main.
