import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';

/// Widget burro que exibe texto formatado de um evento
/// 
/// Exemplo: "João quer jogar futebol em Parque Ibirapuera dia 15/12 às 18:00"
class EventFormattedText extends StatelessWidget {
  const EventFormattedText({
    required this.fullName,
    required this.activityText,
    required this.locationName,
    required this.dateText,
    required this.timeText,
    required this.onLocationTap,
    super.key,
  });

  final String fullName;
  final String activityText;
  final String locationName;
  final String dateText;
  final String timeText;
  final VoidCallback onLocationTap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = GoogleFonts.getFont(
      FONT_PLUS_JAKARTA_SANS,
      fontSize: 18,
      fontWeight: FontWeight.w700,
    );

    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: baseStyle.copyWith(color: GlimpseColors.textSubTitle),
        children: [
          // Nome do criador
          TextSpan(
            text: fullName,
            style: baseStyle.copyWith(color: GlimpseColors.primary),
          ),
          
          // Conectivo
          const TextSpan(text: ' quer '),
          
          // Atividade
          TextSpan(
            text: activityText,
            style: baseStyle.copyWith(color: GlimpseColors.primaryColorLight),
          ),
          
          // Local (clicável, sem sublinhado)
          if (locationName.isNotEmpty) ...[
            const TextSpan(text: ' em '),
            TextSpan(
              text: locationName,
              style: baseStyle.copyWith(color: GlimpseColors.primary),
              recognizer: TapGestureRecognizer()..onTap = onLocationTap,
            ),
          ],
          
          // Data
          if (dateText.isNotEmpty) ...[
            TextSpan(text: dateText.startsWith('dia ') ? ' no ' : ' '),
            TextSpan(text: dateText),
          ],
          
          // Horário
          if (timeText.isNotEmpty) ...[
            const TextSpan(text: ' às '),
            TextSpan(text: timeText),
          ],
        ],
      ),
    );
  }
}
