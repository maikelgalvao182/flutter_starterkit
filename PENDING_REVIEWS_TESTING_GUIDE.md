# 🧪 GUIA DE TESTE - PENDING REVIEWS

## 📝 PRÉ-REQUISITOS

1. ✅ Índices deployados no Firestore
2. ✅ App compilado sem erros
3. ✅ Listener integrado no HomeScreenRefactored

---

## 🧪 CENÁRIO DE TESTE 1: Review de Participante pelo Owner

### **Passo 1: Criar Evento**
1. Login como **Owner** (criador de eventos)
2. Criar um evento qualquer
3. Anotar o `eventId`

### **Passo 2: Aplicar como Participante**
1. Logout
2. Login como **Participante**
3. Candidatar-se ao evento

### **Passo 3: Aceitar Aplicação**
1. Logout
2. Login como **Owner** novamente
3. Ir para o evento
4. Aceitar a aplicação do participante

### **Passo 4: Verificar PendingReview no Firestore**
1. Ir ao Firestore Console
2. Navegar para coleção `PendingReviews`
3. Verificar se foi criado um documento com:
   - `reviewer_id` = ID do Owner
   - `reviewee_id` = ID do Participante
   - `dismissed` = false
   - `event_id` = ID do evento

### **Passo 5: Testar Listener (Owner avalia Participante)**
1. Com app aberto como **Owner**
2. Verificar logs no terminal:
   ```
   [PendingReviewsListener] 🎯 Iniciando listener para userId: xxx
   [PendingReviewsListener] ✅ Listener configurado...
   [PendingReviewsListener] 📸 Snapshot recebido! Documentos: 1
   [PendingReviewsListener] 🔔 Inicialização: 1 reviews existentes detectados!
   [PendingReviewsChecker] 🔍 Verificando pending reviews...
   [PendingReviewsChecker] 📋 Encontrado(s) 1 review(s) pendente(s)
   [PendingReviewsChecker] 🎯 Exibindo dialog para avaliar [Nome do Participante]
   ```

3. **ReviewDialog deve aparecer automaticamente** com:
   - Nome do participante
   - Foto do participante
   - Título do evento
   - Critérios de avaliação

### **Passo 6: Submeter Review**
1. Avaliar critérios (1-5 estrelas)
2. Selecionar badges (opcional)
3. Adicionar comentário (opcional)
4. Clicar em "Enviar Avaliação"

### **Passo 7: Verificar Resultado**
1. Dialog fecha automaticamente
2. SnackBar aparece: "✅ Avaliação enviada com sucesso!"
3. No Firestore:
   - PendingReview foi **deletado**
   - Review foi criado na coleção `Reviews`
   - ReviewStats do participante foi atualizado

---

## 🧪 CENÁRIO DE TESTE 2: Review de Owner pelo Participante

### **Passo 1: Mesmo Evento**
Use o evento criado no teste anterior

### **Passo 2: Verificar PendingReview no Firestore**
1. Ir ao Firestore Console
2. Coleção `PendingReviews`
3. Deve existir documento com:
   - `reviewer_id` = ID do Participante
   - `reviewee_id` = ID do Owner
   - `dismissed` = false

### **Passo 3: Testar Listener (Participante avalia Owner)**
1. Login como **Participante**
2. ReviewDialog deve aparecer automaticamente
3. Avaliar o owner
4. Submeter review

---

## 🧪 CENÁRIO DE TESTE 3: Listener em Tempo Real

### **Teste Criar Review Novo**
1. Com app aberto como **Owner**
2. Via Firestore Console, criar novo documento em `PendingReviews`:
   ```json
   {
     "reviewer_id": "ID_DO_OWNER",
     "reviewee_id": "ID_QUALQUER",
     "event_id": "EVENT_ID",
     "event_title": "Teste Manual",
     "event_emoji": "🎉",
     "event_date": Timestamp (futuro),
     "reviewee_name": "Teste User",
     "reviewer_role": "owner",
     "created_at": Timestamp.now(),
     "expires_at": Timestamp (30 dias depois),
     "dismissed": false
   }
   ```

3. **Resultado esperado:**
   - Logs mostram novo documento detectado
   - ReviewDialog aparece automaticamente
   - Sem necessidade de recarregar app

---

## 🧪 CENÁRIO DE TESTE 4: Dismiss Review

### **Passo 1: Abrir Review**
1. Login com usuário que tem pending review
2. ReviewDialog aparece

### **Passo 2: Dismiss**
1. Clicar em "X" (fechar) ou "Não avaliar"
2. Confirmar dismiss

### **Passo 3: Verificar Resultado**
1. No Firestore:
   - PendingReview tem `dismissed: true`
   - `dismissed_at` foi preenchido
2. Logs mostram:
   ```
   [PendingReviewsListener] 🗑️ Pending review removido do cache: xxx
   ```

---

## 📊 LOGS IMPORTANTES

### **Inicialização Correta**
```
[PendingReviewsListener] 🎯 Iniciando listener para userId: abc123
[PendingReviewsListener] ✅ Listener configurado e aguardando snapshots...
[PendingReviewsListener] 📸 Snapshot recebido! Documentos: 2
[PendingReviewsListener] 🔔 Inicialização: 2 reviews existentes detectados!
```

### **Novo Review Detectado**
```
[PendingReviewsListener] 📸 Snapshot recebido! Documentos: 3
[PendingReviewsListener] 🔔 1 novos pending reviews detectados!
[PendingReviewsChecker] 🔍 Verificando pending reviews...
```

### **Review Submetido**
```
[PendingReviewsChecker] ✅ Review enviado com sucesso
[PendingReviewsListener] 🗑️ Pending review removido do cache: xxx
```

---

## ❌ PROBLEMAS COMUNS

### **Dialog não aparece**

**Causa 1: Índice não foi deployado**
```bash
firebase deploy --only firestore:indexes
```

**Causa 2: PendingReview já expirou**
- Verificar se `expires_at` é futuro
- Verificar se `dismissed` é false

**Causa 3: Listener não iniciou**
- Verificar logs: deve ter "[PendingReviewsListener] 🎯 Iniciando listener"
- Se não tem, o HomeScreenRefactored não está chamando startListening()

### **Erro: "The query requires an index"**

**Solução:**
```bash
cd /Users/maikelgalvao/partiu
firebase deploy --only firestore:indexes
```

Aguardar alguns minutos para o índice ser criado no Firebase.

### **Dialog aparece múltiplas vezes**

**Causa:** Rate limiting não está funcionando

**Solução:** Verificar se `_lastCheckTime` está sendo respeitado no PendingReviewsCheckerService

---

## ✅ CHECKLIST DE VALIDAÇÃO

- [ ] Listener inicia corretamente no login
- [ ] Snapshot recebe documentos do Firestore
- [ ] ReviewDialog aparece automaticamente
- [ ] Critérios de avaliação são exibidos
- [ ] Badges são exibidos
- [ ] Campo de comentário funciona
- [ ] Submissão cria Review no Firestore
- [ ] PendingReview é deletado após submissão
- [ ] ReviewStats é atualizado
- [ ] Dismiss marca como dismissed
- [ ] Listener detecta novos reviews em tempo real
- [ ] Logs estão corretos e claros
- [ ] Não há erros no console

---

## 🎯 CRITÉRIOS DE SUCESSO

1. ✅ Dialog aparece **automaticamente** quando há pending review
2. ✅ Listener detecta **novos reviews em tempo real**
3. ✅ Review é salvo corretamente no Firestore
4. ✅ PendingReview é **deletado** após submissão
5. ✅ Dismiss funciona corretamente
6. ✅ Não há crashes ou erros
7. ✅ Performance é boa (< 2s para exibir dialog)

---

**📝 NOTAS:**
- Testar com **dados reais** e não mockados
- Verificar logs no terminal durante os testes
- Se algo falhar, verificar o Firestore Console para debug
- Testar fluxo completo: criar evento → aceitar → avaliar → verificar resultado
