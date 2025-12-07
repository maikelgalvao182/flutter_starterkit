import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/features/reviews/domain/constants/review_badges.dart';

class ReviewBadgesSection extends StatelessWidget {
  const ReviewBadgesSection({
    required this.badgesCount,
    super.key,
  });

  final Map<String, int> badgesCount;

  @override
  Widget build(BuildContext context) {
    if (badgesCount.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: GlimpseStyles.profileSectionPadding,
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Elogios mais recebidos',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: GlimpseColors.primaryColorLight,
            ),
          ),
          _buildTopBadges(),
        ],
      ),
    );
  }

  Widget _buildTopBadges() {
    // Ordena badges por count
    final sortedBadges = badgesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: sortedBadges.map((entry) {
        final badge = ReviewBadge.fromKey(entry.key);
        if (badge == null) return const SizedBox.shrink();

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: GlimpseColors.lightTextField,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                badge.emoji,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(width: 8),
              Text(
                badge.title,
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: GlimpseColors.primaryColorLight,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: GlimpseColors.primaryColorLight.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${entry.value}',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: GlimpseColors.primaryColorLight,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
