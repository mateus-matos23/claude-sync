#!/usr/bin/env bash
# PreToolUse/Bash: comandos que alteram banco só rodam contra o banco de teste; os demais
# são negados e o usuário os executa com `!`.
# Sem NODE_ENV=test o prisma.config.ts carrega .env.development, então o alvo é o banco de dev.
set -uo pipefail
source "$(dirname "$0")/lib/command-segments.sh"

command=$(jq -r '.tool_input.command // ""')

targets_test_database() {
  local assignment
  for assignment in "${SEGMENT_ENV[@]}"; do
    [[ $assignment == NODE_ENV=test ]] && return 0
    local unquoted=${assignment//[\"\']/}
    [[ $unquoted =~ ^PRISMA_DATABASE_URL=.*/sgi_test(\?|$) ]] && return 0
  done
  return 1
}

# Imprime "push", "always", "unless-test" ou nada.
classify_segment() {
  local words=" ${SEGMENT_WORDS[*]} "
  local runner='^ ((pnpm|yarn|bun)( exec)? |npx |pnpx |bunx )?'
  if [[ $words =~ ${runner}prisma\ db\ push\  ]]; then
    echo push
  elif [[ $words =~ ${runner}prisma\ (migrate\ (dev|reset|deploy)|db\ (seed|execute))\  ]]; then
    echo unless-test
  elif [[ $words =~ ^\ (pnpm|npm|yarn|bun)(\ run)?\ db:migrate:deploy(:development)?\  ]]; then
    # db:migrate:deploy força NODE_ENV=production no próprio script.
    echo always
  elif [[ $words =~ ^\ (pnpm|npm|yarn|bun)(\ run)?\ (db:migrate|db:seed|db:totvs-section-codes|totvs:sync)\  ]]; then
    echo unless-test
  fi
}

while IFS= read -r segment; do
  parse_segment "$segment"
  case $(classify_segment) in
    push)
      emit_decision deny "prisma db push é proibido (AGENTS.md): use migration versionada."
      exit 0
      ;;
    always) ;;
    unless-test) targets_test_database && continue ;;
    *) continue ;;
  esac
  emit_decision deny "Comando altera um banco que não é o de teste (sem NODE_ENV=test): ${SEGMENT_WORDS[*]}. Use NODE_ENV=test ou peça ao usuário para rodar com '! <comando>'."
  exit 0
done < <(command_segments "$command")
exit 0
