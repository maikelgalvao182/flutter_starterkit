import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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
        return AlertDialog(
          title: Text(title ?? 'Excluir Conta'),
          content: Text(
            message ??
                'Tem certeza que deseja excluir sua conta? Esta ação não pode ser desfeita.',
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => context.pop(false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => context.pop(true),
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Excluir'),
            ),
          ],
        );
      },
    );
  }
}
