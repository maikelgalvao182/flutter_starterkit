import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dating_app/constants/constants.dart';

/// Tag de posição que sobrepõe o avatar na parte inferior centralizada
/// 
/// Variações:
/// - Padrão: fundo preto, texto branco, borda branca
/// - Podium: fundo colorido (ouro/prata/bronze), texto branco, borda branca
class PositionTag extends StatelessWidget {
  const PositionTag({
    required this.position,
    super.key,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderColor,
  });

  final int position;
  final Color? backgroundColor;
  final Color textColor;
  final Color? borderColor;

  String get _positionText => '${position}º';

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.black,
        borderRadius: BorderRadius.circular(8), // Borda circular (metade da altura)
        border: Border.all(
          color: borderColor ?? Colors.white,
          width: 2,
        ),
      ),
      child: Text(
        _positionText,
        style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: textColor,
          height: 0,
        ),
      ),
    );
  }
}
