import 'package:flutter/material.dart';

/// Widget que anima a expansão e colapso de seu conteúdo
/// Útil para mostrar/ocultar seções com transição suave
class AnimatedExpandable extends StatelessWidget {
  const AnimatedExpandable({
    required this.isExpanded,
    required this.child,
    super.key,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
  });

  final bool isExpanded;
  final Widget child;
  final Duration duration;
  final Curve curve;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: duration,
      curve: curve,
      child: isExpanded ? child : const SizedBox.shrink(),
    );
  }
}
