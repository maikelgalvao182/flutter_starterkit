# Sistema de Cache do Partiu

Sistema de cache em memória otimizado seguindo padrões de apps sociais modernos (Instagram, TikTok, Uber).

## 📋 Índice

- [Arquitetura](#arquitetura)
- [Serviços Disponíveis](#serviços-disponíveis)
- [Como Usar](#como-usar)
- [Padrões e Boas Práticas](#padrões-e-boas-práticas)
- [TTL (Time To Live)](#ttl-time-to-live)
- [Quando Invalidar](#quando-invalidar)

## 🏗️ Arquitetura

```
UI → ViewModel → Repository → CacheService → Firestore/API
```

**NUNCA** faça chamadas diretas do UI para o Firestore. Sempre passe pelo cache.

## 📦 Serviços Disponíveis

### 1. UserCacheService
- **TTL**: 10 minutos
- **Uso**: Perfis de usuários
- **Singleton**: `UserCacheService.instance`

### 2. AvatarCacheService
- **TTL**: Infinito (até usuário trocar foto)
- **Uso**: URLs de fotos de perfil
- **Singleton**: `AvatarCacheService.instance`

### 3. CacheManager
- **Uso**: Gerenciador central coordenando todos os caches
- **Singleton**: `CacheManager.instance`

## 🚀 Como Usar

### Inicialização (main.dart)

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializa Firebase
  await Firebase.initializeApp();
  
  // Inicializa SessionManager
  await SessionManager.instance.initialize();
  
  // Inicializa Cache
  CacheManager.instance.initialize();
  
  runApp(MyApp());
}
```

### Buscar Usuário (Padrão Cache-First)

```dart
// ✅ CORRETO: Cache-first, depois Firestore
Future<void> loadUser(String userId) async {
  // 1. Tenta cache (síncrono, rápido)
  UserModel? user = UserCacheService.instance.getUser(userId);
  
  // 2. Se não tiver, busca Firestore
  if (user == null) {
    user = await UserCacheService.instance.fetchUser(userId);
  }
  
  // 3. Usa o usuário
  if (user != null) {
    setState(() {
      _user = user;
    });
  }
}

// OU use o método conveniente:
final user = await UserCacheService.instance.getOrFetchUser(userId);
```

### Buscar Avatar

```dart
// Widgets sempre pegam do cache (síncrono)
Widget build(BuildContext context) {
  final avatarUrl = AvatarCacheService.instance.getAvatarUrl(userId);
  
  return CachedNetworkImage(
    imageUrl: avatarUrl ?? defaultAvatarUrl,
    placeholder: (context, url) => CircularProgressIndicator(),
    errorWidget: (context, url, error) => Icon(Icons.person),
  );
}

// Ao carregar perfil, cache o avatar
void _cacheUserAvatar(UserModel user) {
  if (user.photoUrl != null) {
    AvatarCacheService.instance.cacheAvatar(user.userId, user.photoUrl!);
  }
}
```

### Batch Loading (Múltiplos Usuários)

```dart
// ✅ Otimizado: busca vários usuários de uma vez
Future<void> loadParticipants(List<String> userIds) async {
  final users = await UserCacheService.instance.fetchUsers(userIds);
  
  // users = Map<String, UserModel>
  setState(() {
    _participants = users.values.toList();
  });
}
```

### Invalidar Cache (Após Update)

```dart
// Após atualizar perfil no Firestore
Future<void> updateProfile(UserModel updatedUser) async {
  // 1. Atualiza no Firestore
  await FirebaseFirestore.instance
      .collection('Users')
      .doc(updatedUser.userId)
      .update(updatedUser.toMap());
  
  // 2. Invalida cache antigo
  CacheManager.instance.invalidateUser(updatedUser.userId);
  
  // OU atualiza diretamente (evita fetch desnecessário)
  UserCacheService.instance.updateUser(updatedUser);
}

// Após trocar foto de perfil
Future<void> updateAvatar(String userId, String newPhotoUrl) async {
  // 1. Upload + atualiza Firestore
  await _uploadAndSaveAvatar(newPhotoUrl);
  
  // 2. Atualiza cache
  AvatarCacheService.instance.updateAvatar(userId, newPhotoUrl);
}
```

### Pull-to-Refresh

```dart
Future<void> _onRefresh() async {
  // Força buscar dados atualizados (ignora cache)
  final freshUser = await UserCacheService.instance.refreshUser(userId);
  
  setState(() {
    _user = freshUser;
  });
}

Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: _onRefresh,
    child: ListView(...),
  );
}
```

### Limpeza Periódica

```dart
// Em algum lugar do app (ex: AppLifecycleObserver)
class AppLifecycleManager with WidgetsBindingObserver {
  Timer? _cleanupTimer;
  
  void startPeriodicCleanup() {
    // Limpa cache expirado a cada 5 minutos
    _cleanupTimer = Timer.periodic(Duration(minutes: 5), (_) {
      CacheManager.instance.cleanExpired();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      // App foi para background → limpa cache expirado
      CacheManager.instance.cleanExpired();
    }
  }
}
```

### Logout

```dart
Future<void> logout() async {
  // 1. Limpa sessão
  await SessionManager.instance.logout();
  
  // 2. Limpa TODO o cache (memória + disco)
  await CacheManager.instance.clearAll();
  
  // 3. Navega para tela de login
  Navigator.of(context).pushReplacementNamed('/login');
}
```

## 📏 Padrões e Boas Práticas

### ✅ FAÇA

```dart
// ✅ Use cache-first sempre
final user = UserCacheService.instance.getUser(userId);

// ✅ Batch loading para múltiplos itens
final users = await UserCacheService.instance.fetchUsers(userIds);

// ✅ Invalide após update
CacheManager.instance.invalidateUser(userId);

// ✅ Use CachedNetworkImage para imagens
CachedNetworkImage(imageUrl: avatarUrl)

// ✅ Pull-to-refresh força atualização
await UserCacheService.instance.refreshUser(userId);
```

### ❌ NÃO FAÇA

```dart
// ❌ NUNCA chame Firestore direto da UI
final doc = await FirebaseFirestore.instance.collection('Users').doc(id).get();

// ❌ NUNCA guarde cache no State/ViewModel
class MyViewModel extends ChangeNotifier {
  final Map<String, User> _cache = {}; // ❌ ERRADO
}

// ❌ NUNCA use Provider para cache
Provider<Map<String, User>>(...) // ❌ ERRADO

// ❌ NUNCA faça múltiplas queries individuais
for (final id in userIds) {
  await fetchUser(id); // ❌ LENTO - use fetchUsers()
}

// ❌ NUNCA limpe todo o cache por qualquer motivo
CacheManager.instance.clearAll(); // ❌ Só no logout!
```

## ⏱️ TTL (Time To Live)

Cada tipo de dado tem um tempo de vida no cache:

| Serviço | TTL | Motivo |
|---------|-----|--------|
| UserCacheService | 10 min | Perfis não mudam frequentemente |
| AvatarCacheService | Infinito | Foto só muda quando usuário trocar |

**Por que TTL é importante?**
- ✅ Garante dados atualizados
- ✅ Evita requests repetidos
- ✅ Reduz custo do Firestore
- ✅ Evita mostrar dados muito antigos

## 🔄 Quando Invalidar

| Ação | Cache a Invalidar | Como |
|------|-------------------|------|
| Usuário atualiza perfil | User + Avatar | `CacheManager.instance.invalidateUser(userId)` |
| Usuário troca foto | Avatar | `AvatarCacheService.instance.invalidateAvatar(userId)` |
| Logout | TUDO | `CacheManager.instance.clearAll()` |
| Delete conta | TUDO | `CacheManager.instance.clearAll()` |
| Pull-to-refresh | Seletivo | `UserCacheService.instance.refreshUser(userId)` |

## 🐛 Debug e Estatísticas

```dart
// Ver estatísticas de todos os caches
CacheManager.instance.printStats();

// Ver apenas usuários
UserCacheService.instance.printStats();

// Ver apenas avatares
AvatarCacheService.instance.printStats();

// Output exemplo:
// === CACHE MANAGER STATS ===
// Initialized: true
//
// === USER CACHE STATS ===
// Cached users: 42
// Oldest entry: 0:08:32.123456
// Newest entry: 0:00:12.987654
// TTL: 10 minutes
// ========================
//
// === AVATAR CACHE STATS ===
// Cached avatars: 38
// Oldest: 0:15:43.234567
// Newest: 0:00:05.123456
// ==========================
```

## 🎯 Exemplos Reais

### Tela de Perfil

```dart
class ProfileScreen extends StatefulWidget {
  final String userId;
  
  const ProfileScreen({required this.userId});
  
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserModel? _user;
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadUser();
  }
  
  Future<void> _loadUser() async {
    setState(() => _loading = true);
    
    // Cache-first
    final user = await UserCacheService.instance.getOrFetchUser(widget.userId);
    
    setState(() {
      _user = user;
      _loading = false;
    });
  }
  
  Future<void> _onRefresh() async {
    final freshUser = await UserCacheService.instance.refreshUser(widget.userId);
    setState(() => _user = freshUser);
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) return LoadingWidget();
    if (_user == null) return ErrorWidget();
    
    return RefreshIndicator(
      onRefresh: _onRefresh,
      child: ProfileView(user: _user!),
    );
  }
}
```

### Lista de Participantes

```dart
class ParticipantsList extends StatefulWidget {
  final List<String> participantIds;
  
  const ParticipantsList({required this.participantIds});
  
  @override
  State<ParticipantsList> createState() => _ParticipantsListState();
}

class _ParticipantsListState extends State<ParticipantsList> {
  Map<String, UserModel> _participants = {};
  bool _loading = true;
  
  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }
  
  Future<void> _loadParticipants() async {
    setState(() => _loading = true);
    
    // Batch loading otimizado
    final users = await UserCacheService.instance.fetchUsers(widget.participantIds);
    
    setState(() {
      _participants = users;
      _loading = false;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    if (_loading) return LoadingWidget();
    
    return ListView.builder(
      itemCount: _participants.length,
      itemBuilder: (context, index) {
        final user = _participants.values.elementAt(index);
        return UserListTile(user: user);
      },
    );
  }
}
```

## 📚 Referências

Este sistema de cache segue padrões usados por:
- Instagram
- TikTok
- Uber
- iFood
- WhatsApp
- BeReal

Para mais informações, consulte:
- [SessionManager](../managers/session_manager.dart)
- [UserModel](../../../shared/models/user_model.dart)
