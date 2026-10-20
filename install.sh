#!/usr/bin/env bash
# Liga os itens versionados em home/ a ~/.claude via symlink.
# Uso: ./install.sh          cria/corrige os links (faz backup do que existir)
#      ./install.sh --check  só verifica; sai com 1 se algum link estiver errado
set -euo pipefail

REPO_HOME="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/home"
CLAUDE_HOME="${CLAUDE_HOME:-$HOME/.claude}"

ITEMS=(
  CLAUDE.md
  settings.json
  claude-security-guidance.md
  agents
  hooks
  skills/code-style
  skills/fatiar
  playwright-mcp.json
)

is_linked() {
  local target="$CLAUDE_HOME/$1"
  [[ -L "$target" && "$(readlink "$target")" == "$REPO_HOME/$1" ]]
}

check() {
  local item broken=0
  for item in "${ITEMS[@]}"; do
    if is_linked "$item"; then
      echo "ok      $item"
    else
      echo "ERRADO  $item"
      broken=1
    fi
  done
  return "$broken"
}

install() {
  local item target backup_dir=""
  for item in "${ITEMS[@]}"; do
    [[ -e "$REPO_HOME/$item" ]] || { echo "ausente no repo: home/$item" >&2; exit 1; }
    target="$CLAUDE_HOME/$item"
    if is_linked "$item"; then
      echo "ok      $item"
      continue
    fi
    if [[ -e "$target" || -L "$target" ]]; then
      backup_dir="${backup_dir:-$CLAUDE_HOME/backups/sync-$(date +%Y%m%d-%H%M%S)}"
      mkdir -p "$(dirname "$backup_dir/$item")"
      mv "$target" "$backup_dir/$item"
      echo "backup  $item -> $backup_dir/$item"
    fi
    mkdir -p "$(dirname "$target")"
    ln -s "$REPO_HOME/$item" "$target"
    echo "linkado $item"
  done
}

case "${1:-}" in
  "") install ;;
  --check) check ;;
  *) echo "uso: $0 [--check]" >&2; exit 2 ;;
esac
