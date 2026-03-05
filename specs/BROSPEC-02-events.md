# BROSPEC-02: Eventos e Mensagens

`draft` `mandatory`

## Resumo

Esta especificação define a estrutura dos eventos Nostr utilizados pelo Protocolo Bro.

## Event Kinds

### Kind 30078: Ordem de Pagamento (Bro Order)

Evento parametrized replaceable que representa uma ordem de pagamento.

#### Estrutura

```json
{
  "kind": 30078,
  "pubkey": "<pubkey_do_usuario>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "<order_id>"],
    ["t", "bro-order"],
    ["t", "bro-app"],
    ["t", "<bill_type>"],
    ["amount", "<amount_brl>"],
    ["status", "pending"],
    ["p", "<provider_pubkey>"]  // opcional, para ordem direta
  ],
  "content": "<json_criptografado_ou_plaintext>",
  "id": "<event_id>",
  "sig": "<signature>"
}
```

#### Tags

| Tag | Obrigatória | Descrição |
|-----|-------------|-----------|
| `d` | Sim | Identificador único da ordem (UUID) |
| `t` | Sim | Tag de tipo: `bro-order`, `bro-app`, tipo de conta |
| `amount` | Sim | Valor em BRL (string decimal) |
| `status` | Sim | Status atual: `pending`, `accepted`, etc |
| `p` | Não | Pubkey do provedor (para ordens diretas) |

#### Content

O campo `content` contém um JSON com os detalhes da ordem:

```json
{
  "type": "bro_order",
  "version": "1.0",
  "orderId": "550e8400-e29b-41d4-a716-446655440000",
  "billType": "pix",
  "billCode": "00020126580014br.gov.bcb.pix...",
  "amount": 100.00,
  "btcAmount": 0.00012500,
  "btcPrice": 800000.00,
  "providerFee": 3.00,
  "platformFee": 0.50,
  "total": 103.50,
  "status": "pending",
  "createdAt": "2026-01-20T10:30:00Z"
}
```

#### Campos do Content

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `type` | string | Sim | Sempre `"bro_order"` |
| `version` | string | Sim | Versão do protocolo (ex: `"1.0"`) |
| `orderId` | string | Sim | UUID da ordem |
| `billType` | string | Sim | Tipo: `pix`, `boleto`, `ted` |
| `billCode` | string | Sim | Código PIX/Boleto para pagamento |
| `amount` | number | Sim | Valor em BRL |
| `btcAmount` | number | Sim | Valor em BTC |
| `btcPrice` | number | Sim | Cotação BTC/BRL usada |
| `providerFee` | number | Sim | Taxa do provedor (%) |
| `platformFee` | number | Sim | Taxa da plataforma (%) |
| `total` | number | Sim | Valor total em sats a pagar |
| `status` | string | Sim | Status da ordem |
| `createdAt` | string | Sim | ISO 8601 timestamp |

---

### Kind 30079: Aceitação de Ordem (Bro Accept)

Evento publicado pelo provedor quando aceita uma ordem.

#### Estrutura

```json
{
  "kind": 30079,
  "pubkey": "<pubkey_do_provedor>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "<order_id>_accept"],
    ["e", "<order_event_id>"],
    ["p", "<user_pubkey>"],
    ["t", "bro-order"],
    ["t", "bro-accept"],
    ["orderId", "<order_id>"]
  ],
  "content": "<json>",
  "id": "<event_id>",
  "sig": "<signature>"
}
```

#### Tags

| Tag | Obrigatória | Descrição |
|-----|-------------|-----------|
| `d` | Sim | `<order_id>_accept` |
| `e` | Sim | ID do evento da ordem original |
| `p` | Sim | Pubkey do usuário que criou a ordem |
| `t` | Sim | Tags: `bro-order`, `bro-accept` |
| `orderId` | Sim | ID da ordem sendo aceita |

#### Content

```json
{
  "type": "bro_accept",
  "orderId": "550e8400-e29b-41d4-a716-446655440000",
  "orderEventId": "<event_id_da_ordem>",
  "providerId": "<pubkey_do_provedor>",
  "acceptedAt": "2026-01-20T10:31:00Z"
}
```

---

### Kind 30080: Atualização de Status (Bro Update)

Evento para atualizar status de uma ordem sem substituir o original.

#### Estrutura

```json
{
  "kind": 30080,
  "pubkey": "<pubkey>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "<order_id>_update"],
    ["e", "<order_id>"],
    ["p", "<provider_pubkey>"],
    ["t", "bro-order"],
    ["t", "bro-update"],
    ["status", "<new_status>"],
    ["orderId", "<order_id>"]
  ],
  "content": "<json>",
  "id": "<event_id>",
  "sig": "<signature>"
}
```

#### Content

```json
{
  "type": "bro_order_update",
  "orderId": "550e8400-e29b-41d4-a716-446655440000",
  "status": "processing",
  "providerId": "<pubkey>",
  "paymentProof": null,
  "updatedAt": "2026-01-20T10:32:00Z"
}
```

---

### Kind 30081: Conclusão com Comprovante (Bro Complete)

Evento publicado pelo provedor quando completa o pagamento.

#### Estrutura

```json
{
  "kind": 30081,
  "pubkey": "<pubkey_do_provedor>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "<order_id>_complete"],
    ["e", "<order_event_id>"],
    ["p", "<user_pubkey>"],
    ["t", "bro-order"],
    ["t", "bro-complete"],
    ["orderId", "<order_id>"]
  ],
  "content": "<json>",
  "id": "<event_id>",
  "sig": "<signature>"
}
```

#### Content

```json
{
  "type": "bro_complete",
  "orderId": "550e8400-e29b-41d4-a716-446655440000",
  "orderEventId": "<event_id_da_ordem>",
  "providerId": "<pubkey_do_provedor>",
  "proofImage_nip44": "<nip44v2_encrypted_base64_image>",
  "recipientPubkey": "<user_pubkey>",
  "completedAt": "2026-01-20T10:35:00Z"
}
```

#### Campos do Content

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `proofImage_nip44` | string | Sim | Comprovante base64 criptografado com NIP-44v2 |
| `recipientPubkey` | string | Sim | Pubkey do destinatário |

> **Privacidade**: O comprovante é **obrigatoriamente** criptografado com NIP-44v2 (XChaCha20-Poly1305). O campo `proofImage_nip44` contém a imagem base64 criptografada via `Nip44Service().encryptBetween()` para o destinatário (usuário) e separadamente para o mediador admin.

---

### Kind 30082: Perfil de Provedor (Bro Provider)

Evento que descreve um provedor e suas capacidades.

#### Estrutura

```json
{
  "kind": 30082,
  "pubkey": "<pubkey_do_provedor>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "provider_profile"],
    ["t", "bro-provider"],
    ["name", "ProviderX"],
    ["methods", "pix,boleto,ted"],
    ["min_amount", "10.00"],
    ["max_amount", "5000.00"],
    ["spread", "3.5"],
    ["collateral", "500000"]
  ],
  "content": "<json>",
  "id": "<event_id>",
  "sig": "<signature>"
}
```

#### Tags

| Tag | Obrigatória | Descrição |
|-----|-------------|-----------|
| `d` | Sim | `provider_profile` |
| `t` | Sim | `bro-provider` |
| `name` | Não | Nome de exibição |
| `methods` | Sim | Métodos aceitos (csv) |
| `min_amount` | Não | Valor mínimo em BRL |
| `max_amount` | Não | Valor máximo em BRL |
| `spread` | Não | Taxa/spread cobrada (%) |
| `collateral` | Não | Garantia em sats |

#### Content

```json
{
  "name": "ProviderX",
  "description": "Pagamentos rápidos 24/7",
  "methods": ["pix", "boleto", "ted"],
  "limits": {
    "min": 10.00,
    "max": 5000.00
  },
  "spread": 3.5,
  "collateral": 500000,
  "stats": {
    "totalOrders": 150,
    "successRate": 98.5,
    "avgTimeSeconds": 180,
    "totalVolume": 5000000
  },
  "activeSince": "2025-06-01T00:00:00Z",
  "contact": {
    "nostr": "<npub>",
    "email": "provider@example.com"
  }
}
```

---

### Kind 30085: Avaliação Marketplace (Bro Review)

Evento para avaliações de provedores no marketplace.

#### Estrutura

```json
{
  "kind": 30085,
  "pubkey": "<user_pubkey>",
  "created_at": <unix_timestamp>,
  "tags": [
    ["d", "<order_id>_review"],
    ["e", "<order_event_id>"],
    ["p", "<provider_pubkey>"],
    ["t", "bro-review"]
  ],
  "content": "<json>"
}
```

#### Content

```json
{
  "ratingAtendimento": 3,
  "ratingProduto": 3,
  "comment": "Pagamento rápido, recomendo!"
}
```

#### Campos do Content

| Campo | Tipo | Obrigatório | Descrição |
|-------|------|-------------|-----------|
| `ratingAtendimento` | number (1-3) | Sim | Avaliação do atendimento: 1=ruim, 2=médio, 3=bom |
| `ratingProduto` | number (1-3) | Sim | Avaliação do produto/serviço: 1=ruim, 2=médio, 3=bom |
| `comment` | string | Não | Comentário opcional |

#### Classificação de Rating

A média dos ratings é classificada em 3 níveis:

| Média | Label | Ícone |
|-------|-------|-------|
| ≥ 2.5 | Bom | 👍 |
| ≥ 1.5 | Médio | 👌 |
| < 1.5 | Ruim | 👎 |

---

## Status de Ordem

| Status | Descrição |
|--------|-----------|
| `draft` | Rascunho, ordem ainda não publicada |
| `pending` | Ordem criada, aguardando provedor |
| `payment_received` | Pagamento Lightning recebido |
| `accepted` | Provedor aceitou a ordem |
| `processing` | Provedor executando pagamento fiat |
| `awaiting_confirmation` | Comprovante enviado, aguardando confirmação |
| `completed` | Ordem finalizada com sucesso |
| `liquidated` | Ordem auto-liquidada após 36h sem confirmação |
| `cancelled` | Ordem cancelada (terminal absoluto, apenas `disputed` pode sobrescrever) |
| `disputed` | Ordem em disputa (sobrescreve qualquer status não-terminal) |

> **Nota**: Não existe status `expired`. Ordens não aceitas ficam em `pending` até cancelamento ou expiração do TTL no relay.

---

## Tipos de Pagamento (billType)

| Tipo | Descrição | Código Esperado |
|------|-----------|-----------------|
| `pix` | PIX | Chave PIX ou código copia-e-cola |
| `boleto` | Boleto Bancário | Código de barras (47/48 dígitos) |
| `ted` | TED/DOC | Dados bancários (JSON) |

---

## Exemplo Completo de Fluxo

### 1. Usuário cria ordem

```json
{
  "kind": 30078,
  "pubkey": "a1b2c3...",
  "created_at": 1737369000,
  "tags": [
    ["d", "order-123"],
    ["t", "bro-order"],
    ["t", "bro-app"],
    ["t", "pix"],
    ["amount", "100.00"],
    ["status", "pending"]
  ],
  "content": "{\"type\":\"bro_order\",\"orderId\":\"order-123\",\"billType\":\"pix\",\"billCode\":\"chavepix@email.com\",\"amount\":100,\"btcAmount\":0.000125,\"btcPrice\":800000,\"status\":\"pending\"}",
  "id": "event-abc",
  "sig": "..."
}
```

### 2. Provedor aceita

```json
{
  "kind": 30079,
  "pubkey": "d4e5f6...",
  "created_at": 1737369060,
  "tags": [
    ["d", "order-123_accept"],
    ["e", "event-abc"],
    ["p", "a1b2c3..."],
    ["t", "bro-order"],
    ["t", "bro-accept"],
    ["orderId", "order-123"]
  ],
  "content": "{\"type\":\"bro_accept\",\"orderId\":\"order-123\",\"providerId\":\"d4e5f6...\"}",
  "id": "event-def",
  "sig": "..."
}
```

### 3. Provedor completa

```json
{
  "kind": 30081,
  "pubkey": "d4e5f6...",
  "created_at": 1737369300,
  "tags": [
    ["d", "order-123_complete"],
    ["e", "event-abc"],
    ["p", "a1b2c3..."],
    ["t", "bro-order"],
    ["t", "bro-complete"],
    ["orderId", "order-123"]
  ],
  "content": "{\"type\":\"bro_complete\",\"orderId\":\"order-123\",\"proofImage\":\"iVBORw0KGgo...\",\"completedAt\":\"2026-01-20T10:35:00Z\"}",
  "id": "event-ghi",
  "sig": "..."
}
```

---

## Filtrando Eventos

### Buscar ordens pendentes

```json
{
  "kinds": [30078],
  "#t": ["bro-order"],
  "#status": ["pending"],
  "limit": 100
}
```

### Buscar atualizações para usuário

```json
{
  "kinds": [30079, 30080, 30081],
  "#p": ["<user_pubkey>"],
  "limit": 50
}
```

### Buscar provedores ativos

```json
{
  "kinds": [30082],
  "#t": ["bro-provider"],
  "limit": 20
}
```

---

*Versão: 0.1-draft*
*Data: Janeiro 2026*
