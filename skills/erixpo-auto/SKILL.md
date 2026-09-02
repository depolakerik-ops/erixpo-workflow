---
name: erixpo-auto
description: Autonomous build loop for an approved erixpo plan. Use when the user says erixpo auto, go, continue, keep building, or when .erixpo/plan.md is approved. One slice: implement, write tests for that change, self-review, run check, update wiki.
license: MIT
metadata:
  author: Erixpo
  version: "0.4.0"
---

# erixpo auto

Build phase. No product interview unless a slice is blocked on a decision.

## Loop

1. Read AGENTS.md, PROFILE, USER, MEMORY, plan, wiki. Apply prior learnings.
2. Implement one slice only.
3. Tests for this slice (testing.md): list cases this change created, write tests that can fail, run them. If the runner is not chosen, research and ask once.
4. Edge cases + quality.md + ui.md when there is a surface.
5. Self-review the diff. Update wiki, progress, test-plan.md.
6. Run check:. Fail → fix that failure. Same mistake three times → stop and learn.
7. Pass → sessions.jsonl line, next slice.
8. No done claim without fresh test/check output.

Stop and ask when a product decision was not in the plan, check cannot run, or a new dependency was not approved.

After the plan is green: delivery note, then two-stage review in a different session. Do not merge a worktree until they say merge.
