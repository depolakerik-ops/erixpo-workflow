# Domains — this repo can be anything

erixpo is not only a software factory. It is a workflow that specializes to **the folder it is in**.

## PROFILE.md

Init writes `.erixpo/PROFILE.md` from inventory + one question if needed:

```
# Profile
class: software | site | automation | research | writing | ops | assistant | mixed
surfaces: [web, ios, cli, notes, inbox, wiki, …]
one_liner: …
check: <command or "n/a — human accepts artifact">
```

`class` decides default research and default check. It does not lock the router — a writing repo can still ask for a small script.

## Scale (BMAD)

| Size | Process |
|---|---|
| One-line typo / rename | fix or work, no research interview |
| Feature on a known stack | feature |
| New product | new (talk → research → plan → go) |
| Assistant / research / ops | work |
| "what did we learn" | learn |

Do not run the full product interview for "file these PDFs into documents/".

## Check per class

Software: test / lint / build command that exits 0.
Site: build + optional browser smoke if the user approved a browser tool.
Automation: script on a fixture exits 0.
Research / writing: the file exists and the claims that can be checked are checked.
Assistant / ops: the specified file or folder change is visible.

Never claim done without that evidence.
