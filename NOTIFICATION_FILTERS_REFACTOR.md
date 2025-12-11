# Refatoração dos Filtros de Notificações

## 📋 Problema Identificado

Os filtros de notificações em `simplified_notification_screen.dart` não correspondiam às categorias de notificações realmente implementadas nos Cloud Functions. Havia filtros para categorias que nunca são usadas e faltavam filtros para categorias existentes.

## 🔍 Análise dos Triggers Implementados

### Cloud Functions Ativas:

1. **`profileViewNotifications.ts`** 
   - Tipo: `profile_views_aggregated`
   - Dispara quando 3+ pessoas visualizam o perfil

2. **`eventChatNotifications.ts`**
   - Tipo: `event_chat_message`
   - Mensagens em chats de eventos

3. **`notification_orchestrator.dart`** (client-side)
   - 8 tipos de `activity_*`:
     - `activity_created`
     - `activity_join_request`
     - `activity_join_approved`
     - `activity_join_rejected`
     - `activity_new_participant`
     - `activity_heating_up`
     - `activity_expiring_soon`
     - `activity_canceled`

### ❌ Filtros Incorretos (Removidos):

- **Messages** - Chat 1-1 usa push direto (FCM), não cria notificações in-app
- **Requests** - É redundante, já está incluído em Activities
- **Social** - Nome genérico que não corresponde a nenhum tipo específico
- **System** - Não existe nenhum trigger que crie notificações deste tipo

## ✅ Nova Estrutura de Filtros

### 4 Filtros Implementados:

| Índice | Key | Label (PT) | Descrição |
|--------|-----|------------|-----------|
| 0 | `null` | Todas | Todas as notificações |
| 1 | `activity` | Atividades | Todos os 8 tipos de `activity_*` |
| 2 | `event_chat_message` | Chat de Eventos | Mensagens em eventos |
| 3 | `profile_views_aggregated` | Visualizações | Visualizações de perfil (3+) |

## 🔧 Arquivos Modificados

### 1. Controller
**`lib/features/notifications/controllers/simplified_notification_controller.dart`**
```dart
// Antes: 6 filtros (All, Messages, Activities, Requests, Social, System)
static const int filterCount = 6;

// Depois: 4 filtros (All, Activities, Event Chat, Profile Views)
static const int filterCount = 4;
```

**Mapeamento atualizado:**
```dart
String? mapFilterIndexToKey(int index) {
  switch (index) {
    case 0: return null; // Todas
    case 1: return 'activity'; // Atividades (whereIn com 8 tipos)
    case 2: return 'event_chat_message'; // Chat de Eventos
    case 3: return 'profile_views_aggregated'; // Visualizações
    default: return null;
  }
}
```

### 2. View
**`lib/features/notifications/widgets/simplified_notification_screen.dart`**
- Atualizada constante `filterCount` para 4

### 3. Traduções
**Arquivos atualizados:**
- `assets/lang/pt.json`
- `assets/lang/en.json`
- `assets/lang/es.json`

**Novas chaves:**
```json
{
  "notif_filter_all": "Todas",
  "notif_filter_activities": "Atividades",
  "notif_filter_event_chat": "Chat de Eventos",
  "notif_filter_profile_views": "Visualizações"
}
```

### 4. Repository
**`lib/features/notifications/repositories/notifications_repository.dart`**
- ✅ Já tratava corretamente o filtro `'activity'` com `whereIn` para os 8 tipos
- Nenhuma modificação necessária

## 🎯 Benefícios

1. **Precisão**: Filtros correspondem exatamente aos triggers implementados
2. **Clareza**: Usuários veem apenas categorias que realmente existem
3. **Manutenibilidade**: Fácil adicionar novos filtros quando novos triggers forem implementados
4. **Performance**: Menos filtros = menos queries desnecessárias

## 📊 Impacto Visual

### Antes (6 filtros):
```
[Todas] [Mensagens] [Atividades] [Pedidos] [Social] [Sistema]
   ✅        ❌           ✅          ❌       ❌       ❌
```

### Depois (4 filtros):
```
[Todas] [Atividades] [Chat de Eventos] [Visualizações]
   ✅        ✅              ✅                ✅
```

## 🔮 Próximos Passos (Futuro)

Se novos triggers forem implementados:

1. **Reviews** - Se implementado trigger de novas avaliações
   - Adicionar filtro: `case 4: return 'review_received'`
   - Tradução: `"notif_filter_reviews": "Avaliações"`

2. **Ranking** - Se implementado trigger de mudanças de ranking
   - Adicionar filtro: `case 5: return 'ranking_change'`
   - Tradução: `"notif_filter_ranking": "Ranking"`

3. **Matches** - Se implementado sistema de matches
   - Adicionar filtro: `case 6: return 'new_match'`
   - Tradução: `"notif_filter_matches": "Matches"`

## ✅ Checklist de Implementação

- [x] Mapear triggers implementados nos Cloud Functions
- [x] Atualizar `mapFilterIndexToKey()` no controller
- [x] Atualizar `filterLabelKeys` no controller
- [x] Atualizar `filterCount` na view
- [x] Adicionar traduções PT, EN, ES
- [x] Validar que repository suporta as queries
- [x] Testar compilação sem erros

---

**Data**: 10 de dezembro de 2025  
**Status**: ✅ Implementado e funcional
