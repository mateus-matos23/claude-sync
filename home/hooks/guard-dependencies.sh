#!/usr/bin/env bash
# PreToolUse/Bash: nega adicionar, atualizar ou remover dependências; o usuário roda com `!`.
# `pnpm install` sem pacote (restaurar o lockfile) passa direto.
set -uo pipefail
source "$(dirname "$0")/lib/command-segments.sh"

command=$(jq -r '.tool_input.command // ""')

changes_dependencies() {
  [[ ${SEGMENT_WORDS[0]:-} =~ ^(pnpm|npm|yarn|bun)$ ]] || return 1
  local i=1 subcommand=""
  while ((i < ${#SEGMENT_WORDS[@]})); do
    local word=${SEGMENT_WORDS[i]}
    i=$((i + 1))
    if [[ $word =~ ^(-C|--dir|--filter|-F|--prefix|--cwd)$ ]]; then
      i=$((i + 1))
    elif [[ $word != -* ]]; then
      subcommand=$word
      break
    fi
  done
  case $subcommand in
    add | up | update | upgrade | remove | rm | uninstall | un) return 0 ;;
    install | i | in)
      local word
      for word in "${SEGMENT_WORDS[@]:i}"; do
        [[ $word != -* ]] && return 0
      done
      return 1
      ;;
    *) return 1 ;;
  esac
}

while IFS= read -r segment; do
  parse_segment "$segment"
  if changes_dependencies; then
    emit_decision deny "Alteração de dependências exige aprovação do usuário: ${SEGMENT_WORDS[*]}. Peça ao usuário para rodar com '! <comando>'."
    exit 0
  fi
done < <(command_segments "$command")
exit 0
