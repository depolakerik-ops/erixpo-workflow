#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
fail=0
CLEANUP=()
say() { echo "$*"; }
bad() { echo "FAIL: $*" >&2; fail=1; }
cleanup() {
  local p
  for p in "${CLEANUP[@]+"${CLEANUP[@]}"}"; do
    if [[ -d "$p/.git" ]]; then
      git -C "$p" worktree list --porcelain 2>/dev/null | awk '/^worktree /{print $2}' | while read -r wt; do
        [[ "$wt" == "$p" ]] && continue
        git -C "$p" worktree remove --force "$wt" 2>/dev/null || rm -rf "$wt"
      done
      git -C "$p" worktree prune 2>/dev/null || true
    fi
    rm -rf "$p"
  done
}
trap cleanup EXIT

init_git() {
  local d="$1"
  git -C "$d" init -q -b main
  git -C "$d" config user.email "smoke@erixpo"
  git -C "$d" config user.name smoke
}

say "== detect-host =="
bash "$ROOT/scripts/detect-host.sh" >/dev/null || bad "detect-host failed"

say "== install --host generic does not spray vendor folders =="
TMP="$(mktemp -d)"; CLEANUP+=("$TMP")
bash "$ROOT/install.sh" --target "$TMP" --host generic >/dev/null
[[ -d "$TMP/.agents/skills/erixpo" ]] || bad "missing .agents/skills/erixpo"
[[ -d "$TMP/.agents/skills/erixpo-ui" ]] || bad "missing .agents/skills/erixpo-ui"
[[ -d "$TMP/.claude/skills" ]] && bad "sprayed .claude/skills"
[[ -d "$TMP/.codex/skills" ]] && bad "sprayed .codex/skills"
[[ -f "$TMP/.erixpo/hosts.txt" ]] || bad "missing hosts.txt"
[[ -f "$TMP/.erixpo/pack-templates/PROMPT.md" ]] || bad "missing pack-templates/PROMPT.md"
[[ -f "$TMP/.erixpo/pack-templates/documents/ui/layout.md" ]] || bad "missing layout.md template"
VER="$(tr -d ' \t\n' < "$ROOT/VERSION")"
grep -q "$VER" "$TMP/.erixpo/install-manifest.txt" || bad "install manifest not $VER"
[[ -f "$TMP/.erixpo/VERSION" ]] || bad "missing .erixpo/VERSION after install"
[[ -f "$TMP/.erixpo/scripts/research-scope.py" ]] || bad "missing .erixpo/scripts/research-scope.py after install"
[[ -L "$TMP/scripts" ]] || bad "scripts is not a compat symlink"
[[ -L "$TMP/bin" ]] || bad "bin is not a compat symlink"
[[ -f "$TMP/scripts/research-scope.py" ]] || bad "missing scripts/research-scope.py via symlink after install"
[[ -f "$TMP/bin/erixpo" ]] || bad "missing bin/erixpo via symlink after install"
[[ -e "$TMP/adapters" ]] && bad "top-level adapters/ should not be installed"
[[ -d "$TMP/.agents/skills/erixpo-update" ]] || bad "missing erixpo-update skill after install"
out="$(python3 "$ROOT/scripts/classify-signals.py" "please update erixpo there is new update")"
printf '%s\n' "$out" | grep -q 'request_class: update' || bad "update erixpo != update"

say "== install host matrix + multi-host merge =="
MHOST="$(mktemp -d)"; CLEANUP+=("$MHOST")
bash "$ROOT/install.sh" --target "$MHOST" --host claude >/dev/null
[[ -d "$MHOST/.claude/skills/erixpo" ]] || bad "missing .claude/skills after --host claude"
[[ -d "$MHOST/.agents/skills/erixpo" ]] || bad "missing .agents/skills after --host claude"
[[ -d "$MHOST/.codex/skills" ]] && bad "sprayed .codex/skills on --host claude"
bash "$ROOT/install.sh" --target "$MHOST" --host codex >/dev/null
grep -q '^claude$' "$MHOST/.erixpo/hosts.txt" || bad "hosts.txt lost claude after second install"
grep -q '^codex$' "$MHOST/.erixpo/hosts.txt" || bad "hosts.txt missing codex after second install"
[[ -d "$MHOST/.codex/skills/erixpo" ]] || bad "missing .codex/skills after second install"

say "== install upgrade over legacy layout =="
UPG="$(mktemp -d)"; CLEANUP+=("$UPG")
mkdir -p "$UPG/bin" "$UPG/scripts"
cp "$ROOT/bin/erixpo" "$UPG/bin/erixpo"
cp "$ROOT/scripts/worktree.sh" "$UPG/scripts/worktree.sh"
echo "user content" > "$UPG/scripts/mine.txt"
bash "$ROOT/install.sh" --target "$UPG" --host generic >/dev/null
[[ -d "$UPG/bin" && ! -L "$UPG/bin" ]] || bad "upgrade replaced existing bin directory"
[[ -x "$UPG/bin/erixpo" ]] || bad "upgrade missing executable bin/erixpo shim"
"$UPG/bin/erixpo" --root "$UPG" capabilities >/dev/null || bad "upgraded shim does not execute"
[[ -f "$UPG/scripts/mine.txt" ]] || bad "upgrade deleted user file in scripts/"
grep -q "user content" "$UPG/scripts/mine.txt" || bad "upgrade clobbered user file"

say "== install --global respects HOME =="
GHOME="$(mktemp -d)"; CLEANUP+=("$GHOME")
GTARG="$(mktemp -d)"; CLEANUP+=("$GTARG")
HOME="$GHOME" bash "$ROOT/install.sh" --target "$GTARG" --host generic --global >/dev/null
[[ -d "$GHOME/.agents/skills/erixpo" ]] || bad "missing HOME/.agents/skills after --global"
[[ ! -e "$GTARG/.erixpo" ]] || bad "global install touched local target"

say "== review-stage1 rejects dummy check =="
FIX="$(mktemp -d)"; CLEANUP+=("$FIX")
init_git "$FIX"
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

say "== review-stage1 pairing fails after commit of product without tests =="
PAIR="$(mktemp -d)"; CLEANUP+=("$PAIR")
init_git "$PAIR"
mkdir -p "$PAIR/.erixpo"
printf 'check: test -f README.md\n' > "$PAIR/.erixpo/stack.md"
echo x > "$PAIR/README.md"
git -C "$PAIR" add README.md .erixpo/stack.md
git -C "$PAIR" commit -qm init
mkdir -p "$PAIR/src"
echo 'int main(void) { return 0; }' > "$PAIR/src/app.c"
git -C "$PAIR" add src/app.c
git -C "$PAIR" commit -qm 'product no tests'
if (cd "$PAIR" && bash "$ROOT/scripts/review-stage1.sh") >/dev/null 2>&1; then
  bad "stage1 passed product commit with no tests"
else
  say "ok pairing rejected committed product without tests"
fi

say "== review-stage1 writing class skips pairing =="
WR="$(mktemp -d)"; CLEANUP+=("$WR")
init_git "$WR"
mkdir -p "$WR/.erixpo" "$WR/src"
printf 'check: test -f README.md\n' > "$WR/.erixpo/stack.md"
printf 'class: writing\nceremony: light\n' > "$WR/.erixpo/PROFILE.md"
echo x > "$WR/README.md"
echo 'int main(void) { return 0; }' > "$WR/src/app.c"
git -C "$WR" add README.md src/app.c .erixpo/stack.md .erixpo/PROFILE.md
git -C "$WR" commit -qm init
if (cd "$WR" && bash "$ROOT/scripts/review-stage1.sh") >/dev/null 2>&1; then
  say "ok writing class skipped pairing"
else
  bad "stage1 failed a writing-class repo (pairing should skip)"
fi

say "== review-stage1 rejects dummy XCTAssertTrue(true) =="
DUM="$(mktemp -d)"; CLEANUP+=("$DUM")
init_git "$DUM"
mkdir -p "$DUM/.erixpo" "$DUM/Tests"
printf 'check: test -f README.md\n' > "$DUM/.erixpo/stack.md"
echo x > "$DUM/README.md"
printf 'XCTAssertTrue(true)\n' > "$DUM/Tests/FooTests.swift"
git -C "$DUM" add README.md Tests .erixpo/stack.md
git -C "$DUM" commit -qm init
if (cd "$DUM" && bash "$ROOT/scripts/review-stage1.sh") >/dev/null 2>&1; then
  bad "stage1 passed dummy XCTAssertTrue(true)"
else
  say "ok dummy XCTAssert rejected"
fi

say "== worktree isolate / close removes tree and branch =="
WT="$(mktemp -d)"; CLEANUP+=("$WT")
init_git "$WT"
echo x > "$WT/README.md"
printf ".erixpo/\n" > "$WT/.gitignore"
mkdir -p "$WT/.erixpo"
printf "check: test -f README.md\n" > "$WT/.erixpo/stack.md"
git -C "$WT" add README.md .gitignore
git -C "$WT" commit -qm init
iso_out="$(bash "$ROOT/bin/erixpo" --root "$WT" isolate --slug smoke --porcelain)"
iso_id="$(printf '%s\n' "$iso_out" | sed -n 's/^id=//p')"
iso_path="$(printf '%s\n' "$iso_out" | sed -n 's/^path=//p')"
iso_branch="$(printf '%s\n' "$iso_out" | sed -n 's/^branch=//p')"
if [[ -z "$iso_id" || ! -d "$iso_path" ]]; then
  bad "isolate did not create a worktree"
else
  echo y >> "$iso_path/README.md"
  git -C "$iso_path" add README.md
  git -C "$iso_path" commit -qm 'wt change'
  wt_sha="$(git -C "$iso_path" rev-parse HEAD)"
  bash "$ROOT/bin/erixpo" --root "$iso_path" review --stage 1 >/dev/null || bad "fresh stage1 review failed"
  python3 - "$iso_path" <<'PYREVIEW'
import json
from pathlib import Path
import sys
root = Path(sys.argv[1])
evidence = json.loads((root / '.erixpo/REVIEW-stage1.json').read_text())
(root / '.erixpo/REVIEW.md').write_text('Result: ship\nReview-ID: ' + evidence['review_id'] + '\nReviewer: smoke fixture\n')
PYREVIEW
  if ! bash "$ROOT/bin/erixpo" --root "$WT" close --id "$iso_id" >/dev/null; then
    bad "close failed"
  else
    [[ -d "$iso_path" ]] && bad "worktree dir still present after close"
    git -C "$WT" show-ref --verify --quiet "refs/heads/${iso_branch}" && bad "branch still present after close"
    if [[ -f "$WT/.erixpo/worktrees.jsonl" ]] && grep -q '"status": "closed"' "$WT/.erixpo/worktrees.jsonl"; then
      say "ok close removed tree+branch and marked closed"
    else
      bad "jsonl not marked closed"
    fi
    git -C "$WT" merge-base --is-ancestor "$wt_sha" HEAD || bad "close did not merge the worktree commit"
  fi
fi

say "== sweep reports (dry) =="
if ! bash "$ROOT/bin/erixpo" --root "$WT" sweep >/dev/null; then
  bad "sweep dry failed"
else
  say "ok sweep dry"
fi

say "== classify-signals look-at vs ui =="
out="$(python3 "$ROOT/scripts/classify-signals.py" "look at the checkout")"
printf '%s\n' "$out" | grep -q 'request_class: review' || bad "look at checkout != review"
out="$(python3 "$ROOT/scripts/classify-signals.py" "calmer blue")"
printf '%s\n' "$out" | grep -q 'request_class: ui' || bad "calmer blue != ui"
out="$(python3 "$ROOT/scripts/classify-signals.py" "sidebar to tabs")"
printf '%s\n' "$out" | grep -q 'recompose' || bad "sidebar to tabs != recompose"
python3 "$ROOT/scripts/classify-signals.py" --selftest >/dev/null || bad "classify --selftest"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class fix)"
[[ "$scope" == skip ]] || bad "research-scope fix != skip"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class new)"
[[ "$scope" == full ]] || bad "research-scope new != full"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class ui --ui relanguage)"
[[ "$scope" == full ]] || bad "research-scope relanguage != full"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class feature)"
[[ "$scope" == narrow ]] || bad "research-scope feature != narrow (builds must research)"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class work)"
[[ "$scope" == narrow ]] || bad "research-scope work != narrow"
scope="$(bash "$ROOT/bin/erixpo" research-scope --class auto)"
[[ "$scope" == narrow ]] || bad "research-scope auto != narrow"
python3 "$ROOT/scripts/research-scope.py" --selftest >/dev/null || bad "research-scope --selftest"
like_out="$(python3 "$ROOT/scripts/classify-signals.py" "SwiftUI app like Things")"
printf '%s\n' "$like_out" | grep -q 'like Things' || bad "did not extract like Things"

say "== stage1 rejects freelance hex outside theme_file =="
HEX="$(mktemp -d)"; CLEANUP+=("$HEX")
init_git "$HEX"
mkdir -p "$HEX/.erixpo" "$HEX/documents/ui" "$HEX/src"
printf 'check: test -f README.md\n' > "$HEX/.erixpo/stack.md"
printf 'Path: src/theme.css\n' > "$HEX/documents/ui/mapping.md"
printf ':root { --accent: #111111; }\n' > "$HEX/src/theme.css"
echo x > "$HEX/README.md"
git -C "$HEX" add README.md .erixpo/stack.md documents src/theme.css
git -C "$HEX" commit -qm init
printf '.x { color: #ff00aa; }\n' > "$HEX/src/widget.css"
printf '/* pair */\n' > "$HEX/src/widget.test.css"
git -C "$HEX" add src/widget.css src/widget.test.css
git -C "$HEX" commit -qm 'freelance hex'
if (cd "$HEX" && bash "$ROOT/scripts/review-stage1.sh") >/dev/null 2>&1; then
  bad "stage1 passed freelance hex outside theme_file"
else
  say "ok freelance hex rejected"
fi

say "== installed CLI front door executes =="
"$TMP/.erixpo/bin/erixpo" --root "$TMP" capabilities >/dev/null || bad "installed CLI status failed"
"$TMP/.erixpo/bin/erixpo" classify 'update the README' | grep -q 'request_class: docs' || bad "installed classify dispatch failed"

say "== uninstall pack-only keeps AGENTS.md =="
echo 'keep-agents' > "$TMP/AGENTS.md"
mkdir -p "$TMP/documents"
echo wiki > "$TMP/documents/INDEX.md"
bash "$ROOT/install.sh" --uninstall --target "$TMP" >/dev/null
[[ -f "$TMP/AGENTS.md" ]] || bad "uninstall deleted AGENTS.md"
[[ -f "$TMP/documents/INDEX.md" ]] || bad "uninstall deleted documents"
[[ -d "$TMP/.agents/skills/erixpo" ]] && bad "skills still present after uninstall"
[[ -d "$TMP/.agents/skills/erixpo-ui" ]] && bad "erixpo-ui still present after uninstall"

if [[ "$fail" -ne 0 ]]; then echo "SMOKE FAILED"; exit 1; fi
echo "SMOKE PASSED"
exit 0
