import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Placeholder - Tela de atualização de localização
/// TODO: Implementar tela real
class UpdateLocationScreenRouter extends StatelessWidget {
  const UpdateLocationScreenRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Text(i18n.translate('update_location_placeholder')),
      ),
    );
  }
}
