/// Modelo de avaliação de usuário
/// 
/// Representa uma review feita por um usuário sobre outro
class Review {
  const Review({
    required this.id,
    required this.reviewerId,
    required this.revieweeId,
    required this.announcementId,
    required this.overallRating,
    required this.createdAt,
    required this.userJobTitle,
    this.comment,
    this.detailedRatings = const {},
  });

  final String id;
  final String reviewerId;
  final String revieweeId;
  final String announcementId;
  final double overallRating;
  final String? comment;
  final Map<String, double> detailedRatings;
  final DateTime createdAt;
  final String userJobTitle;

  /// Labels para critérios de avaliação (fallback se tradução falhar)
  static const Map<String, String> criteriaLabels = {
    'punctuality': 'Pontualidade',
    'appearance': 'Postura / Aparência',
    'communication': 'Comunicação e Simpatia',
    'briefing_delivery': 'Entrega do Briefing',
    'teamwork': 'Trabalho em Equipe',
    'instruction_clarity': 'Clareza nas Instruções',
    'payment_timeliness': 'Pagamento no Prazo',
    'communication_support': 'Comunicação e Suporte',
  };

  factory Review.fromFirestore(Map<String, dynamic> data, String id) {
    // Extrai ratings detalhados
    final Map<String, double> detailedRatings = {};
    if (data['detailedRatings'] != null) {
      final ratings = data['detailedRatings'] as Map<String, dynamic>;
      ratings.forEach((key, value) {
        if (value is num) {
          detailedRatings[key] = value.toDouble();
        }
      });
    }

    return Review(
      id: id,
      reviewerId: data['reviewerId'] as String? ?? '',
      revieweeId: data['revieweeId'] as String? ?? '',
      announcementId: data['announcementId'] as String? ?? '',
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0.0,
      comment: data['comment'] as String?,
      detailedRatings: detailedRatings,
      createdAt: data['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              (data['createdAt'] as num).toInt() * 1000,
            )
          : DateTime.now(),
      userJobTitle: data['userJobTitle'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'reviewerId': reviewerId,
      'revieweeId': revieweeId,
      'announcementId': announcementId,
      'overallRating': overallRating,
      if (comment != null) 'comment': comment,
      'detailedRatings': detailedRatings,
      'createdAt': createdAt.millisecondsSinceEpoch ~/ 1000,
      'userJobTitle': userJobTitle,
    };
  }

  Review copyWith({
    String? id,
    String? reviewerId,
    String? revieweeId,
    String? announcementId,
    double? overallRating,
    String? comment,
    Map<String, double>? detailedRatings,
    DateTime? createdAt,
    String? userJobTitle,
  }) {
    return Review(
      id: id ?? this.id,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      announcementId: announcementId ?? this.announcementId,
      overallRating: overallRating ?? this.overallRating,
      comment: comment ?? this.comment,
      detailedRatings: detailedRatings ?? this.detailedRatings,
      createdAt: createdAt ?? this.createdAt,
      userJobTitle: userJobTitle ?? this.userJobTitle,
    );
  }
}
