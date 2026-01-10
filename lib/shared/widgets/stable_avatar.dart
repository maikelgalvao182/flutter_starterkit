import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/router/app_router.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/shared/repositories/user_repository.dart';
import 'package:partiu/core/models/user.dart';

/// Avatar reativo, quadrado, leve, sem jank e com skeleton automático.
///
/// Integrado com AvatarCacheService para cache em memória.
/// Totalmente baseado em AvatarStore.
/// Mantém borderRadius configurável.
/// Nunca usa formato circular.
class StableAvatar extends StatelessWidget {
  const StableAvatar({
    required this.userId,
    required this.size,
    super.key,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    this.enableNavigation = true,
    this.onTap,
    this.photoUrl,
  });

  final String userId;
  final double size;
  final BorderRadius borderRadius;
  final bool enableNavigation;
  final VoidCallback? onTap;
  final String? photoUrl;

  static const String _emptyAsset = 'assets/images/empty_avatar.jpg';
  static const AssetImage _emptyImage = AssetImage(_emptyAsset);

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.of(context).devicePixelRatio;

    // UserID vazio → avatar padrão
    if (userId.trim().isEmpty) {
      return _AvatarShell(
        size: size,
        borderRadius: borderRadius,
        enableNavigation: false,
        child: _image(_emptyImage, 'empty', devicePixelRatio: devicePixelRatio),
      );
    }

    // ✅ Usar UserStore para reatividade global
    // O StableAvatar APENAS consome o cache - NUNCA faz preload
    // Preload é responsabilidade de controllers/viewmodels/app init
    final notifier = UserStore.instance.getAvatarEntryNotifier(userId);

    return _AvatarShell(
      size: size,
      borderRadius: borderRadius,
      enableNavigation: enableNavigation,
      userId: userId,
      onTap: onTap,
      child: RepaintBoundary(
        child: ValueListenableBuilder(
          valueListenable: notifier,
          builder: (context, entry, _) {
            final provider = entry.provider;
            
            // ✅ Sempre renderiza a imagem diretamente
            // Sem AnimatedSwitcher = sem troca de árvore = sem fallback
            return _image(provider, userId, devicePixelRatio: devicePixelRatio);
          },
        ),
      ),
    );
  }

  /// ✅ CORREÇÃO: Usar ValueKey(keyId) baseado no userId, NÃO no provider
  /// Isso evita rebuilds desnecessários quando o provider muda de instância
  /// mas a imagem é a mesma (mesma URL)
  Widget _image(
    ImageProvider provider,
    String keyId, {
    required double devicePixelRatio,
  }) {
    // ResizeImage usa pixels físicos; isso reduz uso de memória e evita evictions.
    final cacheSize = (size * devicePixelRatio).round().clamp(1, 4096);
    final resizedProvider = ResizeImage(provider, width: cacheSize, height: cacheSize);

    return Image(
      key: ValueKey(keyId),
      image: resizedProvider,
      width: size,
      height: size,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.low,
    );
  }
}

class _AvatarShell extends StatelessWidget {
  const _AvatarShell({
    required this.size,
    required this.borderRadius,
    required this.enableNavigation,
    required this.child,
    this.userId,
    this.onTap,
  });

  final double size;
  final BorderRadius borderRadius;
  final bool enableNavigation;
  final String? userId;
  final VoidCallback? onTap;
  final Widget child;

  void _handleTap(BuildContext context) async {
    // Se há callback customizado, usa ele
    if (onTap != null) {
      onTap!();
      return;
    }

    // Navegação padrão para perfil
    if (userId == null || userId!.isEmpty) return;

    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) return;

    try {
      User userToShow;

      // Se for o próprio usuário, usa AppState
      if (userId == currentUserId) {
        final currentUser = AppState.currentUser.value;
        if (currentUser == null) return;
        userToShow = currentUser;
      } else {
        // Buscar dados do outro usuário
        final userRepository = UserRepository();
        final userData = await userRepository.getUserById(userId!);
        if (userData == null) return;
        
        userToShow = User.fromDocument(userData);
      }

      // Navega para o perfil usando GoRouter
      if (context.mounted) {
        context.push(
          '${AppRoutes.profile}/$userId',
          extra: {
            'user': userToShow,
            'currentUserId': currentUserId,
          },
        );
      }
    } catch (e) {
      debugPrint('❌ Error navigating to profile from avatar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final clipped = ClipOval(
      child: Container(
        width: size,
        height: size,
        color: GlimpseColors.lightTextField,
        child: child,
      ),
    );

    if (!enableNavigation) return clipped;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: () => _handleTap(context),
        child: clipped,
      ),
    );
  }
}
