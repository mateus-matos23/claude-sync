---
name: code-style
description: Preferências de escrita e organização de código do usuário para TypeScript (NestJS no backend, React no frontend). Use ao escrever, refatorar ou revisar código TS/JS, criar módulos NestJS, componentes/hooks React ou testes.
---

# Code style

Complementa o `CLAUDE.md` global (corretude, contratos, tipos, erros e validação vêm antes). Em projeto existente, o padrão já adotado no repositório prevalece; aplique estas regras no código novo e sinalize divergências relevantes em vez de reescrever o que não foi pedido.

## Princípio central

Minimizar o esforço cognitivo de quem lê. Arquivos e funções longos demais são o principal sinal de problema: se é preciso rolar a tela ou manter muitos estados na cabeça para entender o que acontece, divida.

## Nomes

- Identificadores em **inglês**; comentários podem ser em português.
- Verbosidade um pouco acima do "médio": o nome diz a responsabilidade e o contexto, sem virar frase.

```ts
// ✅
const pendingOrdersToNotify = orders.filter(isPendingDelivery);
for (const pendingOrder of pendingOrdersToNotify) {
  await sendOrderDelayNotification(pendingOrder);
}

// ❌ curto demais
const pend = ps.filter((p) => p.st === 'P');
for (const p of pend) await notify(p);

// ❌ explícito demais
const listOfOrdersWithPendingStatus = listOfOrders.filter(checkIfOrderIsPending);
```

## Comentários

Só o **porquê**, e apenas quando há regra de negócio específica ou quando o fluxo do módulo depende daquela linha. Nunca narre o que o código já diz.

```ts
// ✅
// Financeiro: atraso só conta a partir do D+3 após o vencimento.
const OVERDUE_GRACE_DAYS = 3;

// ❌
// Arredonda o total para 2 casas
const amount = Math.round(total * 100) / 100;
```

## Fluxo de controle

- Guard clauses / early return para casos inválidos; caminho feliz no fim, sem aninhamento.
- Ternário só simples; **nunca aninhado** (inclusive em JSX).

```ts
// ✅
function applyDiscount(order: Order): number {
  if (!order.customer) return order.total;
  if (order.items.length === 0) return 0;
  if (!order.coupon?.isValid) return order.total;

  return order.total * (1 - order.coupon.percentage);
}

// ❌
if (order.customer) {
  if (order.items.length > 0) {
    if (order.coupon?.isValid) { ... }
  }
}
```

```tsx
// ✅
if (isLoading) return <Spinner />;
if (error) return <ErrorMessage error={error} />;
if (orders.length === 0) return <EmptyState />;
return <OrderList orders={orders} />;

// ❌
{isLoading ? <Spinner /> : error ? <ErrorMessage /> : orders.length ? <OrderList /> : <EmptyState />}
```

## Verificações e guardas

Nada de cadeias de checagem composta (`typeof x === ... && x !== null && ...`, `if (a || !b || c || d)`). Combine conforme o contexto:

- **Fronteira**: valide o dado externo uma vez na entrada (DTO + class-validator no backend, tipos gerados pelo Orval no front) e confie no tipo dali para dentro. Não repita `typeof`/`null` em código que já recebe tipo.
- **Predicado nomeado**: quando a checagem expressa uma regra ou se repete, extraia para uma função com nome de intenção (type guard quando estreita tipo).
- **Early return**: em fluxo de decisão, uma condição por linha; não junte 3+ condições com `&&`/`||` num único `if` ou `return`.

```ts
// ✅ predicado nomeado
function isNonNegativeInteger(value: unknown): value is number {
  if (typeof value !== 'number') return false;
  return Number.isInteger(value) && value >= 0;
}

return isNonNegativeInteger(value) ? value : null;

// ✅ decisão com uma condição por linha
function shouldRefreshToken(error: unknown, config: RequestConfig | undefined): config is RequestConfig {
  if (getHttpStatus(error) !== 401) return false;
  if (!config) return false;
  if (config.authRetried) return false;
  return !isPublicAuthRequest(config);
}

// ❌
return typeof value === 'number' && Number.isInteger(value) && value >= 0 ? value : null;
if (getHttpStatus(error) !== 401 || !config || config.authRetried || isPublicAuthRequest(config)) { ... }
```

## Coleções

Encadeamento funcional (`filter`/`map`/`reduce`) com nomes completos nos parâmetros do callback.

```ts
const totalOfPaidOrders = orders
  .filter((order) => order.status === 'paid')
  .map((order) => order.total)
  .reduce((sum, total) => sum + total, 0);
```

## Funções e parâmetros

- Até 2 parâmetros: posicionais. A partir de 3: objeto nomeado.
- Muitos parâmetros indicam responsabilidade demais: considere dividir a função antes de só agrupar em objeto.

```ts
// ✅
findOrderById(orderId);
createOrder({ customerId, items, couponCode, isGift: true });

// ❌
createOrder(customerId, items, couponCode, true);
```

## Tipos

- Tipo de retorno explícito em funções exportadas e métodos públicos.
- Constantes nomeadas no lugar de números/strings mágicos.
- Estados como union literal ou enum, nunca `string` solta.
- `readonly` e imutabilidade em entidades, DTOs e props.

```ts
const FREE_SHIPPING_THRESHOLD = 200;
const DEFAULT_SHIPPING_FEE = 15;

type OrderStatus = 'pending' | 'paid' | 'canceled';

interface Order {
  readonly id: string;
  readonly status: OrderStatus;
  readonly items: readonly OrderItem[];
}

async findById(orderId: string): Promise<Order> { ... }
```

## NestJS (backend)

- Lógica em classes/services com dependências injetadas no construtor; método público como orquestrador e métodos privados pequenos.
- Erros: lançar `HttpException` do Nest (`NotFoundException`, `BadRequestException`, `ConflictException`...) diretamente no service.

```ts
@Injectable()
export class OrderFinalizationService {
  constructor(
    private readonly orderRepository: OrderRepository,
    private readonly eventPublisher: EventPublisher,
  ) {}

  async finalize(orderId: string): Promise<Order> {
    const order = await this.orderRepository.findById(orderId);
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);

    const finalizedOrder = this.buildFinalizedOrder(order);
    await this.orderRepository.save(finalizedOrder);
    await this.eventPublisher.publish('order.finalized', { orderId });
    return finalizedOrder;
  }

  private buildFinalizedOrder(order: Order): Order { ... }
  private calculateShippingFee(total: number): number { ... }
}
```

## React (frontend)

- Lógica, estado e data fetching em **hook custom**; componente fino que só renderiza.
- Função orquestradora + helpers pequenos e nomeados (sem classes).

```tsx
function usePendingOrders() {
  const { data: orders = [], isLoading } = useQuery(...);
  const pendingOrders = useMemo(() => orders.filter(isPending), [orders]);
  return { pendingOrders, isLoading };
}

export function PendingOrderList() {
  const { pendingOrders, isLoading } = usePendingOrders();
  if (isLoading) return <Spinner />;
  return <OrderTable orders={pendingOrders} />;
}
```

## Organização de pastas

Por feature/módulo: controller, service, DTOs e testes da feature juntos.

```
src/
  orders/
    orders.controller.ts
    orders.service.ts
    orders.service.spec.ts
    dto/create-order.dto.ts
  payments/
    ...
```

Helpers vivem perto de quem os usa (dentro da feature). Nada de `utils.ts`/`helpers.ts` genéricos.

## Testes

AAA separado por linha em branco; nome do `it` é uma frase que descreve o comportamento.

```ts
it('returns zero shipping when total reaches the free shipping threshold', () => {
  const order = buildOrder({ total: FREE_SHIPPING_THRESHOLD });

  const shippingFee = calculateShippingFee(order);

  expect(shippingFee).toBe(0);
});
```

## Anti-padrões (ruim de ler)

- Arquivos/funções longos que sobrecarregam o esforço cognitivo.
- Ternários aninhados.
- `utils.ts`/`helpers.ts` genéricos que viram depósito de funções sem dono.
- Abstração prematura: interface, factory, strategy ou generic com uma única implementação/uso.
- Comentários narrativos que repetem o código.
- Números/strings mágicos e estados como `string` solta.
