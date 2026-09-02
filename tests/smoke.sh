#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
say() { echo "$*"; }
bad() { echo "FAIL: $*" >&2; fail=1; }
say "== detect-host =="
bash "$ROOT/scripts/detect-host.sh" >/dev/null || bad "detect-host failed"
say "== install --host generic does not spray vendor folders =="
TMP="$(mktemp -d)"
bash "$ROOT/install.sh" --target "$TMP" --host generic >/dev/null
[[ -d "$TMP/.agents/skills/erixpo" ]] || bad "missing .agents/skills/erixpo"
[[ -d "$TMP/.claude/skills" ]] && bad "sprayed .claude/skills"
[[ -d "$TMP/.codex/skills" ]] && bad "sprayed .codex/skills"
[[ -f "$TMP/.erixpo/hosts.txt" ]] || bad "missing hosts.txt"
say "== review-stage1 rejects dummy check =="
FIX="$(mktemp -d)"
git -C "$FIX" init -q
git -C "$FIX" config user.email "smoke@erixpo"
git -C "$FIX" config user.name smoke
mkdir -p "$FIX/.erixpo"
printf 'check: exit 0\n' > "$FIX/.erixpo/stack.md"
echo x > "$FIX/README.md"
git -C "$FIX" add README.md .erixpo/stack.md
git -C "$FIX" commit -qm init
if (cd "$FIX" && bash "$ROOT/scripts/review-stage1.sh") >/dev/null 2>&1; then
  bad "stage1 passed a dummy exit 0 check"
else
  say "ok dummy check rejected"
fi
say "== uninstall pack-only keeps AGENTS.md =="
echo 'keep-agents' > "$TMP/AGENTS.md"
mkdir -p "$TMP/documents"
echo wiki > "$TMP/documents/INDEX.md"
bash "$ROOT/install.sh" --uninstall --target "$TMP" >/dev/null
[[ -f "$TMP/AGENTS.md" ]] || bad "uninstall deleted AGENTS.md"
[[ -f "$TMP/documents/INDEX.md" ]] || bad "uninstall deleted documents"
[[ -d "$TMP/.agents/skills/erixpo" ]] && bad "skills still present after uninstall"
rm -rf "$TMP" "$FIX"
if [[ "$fail" -ne 0 ]]; then echo "SMOKE FAILED"; exit 1; fi
echo "SMOKE PASSED"
