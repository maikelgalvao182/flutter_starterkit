import 'dart:developer' as developer;
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:partiu/core/services/cache/image_caches.dart';

/// Serviço de cache da aplicação
/// 
/// Gerencia diferentes tipos de cache utilizados no app
class AppCacheService {
  AppCacheService._();

  /// Limpa todos os caches da aplicação
  static Future<void> clearCache() async {
    try {
      // Limpa cache padrão de imagens
      await DefaultCacheManager().emptyCache();

      // Limpa caches custom
      await AvatarImageCache.instance.emptyCache();
      await ChatMediaImageCache.instance.emptyCache();
      
      // Aqui você pode adicionar outros caches específicos
      // await CustomCacheManager().emptyCache();
      
      _log('All app caches cleared');
    } catch (e, stack) {
      _logError('Failed to clear app cache', e, stack);
      rethrow;
    }
  }

  /// Limpa cache específico de imagens
  static Future<void> clearImageCache() async {
    try {
      await DefaultCacheManager().emptyCache();
      _log('Image cache cleared');
    } catch (e, stack) {
      _logError('Failed to clear image cache', e, stack);
      rethrow;
    }
  }

  // ==================== LOGGING ====================

  static void _log(String message) {
    developer.log(message, name: 'partiu.cache');
  }

  static void _logError(String message, Object error, StackTrace stackTrace) {
    developer.log(
      message,
      name: 'partiu.cache',
      error: error,
      stackTrace: stackTrace,
    );
  }
}