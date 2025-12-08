import 'package:flutter/material.dart';

/// Diálogo de confirmação para exclusão de conta
class DeleteAccountConfirmDialog {
  static Future<bool?> show(
    BuildContext context, {
    required IconData iconData,
    required String title,
    required String message,
    required String negativeText,
    required String positiveText,
    required VoidCallback negativeAction,
    required VoidCallback positiveAction,
  }) async {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(
                iconData,
                color: Colors.red,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF6F6E6E),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: negativeAction,
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF6F6E6E),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                negativeText,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            TextButton(
              onPressed: positiveAction,
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                positiveText,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
