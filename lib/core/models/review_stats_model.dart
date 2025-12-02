/// Estatísticas agregadas de avaliações
/// 
/// Contém métricas calculadas a partir de múltiplas reviews
class ReviewStats {
  const ReviewStats({
    required this.totalReviews,
    required this.overallRating,
    this.ratingsBreakdown = const {},
  });

  final int totalReviews;
  final double overallRating;
  final Map<String, double> ratingsBreakdown;

  factory ReviewStats.fromReviews(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return const ReviewStats(
        totalReviews: 0,
        overallRating: 0.0,
      );
    }

    double totalOverallRating = 0.0;
    final Map<String, List<double>> criteriaRatings = {};

    for (final review in reviews) {
      // Overall rating
      final overallRating = (review['overallRating'] as num?)?.toDouble() ?? 0.0;
      totalOverallRating += overallRating;

      // Detailed ratings
      if (review['detailedRatings'] != null) {
        final detailed = review['detailedRatings'] as Map<String, dynamic>;
        detailed.forEach((criterion, rating) {
          if (rating is num) {
            criteriaRatings.putIfAbsent(criterion, () => []);
            criteriaRatings[criterion]!.add(rating.toDouble());
          }
        });
      }
    }

    // Calcula médias
    final breakdown = <String, double>{};
    criteriaRatings.forEach((criterion, ratings) {
      if (ratings.isNotEmpty) {
        final average = ratings.reduce((a, b) => a + b) / ratings.length;
        breakdown[criterion] = double.parse(average.toStringAsFixed(1));
      }
    });

    return ReviewStats(
      totalReviews: reviews.length,
      overallRating: double.parse(
        (totalOverallRating / reviews.length).toStringAsFixed(1),
      ),
      ratingsBreakdown: breakdown,
    );
  }

  factory ReviewStats.fromFirestore(Map<String, dynamic> data) {
    final Map<String, double> breakdown = {};
    if (data['ratingsBreakdown'] != null) {
      final ratings = data['ratingsBreakdown'] as Map<String, dynamic>;
      ratings.forEach((key, value) {
        if (value is num) {
          breakdown[key] = value.toDouble();
        }
      });
    }

    return ReviewStats(
      totalReviews: data['totalReviews'] as int? ?? 0,
      overallRating: (data['overallRating'] as num?)?.toDouble() ?? 0.0,
      ratingsBreakdown: breakdown,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalReviews': totalReviews,
      'overallRating': overallRating,
      'ratingsBreakdown': ratingsBreakdown,
    };
  }

  bool get isEmpty => totalReviews == 0;
}
