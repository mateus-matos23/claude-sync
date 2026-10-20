# Funções compartilhadas pelos guards de comandos Bash.

# Divide um comando em segmentos simples (&&, ||, ;, |). Texto entre aspas que não
# é valor de atribuição vira "Q", para que mensagens como `git commit -m "prisma migrate"`
# não sejam confundidas com comandos.
command_segments() {
  printf '%s\n' "$1" |
    sed -E "s/(^|[^=])\"[^\"]*\"/\1Q/g; s/(^|[^=])'[^']*'/\1Q/g" |
    sed -E 's/&&|\|\||;|\|/\n/g'
}

# Preenche SEGMENT_ENV (atribuições iniciais, ex.: NODE_ENV=test) e
# SEGMENT_WORDS (o comando que sobra).
parse_segment() {
  local -a words
  read -ra words <<<"$1"
  SEGMENT_ENV=()
  local i=0
  [[ ${words[0]:-} == env ]] && i=1
  while ((i < ${#words[@]})) && [[ ${words[i]} =~ ^[A-Za-z_][A-Za-z0-9_]*= ]]; do
    SEGMENT_ENV+=("${words[i]}")
    i=$((i + 1))
  done
  SEGMENT_WORDS=("${words[@]:i}")
}

# Emite a decisão do PreToolUse no formato JSON esperado pelo Claude Code.
emit_decision() {
  jq -n --arg decision "$1" --arg reason "$2" \
    '{hookSpecificOutput: {hookEventName: "PreToolUse", permissionDecision: $decision, permissionDecisionReason: $reason}}'
}
