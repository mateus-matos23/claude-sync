---
name: fatiar
description: Entrega uma feature em fatias sequenciais implementadas por subagentes Haiku/Sonnet, com revisão do agente principal contra um checklist fixo e gates entre fatias. Use quando o usuário pedir /fatiar ou para implementar uma feature planejada em fatias com delegação.
---

# Fatiar

Fluxo para features maiores: o agente principal planeja, delega uma fatia por vez e revisa. As regras do `CLAUDE.md` global e do projeto (`AGENTS.md`) continuam valendo.

## 1. Entender

- Leia somente a spec, os docs da feature e o código tocado.
- Pergunte (AskUserQuestion) toda ambiguidade que mude contrato, dados, segurança ou comportamento observável antes de planejar.

## 2. Planejar

- Divida em 3 a 7 fatias sequenciais (ex.: migration, domínio, persistência, caso de uso, HTTP/OpenAPI, docs). Cada fatia depende da anterior estar validada.
- Para cada fatia, registre: arquivos, critério de aceite verificável, testes esperados e gates.
- Apresente o plano e aguarde aprovação.

## 3. Delegar (uma fatia por vez)

- Um subagente escritor por vez, sempre com `model` explícito: `haiku` por padrão, `sonnet` para fatia complexa. Nunca Opus nem fork.
- O brief contém: objetivo, arquivos, critério de aceite, comandos de gate, o que não tocar e o **checklist abaixo** copiado na íntegra.
- Proíba no brief: dependências novas, edição de código gerado, comandos de banco sem `NODE_ENV=test`.
- Exija no brief uma autochecagem antes de retornar: rodar os gates da fatia, conferir cada item do checklist e devolver a saída final de cada gate (comando, exit code, contagem de testes) e os itens do checklist que não conseguiu confirmar. Entrega sem essa saída volta ao subagente sem revisão.

## 4. Revisar

Depois de cada entrega de subagente, nesta ordem:

1. **Revisão aprofundada**: delegue ao agente `revisor` (Sonnet, somente leitura), informando o diff da fatia, o contrato esperado e o checklist abaixo. Ele roda `engineering:code-review` e verifica os achados.
2. **Simplificação**: o agente principal roda `/simplify` sobre o diff da fatia. Ele edita arquivos, por isso fica fora do revisor. Descarte sugestões que contrariem a `code-style` ou o escopo.
3. **Segurança**: o plugin `security-guidance` revisa sozinho, com alertas por padrão nas edições, revisão do diff no fim do turno e revisão agêntica no commit. Todo achado dele precisa ser corrigido ou justificado antes de liberar a fatia.
4. **Checklist**: leia o diff (`git diff`) e confira cada item abaixo.

Achado confirmado volta ao subagente escritor via `SendMessage`, com feedback específico (até 2 iterações; depois corrija ou escale ao usuário). Se o `SendMessage` falhar, o agente principal aplica direto as correções pequenas e localizadas e registra isso no relatório final; correção grande vai a um novo subagente com o feedback no brief.

### Checklist de revisão

- [ ] Contas, contagens e números consistentes entre docs, testes e código.
- [ ] Camadas `http → application → domain`; domínio sem Nest/Prisma/HTTP/env; nenhum import interno de outro módulo.
- [ ] Recurso de unidade com `unitId` vindo da rota/contexto e teste de isolamento entre unidades.
- [ ] Fixtures de teste FK-válidas (usuários e registros reais, sem IDs aleatórios em FK como `audit.user_sub`).
- [ ] Contrato HTTP alterado → OpenAPI regenerado e `pnpm openapi:check` verde.
- [ ] Cache: leituras afetadas pela escrita são invalidadas.
- [ ] Erros como classes com código estável; nada do Prisma exposto ao cliente.
- [ ] Sem `any`, sem `as` para esconder tipo, sem dependência nova.
- [ ] Testes cobrem caso feliz, limites e regressão.

## 5. Gates

Rode no fim de cada fatia, contra o banco de teste (`NODE_ENV=test`): `pnpm check`, `pnpm typecheck`, `pnpm test`, os testes de integração/e2e relevantes e `git diff --check`. Uma falha bloqueia a próxima fatia.

Fatia que altera tela ou componente também passa pelo navegador: suba a aplicação (agente `executor` ou comando em background), delegue ao agente `verificador-ui` com a URL base, as rotas, os elementos alterados, o comportamento esperado e como autenticar, e confira os screenshots. Falha dele bloqueia a fatia como qualquer gate.

Com os gates verdes, faça um commit convencional em inglês com a fatia (sem incluir arquivos de outras fatias).

## 6. Relatório final

Tabela curta: fatia, status, gates executados, testes adicionados. Depois liste as suposições, limitações e o que não foi verificado (ex.: UI não aberta no navegador, com o motivo).
