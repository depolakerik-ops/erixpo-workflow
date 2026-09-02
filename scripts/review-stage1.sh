#!/usr/bin/env bash
# Mechanical review. Exit 0 only if the gate is real and not obviously lied-to.
set -euo pipefail

ROOT="$(pwd)"
fail=0
notes=()

note() { notes+=("$1"); }
bad() { notes+=("FAIL: $1"); fail=1; }

read_field() {
  local file="$1" key="$2"
  [[ -f "$file" ]] || return 0
  grep -E "^${key}:" "$file" 2>/dev/null | head -1 | sed "s/^${key}:[[:space:]]*//" || true
}

CHECK="$(read_field "$ROOT/.erixpo/stack.md" check)"
if [[ -z "$CHECK" ]]; then
  CHECK="$(read_field "$ROOT/AGENTS.md" check)"
fi

CLASS=""
if [[ -f "$ROOT/.erixpo/PROFILE.md" ]]; then
  CLASS="$(grep -E '^class:' "$ROOT/.erixpo/PROFILE.md" 2>/dev/null | head -1 | sed 's/^class:[[:space:]]*//' | tr -d ' ' || true)"
fi

if [[ -z "$CHECK" ]]; then
  bad "no check: line in .erixpo/stack.md or AGENTS.md"
else
  case "$CHECK" in
    true|"exit 0"|":"|echo\ ok|echo\ "ok"|echo\ OK|echo\ "OK")
      bad "dummy check command: $CHECK"
      ;;
    *)
      note "check command: $CHECK"
      if bash -lc "$CHECK"; then
        note "check exited 0 in this review"
      else
        bad "check failed in this review"
      fi
      ;;
  esac
fi

scan_secrets_text() {
  local path="$1"
  [[ -f "$path" ]] || return 0
  if grep -E -I -n 'BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}' "$path" >/dev/null 2>&1; then
    bad "secret-looking content in $path"
  fi
}

if git -C "$ROOT" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  if git -C "$ROOT" status --porcelain | grep -q .; then
    note "working tree has changes (ok if this is the slice)"
  else
    note "working tree clean"
  fi
  secret_names="$(git -C "$ROOT" ls-files | grep -E '(^|/)\.env$|(^|/)id_rsa|(^|/)id_ed25519|\.pem$|\.p12$' | grep -v example || true)"
  if [[ -n "$secret_names" ]]; then
    bad "secret-looking tracked file names"
    note "$secret_names"
  fi
  secret_hits="$(git -C "$ROOT" grep -I -n -E 'BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}' -- . 2>/dev/null || true)"
  if [[ -n "$secret_hits" ]]; then
    bad "secret-looking content in tracked files"
  fi

  docs_only=0
  case "$CLASS" in
    writing|research|ops|assistant) docs_only=1 ;;
  esac
  [[ "${ERIXPO_DOCS_ONLY:-0}" == "1" ]] && docs_only=1

  if [[ "$docs_only" -eq 0 ]]; then
    changed="$(git -C "$ROOT" diff --name-only HEAD 2>/dev/null || true)"
    changed="${changed}"$'
'"$(git -C "$ROOT" diff --name-only --cached 2>/dev/null || true)"
    product=0
    tests=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      case "$f" in
        documents/*|*.md|.erixpo/*|AGENTS.md|CLAUDE.md|README.md) continue ;;
        *test*|*spec*|*Test*|*Spec*|tests/*|__tests__/*|*_test.*|*.test.*|*.spec.*) tests=1 ;;
        *) product=1 ;;
      esac
    done <<< "$changed"
    if [[ "$product" -eq 1 && "$tests" -eq 0 ]]; then
      bad "product files changed with no test/spec file in the diff (set ERIXPO_DOCS_ONLY=1 if this slice is not software)"
    fi
  else
    note "docs/non-software class — skipped test-file pairing"
  fi
else
  note "not a git repo; skipped diff/secret filename scan"
fi

dummy_assert="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo \
  -E 'expect\(true\)|assert True|assert\(true\)|XCTAssertTrue\(true\)' "$ROOT" 2>/dev/null | head -10 || true)"
if [[ -n "$dummy_assert" ]]; then
  bad "dummy assertion (expect(true) / assert True) found"
  note "$dummy_assert"
fi

slop="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo \
    -e 'TODO: implement' -e 'lorem ipsum' "$ROOT" 2>/dev/null | head -20 || true)"
if [[ -n "$slop" ]]; then
  bad "TODO: implement or lorem ipsum still in the tree"
fi

scan_secrets_text "$ROOT/.erixpo/sessions.jsonl"
scan_secrets_text "$ROOT/.erixpo/learnings.jsonl"

mkdir -p "$ROOT/.erixpo"
{
  echo "## Stage 1"
  echo "Result: $([[ $fail -eq 0 ]] && echo pass || echo fail)"
  echo "Notes:"
  for n in "${notes[@]}"; do
    echo "- $n"
  done
} | tee "$ROOT/.erixpo/REVIEW-stage1.md"

if [[ $fail -ne 0 ]]; then
  echo "STAGE 1 FAILED"
  exit 1
fi
echo "STAGE 1 PASSED"
exit 0
