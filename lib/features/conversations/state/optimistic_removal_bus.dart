import 'package:flutter/foundation.dart';

/// Tiny global bus to broadcast conversation removals (by other user id)
class ConversationRemovalBus {
  ConversationRemovalBus._();
  static final ConversationRemovalBus instance = ConversationRemovalBus._();

  // Set of userIds to hide optimistically
  final ValueNotifier<Set<String>> hiddenUserIds = ValueNotifier<Set<String>>(<String>{});

  void hideUser(String userId) {
    if (userId.isEmpty) return;
    final current = Set<String>.from(hiddenUserIds.value);
    if (current.add(userId)) {
      hiddenUserIds.value = current; // notify listeners
    }
  }

  void clearUser(String userId) {
    final current = Set<String>.from(hiddenUserIds.value);
    if (current.remove(userId)) {
      hiddenUserIds.value = current; // notify listeners
    }
  }
}
