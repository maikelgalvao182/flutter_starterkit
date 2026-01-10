import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Placeholder - Tela de conta bloqueada
/// TODO: Implementar tela real
class BlockedAccountScreenRouter extends StatelessWidget {
  const BlockedAccountScreenRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Scaffold(
      body: Center(
        child: Text(i18n.translate('blocked_account_placeholder')),
      ),
    );
  }
}
