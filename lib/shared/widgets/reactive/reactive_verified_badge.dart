import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// 🎯 Badge de verificação reativo
/// Reconstrói APENAS quando status de verificação muda
/// 
/// Usage:
/// ```dart
/// ReactiveVerifiedBadge(userId: 'abc123')
/// ReactiveVerifiedBadge(userId: 'abc123', size: 24)
/// ```
class ReactiveVerifiedBadge extends StatefulWidget {
  const ReactiveVerifiedBadge({
    required this.userId,
    super.key,
    this.size = 18,
    this.verifiedColor = Colors.blue,
    this.unverifiedColor = Colors.grey,
    this.showUnverified = false, // Se false, não mostra nada quando não verificado
  });

  final String userId;
  final double size;
  final Color verifiedColor;
  final Color unverifiedColor;
  final bool showUnverified;

  @override
  State<ReactiveVerifiedBadge> createState() => _ReactiveVerifiedBadgeState();
}

class _ReactiveVerifiedBadgeState extends State<ReactiveVerifiedBadge> {
  late ValueNotifier<bool> _verifiedNotifier;

  @override
  void initState() {
    super.initState();
    _verifiedNotifier = UserStore.instance.getVerifiedNotifier(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ReactiveVerifiedBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _verifiedNotifier = UserStore.instance.getVerifiedNotifier(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _verifiedNotifier,
      builder: (context, verified, _) {
        if (!verified && !widget.showUnverified) {
          return const SizedBox.shrink();
        }

        return Icon(
          verified ? Icons.verified : Icons.error_outline,
          size: widget.size,
          color: verified ? widget.verifiedColor : widget.unverifiedColor,
        );
      },
    );
  }
}