import 'dart:async';
import 'package:flutter/material.dart';

/// Mixin para gerenciar StreamSubscriptions com cleanup automático em dispose().
///
/// Uso:
/// ```dart
/// class _MyState extends State<MyWidget> with StreamSubscriptionMixin {
///   @override
///   void initState() {
///     super.initState();
///     addSubscription(myStream.listen((event) { /* ... */ }));
///   }
/// }
/// ```
mixin StreamSubscriptionMixin<T extends StatefulWidget> on State<T> {
  final List<StreamSubscription<dynamic>> _subscriptions = <StreamSubscription<dynamic>>[];

  /// Registra uma subscription para cancelamento automático.
  @protected
  void addSubscription(StreamSubscription<dynamic> subscription) {
    _subscriptions.add(subscription);
  }

  /// Cancela todas as subscriptions registradas.
  @override
  @mustCallSuper
  void dispose() {
    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {
        // já cancelado ou stream encerrada
      }
    }
    _subscriptions.clear();
    super.dispose();
  }
}
