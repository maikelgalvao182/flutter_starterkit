import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// Widget reativo que exibe o nome do usuário com badge de verificado
/// 
/// Usa UserStore para reatividade granular (nome + verificado)
class ReactiveUserNameWithBadge extends StatelessWidget {
  const ReactiveUserNameWithBadge({
    super.key,
    required this.userId,
    this.style,
    this.iconSize = 13.0,
    this.spacing = 4.0,
    this.textAlign = TextAlign.start,
  });

  final String userId;
  final TextStyle? style;
  final double iconSize;
  final double spacing;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }

    final nameNotifier = UserStore.instance.getNameNotifier(userId);
    final verifiedNotifier = UserStore.instance.getVerifiedNotifier(userId);

    return ValueListenableBuilder<String?>(
      valueListenable: nameNotifier,
      builder: (context, name, _) {
        return ValueListenableBuilder<bool>(
          valueListenable: verifiedNotifier,
          builder: (context, isVerified, _) {
            final displayName = name ?? 'Usuário';

            return Row(
              mainAxisAlignment: textAlign == TextAlign.center 
                  ? MainAxisAlignment.center 
                  : MainAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(
                    displayName,
                    style: style ?? TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).brightness == Brightness.dark 
                          ? Colors.white 
                          : Colors.black,
                    ),
                    textAlign: textAlign,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isVerified) ...[
                  SizedBox(width: spacing),
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.verified,
                      size: iconSize,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }
}