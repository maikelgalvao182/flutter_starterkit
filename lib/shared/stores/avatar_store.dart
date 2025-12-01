import 'package:flutter/material.dart';

/// Estado do avatar
enum AvatarState { loading, loaded, empty }

/// Entry com estado e provider
class AvatarEntry {
  AvatarEntry({required this.state, required this.provider});

  final AvatarState state;
  final ImageProvider provider;
}

/// Store simplificado para avatares
/// TODO: Implementar cache e carregamento real de imagens
class AvatarStore {
  AvatarStore._internal();
  static final AvatarStore instance = AvatarStore._internal();

  // Cache de notifiers
  final Map<String, ValueNotifier<AvatarEntry>> _avatarNotifiers = {};
  static const AssetImage _emptyImage = AssetImage('assets/images/empty_avatar.jpg');

  /// Obtém notifier com estado (loading/loaded/empty)
  ValueNotifier<AvatarEntry> getAvatarEntryNotifier(String userId) {
    if (!_avatarNotifiers.containsKey(userId)) {
      _avatarNotifiers[userId] = ValueNotifier<AvatarEntry>(
        AvatarEntry(
          state: AvatarState.loaded,
          provider: _emptyImage,
        ),
      );
      
      // TODO: Carregar avatar real do Firebase/Storage
      _loadAvatar(userId);
    }
    return _avatarNotifiers[userId]!;
  }

  /// Carrega avatar do usuário (placeholder por enquanto)
  Future<void> _loadAvatar(String userId) async {
    // TODO: Implementar carregamento real
    // Por enquanto, apenas simula carregamento
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Pré-carrega avatar com URL conhecida do cache
  void preloadAvatar(String userId, String imageUrl) {
    // TODO: Implementar pré-carregamento com URL cacheada
    // Por enquanto, não faz nada
  }

  /// Limpa cache
  void dispose() {
    for (final notifier in _avatarNotifiers.values) {
      notifier.dispose();
    }
    _avatarNotifiers.clear();
  }
}
