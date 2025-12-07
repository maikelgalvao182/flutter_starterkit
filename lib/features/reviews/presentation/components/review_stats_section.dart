import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/features/reviews/data/models/review_stats_model.dart';

/// Widget que exibe as estatísticas agregadas de reviews no perfil
/// 
/// Features:
/// - Overall rating com estrelas
/// - Total de reviews
/// - Breakdown por critério
class ReviewStatsSection extends StatelessWidget {
  const ReviewStatsSection({
    required this.stats,
    super.key,
  });

  final ReviewStatsModel stats;

  @override
  Widget build(BuildContext context) {
    if (!stats.hasReviews) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: GlimpseStyles.profileSectionPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Avaliações',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontWeight: FontWeight.w700,
              fontSize: 18,
              color: GlimpseColors.primaryColorLight,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Overall Rating
              Row(
                children: [
                  Text(
                    stats.overallRating.toStringAsFixed(1),
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: GlimpseColors.primaryColorLight,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildStars(stats.overallRating),
                        const SizedBox(height: 4),
                        Text(
                          '${stats.totalReviews} ${stats.totalReviews == 1 ? "avaliação" : "avaliações"}',
                          style: GoogleFonts.getFont(
                            FONT_PLUS_JAKARTA_SANS,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: GlimpseColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // Breakdown por critério
              if (stats.ratingsBreakdown.isNotEmpty) ...[
                const SizedBox(height: 20),
                ...stats.ratingsBreakdown.entries.toList().asMap().entries.map((entry) {
                  final isLast = entry.key == stats.ratingsBreakdown.length - 1;
                  return _buildCriterionBar(
                    entry.value.key,
                    entry.value.value,
                    isLast: isLast,
                  );
                }).toList(),
              ],
            ],
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildStars(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        if (index < rating.floor()) {
          return const Icon(
            Iconsax.star1,
            color: Colors.amber,
            size: 20,
          );
        } else if (index < rating) {
          return const Icon(
            Iconsax.star1, // Usando star1 para meia estrela também, já que Iconsax não tem meia
            color: Colors.amber,
            size: 20,
          );
        } else {
          return Icon(
            Iconsax.star,
            color: Colors.grey.shade300,
            size: 20,
          );
        }
      }),
    );
  }

  Widget _buildCriterionBar(String key, double rating, {bool isLast = false}) {
    final label = _getCriterionLabel(key);
    final emoji = _getCriterionEmoji(key);
    final percentage = (rating / 5) * 100;

    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: GlimpseColors.textSecondary,
                  ),
                ),
              ),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: GlimpseColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: rating / 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(GlimpseColors.primary),
              minHeight: 6,
            ),
          ),
        ],
      ),
    );
  }



  String _getCriterionEmoji(String key) {
    switch (key) {
      case 'conversation':
        return '💬';
      case 'energy':
        return '⚡';
      case 'coexistence':
        return '🤝';
      case 'participation':
        return '🎯';
      default:
        return '⭐';
    }
  }

  String _getCriterionLabel(String key) {
    switch (key) {
      case 'conversation':
        return 'Papo & Conexão';
      case 'energy':
        return 'Energia & Presença';
      case 'coexistence':
        return 'Convivência';
      case 'participation':
        return 'Participação';
      default:
        return key;
    }
  }
}
