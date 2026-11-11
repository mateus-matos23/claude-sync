---
name: fatiar
description: Entrega uma feature em fatias sequenciais implementadas por subagentes Haiku/Sonnet, com revisão do agente principal contra um checklist fixo e gates entre fatias. Use quando o usuário pedir /fatiar ou para implementar uma feature planejada em fatias com delegação.
---

# Fatiar

Fluxo para features maiores: o agente principal planeja, delega uma fatia por vez e revisa. As regras do `CLAUDE.md` global e do projeto (`AGENTS.md`) continuam valendo.

## 1. Entender

- Leia somente a spec, os docs da feature e o código tocado.
- Liste `.claude/skills/` do projeto e leia as skills relevantes à feature. Junto com o `AGENTS.md`, elas formam a régua do plano, da implementação e da revisão.
- Muitas skills de projeto são genéricas, de terceiros. Quando uma delas contradiz o `AGENTS.md` ou os `docs/` do projeto, vale o projeto (ex.: `HttpException` no service contra erro de domínio traduzido num filtro central).
- Entreviste o usuário em rodadas (AskUserQuestion) antes de planejar, cobrindo toda ambiguidade que mude contrato, dados, segurança ou comportamento observável:
  - Cada rodada traz só as decisões cujas dependências já estão resolvidas; cada pergunta vem com a sua resposta recomendada.
  - Fatos (o que o código, docs ou skills dizem) você busca sozinho; só decisões vão ao usuário.
  - No máximo 2 rodadas de até 4 perguntas. Decisão de baixo impacto não vira pergunta: adote a recomendação e registre-a como suposição no plano.

## 2. Planejar

- Divida em 3 a 7 fatias sequenciais (ex.: migration, domínio, persistência, caso de uso, HTTP/OpenAPI, docs). Cada fatia depende da anterior estar validada.
- Para cada fatia, registre: arquivos, critério de aceite verificável, testes esperados, gates, a régua da fatia e o risco.
- A régua da fatia tem quatro partes:
  - **Skills**: de 1 a 3 caminhos de `SKILL.md` do projeto.
  - **Regras**: de 3 a 8 regras concretas extraídas dessas skills e do `AGENTS.md` (ex.: "query key via `queryOptions` em `x.queries.ts`").
  - **Reusar**: helpers, componentes ou serviços existentes que a fatia deve usar, com caminho.
  - **Não se aplica**: regras das Skills listadas que o projeto contradiz, com o trecho do `AGENTS.md` ou dos `docs/` que prevalece.
- Regra de negócio da régua vem da spec ou da feature em `docs/`, nunca de código vizinho. O subagente segue a régua à risca, inclusive quando ela está errada.
- Classifique o risco assim:
  - **Alto**: domínio/regra de negócio, migration, auth/segurança, contrato HTTP/OpenAPI, isolamento por `unitId`, valores monetários.
  - **Baixo**: docs, ajuste de testes, wiring/DI, renomeação, UI sem lógica.
- Para fatias de risco alto, planeje os testes com `engineering:testing-strategy`.
- Apresente o plano, com as suposições, e aguarde aprovação. É a única parada planejada: aprovado o plano, execute todas as fatias até o relatório final.
- Só pare antes disso por bloqueio: gate vermelho depois de 2 iterações, ambiguidade nova de contrato, dados ou segurança, ou achado de segurança que não dá para corrigir nem justificar.

## 3. Delegar (uma fatia por vez)

- Fatia de risco baixo que toca até 3 arquivos: o agente principal implementa direto, sem subagente, porque cada subagente começa com contexto e cache frios. Revisão, gates e commit seguem iguais.
- Um subagente escritor por vez, sempre com `model: haiku` explícito, inclusive em risco alto: a régua no brief compensa o modelo menor. Se a primeira correção de um achado também falhar, a fatia vai para um novo subagente `sonnet`, com o brief e os achados. Nunca Opus nem fork. Isso vale para as demais fatias.
- O brief contém: objetivo, arquivos, critério de aceite, comandos de gate, o que não tocar, as **Regras**, o **Reusar** e o **Não se aplica** da fatia copiados na íntegra, os caminhos das **Skills** com a ordem de lê-los antes de editar, e o **checklist abaixo** copiado na íntegra. O que não estiver no brief o subagente decide sozinho, a partir do código vizinho, e é daí que vem a divergência de contrato.
- Proíba no brief: dependências novas, edição de código gerado, comandos de banco sem `NODE_ENV=test`.
- Exija no brief uma autochecagem antes de retornar: rodar os gates da fatia, conferir cada item do checklist e devolver a saída final de cada gate (comando, exit code, contagem de testes), cada regra da fatia marcada como aplicada (com arquivo) ou não aplicável (com motivo) e os itens do checklist que não conseguiu confirmar. Entrega sem essa saída volta ao subagente sem revisão.

## 4. Revisar

Depois de cada entrega de subagente, nesta ordem. Fatia de risco baixo pula o passo 1; o passo 2 roda uma vez sobre o diff final da feature, não por fatia.

1. **Revisão aprofundada** (só risco alto): delegue ao agente `revisor` (Sonnet, somente leitura), informando o diff da fatia, o contrato esperado, a régua da fatia (Skills, Regras, Reusar e Não se aplica) e o checklist abaixo. Ele roda `engineering:code-review` e verifica os achados.
2. **Simplificação** (uma vez, no fim): o agente principal roda `/simplify` sobre o diff da feature. Ele edita arquivos, por isso fica fora do revisor. Descarte sugestões que contrariem a `code-style` ou o escopo.
3. **Segurança**: o plugin `security-guidance` revisa sozinho, com alertas por padrão nas edições, revisão do diff no fim do turno e revisão agêntica no commit. Todo achado dele precisa ser corrigido ou justificado antes de liberar a fatia.
4. **Checklist**: leia o diff (`git diff`) e confira cada item abaixo.

Achado confirmado volta ao subagente escritor via `SendMessage`, com feedback específico. Se essa correção falhar, a fatia vai para `sonnet` (§3); se a do `sonnet` também falhar, corrija ou escale ao usuário. Se o `SendMessage` falhar, o agente principal aplica direto as correções pequenas e localizadas e registra isso no relatório final; correção grande vai a um novo subagente com o feedback no brief.

### Checklist de revisão

- [ ] Definição de pronto e regras do `AGENTS.md` do projeto atendidas (camadas, erros, fixtures, código gerado).
- [ ] Régua da fatia atendida: cada item de Regras aplicado ou justificado como não aplicável, e cada item de Reusar usado em vez de código novo.
- [ ] Reuso: nenhum componente, hook ou helper novo que duplique um bloco compartilhado do projeto (`src/common/` no backend, `docs/convencoes.md` §2 no frontend).
- [ ] Contas, contagens e números consistentes entre docs, testes e código.
- [ ] Recurso de unidade com `unitId` vindo da rota/contexto e teste de isolamento entre unidades.
- [ ] Contrato HTTP alterado → backend com `pnpm openapi:check` verde; frontend com `pnpm generate-api` e código gerado no commit.
- [ ] Escrita invalida as leituras afetadas (`get*QueryKey` gerado, `invalidateDashboard`).
- [ ] Sem `any`, sem `as` para esconder tipo, sem dependência nova.
- [ ] Testes cobrem caso feliz, limites e regressão.

## 5. Gates

Rode no fim de cada fatia os gates da definição de pronto do `AGENTS.md` do projeto. No backend, integração e e2e rodam contra o banco de teste (`NODE_ENV=test`). Uma falha bloqueia a próxima fatia.

Fatia que altera tela ou componente também passa pelo navegador: suba a aplicação (agente `executor` ou comando em background), delegue ao agente `verificador-ui` com a URL base, as rotas, os elementos alterados, o comportamento esperado e como autenticar, e confira os screenshots das falhas. Falha dele bloqueia a fatia como qualquer gate.

Com os gates verdes, faça um commit convencional em inglês com a fatia (sem incluir arquivos de outras fatias). Se o usuário pedir PRs, abra um por fatia, com base na branch da fatia anterior, e descreva no corpo o objetivo, o critério de aceite e os gates executados.

## 6. Relatório final

Tabela curta: fatia, risco, status, gates executados, testes adicionados. Se houver comentários `shortcut:` novos, rode `ponytail-debt` e liste-os. Depois liste as suposições, limitações e o que não foi verificado (ex.: UI não aberta no navegador, com o motivo).
