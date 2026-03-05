# BROSPEC-05: Sistema de Reputação

`draft` `optional`

## Resumo

Esta especificação define o sistema de avaliação marketplace para provedores no Protocolo Bro.

## Implementação Atual

O sistema de reputação utiliza avaliações simples tipo marketplace com dois critérios em escala 1-3, publicadas como eventos Nostr kind 30085.

## Eventos de Avaliação

### Kind 30085: Avaliação Marketplace

```json
{
  "kind": 30085,
  "pubkey": "<user_pubkey>",
  "created_at": <timestamp>,
  "tags": [
    ["d", "<order_id>_review"],
    ["e", "<order_event_id>"],
    ["p", "<provider_pubkey>"],
    ["t", "bro-review"]
  ],
  "content": "{\"ratingAtendimento\": 3, \"ratingProduto\": 3, \"comment\": \"Rápido e confiável!\"}"
}
```

### Campos do Content

| Campo | Tipo | Valores | Descrição |
|-------|------|---------|-----------|
| `ratingAtendimento` | number | 1, 2, 3 | Avaliação do atendimento |
| `ratingProduto` | number | 1, 2, 3 | Avaliação do serviço/produto |
| `comment` | string | texto livre | Comentário opcional |

### Escala de Rating

| Valor | Significado |
|-------|-------------|
| 1 | Ruim |
| 2 | Médio |
| 3 | Bom |

## Classificação de Provedores

A média dos dois ratings (atendimento + produto) determina o label:

| Média | Label | Ícone | Cor |
|-------|-------|-------|-----|
| ≥ 2.5 | Bom | 👍 | Verde (#4CAF50) |
| ≥ 1.5 | Médio | 👌 | Laranja (#FFA726) |
| < 1.5 | Ruim | 👎 | Vermelho (#EF5350) |
| sem avaliação | Sem avaliações | — | Cinza (#9E9E9E) |

## Prevenção de Fraudes

- Reviews são vinculados a ordens reais (tag `e` referencia o evento da ordem)
- Apenas o usuário que criou a ordem pode avaliar
- Uma avaliação por ordem

## Publicar Avaliação (Exemplo Dart)

```dart
Future<void> publishReview({
  required String orderId,
  required String orderEventId,
  required String providerPubkey,
  required int ratingAtendimento,  // 1-3
  required int ratingProduto,      // 1-3
  String? comment,
}) async {
  final content = jsonEncode({
    'ratingAtendimento': ratingAtendimento,
    'ratingProduto': ratingProduto,
    if (comment != null) 'comment': comment,
  });

  final event = Event.from(
    kind: 30085,
    tags: [
      ['d', '${orderId}_review'],
      ['e', orderEventId],
      ['p', providerPubkey],
      ['t', 'bro-review'],
    ],
    content: content,
    privkey: privateKey,
  );

  await publishToRelays(event);
}
```

## Buscar Reviews de um Provedor

```javascript
const filter = {
  kinds: [30085],
  '#p': [providerPubkey],
  '#t': ['bro-review'],
  limit: 50
};

const events = await relay.fetch(filter);
```

## Funcionalidades Planejadas (Não Implementadas)

As seguintes funcionalidades estão descritas como design futuro:

- **Web of Trust (WoT)**: Peso de avaliações baseado no grafo social Nostr
- **Score composto**: Cálculo com métricas quantitativas (taxa de sucesso, tempo médio, volume)
- **Níveis/badges**: Sistema de badges baseado em score (Lendário, Excelente, etc.)
- **NIP-05 verificação**: Peso extra para provedores com NIP-05
- **Contestação de reviews**: Capacidade de provedores contestarem avaliações

---

*Versão: 0.2-draft*
*Data: Julho 2026*
