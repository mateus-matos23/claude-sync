# claude-setup

Configurações globais do Claude Code (`~/.claude`) versionadas e ligadas por symlink.

## Instalar numa máquina

```sh
git clone <repo> && cd claude-setup
./install.sh
```

Cada item de `home/` vira symlink em `~/.claude`. O que já existia vai para `~/.claude/backups/sync-<timestamp>/` — compare com `diff -r` e traga para `home/` o que quiser manter.

## Dia a dia

- Chegou em outra máquina: `git pull` (os links já apontam para o repo).
- Mudou algo (editando `~/.claude/...` ou `home/...`, é o mesmo arquivo): `git commit` e `git push`.
- `./install.sh --check` confere os links. Se o Claude Code regravar `settings.json` como arquivo comum (ex.: via `/config`), o check acusa: copie-o para `home/settings.json` e rode `./install.sh`.

## Sincronizado

`CLAUDE.md`, `settings.json`, `claude-security-guidance.md`, `agents/`, `hooks/`, `skills/code-style`, `skills/fatiar`, `playwright-mcp.json`. Para adicionar um item, copie-o para `home/` e inclua-o em `ITEMS` no `install.sh`.

## Playwright MCP (agente `verificador-ui`)

O registro do servidor fica em `~/.claude.json`, que não é sincronizado. Em cada máquina, uma vez:

```sh
claude mcp add -s user playwright -- npx -y @playwright/mcp@0.0.83 --config "$HOME/.claude/playwright-mcp.json"
npx -y playwright@1.64.0-alpha-1790635538000 install chromium chromium-headless-shell
```

A versão do Playwright no segundo comando deve ser a que o `@playwright/mcp` fixado usa (`npm view @playwright/mcp@<versão> dependencies`). `playwright-mcp.json` usa Chromium headless e isolado; screenshots vão para `/tmp/playwright-mcp`.

## Não sincronizado

Credenciais, histórico, `projects/` (memória), sessões, cache, backups, `plugins/` (reinstalados a partir de `enabledPlugins`/`extraKnownMarketplaces`), `skills/synced/` (gerenciado pelo claude.ai) e `~/.claude.json`.

Comandos de hook usam `"$HOME"/.claude/...`; não use caminho absoluto de usuário.

## Testes

```sh
./tests/install.test.sh
```
