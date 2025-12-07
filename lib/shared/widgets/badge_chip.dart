import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/domain/constants/review_badges.dart';

/// Widget compartilhado para exibir badge com contador
class BadgeChip extends StatelessWidget {
  const BadgeChip({
    required this.badgeKey,
    required this.count,
    super.key,
    this.showCount = true,
  });

  final String badgeKey;
  final int count;
  final bool showCount;

  @override
  Widget build(BuildContext context) {
    final badge = ReviewBadge.fromKey(badgeKey);
    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 14, height: 1),
          ),
          const SizedBox(width: 6),
          Text(
            badge.title,
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: GlimpseColors.primaryColorLight,
              height: 1,
            ),
          ),
          if (showCount && count > 0) ...[
            const SizedBox(width: 6),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: badge.color.withOpacity(0.17),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(
                '$count',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: GlimpseColors.primaryColorLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
