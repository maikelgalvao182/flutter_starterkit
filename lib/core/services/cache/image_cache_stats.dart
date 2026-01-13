import 'dart:async';

import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/services/cache/image_caches.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;

enum ImageCacheCategory {
  avatar,
  chatMedia,
}

/// Estatísticas leves (debug) para validar se cacheKey está funcionando.
///
/// Objetivos:
/// - Evitar overkill: sem varrer diretórios nem métricas pesadas.
/// - Registrar hit/miss baseado em `getFileFromCache(cacheKey)`.
/// - Log amostrado e 1x por cacheKey (por sessão) para não poluir.
class ImageCacheStats {
  ImageCacheStats._();
  static final ImageCacheStats instance = ImageCacheStats._();

  final Set<String> _seen = <String>{};

  int _avatarChecks = 0;
  int _avatarHits = 0;
  int _avatarMisses = 0;

  int _chatChecks = 0;
  int _chatHits = 0;
  int _chatMisses = 0;

  /// Amostragem: 1 em N checks (reduz overhead e ruído).
  static const int _sampleEvery = 15;

  void record({
    required ImageCacheCategory category,
    required String url,
    required String cacheKey,
  }) {
    if (!AppLogger.enabled || !LogFlags.cache) return;

    final trimmedKey = cacheKey.trim();
    if (trimmedKey.isEmpty) return;

    // Evita checar/logar o mesmo item várias vezes na mesma sessão.
    final uniqueKey = '${category.name}::$trimmedKey';
    if (_seen.contains(uniqueKey)) return;
    _seen.add(uniqueKey);

    // Amostragem global: reduz custo de IO.
    final shouldSample = (_seen.length % _sampleEvery) == 0;
    if (!shouldSample) return;

    unawaited(_check(category: category, url: url, cacheKey: trimmedKey));
  }

  Future<void> _check({
    required ImageCacheCategory category,
    required String url,
    required String cacheKey,
  }) async {
    try {
      final fcm.FileInfo? info;
      switch (category) {
        case ImageCacheCategory.avatar:
          _avatarChecks++;
          info = await AvatarImageCache.instance.getFileFromCache(cacheKey);
          if (info != null) {
            _avatarHits++;
          } else {
            _avatarMisses++;
          }
          break;
        case ImageCacheCategory.chatMedia:
          _chatChecks++;
          info = await ChatMediaImageCache.instance.getFileFromCache(cacheKey);
          if (info != null) {
            _chatHits++;
          } else {
            _chatMisses++;
          }
          break;
      }

      final hit = info != null;
      AppLogger.cache(
        '${category.name.toUpperCase()} ${hit ? 'HIT' : 'MISS'} key=$cacheKey url=${_short(url)}',
        tag: 'IMAGE_CACHE',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Falha ao checar cache (category=${category.name})',
        tag: 'IMAGE_CACHE',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Map<String, dynamic> getStats() {
    return {
      'seen': _seen.length,
      'avatar': {
        'checks': _avatarChecks,
        'hits': _avatarHits,
        'misses': _avatarMisses,
      },
      'chatMedia': {
        'checks': _chatChecks,
        'hits': _chatHits,
        'misses': _chatMisses,
      },
    };
  }

  String _short(String url) {
    final trimmed = url.trim();
    if (trimmed.length <= 80) return trimmed;
    return '${trimmed.substring(0, 60)}…${trimmed.substring(trimmed.length - 16)}';
  }
}
