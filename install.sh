#!/usr/bin/env bash
# Copy (or remove) erixpo skills for the agent that is actually running.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")" && pwd)"
DEST="$PWD"
GLOBAL=0; DRY=0; UNINSTALL=0; PURGE=0; PURGE_WORKTREES=0; PURGE_DOCS=0; EXPAND=0; DETECT_ONLY=0
VERSION="0.6.0"
HOST_ARG="auto"
SKILL_NAMES=(erixpo erixpo-auto erixpo-docs erixpo-feature erixpo-fix erixpo-init erixpo-learn erixpo-new erixpo-review erixpo-search erixpo-ui erixpo-uninstall erixpo-work)
SCRIPT_NAMES=(worktree.sh session-search.sh review-stage1.sh detect-host.sh detect-capabilities.sh classify-signals.py)
ADAPTER_NAMES=(claude.sh codex.sh cursor.sh gemini.sh generic.sh hermes.sh opencode.sh)
usage() { cat <<EOF
erixpo-workflow installer v${VERSION}
Usage: bash install.sh [--host auto|HOST|all] [--expand] [--detect]
       bash install.sh --uninstall [--purge] [--purge-worktrees] [--purge-docs]
Default: .agents/skills + the detected host only. Not every vendor folder.
EOF
}
while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) DEST="${2:-}"; shift 2 ;;
    --host) HOST_ARG="${2:-}"; shift 2 ;;
    --global) GLOBAL=1; shift ;;
    --dry-run) DRY=1; shift ;;
    --uninstall|uninstall|-u) UNINSTALL=1; shift ;;
    --purge) PURGE=1; UNINSTALL=1; shift ;;
    --purge-worktrees) PURGE_WORKTREES=1; UNINSTALL=1; shift ;;
    --purge-docs) PURGE_DOCS=1; UNINSTALL=1; shift ;;
    --expand) EXPAND=1; shift ;;
    --detect) DETECT_ONLY=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "unknown arg: $1" >&2; usage; exit 1 ;;
  esac
done
host_skill_rel() { case "$1" in cursor) echo .cursor/skills ;; claude) echo .claude/skills ;; codex) echo .codex/skills ;; gemini) echo .gemini/skills ;; opencode) echo .opencode/skills ;; github) echo .github/skills ;; windsurf) echo .windsurf/skills ;; cline) echo .cline/skills ;; *) echo .agents/skills ;; esac; }
host_cmd_rel() { case "$1" in claude) echo .claude/commands ;; cursor) echo .cursor/commands ;; agents|generic|crush|aider|hermes) echo .agents/commands ;; *) echo ;; esac; }
host_home_skill() { case "$1" in cursor) echo "$HOME/.cursor/skills" ;; claude) echo "$HOME/.claude/skills" ;; codex) echo "$HOME/.codex/skills" ;; gemini) echo "$HOME/.gemini/skills" ;; opencode) echo "$HOME/.opencode/skills" ;; github) echo "$HOME/.github/skills" ;; windsurf) echo "$HOME/.windsurf/skills" ;; cline) echo "$HOME/.cline/skills" ;; *) echo "$HOME/.agents/skills" ;; esac; }
detect_primary() {
  local line primary
  if [[ -f "$ROOT/scripts/detect-host.sh" ]]; then line="$(bash "$ROOT/scripts/detect-host.sh" || true)"; else line=$'generic\t'; fi
  primary="${line%%$'\t'*}"; [[ -n "$primary" ]] || primary=generic; printf '%s' "$primary"
}
uniq_words() { local seen="|" out="" x; for x in "$@"; do [[ -z "$x" ]] && continue; case "$seen" in *"|$x|"*) continue ;; esac; seen="${seen}${x}|"; out="${out:+$out }$x"; done; printf '%s' "$out"; }
read_saved_hosts() { local f="$DEST/.erixpo/hosts.txt" line; [[ -f "$f" ]] || return 0; while IFS= read -r line || [[ -n "$line" ]]; do [[ -z "$line" || "$line" == \#* ]] && continue; printf '%s\n' "$line"; done < "$f"; }
ALL_HOSTS=(cursor claude codex gemini opencode github windsurf cline crush aider hermes generic)
resolve_hosts() {
  local primary h; primary="$(detect_primary)"; DETECTED="$primary"
  if [[ "$HOST_ARG" == all ]]; then HOSTS=("${ALL_HOSTS[@]}"); HOSTS+=(agents); return; fi
  if [[ "$HOST_ARG" != auto ]]; then HOSTS=("$HOST_ARG"); else HOSTS=("$primary"); fi
  HOSTS+=(agents)
  if [[ "$EXPAND" -eq 1 || "$HOST_ARG" == auto ]]; then
    saved_dump="$(read_saved_hosts || true)"
    if [[ -n "$saved_dump" ]]; then while IFS= read -r h; do [[ -n "$h" ]] && HOSTS+=("$h"); done <<EOF
$saved_dump
EOF
    fi
  fi
  HOSTS=($(uniq_words "${HOSTS[@]}"))
}
if [[ "$DETECT_ONLY" -eq 1 ]]; then echo "detected: $(detect_primary)"; [[ -f "$DEST/.erixpo/hosts.txt" ]] && cat "$DEST/.erixpo/hosts.txt"; exit 0; fi
[[ "$UNINSTALL" -eq 0 && ! -d "$DEST" ]] && mkdir -p "$DEST"
DEST="$(cd "$DEST" && pwd)"; SRC="$ROOT/skills"
MANIFEST="$DEST/.erixpo/install-manifest.txt"; HOSTS_FILE="$DEST/.erixpo/hosts.txt"
DETECTED=generic; HOSTS=(); resolve_hosts
is_protected() { local p="$1"; case "$p" in "$DEST"|"$DEST/"|"/"|"$HOME"|"$HOME/") return 0 ;; esac; [[ -e "$p/.git" || -d "$p/.git" ]] && return 0; return 1; }
rm_path() { local p="$1"; [[ -n "$p" ]] || return 0; is_protected "$p" && { echo "skip protected $p"; return 0; }; [[ "$DRY" -eq 1 ]] && { echo "DRY rm $p"; return 0; }; [[ -e "$p" || -L "$p" ]] && { rm -rf "$p"; echo "removed $p"; }; }
rmdir_empty() { local p="$1"; [[ -d "$p" ]] || return 0; is_protected "$p" && return 0; if [[ -z "$(ls -A "$p" 2>/dev/null || true)" ]]; then rmdir "$p" 2>/dev/null || true; fi; }
manifest_add() { local rel="$1"; [[ "$DRY" -eq 1 ]] && return 0; mkdir -p "$(dirname "$MANIFEST")"; grep -Fxq "$rel" "$MANIFEST" 2>/dev/null || printf '%s\n' "$rel" >> "$MANIFEST"; }
copy_tree() { local from="$1" to="$2" rel="$3"; mkdir -p "$(dirname "$to")"; rm -rf "$to"; cp -R "$from" "$to"; [[ -n "$rel" ]] && manifest_add "$rel"; }
install_skills() { local base="$1" rel_base="$2" skill name; mkdir -p "$base" 2>/dev/null || true; for skill in "$SRC"/*; do [[ -d "$skill" && -f "$skill/SKILL.md" ]] || continue; name="$(basename "$skill")"; copy_tree "$skill" "$base/$name" "$rel_base/$name"; echo "installed $name -> $base/$name"; done; }
install_commands() { local dest_dir="$1" rel_base="$2" f; [[ -d "$ROOT/commands" && -n "$dest_dir" ]] || return 0; mkdir -p "$dest_dir"; cp -R "$ROOT/commands/." "$dest_dir/"; for f in "$ROOT/commands/"*; do [[ -e "$f" ]] || continue; manifest_add "$rel_base/$(basename "$f")"; done; echo "installed commands -> $dest_dir"; }
install_cli() { local bin_dest="$1" ad_dest="$2" bin_rel="$3" ad_rel="$4" a; [[ -d "$ROOT/bin" ]] || return 0; mkdir -p "$bin_dest" "$ad_dest"; cp -R "$ROOT/bin/." "$bin_dest/"; manifest_add "$bin_rel/erixpo"; if [[ -d "$ROOT/adapters" ]]; then cp -R "$ROOT/adapters/." "$ad_dest/"; for a in "$ROOT/adapters/"*.sh; do [[ -f "$a" ]] || continue; manifest_add "$ad_rel/$(basename "$a")"; done; fi; chmod +x "$bin_dest/erixpo" 2>/dev/null || true; echo "installed CLI -> $bin_dest"; }
save_hosts() { mkdir -p "$DEST/.erixpo"; { echo "# hosts this project is installed for"; local h; for h in "${HOSTS[@]}"; do echo "$h"; done; } > "$HOSTS_FILE"; }
do_install() {
  [[ -d "$SRC" ]] || { echo "skills/ missing" >&2; exit 1; }
  echo "detected host: $DETECTED"; echo "installing for: ${HOSTS[*]}"
  mkdir -p "$DEST/.erixpo"
  if [[ "$EXPAND" -eq 0 || ! -f "$MANIFEST" ]]; then : > "$MANIFEST"; printf '# erixpo-workflow %s\n' "$VERSION" >> "$MANIFEST"; fi
  local h rel cmd seen="|"
  for h in "${HOSTS[@]}"; do
    rel="$(host_skill_rel "$h")"
    case "$seen" in *"|$rel|"*) ;; *) install_skills "$DEST/$rel" "$rel"; seen="${seen}${rel}|" ;; esac
    cmd="$(host_cmd_rel "$h")"
    if [[ -n "$cmd" ]]; then case "$seen" in *"|$cmd|"*) ;; *) install_commands "$DEST/$cmd" "$cmd"; seen="${seen}${cmd}|" ;; esac; fi
  done
  if [[ -d "$ROOT/templates" ]]; then mkdir -p "$DEST/.erixpo/pack-templates"; cp -R "$ROOT/templates/." "$DEST/.erixpo/pack-templates/"; manifest_add ".erixpo/pack-templates"; fi
  install_cli "$DEST/.erixpo/bin" "$DEST/.erixpo/adapters" .erixpo/bin .erixpo/adapters
  install_cli "$DEST/bin" "$DEST/adapters" bin adapters
  if [[ -d "$ROOT/scripts" ]]; then mkdir -p "$DEST/.erixpo/scripts" "$DEST/scripts"; cp -R "$ROOT/scripts/." "$DEST/.erixpo/scripts/"; cp -R "$ROOT/scripts/." "$DEST/scripts/"; chmod +x "$DEST/scripts/"*.sh 2>/dev/null || true; local s; for s in "${SCRIPT_NAMES[@]}"; do manifest_add ".erixpo/scripts/$s"; manifest_add "scripts/$s"; done; fi
  if [[ "$GLOBAL" -eq 1 ]]; then local h; for h in "${HOSTS[@]}"; do install_skills "$(host_home_skill "$h")" ""; done; fi
  save_hosts
  echo "erixpo-workflow ${VERSION} installed into $DEST (hosts: ${HOSTS[*]})"
}
do_uninstall() {
  echo "uninstalling erixpo-workflow from $DEST"
  if [[ -f "$MANIFEST" ]]; then
    local line; while IFS= read -r line || [[ -n "$line" ]]; do [[ -z "$line" || "$line" == \#* ]] && continue; rm_path "$DEST/$line"; done < "$MANIFEST"
  else
    local h rel cmd; for h in "${ALL_HOSTS[@]}" agents; do rel="$(host_skill_rel "$h")"; for n in "${SKILL_NAMES[@]}"; do rm_path "$DEST/$rel/$n"; done; cmd="$(host_cmd_rel "$h")"; [[ -n "$cmd" ]] && rm_path "$DEST/$cmd/erixpo.md"; done
    rm_path "$DEST/bin/erixpo"; rm_path "$DEST/.erixpo/pack-templates"
  fi
  if [[ "$PURGE_WORKTREES" -eq 1 ]]; then
    local repo base wt; repo="$(basename "$DEST")"; base="$(dirname "$DEST")/.erixpo-worktrees"
    if [[ -d "$base" ]]; then for wt in "$base/$repo"-*; do [[ -e "$wt/.git" ]] || continue; git -C "$DEST" worktree remove --force "$wt" 2>/dev/null || echo skip "$wt"; done; fi
  fi
  if [[ "$PURGE_DOCS" -eq 1 ]]; then rm_path "$DEST/documents"; rm_path "$DEST/AGENTS.md"; rm_path "$DEST/CLAUDE.md"; fi
  if [[ "$PURGE" -eq 1 ]]; then rm_path "$DEST/.erixpo"; else rm_path "$DEST/.erixpo/install-manifest.txt"; rm_path "$DEST/.erixpo/hosts.txt"; rmdir_empty "$DEST/.erixpo"; fi
  echo "erixpo-workflow removed from $DEST"
}
if [[ "$UNINSTALL" -eq 1 ]]; then do_uninstall; else do_install; fi
