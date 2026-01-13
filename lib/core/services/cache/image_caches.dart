import 'package:flutter_cache_manager/flutter_cache_manager.dart' as fcm;

/// Cache de imagens pequenas e muito frequentes (ex.: avatares).
///
/// Objetivo: alta taxa de hit e baixa chance de expulsão por mídia pesada.
class AvatarImageCache extends fcm.CacheManager {
  AvatarImageCache._()
      : super(
          fcm.Config(
            'avatarImageCache',
            stalePeriod: Duration(days: 90),
            maxNrOfCacheObjects: 10000,
          ),
        );

  static final AvatarImageCache instance = AvatarImageCache._();
}

/// Cache de mídia “pesada” (ex.: imagens do chat / lightbox).
///
/// Objetivo: evitar encher o cache de avatar e reduzir churn.
class ChatMediaImageCache extends fcm.CacheManager {
  ChatMediaImageCache._()
      : super(
          fcm.Config(
            'chatMediaImageCache',
            stalePeriod: Duration(days: 14),
            maxNrOfCacheObjects: 2000,
          ),
        );

  static final ChatMediaImageCache instance = ChatMediaImageCache._();
}
