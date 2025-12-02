/// Lightweight in-memory cache to persist last known avatar URLs across
/// widget disposals (e.g., when filter changes rebuild list items).
/// Keyed by brideId (or userId). Prevents null->url transitions that
/// trigger unnecessary image reloads/flicker.
class AvatarMemoryCache {
  static final Map<String, String> _urls = <String, String>{};

  /// Returns the last cached non-empty URL for a user.
  static String? get(String userId) => _urls[userId];

  /// Stores a non-empty URL for a user. Ignores blanks.
  static void set(String userId, String? url) {
    final trimmed = url?.trim();
    if (trimmed == null || trimmed.isEmpty) return;
    // Only log when actually changing to reduce noise.
    if (_urls[userId] != trimmed) {
      _urls[userId] = trimmed;
    }
  }

  /// Clears a single cached URL (optional hygiene, not used currently).
  static void clear(String userId) => _urls.remove(userId);

  /// Clears all cached URLs (e.g., on logout).
  static void clearAll() => _urls.clear();
}
