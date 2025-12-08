import 'package:flutter/cupertino.dart';

/// Dialog Cupertino reutilizável com botões lado a lado
/// 
/// Estilo iOS nativo com:
/// - Título e mensagem centralizados
/// - Botões com mesma importância visual
/// - Texto azul em ambos os botões
/// - Minúsculas por padrão
class GlimpseCupertinoDialog {
  /// Mostra dialog de confirmação com dois botões
  /// 
  /// Retorna true se confirmado, false se cancelado, null se fechado sem ação
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmText,
    required String cancelText,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            textStyle: const TextStyle(color: CupertinoColors.activeBlue),
            child: Text(cancelText.toLowerCase()),
          ),
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(true),
            textStyle: const TextStyle(color: CupertinoColors.activeBlue),
            child: Text(confirmText.toLowerCase()),
          ),
        ],
      ),
    );
  }
  
  /// Mostra dialog de confirmação com ação destrutiva (texto vermelho)
  /// 
  /// Retorna true se confirmado, false se cancelado, null se fechado sem ação
  static Future<bool?> showDestructive({
    required BuildContext context,
    required String title,
    required String message,
    required String destructiveText,
    required String cancelText,
  }) {
    return showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          CupertinoDialogAction(
            onPressed: () => Navigator.of(context).pop(false),
            textStyle: const TextStyle(color: CupertinoColors.activeBlue),
            child: Text(cancelText.toLowerCase()),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(destructiveText.toLowerCase()),
          ),
        ],
      ),
    );
  }
}
