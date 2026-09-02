---
name: erixpo-docs
description: Create or refresh the project wiki per ceremony. Use when the user says erixpo docs, wiki, README, or progress. Follows wiki.md; light ceremony does not force ARCHITECTURE.md or progress.html. Never invents features or an AI-slop dashboard.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo docs

Follow [wiki.md](../erixpo/references/wiki.md). If `ceremony.md` exists (pack-templates, skill references, or `.erixpo/`), obey it — ceremony is how much wiki to write, not a license to invent features.

## Light ceremony

Do **not** force `documents/ARCHITECTURE.md` or `documents/progress.html`. A module page + `.erixpo/progress.md` is enough. Skip a status dashboard the product does not have.

## Full / already there

If those files already exist or ceremony is full: keep them honest. Regenerate `progress.html` from the template with live facts only. No `{{PRODUCT}}` leftovers. No AI-slop dashboard (hero, card grid, Inter-from-Google as personality).

## Always

1. Read the code and existing docs.
2. `documents/` is the Wikipedia of this product. Write in its language and facts.
3. `AGENTS.md` is the machine file. `README.md` is the human file.
4. Never invent features the code does not have.
