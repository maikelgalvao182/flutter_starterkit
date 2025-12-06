import 'dart:developer' as developer;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/shared/models/user_model.dart';

/// Cache global de usuários
/// 
/// Singleton que mantém usuários em memória para evitar leituras repetidas do Firestore.
/// TTL: 10 minutos (perfis não mudam com muita frequência)
/// 
/// Uso:
/// ```dart
/// final user = UserCacheService.instance.getUser(userId);
/// if (user == null) {
///   final freshUser = await UserCacheService.instance.fetchUser(userId);
/// }
/// ```
class UserCacheService {
  UserCacheService._();
  static final instance = UserCacheService._();

  /// Cache em memória: userId -> UserModel
  final Map<String, UserModel> _cache = {};
  
  /// Timestamp da última busca: userId -> DateTime
  final Map<String, DateTime> _lastFetch = {};
  
  /// Mutex: previne fetch duplo (userId -> Future em andamento)
  final Map<String, Future<UserModel?>> _inFlightRequests = {};
  
  /// TTL (Time To Live) do cache: 10 minutos
  static const Duration _ttl = Duration(minutes: 10);
  
  /// Referência para a coleção de usuários no Firestore
  final CollectionReference _usersCollection = 
      FirebaseFirestore.instance.collection('Users');

  // ==================== LEITURA ====================

  /// Retorna usuário do cache (ou null se não existir/expirado)
  /// 
  /// Sempre use este método para acesso síncrono rápido.
  /// Se retornar null, use fetchUser() para buscar do Firestore.
  UserModel? getUser(String userId) {
    if (userId.isEmpty) return null;
    
    // Verifica se está no cache
    if (!_cache.containsKey(userId)) {
      return null;
    }
    
    // Verifica se expirou (TTL)
    final lastFetch = _lastFetch[userId];
    if (lastFetch == null) {
      _cache.remove(userId);
      return null;
    }
    
    final age = DateTime.now().difference(lastFetch);
    if (age > _ttl) {
      _log('Cache expired for user: $userId (age: ${age.inMinutes}min)');
      _cache.remove(userId);
      _lastFetch.remove(userId);
      return null;
    }
    
    return _cache[userId];
  }

  /// Busca usuário do Firestore e atualiza o cache
  /// 
  /// Use quando getUser() retornar null ou quando precisar forçar atualização.
  /// Usa mutex para evitar múltiplas requisições simultâneas do mesmo usuário.
  Future<UserModel?> fetchUser(String userId) async {
    if (userId.isEmpty) return null;
    
    // ✅ MUTEX: Se já há requisição em andamento, reutiliza
    if (_inFlightRequests.containsKey(userId)) {
      _log('Reusing in-flight request for user: $userId');
      return await _inFlightRequests[userId];
    }
    
    // Cria nova requisição
    final future = _fetchUserInternal(userId);
    _inFlightRequests[userId] = future;
    
    try {
      final user = await future;
      return user;
    } finally {
      // Remove do mutex quando concluir
      _inFlightRequests.remove(userId);
    }
  }
  
  /// Lógica interna de fetch (chamada pelo mutex)
  Future<UserModel?> _fetchUserInternal(String userId) async {
    try {
      _log('Fetching user from Firestore: $userId');
      
      final doc = await _usersCollection.doc(userId).get();
      
      if (!doc.exists) {
        _log('User not found: $userId');
        return null;
      }
      
      // ✅ Usa factory fromFirestore
      final user = UserModel.fromFirestore(doc);
      
      // Atualiza cache
      _cache[userId] = user;
      _lastFetch[userId] = DateTime.now();
      
      _log('User cached: $userId');
      return user;
      
    } catch (e, stack) {
      _logError('Failed to fetch user: $userId', e, stack);
      return null;
    }
  }

  /// Busca usuário (cache-first, depois Firestore)
  /// 
  /// Método conveniente que tenta cache primeiro, depois Firestore.
  /// Retorna null apenas se usuário não existir.
  Future<UserModel?> getOrFetchUser(String userId) async {
    // Tenta cache primeiro
    final cached = getUser(userId);
    if (cached != null) return cached;
    
    // Cache miss ou expirado → busca Firestore
    return await fetchUser(userId);
  }

  /// Busca múltiplos usuários em batch
  /// 
  /// Otimizado: busca do cache primeiro, depois Firestore apenas para os que faltam.
  Future<Map<String, UserModel>> fetchUsers(List<String> userIds) async {
    final result = <String, UserModel>{};
    final missingIds = <String>[];
    
    // Separa: quem está no cache vs quem precisa buscar
    for (final id in userIds) {
      if (id.isEmpty) continue;
      
      final cached = getUser(id);
      if (cached != null) {
        result[id] = cached;
      } else {
        missingIds.add(id);
      }
    }
    
    // Busca os que faltam do Firestore
    if (missingIds.isNotEmpty) {
      _log('Batch fetching ${missingIds.length} users from Firestore');
      
      // Firestore permite até 10 queries "in" por vez
      final chunks = _chunk(missingIds, 10);
      
      for (final chunk in chunks) {
        try {
          final snapshot = await _usersCollection
              .where(FieldPath.documentId, whereIn: chunk)
              .get();
          
          for (final doc in snapshot.docs) {
            // ✅ Usa factory fromFirestore
            final user = UserModel.fromFirestore(doc);
            
            // Atualiza cache
            _cache[doc.id] = user;
            _lastFetch[doc.id] = DateTime.now();
            result[doc.id] = user;
          }
        } catch (e, stack) {
          _logError('Failed to batch fetch users', e, stack);
        }
      }
    }
    
    return result;
  }

  // ==================== INVALIDAÇÃO ====================

  /// Invalida (remove) um usuário do cache
  /// 
  /// Use após atualizar dados do usuário no Firestore.
  void invalidateUser(String userId) {
    _cache.remove(userId);
    _lastFetch.remove(userId);
    _log('User invalidated: $userId');
  }

  /// Invalida múltiplos usuários
  void invalidateUsers(List<String> userIds) {
    for (final id in userIds) {
      invalidateUser(id);
    }
  }

  /// Atualiza usuário no cache (sem buscar do Firestore)
  /// 
  /// Use quando você já tem o objeto atualizado (ex: após update local).
  void updateUser(UserModel user) {
    _cache[user.userId] = user;
    _lastFetch[user.userId] = DateTime.now();
    _log('User updated in cache: ${user.userId}');
  }
  
  /// Atualiza apenas campos específicos de um usuário no cache
  /// 
  /// Exemplo: updateUserFields('userId123', fullName: 'Novo Nome')
  /// 
  /// Só funciona se o usuário já estiver no cache.
  void updateUserFields(
    String userId, {
    String? fullName,
    String? email,
    String? photoUrl,
    String? userType,
  }) {
    final existing = _cache[userId];
    if (existing == null) {
      _log('Cannot update fields: user not in cache: $userId');
      return;
    }
    
    final updated = existing.copyWith(
      fullName: fullName,
      email: email,
      photoUrl: photoUrl,
      userType: userType,
    );
    
    _cache[userId] = updated;
    _lastFetch[userId] = DateTime.now();
    _log('User fields updated in cache: $userId');
  }

  /// Força refresh de um usuário (ignora TTL)
  Future<UserModel?> refreshUser(String userId) async {
    invalidateUser(userId);
    return await fetchUser(userId);
  }

  // ==================== LIMPEZA ====================

  /// Limpa cache expirado (mantém apenas dados válidos)
  /// 
  /// Chame periodicamente ou ao receber memory warning.
  void cleanExpired() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _lastFetch.forEach((userId, lastFetch) {
      if (now.difference(lastFetch) > _ttl) {
        expiredKeys.add(userId);
      }
    });
    
    for (final key in expiredKeys) {
      _cache.remove(key);
      _lastFetch.remove(key);
    }
    
    if (expiredKeys.isNotEmpty) {
      _log('Cleaned ${expiredKeys.length} expired users from cache');
    }
  }

  /// Limpa TODO o cache
  /// 
  /// Use apenas ao fazer logout.
  void clearAll() {
    final count = _cache.length;
    _cache.clear();
    _lastFetch.clear();
    _inFlightRequests.clear();
    _log('Cache cleared ($count users removed)');
  }
  
  /// Revalida cache quando app volta do background
  /// 
  /// Chame no AppLifecycleState.resumed para garantir dados frescos.
  /// Limpa expirados + opcionalmente revalida usuários críticos.
  Future<void> refreshOnForeground({
    List<String>? criticalUserIds,
  }) async {
    _log('Refreshing cache on foreground');
    
    // 1. Limpa expirados
    cleanExpired();
    
    // 2. Revalida usuários críticos (ex: usuário logado, conversas ativas)
    if (criticalUserIds != null && criticalUserIds.isNotEmpty) {
      _log('Revalidating ${criticalUserIds.length} critical users');
      
      for (final userId in criticalUserIds) {
        // Força refresh apenas se estiver no cache
        if (_cache.containsKey(userId)) {
          await refreshUser(userId);
        }
      }
    }
  }

  // ==================== ESTATÍSTICAS ====================

  /// Retorna estatísticas do cache (para debug)
  Map<String, dynamic> getStats() {
    return {
      'cachedUsers': _cache.length,
      'inFlightRequests': _inFlightRequests.length,
      'oldestEntry': _getOldestEntryAge(),
      'newestEntry': _getNewestEntryAge(),
      'ttlMinutes': _ttl.inMinutes,
    };
  }

  Duration? _getOldestEntryAge() {
    if (_lastFetch.isEmpty) return null;
    
    final oldest = _lastFetch.values.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldest);
  }

  Duration? _getNewestEntryAge() {
    if (_lastFetch.isEmpty) return null;
    
    final newest = _lastFetch.values.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(newest);
  }

  /// Imprime estatísticas do cache (debug)
  void printStats() {
    final stats = getStats();
    _log('=== USER CACHE STATS ===');
    _log('Cached users: ${stats['cachedUsers']}');
    _log('In-flight requests: ${stats['inFlightRequests']}');
    _log('Oldest entry: ${stats['oldestEntry']}');
    _log('Newest entry: ${stats['newestEntry']}');
    _log('TTL: ${stats['ttlMinutes']} minutes');
    _log('========================');
  }

  // ==================== UTILITÁRIOS ====================

  /// Divide lista em chunks menores
  List<List<T>> _chunk<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }

  void _log(String message) {
    developer.log(message, name: 'partiu.cache.user');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.cache.user',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
