# Stack

check: echo "set the real check command" && exit 1
install: none

## Job class
unknown

## Chosen
- Language:
- Framework:
- Data:
- UI:
- Test:

## Check command
The one-line `check:` field at the top of this file is what `.erixpo/bin/erixpo` runs.
It must **run tests** (or the class-appropriate proof), not `echo ok` / `exit 0`.
Replace it with the real project command, for example:

```
check: npm test
check: cargo test
check: pytest
check: xcodebuild test -scheme App -destination 'platform=iOS Simulator,name=iPhone 16'
```

`tsc --noEmit` alone is not enough if the bugs are runtime.

## Approved skills
none yet

## Approved MCP
none yet
