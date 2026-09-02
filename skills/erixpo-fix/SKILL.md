---
name: erixpo-fix
description: Fix a bug. Reproduce, fix, add a regression test that fails without the fix, run check. Do not sneak a feature into a fix.
license: MIT
metadata:
  author: Erixpo
  version: "0.4.1"
---

# erixpo fix

1. Reproduce or quote the failing check. Cannot reproduce → stop guessing after one attempt.
2. Smallest cause.
3. Fix it.
4. Regression test that fails without the fix. No harness → research one and ask, or write `untested:` in test-plan.md and do not claim done.
5. Run check. Read output.
6. Self-review. Do not delete or weaken the test that caught this.
7. Update progress. Wiki only if public behaviour changed.
