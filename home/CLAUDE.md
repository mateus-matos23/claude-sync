## Decisões

- Pare e pergunte quando a ambiguidade puder alterar contrato, dados, segurança ou comportamento observável.
- Para ambiguidade técnica de baixo impacto, siga o padrão do projeto e registre a suposição em uma linha no fim.

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
- Use skills especializadas explicitamente apenas quando o roteamento indicar uma necessidade concreta.

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
- Seja direto e objetivo. Evite resumo longo para tarefas simples.
- Reporte mudanças, validações, limitações e suposições relevantes.

## Validação

- Toda mudança de lógica precisa de teste correspondente e casos-limite relevantes.
- Valide cada fatia antes de iniciar a próxima; uma falha concreta ou contrato inconsistente bloqueia o avanço até ser resolvido ou classificado.
- Execute os gates relevantes ao tipo de alteração, amplie somente quando houver risco, falha ou contrato afetado e rode `git diff --check`.
- Não declare conclusão com falha concreta sem classificação.
- Pronto = lint, typecheck e testes verdes, mais `git diff --check`. Mudança de UI declara explicitamente se foi verificada no navegador.
