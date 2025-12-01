import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// 🎯 Idade do usuário reativa
/// Reconstrói APENAS quando a idade muda no Firestore
/// 
/// Usage:
/// ```dart
/// ReactiveUserAge(userId: 'abc123')
/// ReactiveUserAge(userId: 'abc123', suffix: ' anos')
/// ReactiveUserAge(userId: 'abc123', style: TextStyle(color: Colors.grey))
/// ```
class ReactiveUserAge extends StatefulWidget {
  const ReactiveUserAge({
    required this.userId,
    super.key,
    this.style,
    this.suffix = '',
    this.fallback = '--',
  });

  final String userId;
  final TextStyle? style;
  final String suffix;
  final String fallback;

  @override
  State<ReactiveUserAge> createState() => _ReactiveUserAgeState();
}

class _ReactiveUserAgeState extends State<ReactiveUserAge> {
  late ValueNotifier<int?> _ageNotifier;

  @override
  void initState() {
    super.initState();
    _ageNotifier = UserStore.instance.getAgeNotifier(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ReactiveUserAge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _ageNotifier = UserStore.instance.getAgeNotifier(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int?>(
      valueListenable: _ageNotifier,
      builder: (context, age, _) {
        return Text(
          age != null ? '$age${widget.suffix}' : widget.fallback,
          style: widget.style,
        );
      },
    );
  }
}