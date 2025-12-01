import 'package:partiu/core/models/user.dart' show User;
import 'package:flutter/foundation.dart';

/// Estado global reativo da aplicação usando ValueNotifiers.
/// Seguro, simples e nativo do Flutter.
class AppState {
  AppState._();

  // ==================== USER STATE ====================
  static final currentUser = ValueNotifier<User?>(null);
  static final isVerified = ValueNotifier<bool>(false);

  // ==================== COUNTERS ====================
  static final unreadNotifications = ValueNotifier<int>(0);
  static final unreadMessages = ValueNotifier<int>(0);
  static final unreadLikes = ValueNotifier<int>(0);

  // ==================== UI STATE ====================
  static final currentRoute = ValueNotifier<String>('/');
  static final isAppInBackground = ValueNotifier<bool>(false);

  // ==================== LIFECYCLE ====================
  static void init({
    required Stream<User?> userStream,
    required Stream<int> notificationsStream,
    required Stream<int> messagesStream,
    required Stream<int> likesStream,
  }) {
    userStream.listen((user) {
      currentUser.value = user;
      isVerified.value = user?.isVerified ?? false;
    });
    notificationsStream.listen((n) => unreadNotifications.value = n);
    messagesStream.listen((n) => unreadMessages.value = n);
    likesStream.listen((n) => unreadLikes.value = n);
  }

  static void reset() {
    currentUser.value = null;
    isVerified.value = false;
    unreadNotifications.value = 0;
    unreadMessages.value = 0;
    unreadLikes.value = 0;
    currentRoute.value = '/';
    isAppInBackground.value = false;
  }

  static Future<void> signOut() async {
    // TODO: Implementar logout real com Firebase Auth
    reset();
  }

  static int get totalUnread =>
      unreadNotifications.value + unreadMessages.value + unreadLikes.value;

  // ==================== CONVENIENCE ====================
  static String? get currentUserId => currentUser.value?.userId;
  static bool get isLoggedIn => currentUser.value != null;
}