# Wiki and progress

Target project (not this pack) uses:

```
AGENTS.md                 machine rules
CLAUDE.md                 @AGENTS.md
README.md                 humans
documents/INDEX.md        wiki home
documents/*.md            modules, decisions, how-to
documents/progress.html   status board
.erixpo/                  machine state
```

## Init

Create these if missing. Never blow away a good existing README; merge.

`documents/` is the Wikipedia of **this product**. Write in the product's language and facts. No generic "Welcome to your new app" copy.

## Every behaviour-changing slice

Update, in the same turn:

1. The wiki page for the module you touched
2. `documents/INDEX.md` if a new module appeared
3. `.erixpo/progress.md` — date, slice, check pass/fail, notes
4. `documents/progress.html` — regenerate from `templates/progress.html` with current facts
5. `README.md` only if run instructions or the product sentence changed
6. `AGENTS.md` only if commands or invariants changed

## progress.html look

System font. One accent taken from the product if it has one, else near-black and paper. No hero, no cards grid, no gradient, no Inter-from-Google as a personality. It is a status sheet: name, phase, last slice, check, modules.

## Existing repos

On init, inventory what is already there. Quote it in `documents/inventory.md`. Do not invent architecture that the code does not have.
