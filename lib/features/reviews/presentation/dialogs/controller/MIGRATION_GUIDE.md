# 🚀 Guia de Migração - ReviewDialog Controller

## 📋 Checklist de Migração

### Fase 1: Preparação ✅ COMPLETO
- [x] Criar arquitetura modular (6 arquivos novos)
- [x] Extrair `ReviewDialogState`
- [x] Extrair `ReviewValidationService`
- [x] Extrair `ReviewUIService`
- [x] Extrair `ReviewNavigationService`
- [x] Extrair `ReviewBatchService`
- [x] Criar `ReviewDialogController_v2`
- [x] Documentar arquitetura (README + ARCHITECTURE)

### Fase 2: Migração do Widget 🔄 PRÓXIMO PASSO
- [ ] Atualizar imports em `review_dialog.dart`
- [ ] Testar fluxo owner completo
- [ ] Testar fluxo participant completo
- [ ] Validar error handling
- [ ] Testar edge cases (voltar, pular, etc)

### Fase 3: Validação 🔜 PENDENTE
- [ ] Code review
- [ ] QA manual (staging)
- [ ] Monitorar logs (Firestore operations)
- [ ] Validar performance

### Fase 4: Deprecação 🔜 PENDENTE
- [ ] Marcar `review_dialog_controller.dart` como `@deprecated`
- [ ] Adicionar avisos de migração
- [ ] Aguardar 2 sprints
- [ ] Remover arquivo legado

---

## 🔧 Passo a Passo: Migração do Widget

### Step 1: Atualizar Imports

**ANTES:**
```dart
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';
```

**DEPOIS:**
```dart
// Opção 1: Import completo (recomendado)
import 'package:partiu/features/reviews/presentation/dialogs/controller/index.dart';

// Opção 2: Import específico
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller_v2.dart';
```

---

### Step 2: Atualizar Referências ao State

**ANTES:**
```dart
Consumer<ReviewDialogController>(
  builder: (context, controller, _) {
    final isOwner = controller.isOwnerReview;
    final currentStep = controller.currentStep;
    
    return Text('Step $currentStep');
  },
)
```

**DEPOIS:**
```dart
Consumer<ReviewDialogController>(
  builder: (context, controller, _) {
    final state = controller.state;
    final isOwner = state.isOwnerReview;
    final currentStep = state.currentStep;
    
    return Text('Step $currentStep');
  },
)
```

**⚠️ IMPORTANTE:** Apenas propriedades de **estado** foram movidas para `controller.state`. Getters e métodos permanecem no `controller`.

---

### Step 3: Verificar Getters e Métodos (SEM MUDANÇAS)

**✅ SEM MUDANÇAS NECESSÁRIAS:**
```dart
// Getters continuam direto no controller
controller.canProceed
controller.hasCompletedRatings
controller.currentStepLabel
controller.buttonText
controller.shouldShowSkipButton

// Métodos continuam iguais
controller.setRating('pontualidade', 5);
controller.toggleBadge('comunicativo');
controller.goToBadgesStep();
controller.submitReview();
```

---

### Step 4: Checklist de Propriedades Migradas

Use esta tabela para revisar seu código:

| Propriedade | Antes | Depois | Motivo |
|-------------|-------|--------|--------|
| `eventId` | `controller.eventId` | `controller.state.eventId` | Estado |
| `currentStep` | `controller.currentStep` | `controller.state.currentStep` | Estado |
| `ratings` | `controller.ratings` | `controller.state.ratings` | Estado |
| `selectedParticipants` | `controller.selectedParticipants` | `controller.state.selectedParticipants` | Estado |
| `isSubmitting` | `controller.isSubmitting` | `controller.state.isSubmitting` | Estado UI |
| `errorMessage` | `controller.errorMessage` | `controller.state.errorMessage` | Estado UI |
| **isOwnerReview** | `controller.isOwnerReview` | `controller.state.isOwnerReview` | Getter |
| **canProceed** | `controller.canProceed` | `controller.canProceed` | Getter (sem mudança!) |
| **currentStepLabel** | `controller.currentStepLabel` | `controller.currentStepLabel` | Getter (sem mudança!) |

---

## 🧪 Testes de Regressão

### Checklist de Testes Manuais

#### 🔵 Fluxo Owner (4 steps)

**Step 0: Confirmação de Presença**
- [ ] Lista de participantes carregada corretamente
- [ ] Toggle participante funciona (selecionar/desselecionar)
- [ ] Botão "Confirmar" habilitado apenas com participantes selecionados
- [ ] Avançar para Step 1 após confirmar

**Step 1: Ratings (Participante 1)**
- [ ] Nome do participante exibido corretamente
- [ ] 6 critérios exibidos
- [ ] Estrelas funcionam (1-5)
- [ ] Botão "Continuar" habilitado após 4+ critérios
- [ ] Avançar para Step 2

**Step 2: Badges (Participante 1)**
- [ ] Badges exibidos corretamente
- [ ] Toggle badge funciona
- [ ] Botão "Continuar" sempre habilitado
- [ ] Avançar para Step 3

**Step 3: Comentário (Participante 1)**
- [ ] Campo de comentário funciona
- [ ] Botão "Próximo Participante" exibido (se não for o último)
- [ ] Botão "Enviar Avaliação" exibido (se for o último)
- [ ] Botão "Pular" exibido se comentário vazio
- [ ] Avançar para Step 1 do Participante 2

**Loop: Participantes 2-N**
- [ ] Repetir Steps 1-3 para cada participante
- [ ] Dados do participante anterior não aparecem
- [ ] Voltar funciona corretamente

**Submit Final**
- [ ] Validação: todos participantes avaliados
- [ ] Loading exibido durante submit
- [ ] Erro exibido se falhar
- [ ] Dialog fecha após sucesso
- [ ] Reviews criados no Firestore
- [ ] PendingReviews criados para participantes

#### 🟢 Fluxo Participant (3 steps)

**Step 0: Ratings**
- [ ] Nome do owner exibido
- [ ] 6 critérios exibidos
- [ ] Estrelas funcionam
- [ ] Botão "Continuar" habilitado após 4+ critérios
- [ ] Avançar para Step 1

**Step 1: Badges**
- [ ] Badges exibidos
- [ ] Toggle funciona
- [ ] Avançar para Step 2

**Step 2: Comentário**
- [ ] Campo funciona
- [ ] Botão "Enviar Avaliação"
- [ ] Botão "Pular" se vazio
- [ ] Submit funciona

**Submit**
- [ ] Review criado
- [ ] PendingReview deletado
- [ ] Dialog fecha

#### 🔴 Edge Cases

**Navegação para trás**
- [ ] Step 3 → Step 2: Volta para badges
- [ ] Step 2 → Step 1: Volta para ratings (preserva dados)
- [ ] Step 1 (owner, participante 2) → Step 3 (participante 1): Volta para comentário do anterior
- [ ] Step 1 (owner, participante 1) → Step 0: Volta para presença
- [ ] Step 0: Botão voltar desabilitado

**Validações**
- [ ] Ratings insuficientes: Erro exibido
- [ ] Participante sem permissão: Erro exibido
- [ ] Owner não avaliou todos: Erro exibido
- [ ] Network error: Mensagem amigável

**Estado Inconsistente (Recovery)**
- [ ] PendingReview com presenceConfirmed=true mas sem confirmedParticipantIds: Tenta recuperar
- [ ] Fallback para Step 0 se recovery falhar

---

## 🐛 Guia de Debugging

### Logs Importantes

O novo controller mantém todos os logs do legado. Procure por:

```
🔍 [ReviewDialog] Inicializando estruturas
✅ [ReviewDialog] Inicialização completa
❌ [ReviewDialog] ERRO: currentParticipantId é null
⭐ [Controller] setRating chamado
📤 [submitAllReviews] Iniciado
✅ [submitAllReviews] reviews criados com sucesso
```

### Problemas Comuns

#### Problema 1: "currentParticipantId é null"
**Causa:** Estado inconsistente após confirmação de presença  
**Solução:** Verificar logs de inicialização. Recovery automático tenta restaurar.

#### Problema 2: Botão "Continuar" não habilita
**Causa:** Ratings insuficientes (< 4)  
**Verificar:** `controller.hasCompletedRatings`

#### Problema 3: Submit bloqueado (owner)
**Causa:** Nem todos participantes foram avaliados  
**Verificar:** `controller.hasEvaluatedAllParticipants`

#### Problema 4: Participant não pode avaliar
**Causa:** `allowedToReviewOwner = false`  
**Solução:** Owner precisa confirmar presença do participant

---

## 🔬 Testes Automatizados (Próximos Passos)

### Unit Tests

```dart
// test/features/reviews/presentation/dialogs/controller/review_validation_service_test.dart

void main() {
  group('ReviewValidationService', () {
    test('should validate completed ratings with 4 criteria', () {
      final state = ReviewDialogState(
        eventId: '1',
        revieweeId: '2',
        reviewerRole: 'participant',
      );
      state.ratings.addAll({
        'pontualidade': 5,
        'comunicacao': 4,
        'organizacao': 5,
        'simpatia': 4,
      });

      expect(ReviewValidationService.hasCompletedRatings(state), true);
    });

    test('should fail validation with less than 4 criteria', () {
      final state = ReviewDialogState(
        eventId: '1',
        revieweeId: '2',
        reviewerRole: 'participant',
      );
      state.ratings.addAll({
        'pontualidade': 5,
        'comunicacao': 4,
      });

      expect(ReviewValidationService.hasCompletedRatings(state), false);
    });

    test('should validate permission for participant review', () {
      final state = ReviewDialogState(
        eventId: '1',
        revieweeId: '2',
        reviewerRole: 'participant',
        allowedToReviewOwner: false,
      );

      expect(ReviewValidationService.canProceed(state), false);
    });
  });
}
```

### Integration Tests

```dart
// test/features/reviews/presentation/dialogs/review_dialog_controller_test.dart

void main() {
  group('ReviewDialogController - Owner Flow', () {
    late ReviewDialogController controller;

    setUp(() {
      controller = ReviewDialogController(
        eventId: 'test-event',
        revieweeId: 'owner-id',
        reviewerRole: 'owner',
      );
      
      // Simular participantes confirmados
      controller.state.selectedParticipants = {'p1', 'p2'};
      controller.state.presenceConfirmed = true;
      controller.state.currentStep = 1;
    });

    test('should evaluate all participants before submit', () async {
      // Avaliar apenas 1 de 2 participantes
      controller.setRating('pontualidade', 5);
      controller.setRating('comunicacao', 4);
      controller.setRating('organizacao', 5);
      controller.setRating('simpatia', 4);

      final result = await controller.submitAllReviews();

      expect(result, false);
      expect(controller.state.errorMessage, contains('avaliar todos'));
    });
  });
}
```

---

## 📊 Métricas de Sucesso

Após migração, valide:

- ✅ **0 crashes** relacionados a reviews
- ✅ **Taxa de conclusão** de reviews >= 95%
- ✅ **Tempo médio** de submit < 2s
- ✅ **Firestore operations** reduzidas (batch)
- ✅ **Feedback positivo** de usuários

---

## 🆘 Rollback Plan

Se necessário reverter:

### Opção 1: Rollback Rápido (1 linha)
```dart
// review_dialog.dart

// De:
import 'package:partiu/features/reviews/presentation/dialogs/controller/index.dart';

// Para:
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';
```

### Opção 2: Feature Flag
```dart
const bool USE_NEW_CONTROLLER = false; // Trocar para false

final controller = USE_NEW_CONTROLLER
  ? ReviewDialogController_v2(...)
  : ReviewDialogController(...);
```

---

## ✅ Sign-off

Após concluir migração, preencher:

- [ ] **Dev Lead:** Revisou código e aprovou arquitetura
- [ ] **QA:** Testou todos fluxos e edge cases
- [ ] **Product:** Validou UX e performance
- [ ] **Deployment:** Migração concluída em produção
- [ ] **Monitoring:** 7 dias sem incidentes

**Data de conclusão:** ___/___/2025  
**Responsável:** _________________

---

**Dúvidas?** Consulte:
- 📖 [README.md](./README.md) - Visão geral
- 📐 [ARCHITECTURE.md](./ARCHITECTURE.md) - Diagramas detalhados
- 🔧 Este arquivo - Guia prático de migração
