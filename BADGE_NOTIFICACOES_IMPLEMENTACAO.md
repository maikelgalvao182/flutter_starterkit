# 📛 Implementação do Badge de Notificações

## 📋 Visão Geral

O sistema de badge de notificações no `home_app_bar.dart` foi implementado seguindo o padrão **Advanced-Dating**, utilizando `ValueNotifier` e `AppState` para gerenciamento reativo de estado.

---

## 🏗️ Arquitetura

### Componentes Principais

```
┌─────────────────────────────────────────┐
│        home_app_bar.dart                │
│  ┌───────────────────────────────┐     │
│  │   AutoUpdatingBadge           │     │
│  │   (ValueListenableBuilder)    │     │
│  └───────────────┬───────────────┘     │
└──────────────────┼─────────────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │     AppState         │
        │ unreadNotifications  │
        │   (ValueNotifier)    │
        └──────────┬───────────┘
                   │
                   ▼
    ┌──────────────────────────────────┐
    │ NotificationsCounterService      │
    │  - Listener do Firestore         │
    │  - Query de notificações n_read  │
    └──────────────────────────────────┘
```

---

## 📦 Detalhes de Implementação

### 1. **AutoUpdatingBadge Widget**

**Localização:** `lib/features/home/presentation/widgets/auto_updating_badge.dart`

Este widget é responsável por exibir o badge visual de notificações não lidas.

#### Características:

- ✅ **Reativo:** Usa `ValueListenableBuilder` para reagir a mudanças
- ✅ **Flexível:** Pode usar `AppState.unreadNotifications` (padrão) ou um contador customizado
- ✅ **Otimizado:** Usa `RepaintBoundary` para performance
- ✅ **Visual Adaptável:** Suporta customização de cores, tamanhos e padding

#### Código Principal:

```dart
class AutoUpdatingBadge extends StatelessWidget {
  const AutoUpdatingBadge({
    required this.child,
    super.key,
    this.count,  // Opcional - usa AppState se null
    this.badgeColor = Colors.red,
    this.textColor = Colors.white,
    this.fontSize = 10,
    this.minBadgeSize = 16.0,
    this.badgePadding = const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
  });

  @override
  Widget build(BuildContext context) {
    // Se count foi passado explicitamente, usar o valor
    if (count != null) {
      return _buildBadge(count!);
    }
    
    // Caso contrário, usar AppState.unreadNotifications (padrão Advanced-Dating)
    return ValueListenableBuilder<int>(
      valueListenable: AppState.unreadNotifications,
      child: child,
      builder: (context, notificationCount, childWidget) {
        return _buildBadge(notificationCount, childWidget: childWidget);
      },
    );
  }
}
```

#### Lógica do Badge:

1. **Prioridade de Fonte de Dados:**
   - Se `count` for passado → usa o valor explícito
   - Se `count` for `null` → usa `AppState.unreadNotifications`

2. **Renderização Condicional:**
   - Badge só é exibido se `badgeCount > 0`
   - Valores acima de 99 são exibidos como "99+"

3. **Otimizações:**
   - `RepaintBoundary` evita repaint desnecessário
   - `IgnorePointer` no badge evita interceptar gestos
   - Reutilização do `child` widget via parâmetro do builder

---

### 2. **AppState**

**Localização:** `lib/common/state/app_state.dart`

Gerencia o estado global reativo da aplicação usando `ValueNotifier`.

#### Contador de Notificações:

```dart
class AppState {
  // ==================== COUNTERS ====================
  static final unreadNotifications = ValueNotifier<int>(0);
  static final unreadMessages = ValueNotifier<int>(0);
  static final unreadLikes = ValueNotifier<int>(0);
  
  // Getter de conveniência
  static int get totalUnread =>
      unreadNotifications.value + unreadMessages.value + unreadLikes.value;
}
```

#### Características:

- ✅ **Singleton:** Acesso estático em toda a aplicação
- ✅ **Reativo:** Usa `ValueNotifier` nativo do Flutter
- ✅ **Simples:** Sem dependências externas (Provider, Riverpod, etc.)
- ✅ **Reset Seguro:** Método `reset()` limpa todos os contadores

---

### 3. **NotificationsCounterService**

**Localização:** `lib/common/services/notifications_counter_service.dart`

Serviço centralizado que escuta o Firestore e atualiza os contadores.

#### Responsabilidades:

1. 📊 Contar notificações não lidas (ícone de notificações)
2. 💬 Contar conversas não lidas (aba Conversations)
3. ⚡ Contar ações pendentes (aba Actions)

#### Implementação do Listener de Notificações:

```dart
void _listenToUnreadNotifications() {
  final currentUserId = AppState.currentUserId;
  
  if (currentUserId == null) {
    debugPrint('⚠️ [NotificationsCounter] Usuário não autenticado');
    return;
  }

  _firestore
      .collection('Notifications')
      .where('n_receiver_id', isEqualTo: currentUserId)  // Campo correto!
      .where('n_read', isEqualTo: false)  // Filtrar apenas não lidas
      .snapshots()
      .listen(
    (snapshot) {
      final count = snapshot.docs.length;
      
      // Atualizar AppState diretamente (padrão Advanced-Dating)
      AppState.unreadNotifications.value = count;
      unreadNotificationsCount.value = count;
      
      debugPrint('📊 [NotificationsCounter] ✅ Notificações não lidas: $count');
    },
    onError: (error) {
      debugPrint('❌ [NotificationsCounter] Erro: $error');
      AppState.unreadNotifications.value = 0;
    },
  );
}
```

#### Query do Firestore:

```
Collection: Notifications
├── where('n_receiver_id', isEqualTo: currentUserId)
└── where('n_read', isEqualTo: false)
```

#### Inicialização:

O serviço é inicializado automaticamente quando o usuário faz login via `AuthSyncService`:

```dart
// lib/core/services/auth_sync_service.dart
Future<void> _handleAuthStateChange(fire_auth.User? user) async {
  if (user != null) {
    // Carregar dados do usuário...
    
    // Inicializar contadores de notificações
    NotificationsCounterService.instance.initialize();
  } else {
    // Limpar contadores no logout
    NotificationsCounterService.instance.reset();
  }
}
```

---

### 4. **HomeAppBar Integration**

**Localização:** `lib/features/home/presentation/widgets/home_app_bar.dart`

Integração do badge no ícone de notificações.

#### Código:

```dart
actions: [
  Padding(
    padding: const EdgeInsets.only(right: GlimpseStyles.horizontalMargin),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Botão de notificações com badge automático
        AutoUpdatingBadge(
          fontSize: 9,
          minBadgeSize: 14.0,
          badgePadding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
          badgeColor: GlimpseColors.actionColor,
          child: SizedBox(
            width: 28,
            child: IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: const Icon(
                IconsaxPlusLinear.notification,
                size: 24,
                color: GlimpseColors.textSubTitle,
              ),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.push(AppRoutes.notifications);
              },
            ),
          ),
        ),
      ],
    ),
  ),
],
```

#### Características:

- ✅ **Sem Parâmetro `count`:** Usa `AppState.unreadNotifications` automaticamente
- ✅ **Feedback Tátil:** `HapticFeedback.lightImpact()` ao tocar
- ✅ **Navegação:** Redireciona para `/notifications`
- ✅ **Estilo Consistente:** Tamanhos e cores padronizados

---

## 🔄 Fluxo de Dados

### Fluxo Completo:

```
1. Usuário faz login
   ↓
2. AuthSyncService detecta autenticação
   ↓
3. NotificationsCounterService.initialize() é chamado
   ↓
4. Listener do Firestore é criado
   ↓
5. Query busca notificações não lidas (n_read = false)
   ↓
6. Snapshot retorna documentos
   ↓
7. AppState.unreadNotifications.value é atualizado
   ↓
8. ValueListenableBuilder no AutoUpdatingBadge detecta mudança
   ↓
9. Widget rebuild e badge é atualizado visualmente
```

### Atualização em Tempo Real:

1. **Nova Notificação Criada no Firestore:**
   ```
   Firestore → Listener → AppState → AutoUpdatingBadge → UI
   ```

2. **Notificação Marcada como Lida:**
   ```
   User Tap → markAsRead() → Firestore Update → Listener → AppState → Badge
   ```

---

## 📝 Estrutura de Dados do Firestore

### Collection: `Notifications`

```javascript
{
  "userId": "abc123",           // ID do destinatário
  "n_receiver_id": "abc123",    // Campo duplicado (legacy)
  "n_sender_id": "xyz789",      // ID do remetente
  "n_sender_fullname": "João",  // Nome do remetente
  "n_sender_photo_link": "...", // Foto do remetente
  "n_type": "activity_created", // Tipo da notificação
  "n_read": false,              // ⭐ Status de leitura
  "timestamp": Timestamp,       // Data/hora da criação
  "n_params": {                 // Parâmetros adicionais
    "activity_id": "activity123",
    "activity_title": "Futebol"
  }
}
```

#### Campos Importantes:

- **`userId`** ou **`n_receiver_id`**: Identifica o destinatário
- **`n_read`**: `false` = não lida, `true` = lida ⭐
- **`n_type`**: Tipo da notificação (activity, like, match, etc.)

---

## 🔧 Métodos de Atualização

### Marcar Notificação como Lida

**Controller:** `lib/features/notifications/controllers/simplified_notification_controller.dart`

```dart
Future<void> markAsRead(String notificationId) async {
  try {
    await _repository.readNotification(notificationId);
  } catch (_) {
    // silencioso
  }
}
```

**Repository:** `lib/features/notifications/repositories/notifications_repository.dart`

```dart
Future<void> readNotification(String notificationId) async {
  try {
    await _notificationsCollection
        .doc(notificationId)
        .update({'n_read': true});  // ⭐ Atualiza para true
  } catch (e) {
    print('[NOTIFICATIONS] Error marking as read: $e');
  }
}
```

#### Efeito no Badge:

1. `n_read` muda de `false` → `true`
2. Firestore notifica o listener
3. Query retorna menos documentos
4. `AppState.unreadNotifications.value` diminui
5. Badge atualiza automaticamente

---

## 🎯 Vantagens do Padrão Implementado

### ✅ Padrão Advanced-Dating

1. **Simplicidade:** Sem dependências externas pesadas
2. **Performance:** `ValueNotifier` é nativo e otimizado
3. **Reatividade:** Atualizações automáticas em tempo real
4. **Manutenibilidade:** Código claro e fácil de entender
5. **Testabilidade:** Fácil de mockar e testar

### ✅ Arquitetura Clean

- **Separação de Responsabilidades:**
  - `AppState`: Estado global
  - `NotificationsCounterService`: Lógica de contagem
  - `AutoUpdatingBadge`: Apresentação visual
  - `NotificationsRepository`: Acesso a dados

- **Single Source of Truth:**
  - Firestore → único repositório de dados
  - AppState → único estado global reativo

---

## 🐛 Debug e Logs

### Logs Implementados:

```dart
// Inicialização
🚀 [NotificationsCounter] Inicializando serviço...
🚀 [NotificationsCounter] AppState.currentUserId: abc123
🚀 [NotificationsCounter] Serviço inicializado

// Query
📊 [NotificationsCounter] Criando query: Notifications.n_receiver_id == abc123 && n_read == false

// Atualizações
📊 [NotificationsCounter] ✅ Notificações não lidas atualizadas: 5
📊 [NotificationsCounter] Documentos recebidos: [doc1, doc2, doc3, doc4, doc5]

// Erros
❌ [NotificationsCounter] Erro ao contar notificações: [error]
⚠️ [NotificationsCounter] Usuário não autenticado
```

### Como Debugar:

1. **Verificar AppState:**
   ```dart
   debugPrint('Unread: ${AppState.unreadNotifications.value}');
   ```

2. **Verificar Firestore:**
   ```bash
   # No Firebase Console
   Notifications → Filters → n_read == false
   ```

3. **Verificar Listener:**
   - Logs do `NotificationsCounterService`
   - Verificar se `initialize()` foi chamado

---

## 📊 Estados do Badge

### Estado Normal (Sem Notificações)

```
┌─────────────┐
│     🔔      │  Badge não visível
└─────────────┘
```

### Estado com Notificações (1-99)

```
┌─────────────┐
│     🔔  ③  │  Número exato exibido
└─────────────┘
```

### Estado com Muitas Notificações (100+)

```
┌─────────────┐
│     🔔 99+ │  Limite de 99+
└─────────────┘
```

---

## 🔐 Segurança

### Validações Implementadas:

1. **Autenticação:**
   ```dart
   if (currentUserId == null) {
     return;  // Não inicializa listener
   }
   ```

2. **Query Segura:**
   ```dart
   .where('n_receiver_id', isEqualTo: currentUserId)  // Apenas notificações do usuário
   ```

3. **Error Handling:**
   ```dart
   .listen(
     onSuccess: (snapshot) { /* ... */ },
     onError: (error) {
       // Reset seguro em caso de erro
       AppState.unreadNotifications.value = 0;
     },
   );
   ```

---

## 📈 Performance

### Otimizações:

1. **RepaintBoundary:**
   - Isola repaint do badge
   - Evita rebuild de widgets vizinhos

2. **ValueNotifier:**
   - Mais leve que ChangeNotifier
   - Rebuild apenas do listener específico

3. **IgnorePointer:**
   - Badge não intercepta gestos
   - Melhora responsividade do ícone

4. **Query Indexada:**
   - Firestore possui índice para `n_receiver_id + n_read`
   - Query rápida e eficiente

---

## 🧪 Casos de Teste

### Cenários Cobertos:

1. ✅ **Login do Usuário**
   - Badge inicia com contagem correta

2. ✅ **Nova Notificação**
   - Badge incrementa automaticamente

3. ✅ **Marcar como Lida**
   - Badge decrementa automaticamente

4. ✅ **Logout**
   - Badge reseta para 0

5. ✅ **Erro de Conexão**
   - Badge não trava, mostra 0

6. ✅ **Múltiplas Notificações Simultâneas**
   - Contagem precisa mantida

---

## 🔮 Melhorias Futuras

### Possíveis Evoluções:

1. **Agrupamento de Notificações:**
   ```dart
   // Badge por tipo
   unreadActivityNotifications: ValueNotifier<int>(0)
   unreadMatchNotifications: ValueNotifier<int>(0)
   ```

2. **Animações:**
   ```dart
   AnimatedScale(
     scale: badgeCount > 0 ? 1.0 : 0.0,
     child: Badge(...),
   )
   ```

3. **Som/Vibração:**
   ```dart
   if (newCount > oldCount) {
     AudioService.playNotificationSound();
   }
   ```

4. **Cache Local:**
   ```dart
   // Persistir contagem localmente
   SharedPreferences.setInt('unread_count', count);
   ```

---

## 📚 Referências

### Arquivos Relacionados:

- `lib/features/home/presentation/widgets/home_app_bar.dart`
- `lib/features/home/presentation/widgets/auto_updating_badge.dart`
- `lib/common/state/app_state.dart`
- `lib/common/services/notifications_counter_service.dart`
- `lib/features/notifications/repositories/notifications_repository.dart`
- `lib/core/services/auth_sync_service.dart`

### Padrões Utilizados:

- ✅ **Observer Pattern** (ValueNotifier + ValueListenableBuilder)
- ✅ **Singleton Pattern** (AppState, NotificationsCounterService)
- ✅ **Repository Pattern** (NotificationsRepository)
- ✅ **Service Pattern** (NotificationsCounterService)

---

## 🎉 Conclusão

O sistema de badge de notificações foi implementado com sucesso seguindo as melhores práticas do Flutter e o padrão Advanced-Dating. A solução é:

- ✅ **Reativa:** Atualiza em tempo real
- ✅ **Performática:** Otimizações de repaint
- ✅ **Simples:** Sem dependências complexas
- ✅ **Robusta:** Error handling adequado
- ✅ **Escalável:** Fácil adicionar novos contadores

---

**Documentação criada em:** 06/12/2025  
**Versão:** 1.0  
**Autor:** Sistema de Documentação Automática
