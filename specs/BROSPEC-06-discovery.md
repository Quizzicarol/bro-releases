# BROSPEC-06: Descoberta de Provedores

`draft` `optional`

## Resumo

Esta especificação define como usuários descobrem provedores disponíveis no Protocolo Bro.

## Métodos de Descoberta

### 1. Busca em Relays Públicos

Filtrar eventos `kind 30082` (perfil de provedor):

```json
{
  "kinds": [30082],
  "#t": ["bro-provider"],
  "limit": 50
}
```

### 2. Relays Utilizados

O app utiliza relays públicos Nostr:

```
wss://relay.damus.io
wss://nos.lol
wss://relay.primal.net
wss://relay.nostr.band
wss://nostr.mom
```

> **Nota**: Não existe relay dedicado Bro. Qualquer relay NIP-01 compatível funciona.

### 3. Hashtags de Descoberta

| Hashtag | Uso |
|---------|-----|
| `#bro-provider` | Perfil de provedor |
| `#bro-order` | Ordens |
| `#bro-brasil` | Provedores BR |
| `#bro-latam` | Provedores LATAM |
| `#bro-global` | Provedores globais |

### 4. NIP-05 Directory (PLANEJADO)

> **⚠️ NÃO IMPLEMENTADO** — design futuro.

Provedores verificados em domínios conhecidos:

```
provider@bro.example.com
```

## Perfil de Provedor

### Estrutura Completa

```json
{
  "kind": 30082,
  "pubkey": "<provider_pubkey>",
  "created_at": <timestamp>,
  "tags": [
    ["d", "provider_profile"],
    ["t", "bro-provider"],
    ["t", "bro-brasil"],
    
    // Identidade
    ["name", "ProviderX"],
    ["picture", "https://..."],
    ["nip05", "providerx@example.com"],
    
    // Capacidades
    ["methods", "pix,boleto,ted"],
    ["currencies", "BRL"],
    ["regions", "BR"],
    
    // Limites
    ["min_amount", "10.00"],
    ["max_amount", "5000.00"],
    ["daily_limit", "50000.00"],
    
    // Taxas
    ["spread", "3.5"],
    ["fee_type", "percentage"],
    
    // Garantia
    ["collateral_brl", "200.00"],
    ["tier", "basic"],
    
    // Disponibilidade
    ["available", "true"],
    ["hours", "09:00-22:00"],
    ["timezone", "America/Sao_Paulo"],
    
    // Estatísticas
    ["stats_orders", "150"],
    ["stats_success", "98.5"],
    ["stats_avg_time", "180"],
    ["stats_volume", "5000000"],
    
    // Contato
    ["lud16", "providerx@walletofsatoshi.com"]
  ],
  "content": "{...json_detalhado...}"
}
```

### Content JSON

```json
{
  "name": "ProviderX",
  "description": "Pagamentos rápidos 24/7. Especialista em PIX instantâneo.",
  "picture": "https://nostr.build/i/abc123.jpg",
  "banner": "https://nostr.build/i/banner456.jpg",
  
  "capabilities": {
    "methods": ["pix", "boleto", "ted"],
    "currencies": ["BRL"],
    "regions": ["BR"],
    "features": ["instant_pix", "24h_support", "high_volume"]
  },
  
  "limits": {
    "min": 10.00,
    "max": 5000.00,
    "daily": 50000.00,
    "monthly": 500000.00
  },
  
  "pricing": {
    "spread": 3.5,
    "type": "percentage",
    "minFee": 1.00,
    "volumeDiscounts": [
      { "minVolume": 10000, "spread": 3.0 },
      { "minVolume": 50000, "spread": 2.5 }
    ]
  },
  
  "availability": {
    "status": "available",
    "hours": {
      "weekdays": "09:00-22:00",
      "weekends": "10:00-18:00"
    },
    "timezone": "America/Sao_Paulo",
    "responseTime": "< 5 minutes",
    "autoAccept": true,
    "autoAcceptMax": 1000.00
  },
  
  "collateral": {
    "amount": 2000000,
    "tier": "gold",
    "lockedPercent": 15
  },
  
  "stats": {
    "totalOrders": 150,
    "successRate": 98.5,
    "avgTimeSeconds": 180,
    "totalVolume": 5000000,
    "disputeRate": 1.0,
    "activeSince": "2025-06-01T00:00:00Z"
  },
  
  "reviews": {
    "count": 127,
    "avgRating": 4.9,
    "sentiment": {
      "positive": 120,
      "neutral": 5,
      "negative": 2
    }
  },
  
  "contact": {
    "nostr": "npub1...",
    "lud16": "providerx@walletofsatoshi.com",
    "email": "suporte@providerx.com",
    "telegram": "@providerx"
  },
  
  "verification": {
    "nip05": "providerx@example.com",
    "verified": true,
    "verifiedAt": "2025-06-15T00:00:00Z"
  }
}
```

## Filtros de Busca

### Por Capacidade

```javascript
// Provedores que aceitam PIX no Brasil
const filter = {
  kinds: [30082],
  '#t': ['bro-provider', 'bro-brasil'],
  '#methods': ['pix']
};
```

### Por Disponibilidade

```javascript
// Apenas provedores disponíveis
const filter = {
  kinds: [30082],
  '#t': ['bro-provider'],
  '#available': ['true']
};
```

### Por Limite

```javascript
// Provedores que aceitam ordens de R$ 1000+
// (filtro client-side após fetch)
const providers = await fetchProviders();
const filtered = providers.filter(p => 
  parseFloat(p.tags.find(t => t[0] === 'max_amount')?.[1] || '0') >= 1000
);
```

## Ordenação de Resultados (PLANEJADO)

> **⚠️ NÃO IMPLEMENTADO** — A implementação atual lista provedores sem ranking algorítmico. O design abaixo é futuro.

### Critérios Padrão

1. **Disponibilidade** (disponível > indisponível)
2. **Score de Reputação** (maior primeiro)
3. **Taxa de Sucesso** (maior primeiro)
4. **Spread/Taxa** (menor primeiro)
5. **Tempo Médio** (menor primeiro)

### Algoritmo de Ranking

```javascript
function rankProviders(providers, userPreferences) {
  return providers
    .filter(p => p.available)
    .map(p => ({
      ...p,
      rankScore: calculateRankScore(p, userPreferences)
    }))
    .sort((a, b) => b.rankScore - a.rankScore);
}

function calculateRankScore(provider, prefs) {
  const weights = {
    reputation: 0.30,
    successRate: 0.25,
    spread: 0.20,
    time: 0.15,
    wot: 0.10
  };

  // Normalizar métricas (0-100)
  const repScore = provider.stats.reputationScore;
  const successScore = provider.stats.successRate;
  const spreadScore = 100 - (provider.pricing.spread * 10); // Menor é melhor
  const timeScore = Math.max(0, 100 - (provider.stats.avgTimeSeconds / 30));
  const wotScore = provider.wotTrust || 50;

  // Aplicar preferências do usuário
  if (prefs.preferLowFees) weights.spread += 0.10;
  if (prefs.preferFast) weights.time += 0.10;

  // Calcular score final
  return (
    repScore * weights.reputation +
    successScore * weights.successRate +
    spreadScore * weights.spread +
    timeScore * weights.time +
    wotScore * weights.wot
  );
}
```

## UI de Descoberta

### Lista de Provedores

```
┌────────────────────────────────────────────────────────────┐
│ 🔍 Buscar Provedores                     [🔄] [⚙️ Filtros] │
├────────────────────────────────────────────────────────────┤
│ Filtros: PIX ✓  Boleto ✓  Brasil ✓  Disponível ✓          │
├────────────────────────────────────────────────────────────┤
│                                                            │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ 💎 ProviderX                              🟢 Online    │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ ⭐ 4.9 (127)  ✅ 98.5%  ⚡ 3min  💰 3.5%              │ │
│ │ PIX • Boleto • TED   |   R$ 10 - R$ 5.000             │ │
│ │ 👥 3 amigos em comum • Verificado ✓                   │ │
│ │                                         [Selecionar →] │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                            │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ 🥇 BitcoinBro                             🟢 Online    │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ ⭐ 4.7 (89)   ✅ 95%    ⚡ 5min  💰 4.0%              │ │
│ │ PIX • Boleto         |   R$ 50 - R$ 2.000             │ │
│ │                                         [Selecionar →] │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                            │
│ ┌────────────────────────────────────────────────────────┐ │
│ │ 🥈 SatoshiPay                             🟡 Ocupado   │ │
│ │ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │ │
│ │ ⭐ 4.5 (45)   ✅ 92%    ⚡ 8min  💰 3.0%              │ │
│ │ PIX                  |   R$ 10 - R$ 1.000             │ │
│ │                                         [Selecionar →] │ │
│ └────────────────────────────────────────────────────────┘ │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

### Filtros Avançados

```
┌──────────────────────────────────────────┐
│ ⚙️ Filtros                               │
├──────────────────────────────────────────┤
│                                          │
│ Métodos de Pagamento                     │
│ [✓] PIX  [✓] Boleto  [ ] TED            │
│                                          │
│ Região                                   │
│ [✓] Brasil  [ ] Argentina  [ ] Global   │
│                                          │
│ Disponibilidade                          │
│ [✓] Apenas online                        │
│                                          │
│ Reputação Mínima                         │
│ [=========>----] 75                      │
│                                          │
│ Taxa Máxima                              │
│ [=====>--------] 5.0%                    │
│                                          │
│ Valor da Ordem                           │
│ R$ [100.00] ─────── R$ [5000.00]        │
│                                          │
│ Ordenar por                              │
│ (•) Reputação  ( ) Taxa  ( ) Velocidade │
│                                          │
│ [Aplicar Filtros]      [Limpar]         │
└──────────────────────────────────────────┘
```

### Detalhes do Provedor

```
┌────────────────────────────────────────────────────────────┐
│ ← Voltar                                                   │
├────────────────────────────────────────────────────────────┤
│                                                            │
│                    [🖼️ Avatar]                            │
│                                                            │
│            💎 ProviderX                                    │
│            providerx@brostr.app ✓                          │
│                                                            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                            │
│ 📊 Estatísticas                                            │
│ ┌──────────────┬──────────────┬──────────────┐            │
│ │  150         │  98.5%       │  ~3 min      │            │
│ │  ordens      │  sucesso     │  tempo médio │            │
│ └──────────────┴──────────────┴──────────────┘            │
│                                                            │
│ 💰 Taxas                                                   │
│ • Spread: 3.5%                                             │
│ • Desconto volume: 3.0% (> R$ 10k)                        │
│                                                            │
│ 📋 Limites                                                 │
│ • Mínimo: R$ 10,00                                        │
│ • Máximo: R$ 5.000,00                                     │
│ • Diário: R$ 50.000,00                                    │
│                                                            │
│ 💳 Métodos Aceitos                                         │
│ [PIX] [Boleto] [TED]                                      │
│                                                            │
│ 🕐 Horário de Atendimento                                  │
│ • Seg-Sex: 09:00 - 22:00                                  │
│ • Sáb-Dom: 10:00 - 18:00                                  │
│ • Fuso: America/Sao_Paulo                                 │
│                                                            │
│ 🔒 Garantia                                                │
│ • Colateral: 2.000.000 sats                               │
│ • Tier: Ouro 🥇                                           │
│                                                            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                            │
│ ⭐ Avaliações (127)                        [Ver todas →]  │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ ⭐⭐⭐⭐⭐  "Muito rápido, recomendo!"                │  │
│ │ @usuario1 • há 2 dias                                │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ ┌──────────────────────────────────────────────────────┐  │
│ │ ⭐⭐⭐⭐⭐  "Excelente atendimento"                   │  │
│ │ @usuario2 • há 5 dias                                │  │
│ └──────────────────────────────────────────────────────┘  │
│                                                            │
│ ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━ │
│                                                            │
│       [💬 Enviar Mensagem]  [📋 Criar Ordem]             │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

## Implementação

### Buscar Provedores

```dart
Future<List<Provider>> fetchProviders({
  List<String>? methods,
  String? region,
  bool onlyAvailable = true,
  double? minReputation,
  double? maxSpread,
}) async {
  final filters = {
    'kinds': [30082],
    '#t': ['bro-provider'],
    if (region != null) '#t': ['bro-$region'],
    if (onlyAvailable) '#available': ['true'],
  };

  final events = await relay.fetch(filters);
  
  var providers = events.map((e) => Provider.fromEvent(e)).toList();
  
  // Filtros client-side
  if (methods != null) {
    providers = providers.where((p) => 
      methods.any((m) => p.methods.contains(m))
    ).toList();
  }
  
  if (minReputation != null) {
    providers = providers.where((p) => 
      p.reputationScore >= minReputation
    ).toList();
  }
  
  if (maxSpread != null) {
    providers = providers.where((p) => 
      p.spread <= maxSpread
    ).toList();
  }
  
  // Ordenar por ranking
  providers.sort((a, b) => 
    b.calculateRankScore().compareTo(a.calculateRankScore())
  );
  
  return providers;
}
```

### Publicar Perfil de Provedor

```dart
Future<void> publishProviderProfile(ProviderProfile profile) async {
  final event = Event.from(
    kind: 30082,
    tags: [
      ['d', 'provider_profile'],
      ['t', 'bro-provider'],
      ['t', 'bro-brasil'],
      ['name', profile.name],
      ['methods', profile.methods.join(',')],
      ['min_amount', profile.minAmount.toString()],
      ['max_amount', profile.maxAmount.toString()],
      ['spread', profile.spread.toString()],
      ['collateral', profile.collateral.toString()],
      ['available', profile.available.toString()],
      // ... outras tags
    ],
    content: jsonEncode(profile.toJson()),
    privkey: privateKey,
  );

  await publishToRelays(event);
}
```

---

*Versão: 0.1-draft*
*Data: Janeiro 2026*
