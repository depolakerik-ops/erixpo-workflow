# Testing during development

A slice is not done when the code exists. Tests are the scaffold and an unavoidable gate.

This file is the protocol. [quality.md](quality.md) points here. [review.md](review.md) only describes the mechanical gate.

## Harness

If the repo has **no test runner**, this slice (or slice 0 scaffold) **creates** one that fits the surface. Do not ask "should we have tests?"

Ask only when **two official runners are both reasonable** for this surface.

Match the platform. Examples of wrong:

- Playwright as the primary story for Swift
- XCTest for a Python script
- JUnit as the primary for a shell one-liner (use bats or a fixture script)

Live-search current-year docs if the runner is unknown. Record the choice in `.erixpo/test-plan.md` and in `check:`.

Non-software (`PROFILE` class `writing` | `research` | `ops` | `assistant`, or `ERIXPO_DOCS_ONLY=1`): the PROFILE/`check:` command **is** the test. Still write the plan. Ceremony may be light.

## Every slice writes `.erixpo/test-plan.md`

Use the project template. Fill, do not leave placeholders that apply:

### This slice
New behaviour under test.

### Runner
The platform runner (`check:` must execute these tests, or a documented superset). Note if this slice created the harness.

### Cases
- New behaviour
- Nearby breakage (callers, routes, shared types)
- Minimum when they apply: happy, empty, invalid, auth denied, timeout/offline, idempotency, the bug just fixed

Mark each case **automatable now** vs later.

### Result
The command you ran and what the output said. No completion claim without this.

### Later
Cases you cannot automate: `untested:` plus **why** (device/human only). UI without a host preview: `untested: visual` plus why.

## Write tests in the same slice

Same slice, same commit as the behaviour.

- Tests must be able to fail.
- No skipped tests added to look green.
- No deleting or weakening tests to pass.
- No "we'll test it next slice" for behaviour this slice shipped.

## Run

`check:` **must execute those tests** (or a documented superset).

`tsc --noEmit` (or typecheck-only, lint-only) is **not** enough when the bugs are runtime — say so in the plan and **fail the slice** until a runtime test command is the gate.

Run it. Read the output. Fix before the next slice. No completion claim without that output.

Dummy `check:` (`true`, `exit 0`, `:`, `echo ok`) is a fail. See [review.md](review.md).

## UI slices

When the host can, include a **visible proof**: build, screenshot, simulator, browser, or native preview. Put the artifact path or command in the plan Result.

If that is impossible, write `untested: visual` with why. Do not claim "looks good."
