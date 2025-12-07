import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/shared/widgets/badge_card.dart';

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
      padding: const EdgeInsets.only(
        left: 20,
        right: 20,
      ),
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
          const SizedBox(height: 12),
          _buildBadgesGrid(),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid() {
    // Ordena badges por count
    final sortedBadges = badgesCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 0.95,
      ),
      itemCount: sortedBadges.length,
      itemBuilder: (context, index) {
        final entry = sortedBadges[index];
        return BadgeCard(
          badgeKey: entry.key,
          count: entry.value,
        );
      },
    );
  }
}
