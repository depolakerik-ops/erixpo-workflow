---
name: erixpo-fix
description: Fix a bug in an erixpo-managed project. Use when the user says erixpo fix or reports something broken, crashing, failing tests, or a regression. Reproduce, fix, add a guard if cheap, run the check, update wiki only if behaviour or known issues changed.
license: MIT
metadata:
  author: Erixpo
  version: "0.1.0"
---

# erixpo fix

## Steps

1. Reproduce or quote the failing check. If you cannot reproduce, say so and stop guessing after one honest attempt.
2. Find the smallest cause.
3. Fix it. Add or adjust a test when the project already has a test harness.
4. Run the project check command.
5. Update `.erixpo/progress.md`. Update the wiki only if the public behaviour or a known issue list changed.

Do not refactor the neighbourhood. Do not sneak a feature into a fix.
