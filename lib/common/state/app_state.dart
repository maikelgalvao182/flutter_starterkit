import 'package:partiu/core/models/user.dart' show User;
import 'package:partiu/core/services/session_cleanup_service.dart';
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
  // AppState agora é gerenciado pelo AuthSyncService
  // Streams de notificações podem ser adicionadas separadamente quando necessário

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
    // Implementa logout robusto usando SessionCleanupService
    try {
      final sessionCleanupService = SessionCleanupService();
      await sessionCleanupService.performLogout();
    } catch (e) {
      // Fallback para reset básico se houver problemas
      reset();
    }
  }

  static int get totalUnread =>
      unreadNotifications.value + unreadMessages.value + unreadLikes.value;

  // ==================== CONVENIENCE ====================
  static String? get currentUserId => currentUser.value?.userId;
  static bool get isLoggedIn => currentUser.value != null;
}