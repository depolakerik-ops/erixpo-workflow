---
name: erixpo-init
description: Initialize erixpo in a repo. Map first, classify domain, write AGENTS.md and .erixpo without overwriting blindly. Record created files in .erixpo/init-manifest.txt.
license: MIT
---

# erixpo init

1. Map the repo. Write documents/inventory.md. Do not guess a stack the files do not support.
2. Classify domain. Write PROFILE.md.
3. Create missing brain files from templates. Do not overwrite a good README or AGENTS.md.
4. stack.md must have check: and install: (install may be none).
5. Write .erixpo/init-manifest.txt listing files you created. Uninstall --purge-docs may only delete those names.
6. If the user already stated a goal, continue to the router with that goal.
