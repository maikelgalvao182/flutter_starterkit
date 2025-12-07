# 🧪 TESTE MANUAL - SISTEMA DE REVIEWS COM CONFIRMAÇÃO DE PRESENÇA

**Data:** 7 de dezembro de 2025  
**Status:** Aguardando Execução  
**Objetivo:** Validar fluxo completo de reviews após implementação das Fases 1-4

---

## 📋 PRÉ-REQUISITOS

- ✅ Fases 1-4 implementadas
- ✅ Cloud Function `createPendingReviewsScheduled` deployada e ativa
- ✅ Índices Firestore deployados
- ✅ App Flutter compilando sem erros
- ✅ Acesso ao Firebase Console
- ✅ Acesso ao app em device físico ou emulador

---

## 🎯 TESTE 1: CRIAÇÃO AUTOMÁTICA DE PENDING REVIEW

### Objetivo
Verificar se a Cloud Function cria PendingReview para o owner após evento terminar.

### Passos

#### 1.1 Criar Evento de Teste
```
1. Abrir app Partiu
2. Login como usuário A (será o OWNER)
3. Criar novo evento:
   - Título: "Teste Reviews - [TIMESTAMP]"
   - Local: Qualquer
   - Data/Hora: AGORA + 2 minutos
   - Emoji: 🧪
   - Salvar evento
4. Anotar Event ID (verificar no Firebase Console > events)
```

#### 1.2 Adicionar Participantes
```
1. Login como usuário B (será PARTICIPANTE 1)
2. Buscar evento criado
3. Aplicar no evento
4. Marcar presence como "Vou"

5. Login como usuário C (será PARTICIPANTE 2)
6. Buscar evento criado
7. Aplicar no evento
8. Marcar presence como "Vou"

9. Login como usuário D (será PARTICIPANTE 3)
10. Buscar evento criado
11. Aplicar no evento
12. Marcar presence como "Talvez" ⚠️ (não deve ser incluído)
```

#### 1.3 Aprovar Participações (como Owner)
```
1. Login como usuário A (owner)
2. Ir para o evento
3. Aprovar participações dos usuários B, C e D
4. Verificar status: approved
```

#### 1.4 Aguardar Evento Terminar
```
1. Aguardar 2+ minutos (evento terminou)
2. Aguardar mais 5 minutos (Cloud Function executará)
3. Total: ~7 minutos de espera
```

#### 1.5 Verificar no Firebase Console

**A. Verificar Evento Marcado como Processado:**
```
Firebase Console > Firestore > events > [EVENT_ID]

Campos esperados:
✅ pendingReviewsCreated: true
✅ pendingReviewsCreatedAt: Timestamp
```

**B. Verificar PendingReview Criado:**
```
Firebase Console > Firestore > PendingReviews > [EVENT_ID]_owner_[OWNER_ID]

Campos esperados:
✅ pending_review_id: "{eventId}_owner_{ownerId}"
✅ event_id: "{eventId}"
✅ reviewer_id: "{ownerId}"
✅ reviewer_role: "owner"
✅ participant_ids: [userId_B, userId_C] (SEM userId_D - "Talvez")
✅ participant_profiles: {
     userId_B: { name: "Nome B", photo: "url" },
     userId_C: { name: "Nome C", photo: "url" }
   }
✅ presence_confirmed: false
✅ created_at: Timestamp
✅ expires_at: Timestamp (+30 dias)
✅ dismissed: false
```

**C. Verificar Logs da Cloud Function:**
```
Firebase Console > Functions > createPendingReviewsScheduled > Logs

Logs esperados:
🔍 [PendingReviews] Buscando eventos finalizados...
📅 [PendingReviews] X eventos encontrados
🎯 [PendingReviews] Processando evento: {eventId}
👥 [PendingReviews] 2 participantes "Vou"
📸 [PendingReviews] 2 perfis carregados
✅ [PendingReviews] Criado para owner: {pendingReviewId}
✅ [PendingReviews] Evento {eventId} processado com sucesso
```

### Resultado Esperado
- ✅ PendingReview criado para owner com 2 participantes (B e C)
- ✅ Participante D (presence="Talvez") NÃO incluído
- ✅ Evento marcado como processado
- ✅ Perfis dos participantes pré-carregados

---

## 🎯 TESTE 2: OWNER - CONFIRMAR PRESENÇA (STEP 0)

### Objetivo
Verificar se owner consegue confirmar quem realmente compareceu ao evento.

### Passos

#### 2.1 Abrir ReviewDialog
```
1. Login como usuário A (owner)
2. Ir para tela de PendingReviews (ou aguardar notificação)
3. Clicar no card do evento de teste
4. ReviewDialog deve abrir no STEP 0
```

#### 2.2 Verificar UI do STEP 0
```
Elementos esperados:
✅ Título: "Quem realmente apareceu?"
✅ Descrição explicativa
✅ Lista de participantes com checkboxes:
   - [ ] Participante B (nome + avatar)
   - [ ] Participante C (nome + avatar)
✅ Botão "Confirmar (0)" (desabilitado)
```

#### 2.3 Selecionar Participantes
```
1. Marcar checkbox do Participante B
2. Verificar: Botão muda para "Confirmar (1)"
3. Marcar checkbox do Participante C
4. Verificar: Botão muda para "Confirmar (2)"
5. Desmarcar Participante C
6. Verificar: Botão volta para "Confirmar (1)"
7. Marcar novamente Participante C
```

#### 2.4 Confirmar Presença
```
1. Clicar em "Confirmar (2)"
2. Aguardar loading
3. Verificar se avançou para STEP 1 (ratings)
```

#### 2.5 Verificar no Firebase Console

**A. PendingReview Atualizado:**
```
Firebase Console > Firestore > PendingReviews > [PENDING_REVIEW_ID]

Campo esperado:
✅ presence_confirmed: true
```

**B. ConfirmedParticipants Criados:**
```
Firebase Console > Firestore > events > [EVENT_ID] > ConfirmedParticipants

Documentos esperados:
✅ [USER_B_ID]:
   - confirmedAt: Timestamp
   - confirmedBy: {ownerId}
   - presence: "Vou"
   - reviewed: false

✅ [USER_C_ID]:
   - confirmedAt: Timestamp
   - confirmedBy: {ownerId}
   - presence: "Vou"
   - reviewed: false
```

### Resultado Esperado
- ✅ Owner confirmou presença de 2 participantes
- ✅ PendingReview marcado como presence_confirmed=true
- ✅ Subcoleção ConfirmedParticipants criada com 2 documentos
- ✅ ReviewDialog avançou para STEP 1

---

## 🎯 TESTE 3: OWNER - AVALIAR PARTICIPANTES (STEPS 1-3)

### Objetivo
Verificar se owner consegue avaliar cada participante individualmente.

### Passos

#### 3.1 STEP 1 - Avaliar Participante B
```
1. Verificar: Está no STEP 1 (ratings)
2. Verificar: Avatar e nome do Participante B aparecem
3. Verificar: Contador "1 de 2"
4. Avaliar critérios:
   - Pontualidade: 5 estrelas
   - Comunicação: 4 estrelas
   - Simpatia: 5 estrelas
5. Clicar "Próximo"
```

#### 3.2 STEP 2 - Badges para Participante B
```
1. Verificar: Continua mostrando Participante B
2. Verificar: Contador "1 de 2"
3. Selecionar badges:
   - [x] Comunicativo
   - [x] Pontual
   - [ ] Divertido (não selecionado)
4. Clicar "Próximo"
```

#### 3.3 STEP 3 - Comentário para Participante B
```
1. Verificar: Continua mostrando Participante B
2. Verificar: Contador "1 de 2"
3. Escrever comentário:
   "Ótimo participante, super pontual e comunicativo!"
4. Clicar "Próximo Participante"
```

#### 3.4 Avaliar Participante C (STEPS 1-3)
```
Repetir passos 3.1-3.3 para Participante C, mas com notas DIFERENTES:
- Pontualidade: 3 estrelas
- Comunicação: 4 estrelas
- Simpatia: 4 estrelas
- Badges: [Divertido]
- Comentário: "Atrasou um pouco mas foi legal."
```

#### 3.5 Finalizar Avaliações
```
1. Após avaliar Participante C, clicar "Finalizar"
2. Aguardar loading (pode demorar - batch transaction)
3. Verificar: ReviewDialog fecha
4. Verificar: PendingReview desaparece da lista
```

#### 3.6 Verificar no Firebase Console

**A. Reviews Criados:**
```
Firebase Console > Firestore > Reviews

Documentos esperados:
✅ Review 1 (Owner → Participante B):
   - event_id: {eventId}
   - reviewer_id: {ownerId}
   - reviewee_id: {userId_B}
   - reviewer_role: "owner"
   - criteria_ratings: { punctuality: 5, communication: 4, friendliness: 5 }
   - badges: ["Comunicativo", "Pontual"]
   - comment: "Ótimo participante..."
   - created_at: Timestamp

✅ Review 2 (Owner → Participante C):
   - event_id: {eventId}
   - reviewer_id: {ownerId}
   - reviewee_id: {userId_C}
   - reviewer_role: "owner"
   - criteria_ratings: { punctuality: 3, communication: 4, friendliness: 4 }
   - badges: ["Divertido"]
   - comment: "Atrasou um pouco..."
   - created_at: Timestamp
```

**B. PendingReviews Criados para Participantes:**
```
Firebase Console > Firestore > PendingReviews

Documentos esperados:
✅ {eventId}_participant_{userId_B}:
   - pending_review_id: "{eventId}_participant_{userId_B}"
   - event_id: {eventId}
   - reviewer_id: {userId_B}
   - reviewee_id: {ownerId}
   - reviewer_role: "participant"
   - allowed_to_review_owner: true
   - reviewee_name: "Nome do Owner"
   - reviewee_photo_url: "url"
   - expires_at: Timestamp (+30 dias)
   - dismissed: false

✅ {eventId}_participant_{userId_C}:
   - (mesma estrutura)
```

**C. ConfirmedParticipants Atualizados:**
```
Firebase Console > Firestore > events > [EVENT_ID] > ConfirmedParticipants

Documentos atualizados:
✅ [USER_B_ID]:
   - reviewed: true ✅

✅ [USER_C_ID]:
   - reviewed: true ✅
```

**D. PendingReview do Owner Deletado:**
```
Firebase Console > Firestore > PendingReviews

Documento NÃO deve existir:
❌ {eventId}_owner_{ownerId} (deletado)
```

### Resultado Esperado
- ✅ 2 Reviews criados (owner → participantes)
- ✅ 2 PendingReviews criados (participantes → owner)
- ✅ ConfirmedParticipants marcados como reviewed=true
- ✅ PendingReview do owner deletado
- ✅ Cada participante recebeu notas DIFERENTES

---

## 🎯 TESTE 4: PARTICIPANTE - AVALIAR OWNER

### Objetivo
Verificar se participante consegue avaliar o owner após ser avaliado.

### Passos

#### 4.1 Abrir ReviewDialog (Participante B)
```
1. Login como usuário B (participante)
2. Ir para tela de PendingReviews
3. Verificar: Card do evento aparece
4. Clicar no card
5. ReviewDialog deve abrir no STEP 1 (sem STEP 0)
```

#### 4.2 Verificar Dados do Owner
```
Elementos esperados:
✅ Avatar e nome do Owner aparecem
✅ Progress bar: 3 steps (sem STEP 0)
✅ Título: "Avaliar [Nome do Owner]"
```

#### 4.3 Avaliar Owner (STEPS 1-3)
```
1. STEP 1 - Ratings:
   - Pontualidade: 5 estrelas
   - Organização: 5 estrelas
   - Comunicação: 4 estrelas

2. STEP 2 - Badges:
   - [x] Organizado
   - [x] Comunicativo

3. STEP 3 - Comentário:
   "Evento muito bem organizado, parabéns!"

4. Clicar "Enviar Avaliação"
5. Aguardar loading
6. Verificar: Dialog fecha
```

#### 4.4 Verificar no Firebase Console

**A. Review Criado:**
```
Firebase Console > Firestore > Reviews

Documento esperado:
✅ Review (Participante B → Owner):
   - event_id: {eventId}
   - reviewer_id: {userId_B}
   - reviewee_id: {ownerId}
   - reviewer_role: "participant"
   - criteria_ratings: { punctuality: 5, organization: 5, communication: 4 }
   - badges: ["Organizado", "Comunicativo"]
   - comment: "Evento muito bem organizado..."
   - created_at: Timestamp
```

**B. PendingReview Deletado:**
```
Firebase Console > Firestore > PendingReviews

Documento NÃO deve existir:
❌ {eventId}_participant_{userId_B} (deletado)
```

#### 4.5 Repetir para Participante C
```
1. Login como usuário C
2. Repetir passos 4.1-4.4 com notas DIFERENTES
```

### Resultado Esperado
- ✅ 2 Reviews criados (participantes → owner)
- ✅ 2 PendingReviews de participantes deletados
- ✅ Owner agora tem 2 avaliações de participantes

---

## 🎯 TESTE 5: IDEMPOTÊNCIA DA CLOUD FUNCTION

### Objetivo
Verificar que Cloud Function não reprocessa eventos já marcados.

### Passos

#### 5.1 Verificar Evento Atual
```
Firebase Console > Firestore > events > [EVENT_ID]

Verificar:
✅ pendingReviewsCreated: true
✅ pendingReviewsCreatedAt: Timestamp (anotar)
```

#### 5.2 Aguardar Próxima Execução
```
1. Aguardar 5 minutos (próxima execução da função)
2. Verificar logs da função no Firebase Console
```

#### 5.3 Verificar Logs
```
Logs esperados:
🔍 [PendingReviews] Buscando eventos finalizados...
📅 [PendingReviews] 0 eventos encontrados (ou evento de teste NÃO aparece)
✅ [PendingReviews] Nenhum evento para processar

OU (se eventos antigos aparecerem):
🔍 [PendingReviews] Buscando eventos finalizados...
📅 [PendingReviews] X eventos encontrados
🎯 [PendingReviews] Processando evento: {outroEventoId}
⏭️ Skipping - reviews already created (para nosso evento de teste)
```

#### 5.4 Verificar PendingReviews
```
Firebase Console > Firestore > PendingReviews

Verificar que NÃO existe:
❌ {eventId}_owner_{ownerId} (não deve ser recriado)
```

### Resultado Esperado
- ✅ Evento de teste NÃO é reprocessado
- ✅ PendingReview do owner NÃO é recriado
- ✅ Flag pendingReviewsCreated impede duplicação

---

## 🎯 TESTE 6: EVENTO SEM PARTICIPANTES "VOU"

### Objetivo
Verificar que Cloud Function marca evento como processado mesmo sem criar PendingReview.

### Passos

#### 6.1 Criar Evento Sem Participantes
```
1. Login como usuário E (novo owner)
2. Criar evento que termina em 2 minutos
3. NÃO adicionar participantes OU
4. Adicionar participantes mas todos marcam "Talvez"
5. Aguardar evento terminar + 7 minutos
```

#### 6.2 Verificar no Firebase Console

**A. Evento Marcado:**
```
Firebase Console > Firestore > events > [EVENT_ID_2]

Campos esperados:
✅ pendingReviewsCreated: true
✅ pendingReviewsCreatedAt: Timestamp
```

**B. PendingReview NÃO Criado:**
```
Firebase Console > Firestore > PendingReviews

Documento NÃO deve existir:
❌ {eventId2}_owner_{ownerId2} (não criado - sem participantes)
```

**C. Logs:**
```
Logs esperados:
🎯 [PendingReviews] Processando evento: {eventId2}
👥 [PendingReviews] 0 participantes "Vou"
✅ [PendingReviews] Evento {eventId2} sem participantes - marcado como processado
```

### Resultado Esperado
- ✅ Evento marcado como processado
- ✅ PendingReview NÃO criado (correto - sem participantes)
- ✅ Sistema não trava ou gera erro

---

## 📊 CHECKLIST FINAL

### Cloud Function
- [ ] Função executa a cada 5 minutos
- [ ] Busca eventos terminados há 5-10 minutos
- [ ] Filtra apenas participantes com presence="Vou"
- [ ] Carrega perfis dos participantes corretamente
- [ ] Cria PendingReview para owner com dados completos
- [ ] Marca evento como processado
- [ ] Não reprocessa eventos já marcados
- [ ] Lida corretamente com eventos sem participantes

### Frontend - Owner
- [ ] PendingReview aparece na lista
- [ ] STEP 0 (confirmação de presença) renderiza corretamente
- [ ] Checkboxes funcionam
- [ ] Confirmação salva dados no Firestore
- [ ] ConfirmedParticipants são criados
- [ ] STEP 1-3 avaliam cada participante individualmente
- [ ] Ratings diferentes são salvos para cada participante
- [ ] PendingReviews são criados para participantes
- [ ] Reviews são salvos corretamente
- [ ] PendingReview do owner é deletado ao finalizar

### Frontend - Participante
- [ ] PendingReview aparece na lista após ser avaliado
- [ ] ReviewDialog abre sem STEP 0
- [ ] STEP 1-3 avaliam o owner
- [ ] Review é salvo corretamente
- [ ] PendingReview é deletado ao finalizar
- [ ] Participante sem permissão não vê dialog bloqueado (não deve existir PendingReview)

### Database
- [ ] events.pendingReviewsCreated funciona corretamente
- [ ] ConfirmedParticipants subcoleção é criada
- [ ] Reviews são salvos com campos corretos
- [ ] PendingReviews são criados e deletados corretamente
- [ ] Índices compostos estão funcionando

---

## 🐛 PROBLEMAS CONHECIDOS E SOLUÇÕES

### Problema 1: Cloud Function não dispara
**Sintomas:** Evento terminou há 10+ minutos mas PendingReview não foi criado  
**Verificar:**
1. Logs da função no Firebase Console
2. Se `pendingReviewsCreated != true` na query
3. Se índice composto está ativo (pode levar alguns minutos)

**Solução:** Aguardar criação de índice ou executar função manualmente

### Problema 2: Participante "Talvez" foi incluído
**Sintomas:** Participante com presence="Talvez" aparece no STEP 0  
**Causa:** Query da Cloud Function não filtra corretamente  
**Solução:** Revisar `where("presence", "==", "Vou")` na função

### Problema 3: ReviewDialog não avança do STEP 0
**Sintomas:** Clicar "Confirmar" não faz nada  
**Verificar:**
1. Console do Flutter para erros
2. Se pelo menos 1 participante foi selecionado
3. Se método `confirmPresenceAndProceed` está sendo chamado

**Solução:** Verificar logs e estado do controller

### Problema 4: Ratings iguais para todos participantes
**Sintomas:** Todos participantes recebem mesma nota  
**Causa:** `ratingsPerParticipant` não está sendo usado corretamente  
**Solução:** Verificar implementação do controller

---

## 📝 NOTAS FINAIS

- **Tempo estimado:** 2-3 horas para executar todos os testes
- **Recomendação:** Executar em ordem (1 → 6)
- **Ambiente:** Usar ambiente de desenvolvimento/staging primeiro
- **Logs:** Manter Firebase Console aberto durante todos os testes
- **Backup:** Fazer snapshot do Firestore antes de começar

---

## ✅ CRITÉRIOS DE SUCESSO

O sistema estará **PRONTO PARA PRODUÇÃO** se:

1. ✅ Todos os testes (1-6) passarem
2. ✅ Nenhum erro no console Flutter
3. ✅ Nenhum erro nos logs Cloud Functions
4. ✅ Dados corretos salvos no Firestore
5. ✅ UX fluida e intuitiva
6. ✅ Performance adequada (< 3s para transições)

---

**Próximo passo:** Executar estes testes e documentar resultados em novo arquivo `TESTE_REVIEWS_RESULTADOS.md`
