import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:partiu/core/services/cache/user_cache_service.dart';
import 'package:partiu/core/services/cache/avatar_cache_service.dart';
import 'package:partiu/core/services/cache/image_caches.dart';
import 'package:partiu/core/services/cache/image_cache_stats.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Gerenciador central de todos os caches da aplicação
/// 
/// Coordena e gerencia:
/// - UserCacheService (perfis)
/// - AvatarCacheService (fotos de perfil)
/// - DefaultCacheManager (imagens em geral)
/// 
/// Uso:
/// ```dart
/// // Inicializar no main()
/// CacheManager.instance.initialize();
/// 
/// // Limpeza periódica
/// CacheManager.instance.cleanExpired();
/// 
/// // Logout completo
/// await CacheManager.instance.clearAll();
/// ```
class CacheManager {
  CacheManager._();
  static final instance = CacheManager._();

  bool _initialized = false;
  bool _isCleaningExpired = false;
  
  /// Callbacks para notificar UI sobre invalidações
  final List<void Function(String userId)> _onInvalidateCallbacks = [];

  /// Inicializa todos os caches
  /// 
  /// DEVE ser chamado no main() após inicializar Firebase/SessionManager
  void initialize() {
    if (_initialized) return;
    
    _log('Initializing cache system...');
    
    // Caches já são singletons, apenas registra
    _log('✓ UserCacheService ready');
    _log('✓ AvatarCacheService ready');
    _log('✓ DefaultCacheManager ready');
    
    _initialized = true;
    _log('Cache system initialized');
  }

  /// Verifica se foi inicializado
  bool get isInitialized => _initialized;

  // ==================== LIMPEZA SELETIVA ====================

  /// Limpa apenas caches expirados (mantém dados válidos)
  /// 
  /// Chame periodicamente (ex: a cada 5 minutos) ou ao receber memory warning.
  /// Não remove dados que ainda estão dentro do TTL.
  /// 
  /// ✅ Thread-safe: evita limpezas concorrentes.
  void cleanExpired() {
    // 🔒 Lock: evita múltiplas limpezas simultâneas
    if (_isCleaningExpired) {
      _log('Cleanup already in progress, skipping...');
      return;
    }
    
    _isCleaningExpired = true;
    
    try {
      _log('Cleaning expired cache entries...');
      
      // Limpa usuários expirados (TTL: 10 min)
      UserCacheService.instance.cleanExpired();
      
      // Limpa avatares antigos (>1h)
      AvatarCacheService.instance.cleanOld();
      
      _log('Expired cache cleaned');
    } finally {
      _isCleaningExpired = false;
    }
  }
  
  /// Limpa cache quando app volta do background
  /// 
  /// Chame no AppLifecycleState.resumed para manter cache otimizado.
  /// 
  /// Ações:
  /// - Limpa usuários expirados
  /// - Limpa avatares antigos (>6h)
  /// - Revalida usuários críticos (opcional)
  void refreshOnForeground({List<String>? criticalUserIds}) {
    _log('Refreshing cache on foreground resume');
    
    // Limpa expirados
    cleanExpired();
    
    // Limpa avatares muito antigos (6h+)
    AvatarCacheService.instance.refreshOnForeground();
    
    // Revalida usuários críticos
    if (criticalUserIds != null && criticalUserIds.isNotEmpty) {
      UserCacheService.instance.refreshOnForeground(
        criticalUserIds: criticalUserIds,
      );
    }
  }

  /// Invalida cache de um usuário específico
  /// 
  /// Use após atualizar dados do usuário (perfil, foto, etc).
  /// Notifica listeners registrados (opcional).
  void invalidateUser(String userId) {
    UserCacheService.instance.invalidateUser(userId);
    AvatarCacheService.instance.invalidateAvatar(userId);
    
    // Notifica listeners
    _notifyInvalidate(userId);
    
    _log('User cache invalidated: $userId');
  }

  /// Invalida múltiplos usuários
  void invalidateUsers(List<String> userIds) {
    UserCacheService.instance.invalidateUsers(userIds);
    AvatarCacheService.instance.invalidateAvatars(userIds);
    _log('${userIds.length} users invalidated');
  }

  // ==================== LIMPEZA TOTAL ====================

  /// Limpa TODO o cache em memória
  /// 
  /// Use apenas ao fazer LOGOUT.
  /// Não limpa cache de imagens em disco (use clearAll() para isso).
  void clearMemoryCache() {
    _log('Clearing all memory cache...');
    
    UserCacheService.instance.clearAll();
    AvatarCacheService.instance.clearAll();
    
    _log('Memory cache cleared');
  }

  /// Limpa caches da sessão (memória/estado) e opcionalmente o disco.
  ///
  /// Boa prática:
  /// - Produção: `clearAll()` no logout real (privacidade).
  /// - Dev: pode usar `clearSessionCaches(clearDiskImages: false)` para manter o disco
  ///   e validar taxa de hit do cache.
  Future<void> clearSessionCaches({bool clearDiskImages = false}) async {
    _log('Clearing session caches (clearDiskImages=$clearDiskImages)...');

    // Memória/estado
    clearMemoryCache();

    // Flutter ImageCache (RAM)
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
      _log('✓ Flutter ImageCache cleared');
    } catch (e, stack) {
      _logError('Failed to clear Flutter ImageCache', e, stack);
    }

    if (!clearDiskImages) {
      _log('Session caches cleared (memory only)');
      return;
    }

    // Disco (flutter_cache_manager)
    try {
      await DefaultCacheManager().emptyCache();
      _log('✓ Disk image cache cleared (DefaultCacheManager)');
    } catch (e, stack) {
      _logError('Failed to clear disk cache', e, stack);
    }

    // Disco (caches custom)
    try {
      await AvatarImageCache.instance.emptyCache();
      await ChatMediaImageCache.instance.emptyCache();
      _log('✓ Disk image cache cleared (custom caches)');
    } catch (e, stack) {
      _logError('Failed to clear custom disk caches', e, stack);
    }

    _log('Session caches cleared (memory + disk)');
  }

  /// Limpa TODO o cache (memória + disco)
  /// 
  /// Use ao fazer LOGOUT ou DELETAR CONTA.
  /// ATENÇÃO: Operação pesada, use com cuidado.
  /// 
  /// Limpa:
  /// - Cache de usuários em memória
  /// - Cache de avatares em memória
  /// - Cache de imagens em disco (flutter_cache_manager)
  /// - Cache de imagens do Flutter (imageCache)
  Future<void> clearAll() async {
    _log('Clearing ALL cache (memory + disk)...');

    await clearSessionCaches(clearDiskImages: true);
    
    _log('All cache cleared');
  }

  // ==================== ESTATÍSTICAS ====================

  /// Retorna estatísticas de todos os caches
  Map<String, dynamic> getStats() {
    return {
      'initialized': _initialized,
      'isCleaningExpired': _isCleaningExpired,
      'invalidateListeners': _onInvalidateCallbacks.length,
      'users': UserCacheService.instance.getStats(),
      'avatars': AvatarCacheService.instance.getStats(),
      'imageCaches': ImageCacheStats.instance.getStats(),
    };
  }

  /// Imprime estatísticas de todos os caches (debug)
  void printStats() {
    _log('=== CACHE MANAGER STATS ===');
    _log('Initialized: $_initialized');
    _log('');
    UserCacheService.instance.printStats();
    _log('');
    AvatarCacheService.instance.printStats();
    _log('===========================');
  }

  // ==================== ATALHOS DE ACESSO ====================

  /// Acesso direto ao UserCacheService
  UserCacheService get users => UserCacheService.instance;

  /// Acesso direto ao AvatarCacheService
  AvatarCacheService get avatars => AvatarCacheService.instance;
  
  // ==================== CALLBACKS ====================
  
  /// Registra callback para ser notificado quando cache for invalidado
  /// 
  /// Útil para widgets que precisam reagir a mudanças de cache.
  /// 
  /// Exemplo:
  /// ```dart
  /// CacheManager.instance.addInvalidateListener((userId) {
  ///   if (userId == currentUserId) {
  ///     setState(() {}); // Recarrega UI
  ///   }
  /// });
  /// ```
  void addInvalidateListener(void Function(String userId) callback) {
    _onInvalidateCallbacks.add(callback);
  }
  
  /// Remove callback de invalidação
  void removeInvalidateListener(void Function(String userId) callback) {
    _onInvalidateCallbacks.remove(callback);
  }
  
  /// Notifica todos os listeners sobre invalidação
  void _notifyInvalidate(String userId) {
    for (final callback in _onInvalidateCallbacks) {
      try {
        callback(userId);
      } catch (e, stack) {
        _logError('Invalidate callback failed', e, stack);
      }
    }
  }

  // ==================== LOGGING ====================

  void _log(String message) {
    developer.log(message, name: 'partiu.cache');
  }

  void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.cache',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
