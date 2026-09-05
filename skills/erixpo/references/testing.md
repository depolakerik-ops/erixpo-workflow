# Testing during development

A slice is not done when the code exists. Tests are the scaffold and an unavoidable gate.

This file is the protocol. [quality.md](quality.md) points here. [review.md](review.md) only describes the mechanical gate.

## Harness

If the repo has **no test runner**, this slice (or slice 0 scaffold) **creates** one that fits the surface. Do not ask "should we have tests?"

Choose within existing authorization using project facts and current official documentation. Ask only when a consequential missing constraint changes the choice (intent.md).

Match the platform. Examples of wrong:

- Playwright as the primary story for Swift
- XCTest for a Python script
- JUnit as the primary for a shell one-liner (use bats or a fixture script)

Open current official docs if the runner is unknown. Record the choice in `.erixpo/test-plan.md` and in `check:`.

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

## Derive testing from the project

Before selecting a runner, identify the behavior/artifact being changed, its failure modes, observable acceptance, environment and available tools. Reuse a suitable harness. Research missing capabilities using research.md; names in this document are examples, never a runner allowlist.

Choose the cheapest tests that prove the actual risk: pure logic tests, integration against real boundaries, end-to-end journeys, representative renders/exports, simulations or controlled device checks as applicable. Prefer independent expected results and public behavior over assertions that merely mirror implementation. For a regression, demonstrate the failure before the fix when practical, then verify the same case passes. Mock unavailable services at the boundary, but report what a mock cannot establish.

Include adversarial inputs and relevant error paths, not only happy-path snapshots. Check shared consumers when changing tokens, protocols or components. Record fixtures, environment/version, exact command, outcome and gaps in test-plan.md. One-shot light artifacts can keep this evidence in the response instead of persistent files. Never fabricate test execution or physical/visual verification; a build alone is not a visual inspection.

If a required tool is missing, first use a valid existing capability. If none suffices, research a suitable skill, MCP, CLI, simulator or harness and present a concrete addition proposal. Keep unsupported claims unverified while completing independent work.
