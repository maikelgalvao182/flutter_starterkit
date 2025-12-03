# ✅ Checklist de Implementação - Chat de Eventos Multiusuários

## Status Geral: ✅ Implementação Base Completa

---

## 🔧 Backend (Cloud Functions)

### ✅ onEventCreated
- [x] Criar application do criador com `status: autoApproved`
- [x] Criar `EventChats/{eventId}` com dados iniciais
- [x] Adicionar criador como primeiro participante
- [x] Buscar dados do criador (fullName, photoUrl) do Firestore
- [x] Usar batch write para atomicidade

### ✅ onApplicationApproved  
- [x] Detectar mudança de status para `approved` ou `autoApproved`
- [x] Adicionar usuário ao array `participantIds`
- [x] Criar documento em `Participants/{userId}`
- [x] Criar mensagem automática de boas-vindas
- [x] Atualizar `lastMessage` do chat
- [x] Enviar push notification para outros participantes
- [x] Filtrar participantes para não notificar quem acabou de entrar

### 📝 Próximos Passos (Opcionais)
- [ ] `onApplicationRejected` - remover participante se aplicação for rejeitada
- [ ] `onEventDeleted` - deletar chat quando evento for deletado
- [ ] `onEventUpdated` - enviar mensagem no chat quando evento for editado

---

## 📱 Frontend (Flutter)

### ✅ EventChatRepository
- [x] `getEventChat()` - buscar dados do chat
- [x] `getEventMessages()` - stream de mensagens
- [x] `getEventChatStream()` - stream do chat principal
- [x] `sendMessage()` - enviar mensagem de texto
- [x] `markAsRead()` - marcar mensagens como lidas
- [x] `getParticipants()` - buscar participantes
- [x] `getParticipantsStream()` - stream de participantes
- [x] `isParticipant()` - verificar se usuário é participante
- [x] `getUnreadCount()` - buscar contagem de não lidas
- [x] `getUnreadCountStream()` - stream de contagem de não lidas
- [x] Usar `AppLogger` para logging
- [x] Tratamento de erros com try/catch

### ✅ EventChatScreen
- [x] AppBar com nome do evento e botão de info
- [x] Lista de mensagens com scroll reverso
- [x] Stream de mensagens do Firestore
- [x] Input de mensagem com TextField
- [x] Botão de envio com loading
- [x] Marcar como lido ao abrir chat
- [x] Widget `_MessageBubble` para mensagens
- [x] Suporte a mensagens do sistema (type: "system")
- [x] Formatação de timestamp
- [x] Avatar dos senders
- [x] Modal de participantes (`_ParticipantsSheet`)
- [x] Tratamento de erros com SnackBar

### ✅ EventCardController
- [x] Atualizar `buttonText` de "Entrar no chat" → "Ver chat do grupo"
- [x] Manter texto "Participar" para eventos não aplicados

### ✅ Integração no EventCard
- [x] Atualizar navegação no `onActionPressed`
- [x] Buscar nome do evento antes de navegar
- [x] Navegar para `EventChatScreen` quando aprovado
- [x] Adicionar imports necessários (EventChatScreen, Firestore)

### 📝 Melhorias Futuras (Opcionais)
- [ ] Badge de unread count no EventCard
- [ ] Suporte a imagens nas mensagens
- [ ] Suporte a localização nas mensagens
- [ ] Reactions nas mensagens
- [ ] Replies/threads
- [ ] Typing indicators
- [ ] Mensagens temporárias (deletar após X dias)
- [ ] Busca de mensagens
- [ ] Exportar conversa

---

## 🔒 Firestore Security Rules

### ✅ EventChats Collection
- [x] Read: apenas participantes aprovados
- [x] Write: apenas Cloud Functions

### ✅ EventChats/{eventId}/Messages
- [x] Read: apenas participantes
- [x] Create: apenas participantes (senderId deve ser o próprio uid)
- [x] Update/Delete: bloqueado

### ✅ EventChats/{eventId}/Participants
- [x] Read: apenas participantes
- [x] Update: apenas o próprio documento (lastReadAt, unreadCount)
- [x] Create/Delete: apenas Cloud Functions

---

## 🚀 Deploy

### ✅ Cloud Functions
- [x] Arquivo `functions/src/index.ts` atualizado
- [x] README com instruções de deploy criado
- [ ] Build das functions: `cd functions && npm run build`
- [ ] Deploy: `firebase deploy --only functions`
- [ ] Verificar logs: `firebase functions:log`

### ✅ Firestore Rules
- [x] Arquivo `firestore.rules` atualizado
- [ ] Deploy: `firebase deploy --only firestore:rules`
- [ ] Testar rules no Rules Playground

### 📝 Configurações Adicionais
- [ ] Configurar índices compostos (se necessário)
- [ ] Configurar FCM tokens para push notifications
- [ ] Testar notificações em dispositivos reais

---

## 🧪 Testes Necessários

### Backend
- [ ] Criar evento → verificar se EventChat foi criado
- [ ] Criar evento → verificar se criador foi adicionado como participante
- [ ] Aplicação aprovada → verificar se usuário foi adicionado ao chat
- [ ] Aplicação aprovada → verificar mensagem de boas-vindas
- [ ] Aplicação aprovada → verificar notificação push
- [ ] Evento com privacyType "open" → autoApproved + chat automático
- [ ] Evento com privacyType "private" → pending + chat após aprovação

### Frontend
- [ ] Abrir chat do evento
- [ ] Enviar mensagem de texto
- [ ] Ver mensagens de outros participantes
- [ ] Ver mensagem de sistema (entrada de novo participante)
- [ ] Marcar mensagens como lidas
- [ ] Ver lista de participantes
- [ ] Badge de criador (👑) nos participantes
- [ ] Contagem de mensagens não lidas
- [ ] Scroll automático para mensagens mais recentes
- [ ] Tratamento de erro quando offline

### Integração
- [ ] Criar evento → aplicar → chat disponível
- [ ] Botão muda de "Participar" → "Ver chat do grupo"
- [ ] Criador vê "Ver participantes" (futuro)
- [ ] Notificação leva para o chat correto
- [ ] Multiple usuarios no mesmo chat
- [ ] Sincronização em tempo real

---

## 📊 Estrutura Firestore Implementada

```
EventChats/{eventId}
  ├─ eventId: string
  ├─ createdBy: string
  ├─ createdAt: timestamp
  ├─ lastMessage: string
  ├─ lastMessageAt: timestamp
  ├─ lastMessageSenderId: string
  ├─ participantIds: array<string>
  └─ participantCount: number

EventChats/{eventId}/Messages/{messageId}
  ├─ senderId: string
  ├─ senderName: string
  ├─ senderPhotoUrl: string
  ├─ message: string
  ├─ messageType: "text" | "image" | "system"
  ├─ timestamp: timestamp
  └─ readBy: array<string>

EventChats/{eventId}/Participants/{userId}
  ├─ userId: string
  ├─ fullName: string
  ├─ photoUrl: string
  ├─ joinedAt: timestamp
  ├─ lastReadAt: timestamp
  └─ unreadCount: number
```

---

## 🎯 Fluxo Completo Implementado

### 1. Criação do Evento
```
User cria evento
  ↓
Cloud Function: onEventCreated
  ↓
✅ Cria EventApplications (status: autoApproved)
✅ Cria EventChats/{eventId}
✅ Cria EventChats/{eventId}/Participants/{creatorId}
```

### 2. Aplicação de Novo Usuário
```
User aplica ao evento
  ↓
EventApplicationRepository.createApplication()
  ↓
Status: "open" → autoApproved | "private" → pending
  ↓
Cloud Function: onApplicationApproved
  ↓
✅ Adiciona ao participantIds
✅ Cria Participants/{userId}
✅ Mensagem: "{Nome} entrou no grupo! 🎉"
✅ Push notification para outros
```

### 3. Acesso ao Chat
```
User clica "Ver chat do grupo"
  ↓
EventCard.onActionPressed()
  ↓
Navigator.push → EventChatScreen
  ↓
✅ Stream de mensagens
✅ Input para enviar mensagens
✅ Lista de participantes
```

---

## 📝 Arquivos Criados/Modificados

### Criados
- ✅ `/functions/src/index.ts` (atualizado com 2 novas functions)
- ✅ `/lib/features/home/data/repositories/event_chat_repository.dart`
- ✅ `/lib/features/home/presentation/screens/event_chat_screen.dart`
- ✅ `/functions/README.md`
- ✅ `/CHAT_EVENTS_IMPLEMENTATION_CHECKLIST.md` (este arquivo)

### Modificados
- ✅ `/firestore.rules` (adicionadas rules para EventChats)
- ✅ `/lib/features/home/presentation/widgets/event_card/event_card_controller.dart`
- ✅ `/lib/features/home/presentation/widgets/apple_map_view.dart`

---

## 🚦 Próximos Passos Recomendados

1. **Deploy das Cloud Functions:**
   ```bash
   cd functions
   npm install
   npm run build
   firebase deploy --only functions
   ```

2. **Deploy das Firestore Rules:**
   ```bash
   firebase deploy --only firestore:rules
   ```

3. **Testar fluxo completo:**
   - Criar evento
   - Aplicar com outro usuário
   - Verificar se chat foi criado
   - Enviar mensagens
   - Verificar notificações

4. **Monitorar logs:**
   ```bash
   firebase functions:log --follow
   ```

5. **Ajustes finos:**
   - Testar com múltiplos participantes
   - Verificar performance com muitas mensagens
   - Ajustar UI conforme feedback

---

**Data de Implementação:** 3 de dezembro de 2025  
**Status:** ✅ Implementação Base Completa - Pronto para Deploy e Testes
