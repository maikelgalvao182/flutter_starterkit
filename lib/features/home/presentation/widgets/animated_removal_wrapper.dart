import 'package:flutter/material.dart';

/// Wrapper para uma remoção suave com slide + fade (bem natural)
class AnimatedRemovalWrapper extends StatefulWidget {
  const AnimatedRemovalWrapper({
    required this.child,
    required this.onRemove,
    super.key,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  State<AnimatedRemovalWrapper> createState() => AnimatedRemovalWrapperState();
}

class AnimatedRemovalWrapperState extends State<AnimatedRemovalWrapper>
    with SingleTickerProviderStateMixin {

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 320),
      vsync: this,
    );

    // Slide 0 → -0.30 (30% para esquerda)
    _slide = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(-0.30, 0),
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    // Fade só começa após 40% do caminho → mais natural
    _opacity = Tween<double>(
      begin: 1,
      end: 0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(
          0.40, 1.0,
          curve: Curves.easeOut,
        ),
      ),
    );
  }

  /// Chamado externamente ao clicar no PASS
  Future<void> animateRemoval() async {
    await _controller.forward();  // roda animação suave
    if (mounted) widget.onRemove(); // remove item
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        return Opacity(
          opacity: _opacity.value,
          child: SlideTransition(
            position: _slide,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
