import 'package:flutter/material.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/models/user.dart';

/// Widget reativo que exibe o nome do usuário com badge de verificado
class ReactiveUserNameWithBadge extends StatelessWidget {
  const ReactiveUserNameWithBadge({
    super.key,
    required this.userId,
    required this.style,
    this.iconSize = 16.0,
    this.spacing = 4.0,
    this.textAlign = TextAlign.start,
  });

  final String userId;
  final TextStyle style;
  final double iconSize;
  final double spacing;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<User?>(
      valueListenable: AppState.currentUser,
      builder: (context, user, _) {
        if (user?.userId != userId) {
          // TODO: Implementar busca de outros usuários
          return const SizedBox.shrink();
        }

        final name = user?.userFullname ?? '';
        final isVerified = user?.isVerified ?? false;

        return Row(
          mainAxisAlignment: textAlign == TextAlign.center 
              ? MainAxisAlignment.center 
              : MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                name,
                style: style,
                textAlign: textAlign,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isVerified) ...[
              SizedBox(width: spacing),
              Icon(
                Icons.verified,
                size: iconSize,
                color: Colors.blue,
              ),
            ],
          ],
        );
      },
    );
  }
}