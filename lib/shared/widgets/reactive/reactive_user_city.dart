import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// 🎯 Cidade do usuário reativa
/// Reconstrói APENAS quando a cidade muda no Firestore
/// 
/// Usage:
/// ```dart
/// ReactiveUserCity(userId: 'abc123')
/// ReactiveUserCity(userId: 'abc123', prefix: '📍 ')
/// ```
class ReactiveUserCity extends StatelessWidget {
  const ReactiveUserCity({
    required this.userId,
    super.key,
    this.style,
    this.prefix = '',
    this.fallback = 'Localização não informada',
    this.icon,
    this.iconSize,
    this.iconColor,
  });

  final String userId;
  final TextStyle? style;
  final String prefix;
  final String fallback;
  final IconData? icon;
  final double? iconSize;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: UserStore.instance.getCityNotifier(userId),
      builder: (context, city, _) {
        final text = city != null && city.isNotEmpty 
            ? '$prefix$city' 
            : fallback;

        if (icon != null) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: iconSize ?? 16,
                color: iconColor ?? style?.color,
              ),
              const SizedBox(width: 4),
              Text(text, style: style),
            ],
          );
        }

        return Text(text, style: style);
      },
    );
  }
}