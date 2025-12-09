# Correção do Bug de Autoavaliação

## 🐛 Problema Identificado

Usuários estavam recebendo notificações para avaliar a si mesmos no sistema de reviews.

### Causa Raiz

O bug estava no método `getPendingReviewsStream()` do `ReviewRepository`, que estava **enriquecendo TODOS os reviews** com dados do owner, sobrescrevendo o `revieweeId` original que vinha do Firestore.

**Comportamento incorreto:**
```dart
// ❌ ANTES: Enriquecia TODOS os reviews com dados do owner
final enrichedReviews = reviews.map((review) {
  final ownerData = ownersData[review.eventId];
  return review.copyWith(
    revieweeId: ownerData['userId'], // ⚠️ Sobrescreve para TODOS
    revieweeName: ownerData['fullName'],
    revieweePhotoUrl: ownerData['photoUrl'],
  );
});
```

**Resultado:**
- ✅ **Participant reviews** (avaliam owner) → `revieweeId` = ownerId (correto)
- ❌ **Owner reviews** (avaliam participants) → `revieweeId` = ownerId (ERRADO! Deveria ser participantId)

Isso causava:
1. Owner recebia notificações para avaliar a si mesmo
2. Dados do participante sendo avaliado eram perdidos

## ✅ Solução Implementada

### 1. Correção no ReviewRepository

**Arquivo:** `lib/features/reviews/data/repositories/review_repository.dart`

```dart
// ✅ DEPOIS: Enriquece APENAS reviews de PARTICIPANTS
final enrichedReviews = reviews.map((review) {
  // Só enriquece se for PARTICIPANT avaliando owner
  if (review.reviewerRole == 'participant') {
    final ownerData = ownersData[review.eventId];
    return review.copyWith(
      revieweeId: ownerData['userId'],
      revieweeName: ownerData['fullName'],
      revieweePhotoUrl: ownerData['photoUrl'],
    );
  }
  
  // Owner reviews mantêm revieweeId original (participantId)
  return review;
}).toList();

// Filtro adicional: Remove qualquer review de autoavaliação
final validReviews = enrichedReviews.where((review) {
  if (review.reviewerId == review.revieweeId) {
    debugPrint('❌ BLOQUEADO: Autoavaliação detectada!');
    return false;
  }
  return true;
}).toList();
```

### 2. Validação no ReviewDialogController

**Arquivo:** `lib/features/reviews/presentation/dialogs/review_dialog_controller.dart`

```dart
void initializeFromPendingReview(PendingReviewModel pendingReview) {
  // VALIDAÇÃO CRÍTICA: Impedir autoavaliação
  if (pendingReview.reviewerId == pendingReview.revieweeId) {
    debugPrint('❌ ERRO: Tentativa de autoavaliação detectada!');
    _state.errorMessage = 'Erro: Não é possível avaliar a si mesmo';
    notifyListeners();
    return;
  }
  
  // Filtrar owner da lista de participantes
  if (_state.participantIds.contains(_state.reviewerId)) {
    debugPrint('⚠️ Owner detectado na lista de participantes, removendo...');
    _state.participantIds = _state.participantIds
        .where((id) => id != _state.reviewerId)
        .toList();
  }
  
  // ...resto da inicialização
}
```

### 3. Visual Feedback no ReviewCard

**Arquivo:** `lib/features/reviews/presentation/widgets/review_card.dart`

```dart
// Detecta e exibe erro visual para autoavaliações que passarem pelos filtros
if (pendingReview.reviewerId == pendingReview.revieweeId) {
  return Container(
    // Erro visual em vermelho
    decoration: BoxDecoration(
      color: GlimpseColors.error.withOpacity(0.1),
      border: Border.all(color: GlimpseColors.error, width: 2),
    ),
    child: Row(
      children: [
        Icon(Icons.error_outline, color: GlimpseColors.error),
        Text('Erro: Review inválido detectado (autoavaliação)'),
        IconButton(
          icon: Icon(Icons.close),
          onPressed: () => dismissPendingReview(),
        ),
      ],
    ),
  );
}
```

## 🔒 Camadas de Proteção (Defense in Depth)

### Camada 1: Cloud Function (Origem)
✅ Já estava correto - cria reviews com `reviewer_id` e `reviewee_id` distintos

### Camada 2: Repository Stream
✅ **NOVO:** Filtra reviews de autoavaliação antes de emitir no stream

### Camada 3: Controller Initialization
✅ **NOVO:** Valida e bloqueia inicialização de reviews inválidos

### Camada 4: UI Visual Feedback
✅ **NOVO:** Exibe erro visual caso algum review inválido chegue na UI

## 📋 Regras de Negócio Validadas

### ✅ Owner Reviews
- Owner avalia **participants**
- Owner **NÃO** avalia a si mesmo
- Step 0 (confirmação de presença) aparece **apenas** para owner
- `reviewerId` = ownerId
- `revieweeId` = participantId

### ✅ Participant Reviews
- Participant avalia **owner**
- Participant **NÃO** avalia a si mesmo
- Step 0 **NÃO** aparece para participant
- `reviewerId` = participantId
- `revieweeId` = ownerId

## 🧪 Como Testar

### 1. Criar Evento de Teste
```
1. User A cria evento
2. User B se candidata
3. User A aprova User B
4. User B confirma presença ("Eu vou")
5. Aguardar 6h após início do evento (ou usar função manual)
```

### 2. Verificar Notificações
```
✅ User A (owner) deve receber: "User B precisa ser avaliado"
✅ User B (participant) deve receber: "User A precisa ser avaliado"
❌ User A NÃO deve receber: "User A precisa ser avaliado"
❌ User B NÃO deve receber: "User B precisa ser avaliado"
```

### 3. Logs de Debug
Procurar por:
- `✅ [ReviewRepository] Enriquecendo review PARTICIPANT` - Participant reviews enriquecidos
- `✅ [ReviewRepository] Mantendo review OWNER` - Owner reviews mantidos
- `❌ [ReviewRepository] BLOQUEADO: Autoavaliação` - Reviews inválidos filtrados
- `❌ [ReviewCard] ERRO: Autoavaliação` - UI bloqueando review inválido

## 📊 Impacto

### Antes
- ❌ Owner podia receber notificações para avaliar a si mesmo
- ❌ Dados do participante eram sobrescritos por dados do owner
- ❌ Sistema não validava autoavaliações

### Depois
- ✅ Apenas reviews válidos chegam na UI
- ✅ Owner reviews mantêm dados corretos do participante
- ✅ Participant reviews mantêm dados corretos do owner
- ✅ Múltiplas camadas de validação impedem autoavaliações
- ✅ Feedback visual claro em caso de erro

## 🔍 Arquivos Modificados

1. `lib/features/reviews/data/repositories/review_repository.dart`
   - Corrigiu lógica de enriquecimento de reviews
   - Adicionou filtro de autoavaliações

2. `lib/features/reviews/presentation/dialogs/review_dialog_controller.dart`
   - Adicionou validação de autoavaliação na inicialização
   - Filtra owner da lista de participantes

3. `lib/features/reviews/presentation/widgets/review_card.dart`
   - Adicionou visual feedback para reviews inválidos
   - Permite dismiss de reviews com erro

## ✅ Conclusão

O bug foi completamente resolvido com múltiplas camadas de proteção. O sistema agora garante que:

1. **Owner avalia apenas participants** ✅
2. **Participants avaliam apenas owner** ✅
3. **Ninguém avalia a si mesmo** ✅
4. **Step 0 aparece apenas para owner** ✅

Data: 9 de dezembro de 2025
