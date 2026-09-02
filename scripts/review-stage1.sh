#!/usr/bin/env bash
# Mechanical review. Exit 0 only if the gate is real and not obviously lied-to.
set -euo pipefail

ROOT="$(pwd)"
fail=0
notes=()

note() { notes+=("$1"); }
bad() { notes+=("FAIL: $1"); fail=1; }

CHECK=""
if [[ -f "$ROOT/.erixpo/stack.md" ]]; then
  CHECK="$(grep -E '^check:' "$ROOT/.erixpo/stack.md" 2>/dev/null | head -1 | sed 's/^check:[[:space:]]*//' || true)"
fi
if [[ -z "$CHECK" && -f "$ROOT/AGENTS.md" ]]; then
  CHECK="$(grep -E '^check:' "$ROOT/AGENTS.md" 2>/dev/null | head -1 | sed 's/^check:[[:space:]]*//' || true)"
fi

if [[ -z "$CHECK" ]]; then
  bad "no check: line in .erixpo/stack.md or AGENTS.md"
else
  case "$CHECK" in
    true|"exit 0"|":"|echo\ ok|echo\ "ok"|echo\ OK)
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
  secret_hits="$(git -C "$ROOT" grep -I -n -E 'BEGIN PRIVATE KEY|AKIA[0-9A-Z]{16}' -- . 2>/dev/null || true)"
  if [[ -n "$secret_hits" ]]; then
    bad "secret-looking content in tracked files"
  fi
else
  note "not a git repo; skipped diff/secret filename scan"
fi

slop="$(grep -R -I -n --exclude-dir=node_modules --exclude-dir=.git --exclude-dir=.erixpo \
    -e 'TODO: implement' -e 'lorem ipsum' "$ROOT" 2>/dev/null | head -20 || true)"
if [[ -n "$slop" ]]; then
  bad "TODO: implement or lorem ipsum still in the tree"
fi

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
