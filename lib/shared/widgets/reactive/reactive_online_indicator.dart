import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// 🎯 Indicador de status online reativo
/// Reconstrói APENAS quando status online muda
/// 
/// Usage:
/// ```dart
/// ReactiveOnlineIndicator(userId: 'abc123')
/// ReactiveOnlineIndicator(userId: 'abc123', size: 16)
/// ```
class ReactiveOnlineIndicator extends StatelessWidget {
  const ReactiveOnlineIndicator({
    required this.userId,
    super.key,
    this.size = 12,
    this.onlineColor = Colors.green,
    this.offlineColor = Colors.grey,
    this.showOffline = true, // Se false, esconde quando offline
  });

  final String userId;
  final double size;
  final Color onlineColor;
  final Color offlineColor;
  final bool showOffline;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: UserStore.instance.getOnlineNotifier(userId),
      builder: (context, online, _) {
        if (!online && !showOffline) {
          return const SizedBox.shrink();
        }

        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: online ? onlineColor : offlineColor,
            border: Border.all(
              color: Colors.white,
              width: size * 0.15,
            ),
          ),
        );
      },
    );
  }
}