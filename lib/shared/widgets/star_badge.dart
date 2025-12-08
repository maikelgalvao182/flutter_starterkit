import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Badge com estrela e rating
/// 
/// ✅ const constructor para evitar rebuilds desnecessários
class StarBadge extends StatelessWidget {
  const StarBadge({
    required this.rating,
    super.key,
  });

  final double rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
      decoration: BoxDecoration(
        color: GlimpseColors.bgColorLight,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Iconsax.star1,
            size: 16,
            color: Color(0xFFFFB800),
          ),
          const SizedBox(width: 3),
          Text(
            rating.toStringAsFixed(1),
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.primaryColorLight,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}
