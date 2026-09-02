#!/usr/bin/env bash
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
[[ -z "$CHECK" ]] && CHECK="$(read_field "$ROOT/AGENTS.md" check)"
CLASS=""
[[ -f "$ROOT/.erixpo/PROFILE.md" ]] && CLASS="$(grep -E '^class:' "$ROOT/.erixpo/PROFILE.md" 2>/dev/null | head -1 | sed 's/^class:[[:space:]]*//' | tr -d ' ' || true)"
if [[ -z "$CHECK" ]]; then
  bad "no check: line"
else
  case "$CHECK" in
    true|"exit 0"|":"|echo\ ok|echo\ "ok"|echo\ OK)
      bad "dummy check command: $CHECK" ;;
    *)
      note "check command: $CHECK"
      if bash -lc "$CHECK"; then note "check exited 0"; else bad "check failed"; fi
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
  secret_names="$(git -C "$ROOT" ls-files | grep -E '(^|/)\.env$|(^|/)id_rsa|\.pem$' | grep -v example || true)"
  [[ -n "$secret_names" ]] && bad "secret-looking tracked file names"
  docs_only=0
  case "$CLASS" in writing|research|ops|assistant) docs_only=1 ;; esac
  [[ "${ERIXPO_DOCS_ONLY:-0}" == 1 ]] && docs_only=1
  if [[ "$docs_only" -eq 0 ]]; then
    changed="$(git -C "$ROOT" diff --name-only HEAD 2>/dev/null || true)"
    changed+=$'\n'"$(git -C "$ROOT" diff --name-only --cached 2>/dev/null || true)"
    product=0; tests=0
    while IFS= read -r f; do
      [[ -z "$f" ]] && continue
      case "$f" in
        documents/*|*.md|.erixpo/*|AGENTS.md|CLAUDE.md|README.md) continue ;;
        *test*|*spec*|*Test*|tests/*|__tests__/*|*_test.*|*.test.*|*.spec.*) tests=1 ;;
        *) product=1 ;;
      esac
    done <<< "$changed"
    if [[ "$product" -eq 1 && "$tests" -eq 0 ]]; then
      bad "product files changed with no test/spec file in the diff"
    fi
  fi
fi
dummy_assert="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo -E 'expect\(true\)|assert True|assert\(true\)' "$ROOT" 2>/dev/null | head -10 || true)"
[[ -n "$dummy_assert" ]] && bad "dummy assertion expect(true)"
slop="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo -e 'TODO: implement' -e 'lorem ipsum' "$ROOT" 2>/dev/null | head -10 || true)"
[[ -n "$slop" ]] && bad "TODO: implement or lorem ipsum"
scan_secrets_text "$ROOT/.erixpo/sessions.jsonl"
scan_secrets_text "$ROOT/.erixpo/learnings.jsonl"
mkdir -p "$ROOT/.erixpo"
{ echo "## Stage 1"; echo "Result: $([[ $fail -eq 0 ]] && echo pass || echo fail)"; echo Notes:; for n in "${notes[@]}"; do echo "- $n"; done; } | tee "$ROOT/.erixpo/REVIEW-stage1.md"
if [[ $fail -ne 0 ]]; then echo "STAGE 1 FAILED"; exit 1; fi
echo "STAGE 1 PASSED"
