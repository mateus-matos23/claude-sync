#!/usr/bin/env bash
# PostToolUse/Edit|Write: formata e aplica correções seguras do biome no arquivo editado.
# Erros não corrigíveis voltam ao Claude (exit 2). Imports/variáveis não usados ficam para
# o gate `pnpm check`, porque uma edição em andamento pode adicionar o import antes do uso.
set -uo pipefail

file=$(jq -r '.tool_input.file_path // ""')

case $file in
  *.ts | *.tsx | *.mts | *.cts | *.js | *.jsx | *.mjs | *.cjs | *.json | *.jsonc) ;;
  *) exit 0 ;;
esac
[[ -f $file ]] || exit 0

project_root=""
directory=$(dirname "$file")
while [[ $directory != / ]]; do
  if [[ -f $directory/biome.json || -f $directory/biome.jsonc ]]; then
    project_root=$directory
    break
  fi
  directory=$(dirname "$directory")
done
biome="$project_root/node_modules/.bin/biome"
[[ -n $project_root && -x $biome ]] || exit 0

if ! output=$(cd "$project_root" && "$biome" check --write --no-errors-on-unmatched \
  --skip=correctness/noUnusedImports --skip=correctness/noUnusedVariables "$file" 2>&1); then
  printf 'biome encontrou problemas em %s:\n%s\n' "$file" "$output" >&2
  exit 2
fi
exit 0
