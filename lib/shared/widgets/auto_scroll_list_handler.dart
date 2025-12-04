import 'package:flutter/material.dart';

/// Widget wrapper que gerencia o auto-scroll quando novos itens são adicionados à lista.
/// Útil para chats e logs onde a lista deve rolar automaticamente para o final.
class AutoScrollListHandler extends StatefulWidget {
  const AutoScrollListHandler({
    required this.controller,
    required this.itemCount,
    required this.child,
    this.isReverse = false,
    super.key,
  });

  final ScrollController controller;
  final int itemCount;
  final Widget child;
  final bool isReverse;

  @override
  State<AutoScrollListHandler> createState() => _AutoScrollListHandlerState();
}

class _AutoScrollListHandlerState extends State<AutoScrollListHandler> {
  int _lastCount = 0;

  @override
  void didUpdateWidget(covariant AutoScrollListHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.hasClients) return;

      final newCount = widget.itemCount;

      // Se chegaram novas mensagens
      if (newCount > _lastCount) {
        final isNearBottom = widget.isReverse
            ? widget.controller.offset < 80
            : widget.controller.position.maxScrollExtent - widget.controller.offset < 80;

        if (isNearBottom) {
          _scrollToBottom();
        }
      }

      _lastCount = newCount;
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.hasClients) return;

      final position = widget.controller.position;

      if (widget.isReverse) {
        // Evitar animação cancelada (quando já está em 0)
        if (widget.controller.offset == position.minScrollExtent) {
          widget.controller.jumpTo(position.minScrollExtent + 1);
        }

        widget.controller.animateTo(
          position.minScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        widget.controller.animateTo(
          position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
