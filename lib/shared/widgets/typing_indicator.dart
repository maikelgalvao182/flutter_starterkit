import 'package:flutter/material.dart';

/// Widget de indicador de digitação (três pontos animados)
class TypingIndicator extends StatefulWidget {
  final Color? color;
  final double? size;
  final double? dotSize;

  const TypingIndicator({
    super.key,
    this.color,
    this.size,
    this.dotSize,
  });

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dotColor = widget.color ?? Colors.grey;
    final dotSize = widget.dotSize ?? widget.size ?? 8.0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            final delay = index * 0.2;
            final value = (_controller.value - delay).clamp(0.0, 1.0);
            final scale = (value < 0.5 ? value * 2 : (1 - value) * 2);

            return Transform.scale(
              scale: 0.5 + (scale * 0.5),
              child: Container(
                margin: EdgeInsets.symmetric(horizontal: dotSize * 0.2),
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  color: dotColor.withValues(alpha: 0.4 + (scale * 0.6)),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}
