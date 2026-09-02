#!/usr/bin/env bash
# Copy (or remove) erixpo skills for any SKILL.md agent.
# Spec: https://agentskills.io/specification
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$PWD"
GLOBAL=0
DRY=0
UNINSTALL=0
PURGE=0
PURGE_WORKTREES=0
VERSION="0.3.1"

SKILL_NAMES=(
  erixpo
  erixpo-auto
  erixpo-docs
  erixpo-feature
  erixpo-fix
  erixpo-init
  erixpo-learn
  erixpo-new
  erixpo-review
  erixpo-search
  erixpo-work
)

SCRIPT_NAMES=(worktree.sh session-search.sh review-stage1.sh)
ADAPTER_NAMES=(claude.sh codex.sh cursor.sh gemini.sh generic.sh hermes.sh opencode.sh)

PROJECT_SKILL_ROOTS=(
  ".agents/skills"
  ".claude/skills"
  ".cursor/skills"
  ".codex/skills"
  ".github/skills"
  ".gemini/skills"
  ".opencode/skills"
)

GLOBAL_SKILL_ROOTS=(
  "$HOME/.agents/skills"
  "$HOME/.claude/skills"
  "$HOME/.cursor/skills"
  "$HOME/.codex/skills"
  "$HOME/.github/skills"
  "$HOME/.gemini/skills"
  "$HOME/.opencode/skills"
)

usage() {
  cat <<EOF
erixpo-workflow installer v${VERSION}

Usage: bash install.sh [--target DIR] [--global] [--dry-run]
       bash install.sh --uninstall [--target DIR] [--global] [--dry-run]
       bash install.sh --uninstall --purge [--purge-worktrees]

  --target DIR         Project to install into / remove from. Default: current directory
  --global             Also touch home-dir skill folders
  --uninstall          Remove the pack this script installed
  --purge              Also delete .erixpo machine state (memory, sessions, plan)
  --purge-worktrees    Also prune sibling ../.erixpo-worktrees/* for this repo
  --dry-run            Print destinations only
  -h, --help           Show this help

Install copies
  skills/*            → .agents/skills, .claude/skills, .cursor/skills,
                        .codex/skills, .github/skills, .gemini/skills,
                        .opencode/skills
  commands/erixpo.md  → .claude/commands, .agents/commands
  templates/          → .erixpo/pack-templates
  bin/ + adapters/    → .erixpo/bin + .erixpo/adapters
                        and bin/ + adapters/ at project root
  scripts/            → .erixpo/scripts and scripts/

Uninstall never deletes product files: AGENTS.md, CLAUDE.md, README.md,
documents/, source. Default uninstall also keeps .erixpo memory
(PROFILE / MEMORY / USER / learnings / sessions). Use --purge for those.

A manifest is written to .erixpo/install-manifest.txt so uninstall
only removes what this pack put there.
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
    --uninstall|uninstall|-u) UNINSTALL=1; shift ;;
    --purge) PURGE=1; UNINSTALL=1; shift ;;
    --purge-worktrees) PURGE_WORKTREES=1; UNINSTALL=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done

if [[ "$UNINSTALL" -eq 0 && ! -d "$DEST" ]]; then
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY mkdir $DEST"
  else
    mkdir -p "$DEST"
  fi
fi

if [[ ! -d "$DEST" ]]; then
  echo "target does not exist: $DEST" >&2
  exit 1
fi
DEST="$(cd "$DEST" && pwd)"
SRC="$ROOT/skills"
MANIFEST="$DEST/.erixpo/install-manifest.txt"

is_protected() {
  local p="$1"
  case "$p" in
    "$DEST"|"$DEST/"|"/"|"$HOME"|"$HOME/") return 0 ;;
  esac
  if [[ -e "$p/.git" || -d "$p/.git" ]]; then
    return 0
  fi
  return 1
}

rm_path() {
  local p="$1"
  if [[ -z "$p" ]]; then
    return 0
  fi
  if is_protected "$p"; then
    echo "skip protected $p"
    return 0
  fi
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY rm $p"
    return 0
  fi
  if [[ -e "$p" || -L "$p" ]]; then
    rm -rf "$p"
    echo "removed $p"
  fi
}

rmdir_empty() {
  local p="$1"
  [[ -d "$p" ]] || return 0
  is_protected "$p" && return 0
  if [[ -z "$(ls -A "$p" 2>/dev/null || true)" ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "DRY rmdir $p"
    else
      rmdir "$p" 2>/dev/null || true
      echo "removed empty $p"
    fi
  fi
}

manifest_add() {
  local rel="$1"
  [[ "$DRY" -eq 1 ]] && return 0
  mkdir -p "$(dirname "$MANIFEST")"
  if [[ ! -f "$MANIFEST" ]] || ! grep -Fxq "$rel" "$MANIFEST" 2>/dev/null; then
    printf '%s\n' "$rel" >> "$MANIFEST"
  fi
}

copy_tree() {
  local from="$1" to="$2" rel="$3"
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY $from -> $to"
    return
  fi
  mkdir -p "$(dirname "$to")"
  rm -rf "$to"
  cp -R "$from" "$to"
  if [[ -n "$rel" ]]; then
    manifest_add "$rel"
  fi
}

install_skills() {
  local base="$1" rel_base="$2"
  local skill
  mkdir -p "$base" 2>/dev/null || true
  for skill in "$SRC"/*; do
    [[ -d "$skill" && -f "$skill/SKILL.md" ]] || continue
    local name
    name="$(basename "$skill")"
    copy_tree "$skill" "$base/$name" "$rel_base/$name"
    echo "installed $name -> $base/$name"
  done
}

install_commands() {
  local dest_dir="$1" rel_base="$2"
  [[ -d "$ROOT/commands" ]] || return 0
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY commands -> $dest_dir"
    return
  fi
  mkdir -p "$dest_dir"
  cp -R "$ROOT/commands/." "$dest_dir/"
  for f in "$ROOT/commands/"*; do
    [[ -e "$f" ]] || continue
    manifest_add "$rel_base/$(basename "$f")"
  done
  echo "installed commands -> $dest_dir"
}

install_cli() {
  local bin_dest="$1" ad_dest="$2" bin_rel="$3" ad_rel="$4"
  [[ -d "$ROOT/bin" ]] || return 0
  if [[ "$DRY" -eq 1 ]]; then
    echo "DRY bin -> $bin_dest"
    echo "DRY adapters -> $ad_dest"
    return
  fi
  mkdir -p "$bin_dest" "$ad_dest"
  cp -R "$ROOT/bin/." "$bin_dest/"
  manifest_add "$bin_rel/erixpo"
  if [[ -d "$ROOT/adapters" ]]; then
    cp -R "$ROOT/adapters/." "$ad_dest/"
    local a
    for a in "$ROOT/adapters/"*.sh; do
      [[ -f "$a" ]] || continue
      manifest_add "$ad_rel/$(basename "$a")"
    done
  fi
  chmod +x "$bin_dest/erixpo" 2>/dev/null || true
  chmod +x "$ad_dest/"*.sh 2>/dev/null || true
  echo "installed CLI -> $bin_dest"
}

do_install() {
  [[ -d "$SRC" ]] || { echo "skills/ missing in $ROOT" >&2; exit 1; }

  if [[ "$DRY" -eq 0 ]]; then
    mkdir -p "$DEST/.erixpo"
    : > "$MANIFEST"
    printf '# erixpo-workflow %s installed %s\n' "$VERSION" "$(date -Iseconds 2>/dev/null || date)" >> "$MANIFEST"
  fi

  local rel
  for rel in "${PROJECT_SKILL_ROOTS[@]}"; do
    install_skills "$DEST/$rel" "$rel"
  done

  install_commands "$DEST/.claude/commands" ".claude/commands"
  install_commands "$DEST/.agents/commands" ".agents/commands"

  if [[ -d "$ROOT/templates" ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "DRY templates -> $DEST/.erixpo/pack-templates"
    else
      mkdir -p "$DEST/.erixpo/pack-templates"
      cp -R "$ROOT/templates/." "$DEST/.erixpo/pack-templates/"
      manifest_add ".erixpo/pack-templates"
    fi
    echo "installed templates -> $DEST/.erixpo/pack-templates"
  fi

  install_cli "$DEST/.erixpo/bin" "$DEST/.erixpo/adapters" ".erixpo/bin" ".erixpo/adapters"
  install_cli "$DEST/bin" "$DEST/adapters" "bin" "adapters"

  if [[ -d "$ROOT/scripts" ]]; then
    if [[ "$DRY" -eq 1 ]]; then
      echo "DRY scripts -> $DEST/.erixpo/scripts and $DEST/scripts"
    else
      mkdir -p "$DEST/.erixpo/scripts" "$DEST/scripts"
      cp -R "$ROOT/scripts/." "$DEST/.erixpo/scripts/"
      cp -R "$ROOT/scripts/." "$DEST/scripts/"
      chmod +x "$DEST/.erixpo/scripts/"*.sh "$DEST/scripts/"*.sh 2>/dev/null || true
      local s
      for s in "${SCRIPT_NAMES[@]}"; do
        manifest_add ".erixpo/scripts/$s"
        manifest_add "scripts/$s"
      done
    fi
    echo "installed scripts -> $DEST/scripts"
  fi

  if [[ "$GLOBAL" -eq 1 ]]; then
    local base
    for base in "${GLOBAL_SKILL_ROOTS[@]}"; do
      install_skills "$base" ""
    done
    install_commands "$HOME/.claude/commands" ""
    install_commands "$HOME/.agents/commands" ""
  fi

  echo
  echo "erixpo-workflow ${VERSION} installed into $DEST"
  echo "uninstall: bash $ROOT/install.sh --uninstall"
  echo "           or: bin/erixpo uninstall"
  if [[ ! -f "$DEST/AGENTS.md" ]]; then
    echo "Next: in this project, run /erixpo   (router will init first)"
  else
    echo "Next: /erixpo plus whatever you want done"
  fi
}

remove_skill_named() {
  local base="$1"
  local name
  for name in "${SKILL_NAMES[@]}"; do
    rm_path "$base/$name"
  done
  rmdir_empty "$base"
}

remove_known_files() {
  local dest_dir="$1"
  local names=("${@:2}")
  local n
  for n in "${names[@]}"; do
    rm_path "$dest_dir/$n"
  done
  rmdir_empty "$dest_dir"
}

do_uninstall() {
  echo "uninstalling erixpo-workflow from $DEST"
  echo "keeps product files (AGENTS.md, documents/, README, source)"
  if [[ "$PURGE" -eq 0 ]]; then
    echo "keeps .erixpo memory (PROFILE / MEMORY / USER / learnings / sessions)"
  fi

  if [[ -f "$MANIFEST" ]]; then
    local line
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      case "$line" in
        /*) rm_path "$line" ;;
        *) rm_path "$DEST/$line" ;;
      esac
    done < "$MANIFEST"
  else
    echo "no install-manifest.txt — removing known pack names only"
    local rel
    for rel in "${PROJECT_SKILL_ROOTS[@]}"; do
      remove_skill_named "$DEST/$rel"
      rmdir_empty "$DEST/$(dirname "$rel")"
    done
    remove_known_files "$DEST/.claude/commands" erixpo.md
    remove_known_files "$DEST/.agents/commands" erixpo.md
    rmdir_empty "$DEST/.claude"
    rmdir_empty "$DEST/.agents"
    remove_known_files "$DEST/scripts" "${SCRIPT_NAMES[@]}"
    remove_known_files "$DEST/.erixpo/scripts" "${SCRIPT_NAMES[@]}"
    remove_known_files "$DEST/adapters" "${ADAPTER_NAMES[@]}"
    remove_known_files "$DEST/.erixpo/adapters" "${ADAPTER_NAMES[@]}"
    rm_path "$DEST/bin/erixpo"
    rmdir_empty "$DEST/bin"
    rm_path "$DEST/.erixpo/bin/erixpo"
    rmdir_empty "$DEST/.erixpo/bin"
    rm_path "$DEST/.erixpo/pack-templates"
  fi

  if [[ "$GLOBAL" -eq 1 ]]; then
    local base
    for base in "${GLOBAL_SKILL_ROOTS[@]}"; do
      remove_skill_named "$base"
      rmdir_empty "$(dirname "$base")"
    done
    remove_known_files "$HOME/.claude/commands" erixpo.md
    remove_known_files "$HOME/.agents/commands" erixpo.md
  fi

  if [[ "$PURGE_WORKTREES" -eq 1 ]]; then
    local repo base wt
    repo="$(basename "$DEST")"
    base="$(dirname "$DEST")/.erixpo-worktrees"
    if [[ -d "$base" ]]; then
      shopt -s nullglob
      for wt in "$base/$repo"-*; do
        if [[ -d "$wt/.git" || -f "$wt/.git" ]]; then
          if git -C "$DEST" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            git -C "$DEST" worktree remove --force "$wt" 2>/dev/null || echo "skip $wt"
          else
            echo "skip $wt (not removing a git checkout with rm -rf)"
          fi
        fi
      done
      shopt -u nullglob
      rmdir_empty "$base"
    fi
  elif [[ -d "$(dirname "$DEST")/.erixpo-worktrees" ]]; then
    echo "left sibling worktrees. pass --purge-worktrees to prune them via git worktree remove"
  fi

  if [[ "$PURGE" -eq 1 ]]; then
    echo "purging .erixpo machine state"
    rm_path "$DEST/.erixpo"
  else
    rm_path "$DEST/.erixpo/install-manifest.txt"
    rmdir_empty "$DEST/.erixpo"
  fi

  echo
  echo "erixpo-workflow removed from $DEST"
  if [[ "$PURGE" -eq 0 && -d "$DEST/.erixpo" ]]; then
    echo "memory kept in $DEST/.erixpo  (delete with --purge if you want that gone too)"
  fi
  echo "product files were not touched."
}

if [[ "$UNINSTALL" -eq 1 ]]; then
  do_uninstall
else
  do_install
fi
