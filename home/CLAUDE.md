## Decisões

- Pare e pergunte quando a ambiguidade puder alterar contrato, dados, segurança ou comportamento observável.
- Para ambiguidade técnica de baixo impacto, siga o padrão do projeto e registre a suposição em uma linha no fim.
- Se discordar de uma decisão pedida (arquitetura, abordagem, nome), questione antes de implementar, com o risco em até 3 linhas.
- Mudança de contrato (API, schema, comportamento visível) passa por plano aprovado antes de implementar, mesmo pequena. Bug fix e mudança interna localizada seguem direto.
- Qualidade vem antes de prazo: atalhos (`shortcut:`) só fora de domínio, segurança e contrato, e sempre reportados.

## Código

- Corretude, contratos e segurança vêm antes de simplicidade; depois prefira a solução simples, testável e de baixo acoplamento.
- Prefira nomes que expliquem a responsabilidade, funções pequenas e arquivos coesos. Extraia somente quando isso reduzir esforço cognitivo, isolar efeitos ou criar uma fronteira de teste.
- Respeite o sistema de tipos da linguagem; não use tipos permissivos ou casts sem justificativa.
- Valide todo input externo no servidor antes de entrar no fluxo da aplicação.
- Trate erros explicitamente. Não use `try/catch` genérico para esconder falhas, fallback silencioso ou exposição de detalhes internos.
- Não introduza abstrações, configurações, campos, endpoints ou dependências especulativas. Procure utilitários existentes antes de criar novos. Não reinvente a roda.
- Considere complexidade ciclomática, BIG-O, I/O e concorrência.
- Divida a implementação de uma funcionalidade em fatias pequenas sequenciais onde a próxima fatia depende da anterior estar funcional e validada.

## Navegação e documentação

- Leia somente os trechos relevantes e não repita buscas sem motivo concreto.
- Em TypeScript/JavaScript, prefira `LSP` (definição, referências, diagnósticos) a `Grep` para navegar símbolos.
- Para bibliotecas, frameworks, SDKs, APIs, CLIs e serviços, consulte a documentação oficial atual.

## Subagentes e contexto

- Não rode subagente sem tarefa delimitada; por padrão, use no máximo um subagente somente leitura por vez e nunca paralelize escritores na mesma área.
- Subagentes rodam em `haiku`, ou `sonnet` para revisão e fatias complexas; nunca Opus nem fork. Um hook nega o resto.
- O agente principal revisa cada entrega de subagente (contas, contagens, camadas, contratos) antes de liberar a próxima fatia.
- Use skills especializadas explicitamente apenas quando o roteamento abaixo indicar uma necessidade concreta.

## Roteamento de skills

Uma skill por gatilho; não rode duas para a mesma análise. Skill do projeto (`.claude/skills/`) prevalece sobre plugin equivalente.

- Escrever ou refatorar TS (Nest/React): `code-style`. Feature com 3+ fatias: `fatiar`.
- Escolher entre abordagens ou registrar ADR: `engineering:architecture`. Novo módulo, serviço ou modelo de dados: `engineering:system-design`.
- Planejar testes de mudança de risco alto: `engineering:testing-strategy`. Bug sem causa óbvia: `engineering:debug`.
- Release com migration ou feature flag: `engineering:deploy-checklist`. Incidente em produção: `engineering:incident-response`.
- Docs (README, runbook): agente `documentador`.
- Revisão de corretude de diff/PR: agente `revisor` (roda `engineering:code-review`). Excesso de código: `ponytail-review` para relatório, `/simplify` para aplicar.
- Saúde do repo e o que apagar: `ponytail-audit`; priorizar backlog de dívida: `engineering:tech-debt`; listar `shortcut:` pendentes: `ponytail-debt`.
- UI nova ou redesenho: `frontend-design`; componentes shadcn/Tailwind: skill `shadcn` do projeto; revisão de UX e acessibilidade: `ui-ux-pro-max`.
- Mudança sensível de segurança antes do merge: `security-review`.

## Dependências

- Nunca adicione, atualize ou remova dependências sem perguntar. Prefira arquivos estáticos ou bibliotecas já instaladas. Um hook nega esses comandos; o usuário os executa com `!`.

## Bancos de dados

- Banco de dev e banco de teste são distintos. Seed, migrate, reset e backfill rodam só com `NODE_ENV=test`, salvo pedido explícito; confira o `DATABASE_URL` efetivo antes. Um hook nega o resto.
- Fixtures de e2e criam registros reais. Não use IDs aleatórios que violem FK (ex.: `audit.user_sub`).

## Memória

- Memória é uma pista reutilizável, não substitui evidência atual do repositório.
- Não registre segredos, credenciais, dados pessoais, estado temporário ou hipóteses não verificadas.

## Git e comunicação

- Preserve alterações locais e nunca reescreva histórico compartilhado sem autorização explícita.
- Commite cada fatia com gates verdes sem pedir confirmação (conventional commit em inglês). Push e PR só com pedido explícito; quando pedido, um PR por fatia, isolado e reproduzível, empilhado sobre a branch da fatia anterior enquanto ela não for mergeada.
- Seja direto e objetivo. Evite resumo longo para tarefas simples.
- Commits, PRs e docs são revisados por um time pequeno: escreva para um colega que não acompanhou a sessão.
- Reporte mudanças, validações, limitações e suposições relevantes.

## Validação

- Toda mudança de lógica precisa de teste correspondente e casos-limite relevantes. Esta regra prevalece sobre o ponytail.
- Valide cada fatia antes de iniciar a próxima; uma falha concreta ou contrato inconsistente bloqueia o avanço até ser resolvido ou classificado.
- Execute os gates relevantes ao tipo de alteração, amplie somente quando houver risco, falha ou contrato afetado e rode `git diff --check`.
- Não declare conclusão com falha concreta sem classificação.
- Pronto = lint, typecheck e testes verdes, mais `git diff --check`. Mudança de UI é verificada no navegador com o agente `verificador-ui`; se não for possível, declare o motivo.

## Compact instructions

Ao compactar, preserve: decisões tomadas e o porquê, fatias concluídas e pendentes, arquivos alterados, saídas de gates com falha e suposições registradas. Descarte leituras de arquivo e saídas de comando já resolvidas.
