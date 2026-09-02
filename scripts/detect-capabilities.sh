#!/usr/bin/env bash
# Facts for classify.md `capabilities:`. Machine + PATH, not wishes.
set -euo pipefail

has() { command -v "$1" >/dev/null 2>&1; }

bits=()
add() { bits+=("$1"); }

has xcodebuild && add "xcodebuild" || true
has swift && add "swift" || true
{ has adb || [[ -n "${ANDROID_HOME:-}" || -n "${ANDROID_SDK_ROOT:-}" ]]; } && add "android-sdk" || true
has dotnet && add "dotnet" || true
has python3 && add "python3" || true
has node && add "node" || true
has npm && add "npm" || true
has cargo && add "cargo" || true
has go && add "go" || true
has java && add "java" || true
has gradle && add "gradle" || true
has pod && add "cocoapods" || true
has flutter && add "flutter" || true
has cmake && add "cmake" || true
has docker && add "docker" || true

if has google-chrome || has chromium || has chromium-browser; then
  add "browser:chrome"
elif [[ -x "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" ]]; then
  add "browser:chrome"
elif has playwright; then
  add "browser:playwright"
fi

if [[ ${#bits[@]} -eq 0 ]]; then
  add "shell-only"
fi

printf 'capabilities: %s\n' "$(IFS=', '; echo "${bits[*]}")"
