# Testing during development

A slice is not done when the code exists.

## Research what to test (every slice)

Write `.erixpo/test-plan.md`:
1. New behaviour — cases a careful human would try.
2. Nearby breakage — callers, routes, shared types.
3. What this platform actually uses (live-search). No Playwright for Swift. No XCTest for a Python script.
4. Automatable now vs untested (device/human).

Minimum when they apply: happy path, empty, invalid, auth denied, timeout/offline, idempotency, the bug you just fixed.
Non-software jobs: the PROFILE check is the test. Still write the plan.

## Write tests in the same slice

Use the existing harness. If none, research one runner and ask (or use the one already in the plan).
Tests must be able to fail. No skipped tests added to look green.

## Run

Run `check:` and the test command. Read the output. Fix before the next slice.

## Later

Cases you cannot automate go under ## Later with why.
