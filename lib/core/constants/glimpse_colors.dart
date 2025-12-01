import 'package:flutter/material.dart';

/// Constantes de cores utilizadas no aplicativo
class GlimpseColors {
  // Cores do tema claro
  static const Color primary = Color(0xFF00AFF0);
  static const Color primaryLight = Color(0xFFDFF6FF);
  static const Color primaryColorLight = Color(0xFF0a0a0a);
  static const Color borderColorLight = Color(0xFFd4d4d4);
  static const Color subtitleTextColorLight = Color(0xFF4D4B4A);
  static const Color descriptionTextColorLight = Color(0xFF979491);
  static const Color lightTextField = Color(0xFFF8F8F8);
  static const Color textColorLight = Color(0xFF201913);
  static const Color disabledButtonColorLight = Color(0xFFE0E0E0);

  // Cores do tema escuro
  static const Color primaryColorDark = Color(0xFF9B6BBE);
  static const Color borderColorDark = Color(0xFF24211F);
  static const Color descriptionTextColorDark = Color(0xFFB0B0B0);
  static const Color darkTextField = Color(0xFF1B1816);
  static const Color textColorDark = Colors.white;
  static const Color bgColorDark = Color(0XFF110D0A);
  static const Color bgColorLight = Color(0XFFFFFFFF);

  // Cor de ação genérica
  static const Color actionColor = Color(0xFFFF5046);

  // Chips/Tags colors
  static const Color locationChipBackground = lightTextField; // Fundo claro neutro
  static const Color locationChipText = Color(0xFF0a0a0a); // Preto
  static const Color visitsChipBackground = lightTextField; // Fundo claro neutro
  static const Color visitsChipText = Color(0xFF0a0a0a); // Preto

  // Offer cards colors (mesmas cores dos cards de exibição)
  static const Color offerCardGreen = Color(0xFF4CAF50);
  static const Color offerCardBlue = Color(0xFF2196F3);
  static const Color offerCardPurple = Color(0xFF9C27B0);

  // Estados / feedback
  static const Color dangerRed = Color(0xFFD32F2F);
  static const Color warningColor = Color(0xFFEF6C00);

  // Aliases para compatibilidade com componentes existentes
  static const Color primaryColor = primaryColorLight;
  static const Color textPrimary = textColorLight;
  static const Color textSecondary = subtitleTextColorLight;
  static const Color backgroundSecondary = lightTextField;
  static const Color borderColor = borderColorLight;
}
