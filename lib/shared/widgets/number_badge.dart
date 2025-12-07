import 'package:flutter/material.dart';

/// Badge genérico para exibir números com sufixo opcional
/// Pode ser usado para contadores, percentuais, rankings, etc.
/// 
/// Uso:
/// ```dart
/// NumberBadge(
///   value: 75,
///   suffix: '%', // Opcional - para percentuais
///   backgroundColor: Colors.red,
/// )
/// 
/// NumberBadge(
///   value: 5,
///   suffix: '', // Sem sufixo - apenas número
///   backgroundColor: Colors.blue,
/// )
/// 
/// NumberBadge(
///   value: 10,
///   suffix: 'x', // Multiplicador
/// )
/// ```
class NumberBadge extends StatelessWidget {
  const NumberBadge({
    required this.value,
    this.suffix = '',
    this.backgroundColor = const Color(0xFFE53935),
    this.textColor = Colors.white,
    this.fontSize = 10,
    this.fontWeight = FontWeight.w700,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    this.borderColor = Colors.white,
    this.borderWidth = 2,
    super.key,
  });

  final int value;
  final String suffix;
  final Color backgroundColor;
  final Color textColor;
  final double fontSize;
  final FontWeight fontWeight;
  final EdgeInsets padding;
  final Color borderColor;
  final double borderWidth;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: Text(
        '$value$suffix',
        style: TextStyle(
          color: textColor,
          fontSize: fontSize,
          fontWeight: fontWeight,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
