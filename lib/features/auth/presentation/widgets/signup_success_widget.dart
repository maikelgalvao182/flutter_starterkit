import 'package:partiu/core/constants/text_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';

/// Widget de tela de sucesso do cadastro
/// Mostra ícone de check verde e mensagem de boas-vindas
class SignupSuccessWidget extends StatelessWidget {
  const SignupSuccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final minHeight = (screenHeight - 180).clamp(0.0, double.infinity);

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Ícone de sucesso
          Center(
            child: Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: Colors.green,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                color: Colors.white,
                size: 42,
              ),
            ),
          ),
          
          const SizedBox(height: 40),
          
          // Título
          Text(
            i18n.translate('account_created_successfully'),
            textAlign: TextAlign.center,
            style: TextStyles.successTitle,
          ),
          
          const SizedBox(height: 16),
          
          // Subtítulo
          Text(
            i18n.translate('welcome_to_wedconnex_your_journey_starts_now'),
            textAlign: TextAlign.center,
            style: TextStyles.successSubtitle,
          ),
        ],
      ),
    );
  }
}
