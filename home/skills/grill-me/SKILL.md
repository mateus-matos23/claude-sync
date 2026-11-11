---
name: grill-me
description: Entrevista implacável sobre um plano, decisão ou ideia até não restar decisão em aberto. Use quando o usuário pedir /grill-me.
disable-model-invocation: true
---

# Grill me

Entreviste o usuário até chegarem a um entendimento comum. Trate o assunto como uma **árvore de decisões**: cada decisão abre as decisões que dependem dela. Adaptado de `mattpocock/skills` (`grilling`).

## Rodadas

- A **fronteira** são as decisões cujos pré-requisitos já estão resolvidos, ou seja, as que dá para perguntar agora sem supor respostas que você ainda não ouviu. Faça a fronteira inteira em uma rodada e espere as respostas.
- Pergunta que depende de outra ainda aberta na mesma rodada fica para a rodada seguinte.
- Cada resposta remodela a árvore: recalcule a fronteira e faça a próxima rodada.
- Formato de cada pergunta, com a pergunta redigida para que "sim" aceite a recomendação:

```
❓ **P1 · <título>**: <contexto e opções, com o trade-off de cada uma>

➡️ Recomendo: <resposta e o porquê em uma linha>
```

## Fatos x decisões

- Fatos são trabalho seu, nunca do usuário: o que o código, o `AGENTS.md`, os `docs/`, a spec e as skills do projeto dizem. Busque com LSP, Read e Grep; só use um subagente `Explore` (um por vez) para varreduras amplas. Enquanto ele roda, pergunte o resto da fronteira e segure só o que depende do resultado.
- Decisões são do usuário. Priorize as que mudam contrato, dados, segurança ou comportamento observável.
- Decisão de baixo impacto não vira pergunta: adote a recomendação e registre-a como suposição no resumo, onde o usuário pode contestá-la.
- Se uma resposta contradiz o `AGENTS.md`, os `docs/` ou a spec, aponte o trecho antes de seguir.

## Fim

A sessão termina quando a fronteira fica vazia, ou quando o usuário mandar seguir. Então apresente:

- **Decisões**: cada uma com o porquê em uma linha.
- **Suposições**: o que você decidiu sozinho.
- **Em aberto**: o que ficou sem resposta, se o usuário encerrou antes.

Não implemente nada até o usuário confirmar o resumo. O próximo passo é um plano ou o `/slice`, que reaproveita essas decisões.
