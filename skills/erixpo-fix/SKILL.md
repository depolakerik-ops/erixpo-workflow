---
name: erixpo-fix
description: Fix a bug. Reproduce, fix, add a regression test that fails without the fix, run check. Do not sneak a feature into a fix.
license: MIT
metadata:
  author: Erixpo
  version: "0.6.0"
---

# erixpo fix

Follow [testing.md](../erixpo/references/testing.md) and [quality.md](../erixpo/references/quality.md).

1. Reproduce or quote the failing check. Cannot reproduce → stop guessing after one attempt.
2. Smallest cause.
3. Fix it.
4. Regression test that fails without the fix, in this slice. If there is no harness: **create it** ([testing.md](../erixpo/references/testing.md)). Do not stop at `untested:` unless the case is device/human-only.
5. Run `check:` (it must execute those tests, or a documented superset). Read the output.
6. Self-review. Do not delete or weaken the test that caught this.
7. Update progress. Wiki only if public behaviour changed ([wiki.md](../erixpo/references/wiki.md)).
