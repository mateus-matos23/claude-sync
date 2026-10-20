#!/usr/bin/env bash
# PreToolUse/Agent: subagentes só rodam em Haiku ou Sonnet. Forks herdam o modelo
# principal (Opus) e por isso também são negados.
set -uo pipefail
source "$(dirname "$0")/lib/command-segments.sh"

input=$(cat)
model=$(jq -r '.tool_input.model // ""' <<<"$input")
subagent_type=$(jq -r '.tool_input.subagent_type // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")

frontmatter_model() {
  sed -n '1{/^---$/!q};2,/^---$/{/^model:/{s/^model:[[:space:]]*//p;q}}' "$1"
}

if [[ $subagent_type == fork ]]; then
  emit_decision deny "Fork herda o modelo principal (Opus). Use um subagente com model haiku ou sonnet."
  exit 0
fi

source_of_model="parâmetro model"
if [[ -z $model && -n $subagent_type ]]; then
  for agent_file in "$cwd/.claude/agents/$subagent_type.md" "$HOME/.claude/agents/$subagent_type.md"; do
    if [[ -f $agent_file ]]; then
      model=$(frontmatter_model "$agent_file")
      source_of_model="frontmatter de $agent_file"
      break
    fi
  done
fi

case $model in
  "" | *haiku* | *sonnet*) exit 0 ;;
  *) emit_decision deny "Subagente com modelo '$model' ($source_of_model). Use model haiku ou sonnet." ;;
esac
exit 0
