import 'package:flutter/material.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// 🎯 Bio do usuário reativa
/// Reconstrói APENAS quando a bio muda no Firestore
/// 
/// Usage:
/// ```dart
/// ReactiveUserBio(userId: 'abc123')
/// ReactiveUserBio(userId: 'abc123', maxLines: 3)
/// ```
class ReactiveUserBio extends StatefulWidget {
  const ReactiveUserBio({
    required this.userId,
    super.key,
    this.style,
    this.maxLines,
    this.overflow = TextOverflow.ellipsis,
    this.textAlign,
    this.fallback = 'Sem bio',
  });

  final String userId;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final TextAlign? textAlign;
  final String fallback;

  @override
  State<ReactiveUserBio> createState() => _ReactiveUserBioState();
}

class _ReactiveUserBioState extends State<ReactiveUserBio> {
  late ValueNotifier<String?> _bioNotifier;

  @override
  void initState() {
    super.initState();
    _bioNotifier = UserStore.instance.getBioNotifier(widget.userId);
  }

  @override
  void didUpdateWidget(covariant ReactiveUserBio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _bioNotifier = UserStore.instance.getBioNotifier(widget.userId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<String?>(
      valueListenable: _bioNotifier,
      builder: (context, bio, _) {
        if (bio == null || bio.isEmpty) {
          return Text(
            widget.fallback,
            style: widget.style?.copyWith(fontStyle: FontStyle.italic) ?? 
                   const TextStyle(fontStyle: FontStyle.italic, color: Colors.grey),
          );
        }

        return Text(
          bio,
          style: widget.style,
          maxLines: widget.maxLines,
          overflow: widget.overflow,
          textAlign: widget.textAlign,
        );
      },
    );
  }
}