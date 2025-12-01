import 'dart:developer' as developer;

/// Cache de avatares em memória
/// 
/// Singleton que previne rebuilds desnecessários de imagens.
/// TTL: infinito (até usuário trocar foto ou logout)
/// 
/// Uso:
/// ```dart
/// // Ao carregar imagem
/// AvatarCacheService.instance.cacheAvatar(userId, imageUrl);
/// 
/// // Ao renderizar
/// final url = AvatarCacheService.instance.getAvatarUrl(userId);
/// ```
class AvatarCacheService {
  AvatarCacheService._();
  static final instance = AvatarCacheService._();

  /// Cache: userId -> imageUrl
  final Map<String, String> _cache = {};
  
  /// Timestamp de quando foi cacheado: userId -> DateTime
  final Map<String, DateTime> _cachedAt = {};

  // ==================== LEITURA ====================

  /// Retorna URL do avatar do cache (ou null)
  String? getAvatarUrl(String userId) {
    if (userId.isEmpty) return null;
    return _cache[userId];
  }

  /// Verifica se avatar está no cache
  bool hasAvatar(String userId) {
    return _cache.containsKey(userId);
  }

  /// Retorna idade do cache para um usuário
  Duration? getAvatarAge(String userId) {
    final cachedAt = _cachedAt[userId];
    if (cachedAt == null) return null;
    return DateTime.now().difference(cachedAt);
  }

  // ==================== ESCRITA ====================

  /// Adiciona avatar ao cache
  /// 
  /// Use após carregar foto de perfil ou receber update.
  /// 
  /// Aceita string vazia como sinal válido de "sem avatar".
  void cacheAvatar(String userId, String imageUrl) {
    if (userId.isEmpty) return;
    
    _cache[userId] = imageUrl;
    _cachedAt[userId] = DateTime.now();
    _log('Avatar cached: $userId');
  }

  /// Adiciona múltiplos avatares em batch
  /// 
  /// Aceita strings vazias como sinal válido de "sem avatar".
  void cacheAvatars(Map<String, String> userAvatars) {
    final now = DateTime.now();
    userAvatars.forEach((userId, imageUrl) {
      if (userId.isNotEmpty) {
        _cache[userId] = imageUrl;
        _cachedAt[userId] = now;
      }
    });
    _log('${userAvatars.length} avatars cached');
  }

  // ==================== INVALIDAÇÃO ====================

  /// Remove avatar do cache
  /// 
  /// Use quando usuário trocar foto de perfil.
  void invalidateAvatar(String userId) {
    _cache.remove(userId);
    _cachedAt.remove(userId);
    _log('Avatar invalidated: $userId');
  }

  /// Remove múltiplos avatares
  void invalidateAvatars(List<String> userIds) {
    for (final id in userIds) {
      invalidateAvatar(id);
    }
  }

  /// Atualiza avatar (substitui se já existir)
  /// 
  /// Aceita string vazia como sinal válido de "sem avatar".
  /// Não faz nada se a URL for idêntica (otimização).
  void updateAvatar(String userId, String newImageUrl) {
    if (userId.isEmpty) return;
    
    final oldUrl = _cache[userId];
    
    // ✅ Otimização: não sobrescreve se for a mesma URL
    if (oldUrl == newImageUrl) return;
    
    _cache[userId] = newImageUrl;
    _cachedAt[userId] = DateTime.now();
    
    if (oldUrl != null) {
      _log('Avatar updated: $userId (url changed)');
    } else {
      _log('Avatar cached: $userId (first time)');
    }
  }

  // ==================== LIMPEZA ====================

  /// Limpa avatares antigos (1h sem uso)
  /// 
  /// Chame ao receber memory warning ou periodicamente.
  void cleanOld({Duration maxAge = const Duration(hours: 1)}) {
    final now = DateTime.now();
    final oldKeys = <String>[];
    
    _cachedAt.forEach((userId, cachedAt) {
      if (now.difference(cachedAt) > maxAge) {
        oldKeys.add(userId);
      }
    });
    
    for (final key in oldKeys) {
      _cache.remove(key);
      _cachedAt.remove(key);
    }
    
    if (oldKeys.isNotEmpty) {
      _log('Cleaned ${oldKeys.length} old avatars');
    }
  }

  /// Limpa TODO o cache
  /// 
  /// Use apenas ao fazer logout.
  void clearAll() {
    final count = _cache.length;
    _cache.clear();
    _cachedAt.clear();
    _log('All avatars cleared ($count removed)');
  }
  
  /// Limpa cache antigo quando app volta do background
  /// 
  /// Chame no AppLifecycleState.resumed para evitar crescimento eterno do cache.
  /// Mantém avatares usados nas últimas 6 horas (padrão).
  void refreshOnForeground({Duration maxAge = const Duration(hours: 6)}) {
    _log('Cleaning old avatars on foreground resume');
    cleanOld(maxAge: maxAge);
  }

  // ==================== ESTATÍSTICAS ====================

  /// Retorna estatísticas do cache
  Map<String, dynamic> getStats() {
    return {
      'cachedAvatars': _cache.length,
      'oldestAvatar': _getOldestAge(),
      'newestAvatar': _getNewestAge(),
    };
  }

  Duration? _getOldestAge() {
    if (_cachedAt.isEmpty) return null;
    
    final oldest = _cachedAt.values.reduce((a, b) => a.isBefore(b) ? a : b);
    return DateTime.now().difference(oldest);
  }

  Duration? _getNewestAge() {
    if (_cachedAt.isEmpty) return null;
    
    final newest = _cachedAt.values.reduce((a, b) => a.isAfter(b) ? a : b);
    return DateTime.now().difference(newest);
  }

  /// Imprime estatísticas (debug)
  void printStats() {
    final stats = getStats();
    _log('=== AVATAR CACHE STATS ===');
    _log('Cached avatars: ${stats['cachedAvatars']}');
    _log('Oldest: ${stats['oldestAvatar']}');
    _log('Newest: ${stats['newestAvatar']}');
    _log('==========================');
  }

  void _log(String message) {
    developer.log(message, name: 'partiu.cache.avatar');
  }
}
