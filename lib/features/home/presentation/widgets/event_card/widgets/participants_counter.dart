import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Widget burro que exibe contador de participantes em formato chip
class ParticipantsCounter extends StatelessWidget {
  const ParticipantsCounter({
    required this.count,
    required this.singularLabel,
    required this.pluralLabel,
    super.key,
  });

  final int count;
  final String singularLabel;
  final String pluralLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: GlimpseColors.primaryLight,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(
        '$count ${count == 1 ? singularLabel : pluralLabel}',
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: GlimpseColors.primaryColorLight,
        ),
      ),
    );
  }
}
