import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// Diálogo de confirmação para exclusão de conta
class DeleteAccountConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    String? title,
    String? message,
  }) async {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        final i18n = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(title ?? i18n.translate('delete_account_title')),
          content: Text(
            message ??
                i18n.translate('delete_account_message'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: Text(i18n.translate('cancel')),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: Text(i18n.translate('delete')),
            ),
          ],
        );
      },
    );
  }
}
