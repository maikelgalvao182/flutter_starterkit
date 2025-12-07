# Sistema de Pending Reviews - Ativação Automática

## 📋 Visão Geral

O sistema de **Pending Reviews** foi atualizado para exibir automaticamente o `ReviewDialog` quando o usuário abre o app e possui avaliações pendentes na coleção `PendingReviews`.

---

## 🔄 Fluxo Completo

### 1. **Criação de Pending Reviews (Backend)**

**Cloud Function:** `checkEventsForReview`
- **Trigger:** Pub/Sub schedule (a cada 5 minutos)
- **Ação:** Verifica eventos que terminaram há 24 horas
- **Resultado:** Cria documentos na coleção `PendingReviews`

```typescript
// functions/src/reviews/checkEventsForReview.ts
export const checkEventsForReview = functions.pubsub
  .schedule("*/5 * * * *")
  .timeZone("America/Sao_Paulo")
  .onRun(async () => {
    // Busca eventos que terminaram há 24h
    // Cria PendingReviews para owner e participants
    // Envia notificação push
  });
```

**Estrutura do Documento PendingReviews:**
```json
{
  "pending_review_id": "auto-generated",
  "event_id": "event123",
  "application_id": "app456",
  "reviewer_id": "user789",
  "reviewee_id": "user012",
  "reviewer_role": "participant", // ou "owner"
  "event_title": "Pizzaria Italiana",
  "event_emoji": "🍕",
  "event_location": "Centro, São Paulo",
  "event_date": Timestamp,
  "created_at": Timestamp,
  "expires_at": Timestamp, // 7 dias após criação
  "dismissed": false,
  "reviewee_name": "João Silva",
  "reviewee_photo_url": "https://..."
}
```

---

### 2. **Verificação Automática (App)**

**Serviço:** `PendingReviewsCheckerService`
- **Localização:** `lib/features/reviews/presentation/services/pending_reviews_checker_service.dart`
- **Função:** Verifica PendingReviews e exibe ReviewDialog automaticamente

**Características:**
- ✅ **Rate Limiting:** Mínimo de 5 minutos entre verificações
- ✅ **Singleton Pattern:** Instância única compartilhada
- ✅ **Context Safety:** Verifica se context.mounted antes de exibir dialogs
- ✅ **Feedback Visual:** Mostra SnackBar quando há mais reviews pendentes

**Métodos Principais:**
```dart
// Verifica e exibe dialog automaticamente
Future<bool> checkAndShowPendingReviews(BuildContext context)

// Apenas conta reviews pendentes (sem exibir dialog)
Future<int> getPendingReviewsCount()

// Reseta rate limiting (útil para testes)
void resetRateLimit()
```

---

### 3. **Integração com AuthProtectedWrapper**

O `AuthProtectedWrapper` foi atualizado para StatefulWidget e agora:

1. **Aguarda autenticação do usuário**
2. **Verifica pending reviews UMA vez** após login
3. **Exibe ReviewDialog automaticamente** se houver reviews pendentes

```dart
// lib/shared/widgets/auth_protected_wrapper.dart
class AuthProtectedWrapper extends StatefulWidget {
  final bool checkPendingReviews; // Default: true
  
  const AuthProtectedWrapper({
    required this.child,
    this.checkPendingReviews = true, // Pode desabilitar se necessário
  });
}
```

**Comportamento:**
```
Usuário abre app
    ↓
AuthProtectedWrapper detecta login
    ↓
PendingReviewsCheckerService.checkAndShowPendingReviews()
    ↓
Busca na coleção PendingReviews
    ↓
Se houver pendentes → Exibe ReviewDialog
    ↓
Usuário completa avaliação
    ↓
Se houver mais → Mostra SnackBar com ação "Avaliar"
```

---

## 📊 Repository Layer

**Arquivo:** `lib/features/reviews/data/repositories/review_repository.dart`

### Métodos de Pending Reviews:

```dart
// Busca reviews pendentes do usuário atual
Future<List<PendingReviewModel>> getPendingReviews()

// Conta reviews pendentes (para badge)
Future<int> getPendingReviewsCount()

// Marca review como dismissed
Future<void> dismissPendingReview(String pendingReviewId)
```

**Query Firestore:**
```dart
_firestore
  .collection('PendingReviews')
  .where('reviewer_id', isEqualTo: userId)
  .where('dismissed', isEqualTo: false)
  .where('expires_at', isGreaterThan: now)
  .orderBy('expires_at')
  .orderBy('created_at', descending: true)
  .limit(20)
```

**Filtro Extra:** Verifica se já existe review na coleção `Reviews` para evitar duplicatas.

---

## 🎨 UI Components

### ReviewDialog (Não Alterado)

O `ReviewDialog` permanece com 3 steps:
1. **RatingCriteriaStep:** Avaliação por estrelas (comunicação, pontualidade, etc.)
2. **BadgeSelectionStep:** Seleção de badges (divertido, confiável, etc.)
3. **CommentStep:** Comentário opcional

### PendingReviewsScreen

Tela manual para ver/gerenciar todos os pending reviews:
- Lista completa de reviews pendentes
- Botão "Avaliar" para cada item
- Botão "Descartar" com confirmação
- Auto-refresh após completar avaliação

**Rota:** Configurar em `AppRoutes` se necessário

---

## 🔍 Debugging

### Logs do Checker Service:

```dart
🔍 [PendingReviewsChecker] Verificando pending reviews...
📋 [PendingReviewsChecker] Encontrado(s) 2 review(s) pendente(s)
🎯 [PendingReviewsChecker] Exibindo dialog para avaliar João Silva (evento: Pizzaria)
✅ [PendingReviewsChecker] Review enviado com sucesso
📋 [PendingReviewsChecker] Ainda há 1 review(s) pendente(s)
```

### Logs de Rate Limiting:

```dart
⏭️ [PendingReviewsChecker] Pulando verificação (última há 3min)
```

### Forçar Verificação (Para Testes):

```dart
final checker = PendingReviewsCheckerService();
checker.resetRateLimit(); // Remove rate limiting
await checker.checkAndShowPendingReviews(context);
```

---

## ⚙️ Configuração

### Desabilitar Verificação Automática

Se precisar desabilitar em alguma tela específica:

```dart
AuthProtectedWrapper(
  checkPendingReviews: false, // Desabilita verificação
  child: MyCustomScreen(),
)
```

### Ajustar Rate Limiting

Edite `pending_reviews_checker_service.dart`:

```dart
// Duração mínima entre verificações
static const Duration _minCheckInterval = Duration(minutes: 5);
```

---

## 🔐 Firestore Security Rules

**Arquivo:** `firestore.rules`

```javascript
match /PendingReviews/{reviewId} {
  // Leitura: apenas o reviewer
  allow read: if request.auth != null 
              && request.auth.uid == resource.data.reviewer_id;
  
  // Escrita: apenas Cloud Functions (admin)
  allow write: if false;
  
  // Update: reviewer pode marcar como dismissed
  allow update: if request.auth != null 
                && request.auth.uid == resource.data.reviewer_id
                && request.resource.data.diff(resource.data).affectedKeys()
                   .hasOnly(['dismissed', 'dismissed_at']);
}
```

---

## 📝 Índices Firestore Necessários

```json
{
  "collectionGroup": "PendingReviews",
  "queryScope": "COLLECTION",
  "fields": [
    { "fieldPath": "reviewer_id", "order": "ASCENDING" },
    { "fieldPath": "dismissed", "order": "ASCENDING" },
    { "fieldPath": "expires_at", "order": "ASCENDING" },
    { "fieldPath": "created_at", "order": "DESCENDING" }
  ]
}
```

**Criar via Firebase Console:** Firestore → Indexes → Create Index

---

## ✅ Checklist de Funcionamento

- [x] Cloud Function `checkEventsForReview` rodando a cada 5 minutos
- [x] Coleção `PendingReviews` sendo populada após eventos terminarem
- [x] `PendingReviewsCheckerService` integrado no `AuthProtectedWrapper`
- [x] `ReviewDialog` exibindo automaticamente após login
- [x] Rate limiting funcionando (5 minutos entre verificações)
- [x] SnackBar informando sobre reviews adicionais
- [x] Repository filtrando reviews já submetidos
- [x] Security rules configuradas corretamente
- [x] Índices Firestore criados

---

## 🚀 Próximos Passos (Opcional)

1. **Badge de Notificação:**
   - Adicionar contador de pending reviews no ícone de notificações
   - Atualizar badge após completar review

2. **Deep Linking:**
   - Permitir abrir ReviewDialog via notificação push
   - Adicionar `actionType: "open_pending_reviews"` nas notificações

3. **Analytics:**
   - Track completion rate de reviews
   - Monitor tempo médio para completar review

4. **UX Improvements:**
   - Animação de entrada do dialog
   - Confetti ao completar review
   - Progress indicator "X de Y reviews completos"

---

## 📞 Troubleshooting

### Dialog não aparece após login

1. Verificar logs no console: procurar por `[PendingReviewsChecker]`
2. Conferir se há documentos em `PendingReviews` para o usuário
3. Verificar rate limiting: usar `resetRateLimit()` para forçar

### Reviews aparecem duplicados

1. Verificar se filtro de `Reviews` existentes está funcionando
2. Checar se `dismissed` está sendo atualizado corretamente

### Cloud Function não cria PendingReviews

1. Verificar logs no Firebase Console → Functions
2. Conferir se eventos têm `status: "finished"` e terminaram há 24h
3. Validar query de índice composto

---

## 📚 Arquivos Relacionados

- `lib/features/reviews/presentation/services/pending_reviews_checker_service.dart`
- `lib/shared/widgets/auth_protected_wrapper.dart`
- `lib/features/reviews/data/repositories/review_repository.dart`
- `lib/features/reviews/presentation/dialogs/review_dialog.dart`
- `lib/features/reviews/presentation/screens/pending_reviews_screen.dart`
- `functions/src/reviews/checkEventsForReview.ts`
