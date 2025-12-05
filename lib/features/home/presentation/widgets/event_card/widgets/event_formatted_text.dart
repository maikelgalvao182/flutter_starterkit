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
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // Parte 1: Nome + Atividade
        Text(
          fullName,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.primary,
          ),
        ),
        Text(
          ' quer ',
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textSubTitle,
          ),
        ),
        Text(
          activityText,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.primaryColorLight,
          ),
        ),
        
        // Parte 2: Local (clicável)
        if (locationName.isNotEmpty) ...[
          Text(
            ' em ',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.textSubTitle,
            ),
          ),
          GestureDetector(
            onTap: onLocationTap,
            child: Text(
              locationName,
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: GlimpseColors.primary,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],

        // Parte 3: Data
        if (dateText.isNotEmpty) ...[
          Text(
            dateText.startsWith('dia ') ? ' no ' : ' ',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.textSubTitle,
            ),
          ),
          Text(
            dateText,
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.textSubTitle,
            ),
          ),
        ],

        // Parte 4: Horário
        if (timeText.isNotEmpty) ...[
          Text(
            ' às ',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.textSubTitle,
            ),
          ),
          Text(
            timeText,
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: GlimpseColors.textSubTitle,
            ),
          ),
        ],
      ],
    );
  }
}
