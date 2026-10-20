# Regras de segurança (projetos NestJS + Prisma multi-tenant, ex.: SGI)

## Multi-tenancy
- Recursos de unidade têm `unitId`. O `unitId` efetivo vem da rota e do contexto autenticado, nunca do corpo, da query livre nem de headers enviados pelo cliente.
- Todo acesso tenant-scoped valida o vínculo do usuário com a unidade antes da consulta. `unit_manager` nunca consulta sem escopo de unidade.
- Ausência de `unitId` não significa "todas as unidades": a visão consolidada é escolha explícita e só vale para `admin`.
- Buscar por ID sem filtrar também pelo `unitId` do contexto é IDOR.

## Banco de dados
- SQL nativo (`$queryRaw`/`$executeRaw`) só com template parametrizado. `$queryRawUnsafe`/`$executeRawUnsafe` e strings concatenadas com input são injeção.
- Consultas nativas recebem o tenant como parâmetro.
- Operações que alteram vários registros relacionados usam transação; a auditoria vai na mesma transação quando a consistência exige.

## Erros e exposição
- Erros do Prisma, stack traces, SQL ou detalhes internos nunca chegam ao cliente; a tradução para HTTP é feita no exception filter central, com mensagem segura e código estável.
- Logs não registram senhas, tokens, CPF ou outros dados pessoais em claro.

## Entrada externa
- Todo input externo é validado no servidor (DTO + class-validator) antes de entrar no fluxo da aplicação, incluindo planilhas de importação.
- Uploads e imports validam tipo, tamanho e conteúdo; nomes de arquivo do cliente não formam caminhos no disco.

## Autenticação
- Segredos (JWT, credenciais TOTVS, URLs de banco) vêm de variáveis de ambiente validadas, nunca do código.
- Os guards são globais (`APP_GUARD`): JWT por padrão, rota pública só com `@Public()`. O `UnitAccessGuard` só age em rotas que declaram `:unitId`; rota tenant-scoped sem `:unitId` no caminho fica sem validação de vínculo.
