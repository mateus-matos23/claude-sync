#!/usr/bin/env bash
# Testa install.sh contra um CLAUDE_HOME temporário.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$ROOT/install.sh"
REPO_HOME="$ROOT/home"
failures=0

fail() { echo "FALHOU: $1"; failures=$((failures + 1)); }
pass() { echo "ok: $1"; }

TMP_ROOT="$(mktemp -d)"
trap 'rm -r "$TMP_ROOT"' EXIT
new_home() { mktemp -d -p "$TMP_ROOT"; }
run() { CLAUDE_HOME="$1" "$INSTALL" "${@:2}" >/dev/null; }
backups() { find "$1/backups" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l; }

# 1. Alvo inexistente: cria links, inclusive em subdiretório (skills/).
h="$(new_home)"
run "$h"
if [[ "$(readlink "$h/settings.json")" == "$REPO_HOME/settings.json" &&
      "$(readlink "$h/skills/fatiar")" == "$REPO_HOME/skills/fatiar" ]]; then
  pass "cria links em home vazio"
else fail "cria links em home vazio"; fi
[[ "$(backups "$h")" -eq 0 ]] && pass "sem backup quando nada existia" || fail "sem backup quando nada existia"

# 2. Idempotente: segunda execução não gera backup.
run "$h"
[[ "$(backups "$h")" -eq 0 ]] && pass "idempotente" || fail "idempotente"

# 3. --check passa com tudo linkado.
run "$h" --check && pass "--check ok" || fail "--check ok"

# 4. Arquivo comum (ex.: Claude Code reescreveu settings.json): --check falha; install faz backup e relinka.
rm "$h/settings.json"; echo '{"local":true}' > "$h/settings.json"
if run "$h" --check; then fail "--check detecta arquivo comum"; else pass "--check detecta arquivo comum"; fi
run "$h"
bkp="$(find "$h/backups" -name settings.json)"
if [[ -L "$h/settings.json" && "$(cat "$bkp")" == '{"local":true}' ]]; then
  pass "backup preserva conteúdo e relinka"
else fail "backup preserva conteúdo e relinka"; fi

# 5. Diretório existente e link apontando para outro lugar são substituídos.
h="$(new_home)"
mkdir -p "$h/agents" "$h/skills"; echo x > "$h/agents/old.md"
ln -s /tmp "$h/skills/code-style"
run "$h"
if run "$h" --check && [[ -n "$(find "$h/backups" -path '*/agents/old.md')" ]]; then
  pass "substitui diretório e link alheio"
else fail "substitui diretório e link alheio"; fi

# 6. Argumento inválido sai com 2.
set +e; CLAUDE_HOME="$h" "$INSTALL" --foo 2>/dev/null; code=$?; set -e
[[ "$code" -eq 2 ]] && pass "argumento inválido" || fail "argumento inválido"

[[ "$failures" -eq 0 ]] && echo "todos os testes passaram" || { echo "$failures falha(s)"; exit 1; }
