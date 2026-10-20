#!/usr/bin/env bash
# Testes dos hooks: cada caso envia um JSON ao script e compara a decisão obtida.
# Uso: bash ~/.claude/hooks/test-hooks.sh
set -uo pipefail
hooks_dir=$(cd "$(dirname "$0")" && pwd)
biome_source_project="$HOME/Trabalho/sgi-backend"
failures=0

decision_of() {
  local output
  output=$("$hooks_dir/$1" <<<"$2")
  if [[ -z $output ]]; then
    echo allow
  else
    jq -r '.hookSpecificOutput.permissionDecision' <<<"$output"
  fi
}

expect_bash() {
  local script=$1 expected=$2 command=$3 actual
  actual=$(decision_of "$script" "$(jq -n --arg c "$command" '{tool_input: {command: $c}}')")
  report "$script" "$expected" "$actual" "$command"
}

expect_agent() {
  local expected=$1 tool_input=$2 actual
  actual=$(decision_of guard-subagent-model.sh "$(jq -n --argjson t "$tool_input" --arg cwd "$fake_home/project" '{tool_input: $t, cwd: $cwd}')")
  report guard-subagent-model.sh "$expected" "$actual" "$tool_input"
}

report() {
  if [[ $2 == "$3" ]]; then
    printf 'ok    %-26s %-6s %s\n' "$1" "$3" "$4"
  else
    printf 'FALHA %-26s esperado=%s obtido=%s %s\n' "$1" "$2" "$3" "$4"
    failures=$((failures + 1))
  fi
}

# Dependências
expect_bash guard-dependencies.sh allow 'pnpm install'
expect_bash guard-dependencies.sh allow 'pnpm install --frozen-lockfile'
expect_bash guard-dependencies.sh allow 'pnpm i'
expect_bash guard-dependencies.sh allow 'npm ci'
expect_bash guard-dependencies.sh allow 'pnpm test'
expect_bash guard-dependencies.sh allow 'git commit -m "pnpm add x"'
expect_bash guard-dependencies.sh deny 'pnpm add -D write-excel-file'
expect_bash guard-dependencies.sh deny 'pnpm install left-pad'
expect_bash guard-dependencies.sh deny 'npm i left-pad'
expect_bash guard-dependencies.sh deny 'yarn add left-pad'
expect_bash guard-dependencies.sh deny 'pnpm --filter web add left-pad'
expect_bash guard-dependencies.sh deny 'pnpm -C ../sgi-frontend up'
expect_bash guard-dependencies.sh deny 'pnpm remove left-pad'
expect_bash guard-dependencies.sh deny 'pnpm lint && pnpm add zod'

# Banco
expect_bash guard-database.sh allow 'NODE_ENV=test pnpm db:seed'
expect_bash guard-database.sh allow 'NODE_ENV=test pnpm prisma migrate reset --force'
expect_bash guard-database.sh allow 'env NODE_ENV=test pnpm exec prisma migrate dev'
expect_bash guard-database.sh allow 'PRISMA_DATABASE_URL="postgresql://u:p@localhost:5433/sgi_test" pnpm db:seed'
expect_bash guard-database.sh allow 'pnpm db:migrate:test'
expect_bash guard-database.sh allow 'pnpm db:migrate:status'
expect_bash guard-database.sh allow 'pnpm prisma validate'
expect_bash guard-database.sh allow 'git commit -m "prisma migrate dev; db:seed"'
expect_bash guard-database.sh deny 'pnpm db:seed'
expect_bash guard-database.sh deny 'pnpm run db:seed'
expect_bash guard-database.sh deny 'pnpm db:migrate'
expect_bash guard-database.sh deny 'npx prisma migrate reset --force'
expect_bash guard-database.sh deny 'prisma db execute --file x.sql'
expect_bash guard-database.sh deny 'pnpm totvs:sync'
expect_bash guard-database.sh deny 'NODE_ENV=test pnpm db:migrate:deploy'
expect_bash guard-database.sh deny 'NODE_ENV=test pnpm test && pnpm db:seed'
expect_bash guard-database.sh deny 'PRISMA_DATABASE_URL=postgresql://u:p@localhost/sgi pnpm db:seed'
expect_bash guard-database.sh deny 'pnpm prisma db push'
expect_bash guard-database.sh deny 'NODE_ENV=test npx prisma db push'

# Modelo de subagente
fake_home=$(mktemp -d)
mkdir -p "$fake_home/.claude/agents" "$fake_home/project/.claude/agents"
printf -- '---\nname: caro\nmodel: opus\n---\ncorpo model: haiku\n' >"$fake_home/.claude/agents/caro.md"
printf -- '---\nname: barato\nmodel: haiku\n---\n' >"$fake_home/.claude/agents/barato.md"
printf -- '---\nname: barato\nmodel: inherit\n---\n' >"$fake_home/project/.claude/agents/herda.md"
printf -- '---\nname: sem-modelo\n---\nmodel: opus\n' >"$fake_home/.claude/agents/sem-modelo.md"
export HOME=$fake_home
expect_agent allow '{"subagent_type": "Explore"}'
expect_agent allow '{"model": "haiku"}'
expect_agent allow '{"model": "sonnet", "subagent_type": "caro"}'
expect_agent allow '{"subagent_type": "barato"}'
expect_agent allow '{"subagent_type": "sem-modelo"}'
expect_agent deny '{"model": "opus"}'
expect_agent deny '{"model": "fable"}'
expect_agent deny '{"subagent_type": "fork"}'
expect_agent deny '{"subagent_type": "caro"}'
expect_agent deny '{"subagent_type": "herda"}'
rm -rf "$fake_home"

# Biome
project=$(mktemp -d)
cat >"$project/biome.json" <<'JSON'
{
  "javascript": { "formatter": { "semicolons": "asNeeded" } },
  "linter": { "rules": { "suspicious": { "noExplicitAny": "error" } } }
}
JSON
ln -s "$biome_source_project/node_modules" "$project/node_modules"
printf 'const   valor = 1\nexport { valor }\n' >"$project/formatado.ts"
printf 'export const valor: any = 1\n' >"$project/invalido.ts"
printf '# titulo   \n' >"$project/notas.md"
unused_import='import { readFile } from "node:fs"\nexport const valor = 1\n'
printf "$unused_import" >"$project/import-nao-usado.ts"
outside=$(mktemp -d)
printf 'const   x = 1\n' >"$outside/sem-biome.ts"

expect_biome() {
  local expected_exit=$1 file=$2 actual_exit
  jq -n --arg f "$file" '{tool_input: {file_path: $f}}' | "$hooks_dir/format-with-biome.sh" 2>/dev/null
  actual_exit=$?
  report format-with-biome.sh "exit=$expected_exit" "exit=$actual_exit" "$file"
}
expect_biome 0 "$project/formatado.ts"
report format-with-biome.sh reformatado "$([[ $(head -1 "$project/formatado.ts") == 'const valor = 1' ]] && echo reformatado || echo intacto)" formatado.ts
expect_biome 2 "$project/invalido.ts"
expect_biome 0 "$project/notas.md"
expect_biome 0 "$project/import-nao-usado.ts"
report format-with-biome.sh import-mantido "$(grep -q readFile "$project/import-nao-usado.ts" && echo import-mantido || echo removido)" import-nao-usado.ts
expect_biome 0 "$outside/sem-biome.ts"
expect_biome 0 "$project/inexistente.ts"
rm -rf "$project" "$outside"

echo
if ((failures > 0)); then
  echo "$failures caso(s) falharam"
  exit 1
fi
echo "todos os casos passaram"
