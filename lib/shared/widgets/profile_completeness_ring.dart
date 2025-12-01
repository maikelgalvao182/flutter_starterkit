import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';

/// Widget que exibe um anel de completude do perfil
class ProfileCompletenessRing extends StatelessWidget {
  const ProfileCompletenessRing({
    super.key,
    required this.size,
    required this.strokeWidth,
    required this.percentage,
    required this.child,
    this.backgroundColor,
    this.progressColor,
    this.showPercentage = true,
  });

  final double size;
  final double strokeWidth;
  final int percentage;
  final Widget child;
  final Color? backgroundColor;
  final Color? progressColor;
  final bool showPercentage;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Anel de progresso
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: percentage / 100.0,
            strokeWidth: strokeWidth,
            backgroundColor: backgroundColor ?? GlimpseColors.lightTextField,
            valueColor: AlwaysStoppedAnimation<Color>(
              progressColor ?? GlimpseColors.primary,
            ),
          ),
        ),
        
        // Conteúdo central
        child,
        
        // Porcentagem (opcional)
        if (showPercentage && percentage < 100)
          Positioned(
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: progressColor ?? GlimpseColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$percentage%',
                style: GoogleFonts.getFont(
                  FONT_PLUS_JAKARTA_SANS,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
      ],
    );
  }
}