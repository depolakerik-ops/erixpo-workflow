#!/usr/bin/env bash
# Detect which coding agent is running this process.
# Prints: PRIMARY<TAB>also,also
set -euo pipefail

uniq_list() {
  local seen="|" out="" x
  for x in "$@"; do
    [[ -z "$x" ]] && continue
    case "$seen" in *"|$x|"*) continue ;; esac
    seen="${seen}${x}|"
    out="${out:+$out }$x"
  done
  printf '%s' "$out"
}

walk_parents() {
  local pid="${1:-$$}" i=0 comm
  while [[ "$i" -lt 8 && -n "$pid" && "$pid" != "0" && "$pid" != "1" ]]; do
    comm="$(ps -o comm= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    printf '%s\n' "$comm"
    pid="$(ps -o ppid= -p "$pid" 2>/dev/null | tr -d ' ' || true)"
    i=$((i + 1))
  done
}

score_from_text() {
  local t
  t="$(printf '%s' "$1" | tr '[:upper:]' '[:lower:]')"
  case "$t" in
    *cursor-agent*|*cursor*) echo cursor ;;
    *claude*) echo claude ;;
    *codex*) echo codex ;;
    *gemini*) echo gemini ;;
    *opencode*) echo opencode ;;
    *windsurf*|*cascade*) echo windsurf ;;
    *cline*) echo cline ;;
    *crush*) echo crush ;;
    *aider*) echo aider ;;
    *hermes*) echo hermes ;;
    *copilot*) echo github ;;
    *devin*) echo generic ;;
  esac
}

found=()
[[ -n "${CURSOR_TRACE_ID:-}" || -n "${CURSOR_AGENT:-}" || -n "${CURSOR_EXTENSION_HOST:-}" ]] && found+=(cursor)
[[ -n "${CLAUDECODE:-}" || -n "${CLAUDE_CODE:-}" || -n "${CLAUDE_PLUGIN_ROOT:-}" || -n "${CLAUDE_CODE_ENTRYPOINT:-}" ]] && found+=(claude)
[[ -n "${CODEX_HOME:-}" || -n "${CODEX_THREAD_ID:-}" || -n "${CODEX_CI:-}" ]] && found+=(codex)
[[ -n "${GEMINI_CLI:-}" || "${TERM_PROGRAM:-}" == "gemini" ]] && found+=(gemini)
[[ -n "${OPENCODE:-}" || -n "${OPENCODE_DIR:-}" || -n "${OPENCODE_CONFIG:-}" ]] && found+=(opencode)
[[ -n "${AIDER_MODEL:-}" || -n "${AIDER_CONVENTIONS:-}" ]] && found+=(aider)
[[ -n "${WINDSURF:-}" || -n "${CASCADE_PLAN:-}" ]] && found+=(windsurf)
[[ -n "${CRUSH:-}" || -n "${CRUSH_CONFIG:-}" ]] && found+=(crush)
[[ -n "${HERMES:-}" ]] && found+=(hermes)

parent_dump="$(walk_parents "$$" || true)"
if [[ -n "$parent_dump" ]]; then
  while IFS= read -r comm; do
    hit="$(score_from_text "$comm")"
    [[ -n "$hit" ]] && found+=("$hit")
  done <<EOF
$parent_dump
EOF
fi

if [[ ${#found[@]} -eq 0 ]]; then
  command -v cursor >/dev/null 2>&1 && found+=(cursor)
  command -v claude >/dev/null 2>&1 && found+=(claude)
  command -v codex >/dev/null 2>&1 && found+=(codex)
  command -v gemini >/dev/null 2>&1 && found+=(gemini)
  command -v opencode >/dev/null 2>&1 && found+=(opencode)
  command -v aider >/dev/null 2>&1 && found+=(aider)
fi

list="$(uniq_list "${found[@]+"${found[@]}"}")"
if [[ -z "$list" ]]; then
  echo -e "generic\t"
  exit 0
fi
primary="${list%% *}"
rest="${list#"$primary"}"
rest="${rest# }"
rest="${rest// /,}"
printf '%s\t%s\n' "$primary" "$rest"
