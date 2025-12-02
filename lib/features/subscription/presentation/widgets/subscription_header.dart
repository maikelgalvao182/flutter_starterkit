import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

/// Header do dialog de assinatura VIP
/// 
/// Responsabilidades:
/// - Exibir imagem de fundo
/// - Mostrar título "Wedconnex Pro"
/// - Mostrar subtítulo com benefícios
/// - Botão de fechar no canto superior direito
/// 
/// Uso:
/// ```dart
/// SubscriptionHeader(
///   onClose: () => Navigator.of(context).pop(),
/// )
/// ```
class SubscriptionHeader extends StatelessWidget {

  const SubscriptionHeader({
    required this.onClose, super.key,
  });
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    return Stack(
      children: [
        // Background image with overlay
        Container(
          height: 220,
          width: double.infinity,
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/header_dialog.jpg'),
              fit: BoxFit.cover,
            ),
          ),
          child: ColoredBox(
            color: Colors.black.withOpacity(0.6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Título principal
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    i18n.translate('wedconnex_pro'),
                    style: const TextStyle(
                      fontSize: 26,
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // Subtítulo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    i18n.translate('take_advantage_of_the_benefits_of_being_a_pro'),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Botão de fechar
        Positioned(
          right: 8,
          top: 8,
          child: GestureDetector(
            onTap: onClose,
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.14),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 22,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
