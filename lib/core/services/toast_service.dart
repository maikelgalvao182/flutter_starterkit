import 'package:flutter/material.dart';

/// Serviço para exibição de toasts e mensagens
class ToastService {
  
  /// Exibe uma notificação de sucesso (verde)
  static void showSuccess({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Colors.green[600]!,
      textColor: Colors.white,
      icon: Icons.check_circle,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Exibe uma notificação de erro (vermelho)
  static void showError({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Colors.red[600]!,
      textColor: Colors.white,
      icon: Icons.error,
      duration: duration ?? const Duration(seconds: 4),
    );
  }
  
  /// Exibe uma notificação de informação (azul)
  static void showInfo({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Colors.blue[600]!,
      textColor: Colors.white,
      icon: Icons.info,
      duration: duration ?? const Duration(seconds: 3),
    );
  }
  
  /// Exibe uma notificação de aviso (laranja)
  static void showWarning({
    required BuildContext context,
    required String title,
    String? subtitle,
    Duration? duration,
  }) {
    _showSnackBar(
      context: context,
      title: title,
      subtitle: subtitle,
      backgroundColor: Colors.orange[600]!,
      textColor: Colors.white,
      icon: Icons.warning,
      duration: duration ?? const Duration(seconds: 3),
    );
  }

  /// Método interno para exibir SnackBar customizado
  static void _showSnackBar({
    required BuildContext context,
    required String title,
    String? subtitle,
    required Color backgroundColor,
    required Color textColor,
    required IconData icon,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}