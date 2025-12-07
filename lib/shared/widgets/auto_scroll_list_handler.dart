import 'dart:async';
import 'package:flutter/material.dart';

/// Widget wrapper que gerencia o auto-scroll quando novos itens são adicionados.
/// Ideal para chats e feeds onde a lista deve rolar automaticamente para o final.
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
  bool _isAnimating = false;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _lastCount = widget.itemCount;
  }

  @override
  void didUpdateWidget(AutoScrollListHandler oldWidget) {
    super.didUpdateWidget(oldWidget);

    final newCount = widget.itemCount;

    // Detecta incremento real
    if (newCount > _lastCount) {
      debugPrint("📊 [AutoScroll] Contagem mudou: $_lastCount -> $newCount");
      
      // Debounce para evitar múltiplos triggers
      _debounceTimer?.cancel();
      _debounceTimer = Timer(const Duration(milliseconds: 100), () {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleAutoScroll();
        });
      });
    }

    _lastCount = newCount;
  }

  void _handleAutoScroll() {
    if (!mounted || !widget.controller.hasClients || _isAnimating) {
      debugPrint("⏸️ [AutoScroll] Abortado (mounted=$mounted, hasClients=${widget.controller.hasClients}, animating=$_isAnimating)");
      return;
    }

    final position = widget.controller.position;

    final bool isNearBottom = widget.isReverse
        ? (widget.controller.offset < 120)
        : (position.maxScrollExtent - widget.controller.offset < 120);

    if (!isNearBottom) {
      debugPrint("⏳ [AutoScroll] Usuário não está no fim, NÃO auto-scroll");
      return;
    }

    _isAnimating = true;
    debugPrint("🔥 [AutoScroll] DISPARADO! Animando para ${widget.isReverse ? 'minScrollExtent' : 'maxScrollExtent'}");

    final target = widget.isReverse
        ? position.minScrollExtent
        : position.maxScrollExtent;

    widget.controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    ).then((_) {
      _isAnimating = false;
      debugPrint("✅ [AutoScroll] Animação concluída");
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
