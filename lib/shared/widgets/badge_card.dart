import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/domain/constants/review_badges.dart';

/// Card vertical para exibir badge no perfil
class BadgeCard extends StatelessWidget {
  const BadgeCard({
    required this.badgeKey,
    required this.count,
    super.key,
  });

  final String badgeKey;
  final int count;

  @override
  Widget build(BuildContext context) {
    final badge = ReviewBadge.fromKey(badgeKey);
    if (badge == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: badge.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: badge.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Emoji com contador sobreposto
          Stack(
            clipBehavior: Clip.none,
            children: [
              Text(
                badge.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              Positioned(
                bottom: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: GlimpseColors.primaryColorLight,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Título
          Text(
            badge.title,
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: GlimpseColors.primaryColorLight,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
