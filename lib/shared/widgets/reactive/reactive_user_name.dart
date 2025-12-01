import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// Widget reativo que exibe o nome do usuário
/// Reconstrói APENAS quando o nome específico do userId muda
class ReactiveUserName extends StatefulWidget {
  const ReactiveUserName({
    required this.userId,
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.fallback,
    this.shortenName = false,
  });

  final String userId;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final String? fallback;
  final bool shortenName; // Se true, mostra apenas o primeiro nome

  @override
  State<ReactiveUserName> createState() => _ReactiveUserNameState();
}

class _ReactiveUserNameState extends State<ReactiveUserName> {
  late ValueNotifier<String?> _nameNotifier;

  @override
  void initState() {
    super.initState();
    _nameNotifier = UserStore.instance.getNameNotifier(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ReactiveUserName oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _nameNotifier = UserStore.instance.getNameNotifier(widget.userId);
    }
  }

  String _processName(String? name) {
    if (name == null || name.isEmpty) return widget.fallback ?? '';

    if (widget.shortenName) {
      final parts = name.trim().split(RegExp(r'\s+'));
      return parts.isNotEmpty ? parts.first : name;
    }

    return name;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.userId.isEmpty) {
      return Text(
        _processName(null),
        style: widget.style,
        maxLines: widget.maxLines,
        overflow: widget.overflow,
      );
    }

    return ValueListenableBuilder<String?>(
      valueListenable: _nameNotifier,
      builder: (context, name, _) {
        return Text(
          _processName(name),
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
        );
      },
    );
  }
}