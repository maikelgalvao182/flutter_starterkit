import 'package:partiu/core/services/auth_state_service.dart';

/// Central provider for accessing the current user's id.
/// Helps reduce scattered direct calls to SessionManager/AuthStateService for userId
class CurrentUserIdProvider {
  /// Returns the authenticated user's UID or 'guest' when not authenticated.
  /// This prevents cache pollution and ensures proper separation between
  /// authenticated and guest feeds.
  static String get id {
    final uid = AuthStateService.instance.userId;
    if (uid == null || uid.isEmpty) return 'guest';
    return uid;
  }
}
