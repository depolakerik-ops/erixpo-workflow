#!/usr/bin/env bash
# Copy erixpo skills into a target project for any SKILL.md agent.
# Spec: https://agentskills.io/specification
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$PWD"
GLOBAL=0
DRY=0
VERSION="0.3.0"

usage() {
  cat <<EOF
erixpo-workflow installer v${VERSION}

Usage: bash install.sh [--target DIR] [--global] [--dry-run]

  --target DIR   Install into DIR (created if missing). Default: current directory
  --global       Also copy skills into home-dir skill folders
  --dry-run      Print destinations only
  -h, --help     Show this help

What gets copied
  skills/*            → .agents/skills, .claude/skills, .cursor/skills,
                        .codex/skills, .github/skills, .gemini/skills,
                        .opencode/skills  (project-local)
  commands/erixpo.md  → .claude/commands, .agents/commands
  templates/          → .erixpo/pack-templates
  bin/ + adapters/    → .erixpo/bin + .erixpo/adapters
                        (also bin/ + adapters/ at project root for PATH convenience)

This script does not write AGENTS.md or documents/. That is /erixpo init.
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)
      DEST="${2:-}"
      if [[ -z "$DEST" ]]; then
        echo "--target needs a directory" >&2
        exit 1
      fi
      shift 2
      ;;
    --global) GLOBAL=1; shift ;;
    --dry-run) DRY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ ! -d "$DEST" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY mkdir $DEST"
  else
    mkdir -p "$DEST"
  fi
fi
DEST="$(cd "$DEST" && pwd)"
SRC="$ROOT/skills"
[[ -d "$SRC" ]] || { echo "skills/ missing in $ROOT" >&2; exit 1; }

copy_tree() {
  local from="$1" to="$2"
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY $from -> $to"
    return
  fi
  mkdir -p "$(dirname "$to")"
  rm -rf "$to"
  cp -R "$from" "$to"
}

install_skills() {
  local base="$1"
  local skill
  mkdir -p "$base" 2>/dev/null || true
  for skill in "$SRC"/*; do
    [[ -d "$skill" && -f "$skill/SKILL.md" ]] || continue
    local name
    name="$(basename "$skill")"
    copy_tree "$skill" "$base/$name"
    echo "installed $name -> $base/$name"
  done
}

# Canonical + common agent skill roots (project-local).
PROJECT_SKILL_ROOTS=(
  ".agents/skills"
  ".claude/skills"
  ".cursor/skills"
  ".codex/skills"
  ".github/skills"
  ".gemini/skills"
  ".opencode/skills"
)

for rel in "${PROJECT_SKILL_ROOTS[@]}"; do
  install_skills "$DEST/$rel"
done

install_commands() {
  local dest_dir="$1"
  [[ -d "$ROOT/commands" ]] || return 0
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY commands -> $dest_dir"
    return
  fi
  mkdir -p "$dest_dir"
  cp -R "$ROOT/commands/." "$dest_dir/"
  echo "installed commands -> $dest_dir"
}

install_commands "$DEST/.claude/commands"
install_commands "$DEST/.agents/commands"

if [[ -d "$ROOT/templates" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY templates -> $DEST/.erixpo/pack-templates"
  else
    mkdir -p "$DEST/.erixpo/pack-templates"
    cp -R "$ROOT/templates/." "$DEST/.erixpo/pack-templates/"
  fi
  echo "installed templates -> $DEST/.erixpo/pack-templates"
fi

install_cli() {
  local bin_dest="$1" ad_dest="$2"
  [[ -d "$ROOT/bin" ]] || return 0
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY bin -> $bin_dest"
    echo "DRY adapters -> $ad_dest"
    return
  fi
  mkdir -p "$bin_dest" "$ad_dest"
  cp -R "$ROOT/bin/." "$bin_dest/"
  if [[ -d "$ROOT/adapters" ]]; then
    cp -R "$ROOT/adapters/." "$ad_dest/"
  fi
  chmod +x "$bin_dest/erixpo" 2>/dev/null || true
  chmod +x "$ad_dest/"*.sh 2>/dev/null || true
  echo "installed CLI -> $bin_dest"
}

# Hidden copy (does not pollute a product repo as much) + root copy so
# `bin/erixpo` from the README works immediately.
install_cli "$DEST/.erixpo/bin" "$DEST/.erixpo/adapters"
install_cli "$DEST/bin" "$DEST/adapters"

if [[ -d "$ROOT/scripts" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY scripts -> $DEST/.erixpo/scripts and $DEST/scripts"
  else
    mkdir -p "$DEST/.erixpo/scripts" "$DEST/scripts"
    cp -R "$ROOT/scripts/." "$DEST/.erixpo/scripts/"
    cp -R "$ROOT/scripts/." "$DEST/scripts/"
    chmod +x "$DEST/.erixpo/scripts/"*.sh "$DEST/scripts/"*.sh 2>/dev/null || true
  fi
  echo "installed scripts -> $DEST/scripts"
fi

if [[ "$GLOBAL" -eq 1 ]]; then
  GLOBAL_SKILL_ROOTS=(
    "$HOME/.agents/skills"
    "$HOME/.claude/skills"
    "$HOME/.cursor/skills"
    "$HOME/.codex/skills"
    "$HOME/.github/skills"
    "$HOME/.gemini/skills"
    "$HOME/.opencode/skills"
  )
  for base in "${GLOBAL_SKILL_ROOTS[@]}"; do
    install_skills "$base"
  done
  install_commands "$HOME/.claude/commands"
  install_commands "$HOME/.agents/commands"
fi

echo
echo "erixpo-workflow ${VERSION} installed into $DEST"
if [[ ! -f "$DEST/AGENTS.md" ]]; then
  echo "Next: in this project, run /erixpo   (router will init first)"
else
  echo "Next: /erixpo plus whatever you want done"
fi
