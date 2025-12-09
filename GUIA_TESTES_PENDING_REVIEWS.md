# 🧪 GUIA DE TESTES - SISTEMA DE PENDING REVIEWS

## 🎯 O Que Testar

Este guia detalha como testar o fluxo completo do sistema de reviews, desde a criação automática pela Cloud Function até a avaliação mútua entre owner e participantes.

---

## 📋 PRÉ-REQUISITOS

### 1. Deploy do Índice do Firestore
```bash
cd /Users/maikelgalvao/partiu
firebase deploy --only firestore:indexes
```

Aguardar até que o índice seja criado (pode levar alguns minutos).

### 2. Verificar Cloud Function
```bash
firebase functions:log --only createPendingReviewsScheduled
```

A função deve estar rodando a cada 5 minutos.

---

## 🧪 CENÁRIO DE TESTE COMPLETO

### **SETUP: Criar o Evento**

1. **Login como Owner (Usuário A)**
   - Abrir app
   - Fazer login com conta A

2. **Criar Evento**
   - Ir para "Criar Evento"
   - Preencher:
     - Título: "Futebol no Parque"
     - Emoji: ⚽
     - Local: "Parque Ibirapuera"
     - Data/Hora: [Hoje, 2 horas atrás] (importante para simular evento que já passou)
   - Criar evento

3. **Login como Participante B**
   - Logout do Owner
   - Login com conta B
   - Buscar evento "Futebol no Parque"
   - Aplicar para participar

4. **Login como Participante C**
   - Logout do Participante B
   - Login com conta C
   - Buscar evento "Futebol no Parque"
   - Aplicar para participar

5. **Owner Aprova Aplicações**
   - Logout do Participante C
   - Login com Owner (conta A)
   - Ir para o evento
   - Aprovar aplicação do Participante B
   - Aprovar aplicação do Participante C

6. **Participantes Confirmam Presença**
   - Login como Participante B
   - Abrir evento
   - Clicar "Vou" (confirmar presença)
   - Logout
   
   - Login como Participante C
   - Abrir evento
   - Clicar "Vou" (confirmar presença)
   - Logout

---

## ⏰ FASE 1: AGUARDAR CRIAÇÃO DO PENDINGREVIEW

### Opção A: Aguardar 6 horas (Produção)
Aguardar 6 horas após o horário de início do evento. A Cloud Function criará automaticamente o PendingReview.

### Opção B: Forçar Criação (Desenvolvimento)
```javascript
// Firestore Console
// 1. Ir para Events > [seu evento]
// 2. Editar campo schedule.date para 7 horas atrás
// 3. Aguardar 5 minutos (próxima execução da Cloud Function)

// OU executar diretamente no console:
const admin = require('firebase-admin');
admin.initializeApp();

const eventId = 'SEU_EVENT_ID_AQUI';
const ownerId = 'OWNER_USER_ID_AQUI';

// Criar PendingReview manualmente
await admin.firestore().collection('PendingReviews').doc(`${eventId}_owner_${ownerId}`).set({
  pending_review_id: `${eventId}_owner_${ownerId}`,
  event_id: eventId,
  reviewer_id: ownerId,
  reviewer_role: 'owner',
  event_title: 'Futebol no Parque',
  event_emoji: '⚽',
  participant_ids: ['PARTICIPANT_B_ID', 'PARTICIPANT_C_ID'],
  participant_profiles: {
    'PARTICIPANT_B_ID': { name: 'Participante B', photo: null },
    'PARTICIPANT_C_ID': { name: 'Participante C', photo: null }
  },
  presence_confirmed: false,
  created_at: admin.firestore.FieldValue.serverTimestamp(),
  expires_at: admin.firestore.Timestamp.fromDate(new Date(Date.now() + 30*24*60*60*1000)),
  dismissed: false
});
```

### ✅ Checkpoint 1: Verificar Firestore
```
Coleção: PendingReviews
Documento: [eventId]_owner_[ownerId]

Campos esperados:
✅ reviewer_id = ownerId
✅ reviewer_role = "owner"
✅ participant_ids = [array com 2 IDs]
✅ participant_profiles = {objeto com dados}
✅ presence_confirmed = false
✅ dismissed = false
```

---

## 🎮 FASE 2: OWNER AVALIA PARTICIPANTES

### 1. Login como Owner
```
Login com conta A (Owner)
```

### 2. Listener Detecta PendingReview
**Logs esperados no console:**
```
[PendingReviewsListener] 🎯 Iniciando listener para userId: [ownerId]
[PendingReviewsListener] 📸 Snapshot recebido! Documentos: 1
[PendingReviewsListener] 🔔 1 novos pending reviews detectados!
[PendingReviewsChecker] Checking for pending reviews...
```

### 3. ReviewDialog Abre Automaticamente
**✅ Verificar:**
- Dialog aparece automaticamente (não precisa ir em lugar nenhum)
- Título: "Confirmar Presença"
- Lista mostra Participante B e Participante C
- Cada participante tem checkbox

### 4. STEP 0: Confirmar Presença
**Ações:**
- Selecionar checkbox do Participante B
- Selecionar checkbox do Participante C
- Clicar botão "Confirmar (2)"

**Logs esperados:**
```
🔍 [ReviewDialog] confirmPresenceAndProceed iniciado
   - selectedParticipants: 2
   📝 Atualizando PendingReview...
   ✅ PendingReview atualizado
   💾 Salvando participantes confirmados...
   ✅ 2 participantes salvos
   🎯 Iniciando avaliação do participante 0
   ✅ Confirmação concluída, avançando para STEP 1
```

**✅ Checkpoint 2: Verificar Firestore**
```
Coleção: Events/[eventId]/ConfirmedParticipants
Documentos:
- [participantBId]: { confirmed_by: ownerId, reviewed: false }
- [participantCId]: { confirmed_by: ownerId, reviewed: false }

Coleção: PendingReviews/[eventId]_owner_[ownerId]
- presence_confirmed = true
- confirmed_participant_ids = [array com 2 IDs]
```

### 5. STEP 1: Avaliar Participante B (Ratings)
**✅ Verificar:**
- Título: "Avaliação de Critérios"
- Mostra avatar e nome do Participante B
- 5 critérios aparecem:
  - Pontualidade
  - Comunicação
  - Respeito
  - Comprometimento
  - Diversão

**Ações:**
- Dar 5 estrelas para "Pontualidade"
- Dar 4 estrelas para "Comunicação"
- Dar 5 estrelas para "Respeito"
- Dar 5 estrelas para "Comprometimento"
- Dar 4 estrelas para "Diversão"
- Clicar "Continuar"

**Logs esperados:**
```
⭐ [Controller] setRating chamado!
   - criterion: punctuality
   - value: 5
   - isOwnerReview: true
   - currentParticipantId: [participantBId]
   ✅ Rating salvo para participante [participantBId]
```

### 6. STEP 2: Badges (Opcional)
**Ações:**
- Selecionar 2-3 badges
- Clicar "Continuar"

### 7. STEP 3: Comentário para Participante B
**Ações:**
- Escrever: "Ótima companhia, pontual e divertido!"
- Clicar "Próximo Participante"

### 8. Repetir STEPS 1-3 para Participante C
**Ações:**
- Avaliar Participante C (5 critérios)
- Selecionar badges (opcional)
- Escrever comentário: "Pessoa incrível, super animada!"
- Clicar "Enviar Avaliação" (último participante)

### 9. Submit Final
**Logs CRÍTICOS esperados:**
```
ReviewDialogController: submitAllReviews called. pendingReviewId: [eventId]_owner_[ownerId]
ReviewDialogController: selectedParticipants: [participantBId, participantCId]
ReviewDialogController: Owner data fetched. Name: [Owner Name]

ReviewDialogController: Processing participant [participantBId]
ReviewDialogController: Review created for [participantBId]
ReviewDialogController: PendingReview created for [participantBId] ← CRÍTICO!
ReviewDialogController: Participant marked as reviewed: [participantBId]

ReviewDialogController: Processing participant [participantCId]
ReviewDialogController: Review created for [participantCId]
ReviewDialogController: PendingReview created for [participantCId] ← CRÍTICO!
ReviewDialogController: Participant marked as reviewed: [participantCId]

ReviewDialogController: PendingReview deleted: [eventId]_owner_[ownerId]
```

**✅ Checkpoint 3: Verificar Firestore**
```
Coleção: Reviews
Documentos:
- review1: {
    reviewer_id: ownerId,
    reviewee_id: participantBId,
    reviewer_role: "owner",
    overall_rating: 4.6,
    ...
  }
- review2: {
    reviewer_id: ownerId,
    reviewee_id: participantCId,
    reviewer_role: "owner",
    ...
  }

Coleção: PendingReviews
Documentos NOVOS:
- [eventId]_participant_[participantBId]: {
    reviewer_id: participantBId,
    reviewee_id: ownerId,
    reviewer_role: "participant",
    reviewee_name: "[Owner Name]",
    ...
  }
- [eventId]_participant_[participantCId]: {
    reviewer_id: participantCId,
    reviewee_id: ownerId,
    reviewer_role: "participant",
    ...
  }

Documento DELETADO:
- [eventId]_owner_[ownerId] ❌

Coleção: Events/[eventId]/ConfirmedParticipants
Documentos:
- [participantBId]: { reviewed: true }
- [participantCId]: { reviewed: true }
```

### 10. Mensagem de Sucesso
**✅ Verificar:**
- Dialog fecha
- SnackBar aparece: "✅ 2 avaliações enviadas com sucesso!"

---

## 👤 FASE 3: PARTICIPANTE B AVALIA OWNER

### 1. Login como Participante B
```
Logout do Owner
Login com Participante B
```

### 2. Listener Detecta Novo PendingReview
**Logs esperados:**
```
[PendingReviewsListener] 🎯 Iniciando listener para userId: [participantBId]
[PendingReviewsListener] 📸 Snapshot recebido! Documentos: 1
[PendingReviewsListener] 📄 Doc [eventId]_participant_[participantBId]:
   - reviewer_id: [participantBId]
   - dismissed: false
   - event_id: [eventId]
[PendingReviewsListener] 🔔 1 novos pending reviews detectados!
```

### 3. ReviewDialog Abre Automaticamente
**✅ Verificar:**
- Dialog aparece automaticamente
- **NÃO mostra STEP 0** (confirmar presença)
- Começa direto no **STEP 1** (Avaliação de Critérios)
- Mostra avatar e nome do **Owner**
- Título: "Avaliação de Critérios"

### 4. STEP 1: Avaliar Owner (Ratings)
**Ações:**
- Dar 5 estrelas para cada critério
- Clicar "Continuar"

### 5. STEP 2: Badges (Opcional)
**Ações:**
- Selecionar alguns badges
- Clicar "Continuar"

### 6. STEP 3: Comentário
**Ações:**
- Escrever: "Evento bem organizado, owner super atencioso!"
- Clicar "Enviar Avaliação"

### 7. Submit Final
**Logs esperados:**
```
ReviewDialogController: submitReview called
[ReviewRepository] createReview
   - reviewer_id: [participantBId]
   - reviewee_id: [ownerId]
   - reviewer_role: "participant"
[ReviewRepository] deletePendingReview: [eventId]_participant_[participantBId]
```

**✅ Checkpoint 4: Verificar Firestore**
```
Coleção: Reviews
Documento NOVO:
- review3: {
    reviewer_id: participantBId,
    reviewee_id: ownerId,
    reviewer_role: "participant",
    overall_rating: 5.0,
    comment: "Evento bem organizado...",
    ...
  }

Coleção: PendingReviews
Documento DELETADO:
- [eventId]_participant_[participantBId] ❌

Coleção: ReviewStats
Documento atualizado:
- [ownerId]: {
    total_reviews: +1,
    criteria_averages: { ... },
    ...
  }
```

### 8. Mensagem de Sucesso
**✅ Verificar:**
- Dialog fecha
- SnackBar: "✅ Avaliação enviada com sucesso!"

---

## 👤 FASE 4: PARTICIPANTE C AVALIA OWNER

Repetir exatamente os mesmos passos da **FASE 3**, mas com:
- Login como Participante C
- PendingReview: `[eventId]_participant_[participantCId]`

---

## 📊 VERIFICAÇÃO FINAL

### 1. Verificar Reviews Totais
```
Coleção: Reviews
Total de documentos: 4

- review1: owner → participantB
- review2: owner → participantC
- review3: participantB → owner
- review4: participantC → owner
```

### 2. Verificar ReviewStats
```
Coleção: ReviewStats

Documento [ownerId]:
- total_reviews: 2
- criteria_averages: { ... }

Documento [participantBId]:
- total_reviews: 1
- criteria_averages: { ... }

Documento [participantCId]:
- total_reviews: 1
- criteria_averages: { ... }
```

### 3. Verificar PendingReviews
```
Coleção: PendingReviews
Total de documentos: 0 (todos deletados)
```

### 4. Verificar ConfirmedParticipants
```
Coleção: Events/[eventId]/ConfirmedParticipants

- [participantBId]: { reviewed: true, confirmed_by: ownerId }
- [participantCId]: { reviewed: true, confirmed_by: ownerId }
```

---

## 🐛 TROUBLESHOOTING

### Problema 1: Owner não vê PendingReview
**Sintoma:** Dialog não abre automaticamente para owner

**Verificar:**
1. Cloud Function executou?
   ```bash
   firebase functions:log --only createPendingReviewsScheduled
   ```
2. Documento existe no Firestore?
   - Ir para `PendingReviews/[eventId]_owner_[ownerId]`
3. Campos corretos?
   - `reviewer_id` == owner userId?
   - `dismissed` == false?
4. Listener iniciou?
   - Ver logs: `[PendingReviewsListener]`

**Solução:**
- Verificar se `startListening()` foi chamado no `HomeScreenRefactored`
- Verificar permissões no `firestore.rules`

---

### Problema 2: Participante não vê PendingReview
**Sintoma:** Dialog não abre automaticamente para participante

**Verificar:**
1. Owner completou a avaliação?
2. Logs do `submitAllReviews()` mostram criação?
   ```
   ReviewDialogController: PendingReview created for [participantId]
   ```
3. Documento existe no Firestore?
   - Ir para `PendingReviews/[eventId]_participant_[participantId]`
4. Campos corretos?
   - `reviewer_id` == participant userId?
   - `reviewee_id` == owner userId?
   - `reviewer_role` == "participant"?

**Solução:**
- Verificar se `createParticipantPendingReview()` foi executado
- Verificar se não há erro de duplicata (participante já avaliou)

---

### Problema 3: Dialog abre mas começa no step errado
**Sintoma:** Participante vê STEP 0 (confirmar presença)

**Verificar:**
- Campo `reviewer_role` no PendingReview
- Deve ser "participant" (não "owner")

**Solução:**
- Deletar PendingReview incorreto
- Forçar nova criação com role correto

---

### Problema 4: Erro "Você já avaliou esta pessoa"
**Sintoma:** Submit falha com erro de duplicata

**Verificar:**
- Já existe Review no Firestore?
- Query: `Reviews` where `reviewer_id` == userId AND `reviewee_id` == targetId AND `event_id` == eventId

**Solução:**
- Normal se tentar avaliar novamente
- Deletar review antiga se for teste
- PendingReview deve ser deletado após primeira avaliação

---

### Problema 5: PendingReview não é deletado
**Sintoma:** Dialog fecha mas documento permanece no Firestore

**Verificar:**
1. `pendingReviewId` foi passado corretamente?
2. Logs mostram chamada de `deletePendingReview()`?
3. Permissões no `firestore.rules`?

**Solução:**
- Adicionar logs no `deletePendingReview()`
- Verificar regras de segurança do Firestore
- Deletar manualmente e testar novamente

---

## ✅ CHECKLIST FINAL

Após completar todos os testes, confirmar:

- [ ] Cloud Function cria PendingReview do owner
- [ ] Owner recebe notificação via listener
- [ ] Owner seleciona participantes presentes (STEP 0)
- [ ] Owner avalia cada participante (STEPS 1-3)
- [ ] Sistema cria PendingReviews para participantes (logs confirmam)
- [ ] PendingReview do owner é deletado
- [ ] Participante B recebe notificação via listener
- [ ] Participante B avalia owner (direto do STEP 1)
- [ ] PendingReview do participante B é deletado
- [ ] Participante C recebe notificação via listener
- [ ] Participante C avalia owner (direto do STEP 1)
- [ ] PendingReview do participante C é deletado
- [ ] Total de 4 Reviews criadas no Firestore
- [ ] Nenhum PendingReview remanescente
- [ ] ReviewStats atualizados para todos

---

## 📝 RELATÓRIO DE TESTE

Use este template para documentar seus testes:

```markdown
## Teste Executado em: [DATA]

### Fase 1: Criação PendingReview Owner
- [ ] PendingReview criado pela Cloud Function
- [ ] Campos corretos no Firestore
- [ ] Listener detectou mudança

### Fase 2: Owner Avalia Participantes
- [ ] Dialog abriu automaticamente
- [ ] STEP 0: Seleção de participantes funcionou
- [ ] STEP 1-3: Avaliação de cada participante funcionou
- [ ] Logs mostram criação de PendingReviews para participantes
- [ ] PendingReviews dos participantes criados no Firestore
- [ ] PendingReview do owner deletado

### Fase 3: Participante B Avalia Owner
- [ ] Listener detectou PendingReview
- [ ] Dialog abriu automaticamente
- [ ] Começou direto no STEP 1 (sem confirmar presença)
- [ ] Avaliação completa funcionou
- [ ] Review criada no Firestore
- [ ] PendingReview deletado

### Fase 4: Participante C Avalia Owner
- [ ] Mesmos checks da Fase 3

### Verificação Final
- [ ] 4 Reviews no total
- [ ] 0 PendingReviews restantes
- [ ] ReviewStats atualizados

### Problemas Encontrados:
[Listar problemas e soluções]

### Conclusão:
[ ] Sistema funcionando 100%
[ ] Sistema com problemas (detalhar acima)
```

---

**🎉 Boa sorte com os testes!**

Se todos os checkpoints passarem, o sistema está funcionando perfeitamente!
