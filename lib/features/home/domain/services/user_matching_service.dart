class UserMatchingService {
  static List<String> getCommonInterests(
    List<String>? currentUserInterests,
    List<String>? otherUserInterests,
  ) {
    if (currentUserInterests == null || otherUserInterests == null) {
      return [];
    }

    // interseção
    return currentUserInterests
        .toSet()
        .intersection(otherUserInterests.toSet())
        .toList();
  }
}
