import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
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
    final i18n = AppLocalizations.of(context);
    final badge = ReviewBadge.fromKey(badgeKey);
    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: badge.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            badge.emoji,
            style: const TextStyle(fontSize: 12, height: 1),
          ),
          const SizedBox(width: 4),
          Text(
            badge.localizedTitle(i18n),
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: GlimpseColors.primaryColorLight,
              height: 1,
            ),
          ),
          if (showCount && count > 0) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: badge.color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: GlimpseColors.primaryColorLight,
                  height: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
