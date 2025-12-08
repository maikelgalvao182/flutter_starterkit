# 🚫 Sistema de Bloqueio - Guia de Implementação

## ✅ O que foi implementado

### 1. **BlockService** (`lib/core/services/block_service.dart`)
Serviço profissional e escalável para gerenciar bloqueios.

**Métodos disponíveis:**
- `blockUser(blockerId, targetId)` - Bloqueia um usuário
- `unblockUser(blockerId, targetId)` - Desbloqueia um usuário
- `isBlocked(uid1, uid2)` - Verifica bloqueio bilateral
- `hasBlocked(blockerId, targetId)` - Verifica bloqueio unilateral
- `getBlockedUsers(blockerId)` - Lista usuários bloqueados
- `watchBlockedUsers(blockerId)` - Stream em tempo real

### 2. **ReportDialog Otimizado**
- ✅ Segue todas as regras do guia de boas práticas
- ✅ Widgets quebrados em componentes menores
- ✅ Uso de `const` onde possível
- ✅ Sem lógica no `build()`
- ✅ Estrutura limpa e performática
- ✅ Integrado com BlockService

### 3. **Estrutura Firestore**
```
/blockedUsers/{blockerId}_{targetId}
  - blockerId: string
  - targetId: string
  - createdAt: timestamp
```

---

## 📋 Próximos Passos

### 1. **Configurar Firestore**

#### a) Adicionar regras de segurança
Edite `firestore.rules`:

```javascript
match /blockedUsers/{blockId} {
  allow read: if request.auth != null && (
    resource.data.blockerId == request.auth.uid ||
    resource.data.targetId == request.auth.uid
  );
  
  allow create, update: if request.auth != null &&
    request.resource.data.blockerId == request.auth.uid;
  
  allow delete: if request.auth != null &&
    resource.data.blockerId == request.auth.uid;
}
```

Deploy:
```bash
firebase deploy --only firestore:rules
```

#### b) Criar índice composto
Firebase Console > Firestore > Indexes

```
Collection: blockedUsers
Fields:
  - blockerId (Ascending)
  - targetId (Ascending)
```

---

### 2. **Integrar em todas as telas**

#### **Discover/Map (Filtrar usuários bloqueados)**

```dart
// No repository de descoberta
Future<List<User>> getUsers() async {
  final users = await _fetchUsers();
  final currentUserId = AppState.currentUserId!;
  
  // Filtrar usuários bloqueados
  final filtered = <User>[];
  for (final user in users) {
    final blocked = await BlockService().isBlocked(currentUserId, user.userId);
    if (!blocked) {
      filtered.add(user);
    }
  }
  
  return filtered;
}
```

#### **Perfil (Verificar antes de abrir)**

```dart
Future<void> openProfile(String userId) async {
  final currentUserId = AppState.currentUserId!;
  final blocked = await BlockService().isBlocked(currentUserId, userId);
  
  if (blocked) {
    // Mostrar mensagem ou simplesmente não abrir
    return;
  }
  
  // Abrir perfil normalmente
  context.push(AppRoutes.profile, extra: {...});
}
```

#### **Chat (Bloquear acesso)**

```dart
Future<void> openChat(String userId) async {
  final currentUserId = AppState.currentUserId!;
  final blocked = await BlockService().isBlocked(currentUserId, userId);
  
  if (blocked) {
    ToastService.showWarning(
      context: context,
      title: i18n.translate('user_blocked'),
      subtitle: i18n.translate('cannot_message_blocked_user'),
    );
    return;
  }
  
  // Abrir chat normalmente
}
```

#### **Eventos (Filtrar participantes e aplicações)**

```dart
// Ao listar participantes
Future<List<User>> getParticipants(String eventId) async {
  final participants = await _fetchParticipants(eventId);
  final currentUserId = AppState.currentUserId!;
  
  final filtered = <User>[];
  for (final user in participants) {
    final blocked = await BlockService().isBlocked(currentUserId, user.userId);
    if (!blocked) {
      filtered.add(user);
    }
  }
  
  return filtered;
}

// Ao processar aplicação
Future<bool> canApplyToEvent(String eventId, String organizerId) async {
  final currentUserId = AppState.currentUserId!;
  final blocked = await BlockService().isBlocked(currentUserId, organizerId);
  
  return !blocked;
}
```

#### **Notificações (Filtrar notificações de bloqueados)**

```dart
Stream<List<Notification>> watchNotifications(String userId) {
  return _db
      .collection('notifications')
      .where('targetUserId', isEqualTo: userId)
      .snapshots()
      .asyncMap((snapshot) async {
        final notifications = <Notification>[];
        
        for (final doc in snapshot.docs) {
          final notification = Notification.fromFirestore(doc);
          final blocked = await BlockService().isBlocked(
            userId,
            notification.senderId,
          );
          
          if (!blocked) {
            notifications.add(notification);
          }
        }
        
        return notifications;
      });
}
```

---

### 3. **Adicionar traduções**

Já foram adicionadas nos 3 idiomas:
- ✅ `help_us_keep_community_safe`
- ✅ `report_dialog_description`
- ✅ `Block`
- ✅ `report`

**Adicionar mensagens de feedback:**

`pt.json`:
```json
"user_blocked_successfully": "Usuário bloqueado com sucesso",
"cannot_message_blocked_user": "Não é possível enviar mensagem para este usuário",
"user_unblocked_successfully": "Usuário desbloqueado com sucesso"
```

---

### 4. **Tela de Usuários Bloqueados** (Opcional)

```dart
class BlockedUsersScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final currentUserId = AppState.currentUserId!;
    
    return StreamBuilder<List<String>>(
      stream: BlockService().watchBlockedUsers(currentUserId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }
        
        final blockedIds = snapshot.data!;
        
        return ListView.builder(
          itemCount: blockedIds.length,
          itemBuilder: (context, index) {
            return BlockedUserTile(
              userId: blockedIds[index],
              onUnblock: () async {
                await BlockService().unblockUser(
                  currentUserId,
                  blockedIds[index],
                );
              },
            );
          },
        );
      },
    );
  }
}
```

---

## ⚡ Performance e Escalabilidade

### ✅ Vantagens do sistema

1. **Leve**: Apenas 3 campos por documento
2. **Rápido**: Índice composto otimizado
3. **Escalável**: Suporta milhões de documentos
4. **Simples**: Uma query para verificar bloqueio bilateral
5. **Econômico**: 1 leitura por verificação (com cache)

### 📊 Métricas esperadas

- Leitura: ~10-50ms
- Escrita: ~50-100ms
- Custo: ~$0.06 por 100k leituras
- Limite: Sem limite prático

---

## 🎯 Checklist de Implementação

- [x] BlockService criado
- [x] ReportDialog otimizado
- [x] Traduções adicionadas
- [ ] Regras Firestore configuradas
- [ ] Índice composto criado
- [ ] Integração em Discover/Map
- [ ] Integração em Perfil
- [ ] Integração em Chat
- [ ] Integração em Eventos
- [ ] Integração em Notificações
- [ ] Tela de usuários bloqueados (opcional)
- [ ] Testes E2E

---

## 🔥 Resultado Final

Quando implementado completamente:

✅ Usuário bloqueado **some** de:
- Lista de descoberta
- Mapa
- Buscas
- Eventos
- Chat
- Notificações

✅ Usuário bloqueado **não consegue**:
- Ver seu perfil
- Te mandar mensagem
- Te aplicar em eventos
- Te ver em listas

✅ Sistema **escalável** para milhões de usuários
✅ Performance **profissional** como Instagram/Tinder
