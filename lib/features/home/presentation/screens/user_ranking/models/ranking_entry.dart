class RankingEntry {
  const RankingEntry({
    required this.userId,
    required this.position,
    required this.overallRating,
    required this.totalReviews,
    required this.fullName,
    required this.jobTitle,
    this.photoUrl,
    this.locality,
    this.state,
    this.isVerified = false,
    this.isCurrentUser = false,
    this.distanceKm,
  });

  factory RankingEntry.fromMap(Map<String, dynamic> map, {bool isCurrentUser = false}) {
    return RankingEntry(
      userId: map['userId'] ?? '',
      position: (map['position'] ?? 0) as int,
      overallRating: (map['overallRating'] ?? 0.0).toDouble(),
      totalReviews: (map['totalReviews'] ?? 0) as int,
      fullName: map['fullName'] ?? '',
      photoUrl: map['photoUrl'],
      jobTitle: map['jobTitle'] ?? 'Vendor',
      locality: map['locality'],
      state: map['state'],
      isVerified: map['isVerified'] == true,
      isCurrentUser: isCurrentUser,
      distanceKm: map['distance'] != null ? (map['distance'] as num).toDouble() : null,
    );
  }

  final String userId;
  final int position;
  final double overallRating;
  final int totalReviews;
  final String fullName;
  final String? photoUrl;
  final String jobTitle;
  final String? locality;
  final String? state;
  final bool isVerified;
  final bool isCurrentUser;
  final double? distanceKm; // apenas para ranking local
}
