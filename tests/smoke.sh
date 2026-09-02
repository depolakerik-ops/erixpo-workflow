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
grep -q '0.6.0' "$TMP/.erixpo/install-manifest.txt" || bad "install manifest not 0.6.0"

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
git -C "$WT" add README.md
git -C "$WT" commit -qm init
iso_out="$(cd "$WT" && bash "$ROOT/scripts/worktree.sh" isolate --slug smoke)"
iso_id="$(printf '%s\n' "$iso_out" | awk -F': ' '/^id:/{print $2; exit}')"
iso_path="$(printf '%s\n' "$iso_out" | awk -F': ' '/^path:/{print $2; exit}')"
iso_branch="$(printf '%s\n' "$iso_out" | awk -F': ' '/^branch:/{print $2; exit}')"
if [[ -z "$iso_id" || ! -d "$iso_path" ]]; then
  bad "isolate did not create a worktree"
else
  echo y >> "$iso_path/README.md"
  git -C "$iso_path" add README.md
  git -C "$iso_path" commit -qm 'wt change'
  wt_sha="$(git -C "$iso_path" rev-parse HEAD)"
  if ! (cd "$WT" && bash "$ROOT/scripts/worktree.sh" close --id "$iso_id") >/dev/null; then
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
if ! (cd "$WT" && bash "$ROOT/scripts/worktree.sh" sweep) >/dev/null; then
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

say "== bin/erixpo close is wired =="
grep -q 'close' "$ROOT/bin/erixpo" || bad "bin/erixpo missing close"
grep -q 'classify' "$ROOT/bin/erixpo" || bad "bin/erixpo missing classify"

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
