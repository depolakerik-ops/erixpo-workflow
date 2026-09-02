---
name: erixpo-docs
description: Create or refresh the project wiki, AGENTS.md, README, and documents/progress.html. Use when the user says update the docs, rebuild the wiki, refresh progress.html, or when another erixpo flow needs a documentation-only pass.
license: MIT
metadata:
  author: Erixpo
  version: "0.1.0"
---

# erixpo docs

Follow [wiki rules](../erixpo/references/wiki.md) if present.

## Steps

1. Read the code and existing docs. Inventory first on an existing repo.
2. Make `documents/` the Wikipedia of this product. Short pages > one giant file.
3. Regenerate `documents/progress.html` from the template with live facts (name, phase, last slice, check, modules). System font, one accent, no AI-slop dashboard.
4. Keep `AGENTS.md` as the machine file. Keep README as the human file. Do not duplicate essays across all three.

Never invent features in the wiki that the code does not have.
