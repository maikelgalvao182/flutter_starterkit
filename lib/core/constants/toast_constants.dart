import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Constantes para toasts da aplicação
class ToastConstants {
  // Duração padrão das notificações (aumentada para dar tempo de ler)
  static const Duration defaultDuration = Duration(seconds: 6);
  static const Duration animationDuration = Duration(milliseconds: 800);
  
  // Margem superior para fazer o Snackify descer mais
  static const EdgeInsets margin = EdgeInsets.only(
    top: 80, // Aumentado para descer mais durante a animação
    left: 16,
    right: 16,
  );
  
  // Configurações de borda
  static const BorderRadius borderRadius = BorderRadius.all(Radius.circular(12));
  
  // Bordas específicas para cada tipo de toast (mesma cor do texto/ícone) com 45% de opacidade
  static const Border successBorder = Border.fromBorderSide(
    BorderSide(
      color: Color(0x734CAF50), // Verde com 45% de opacidade (0x73 = 115/255 ≈ 45%)
    ),
  );
  
  static const Border errorBorder = Border.fromBorderSide(
    BorderSide(
      color: Color(0x73E53935), // Vermelho com 45% de opacidade
    ),
  );
  
  static const Border infoBorder = Border.fromBorderSide(
    BorderSide(
      color: Color(0x732196F3), // Azul com 45% de opacidade
    ),
  );
  
  static const Border warningBorder = Border.fromBorderSide(
    BorderSide(
      color: Color(0x73FF9800), // Laranja com 45% de opacidade
    ),
  );
  
  // Configurações de cor de fundo para sucesso (verde claro)
  static const Color successBackgroundColor = Color(0xFFF1F8E9); // Verde bem claro
  static const Color successAccentColor = Color(0xFF4CAF50); // Verde para ícone/detalhes
  
  // Configurações de cor de fundo para erro (vermelho claro)
  static const Color errorBackgroundColor = Color(0xFFFFF3F3); // Vermelho bem claro
  static const Color errorAccentColor = Color(0xFFE53935); // Vermelho para ícone/detalhes
  
  // Cor de fundo para info/warning (azul e laranja claros)
  static const Color infoBackgroundColor = Color(0xFFE3F2FD); // Azul bem claro
  static const Color infoAccentColor = Color(0xFF2196F3); // Azul para ícone/detalhes
  
  static const Color warningBackgroundColor = Color(0xFFFFF8E1); // Laranja bem claro
  static const Color warningAccentColor = Color(0xFFFF9800); // Laranja para ícone/detalhes
  
  // Ícones para diferentes tipos de notificação
  static const IconData successIcon = IconsaxPlusLinear.tick_circle;
  static const IconData errorIcon = IconsaxPlusLinear.close_circle;
  static const IconData infoIcon = IconsaxPlusLinear.info_circle;
  static const IconData warningIcon = IconsaxPlusLinear.warning_2;
  
  // Tamanho dos ícones
  static const double iconSize = 24;
  
  // Estilos de texto para sucesso (verde escuro)
  static const TextStyle successTitleStyle = TextStyle(
    color: Color(0xFF2E7D32), // Verde escuro
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle successSubtitleStyle = TextStyle(
    color: Color(0xFF388E3C), // Verde médio
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  // Estilos de texto para erro (vermelho escuro)
  static const TextStyle errorTitleStyle = TextStyle(
    color: Color(0xFFC62828), // Vermelho escuro
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle errorSubtitleStyle = TextStyle(
    color: Color(0xFFD32F2F), // Vermelho médio
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  // Estilos de texto para info (azul escuro)
  static const TextStyle infoTitleStyle = TextStyle(
    color: Color(0xFF1565C0), // Azul escuro
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle infoSubtitleStyle = TextStyle(
    color: Color(0xFF1976D2), // Azul médio
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  // Estilos de texto para warning (laranja escuro)
  static const TextStyle warningTitleStyle = TextStyle(
    color: Color(0xFFEF6C00), // Laranja escuro
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );
  
  static const TextStyle warningSubtitleStyle = TextStyle(
    color: Color(0xFFFF8F00), // Laranja médio
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );
  
  // Configurações de sombra para dar profundidade
  static const List<BoxShadow> boxShadow = [
    BoxShadow(
      color: Color(0x0A000000), // Sombra bem sutil
      offset: Offset(0, 2),
      blurRadius: 8,
    ),
  ];
}
