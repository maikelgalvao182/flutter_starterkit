import 'package:partiu/core/helpers/toast_messages_helper.dart';
import 'package:partiu/shared/services/toast_service.dart';
import 'package:flutter/material.dart';

/// Success Dialog - Agora usando ToastService
void successDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) {
  // Executa ação positiva se fornecida
  if (positiveAction != null) {
    positiveAction();
  }
  
  final tm = ToastMessagesHelper(context);
  
  // Exibe notificação de sucesso
  ToastService.showSuccessDialog(
    context: context,
    title: title ?? tm.success,
    message: message,
  );
}

/// Error Dialog - Agora usando ToastService
void errorDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) {
  // Executa ação positiva se fornecida
  if (positiveAction != null) {
    positiveAction();
  }
  
  final tm = ToastMessagesHelper(context);
  
  // Exibe notificação de erro
  ToastService.showErrorDialog(
    context: context,
    title: title ?? tm.error,
    message: message,
  );
}

/// Confirm Dialog - Apenas executa a ação sem mostrar toast automático
/// (O toast de resultado deve ser mostrado pela própria ação)
void confirmDialog(
  BuildContext context, {
  required String message,
  Widget? icon,
  String? title,
  String? negativeText,
  VoidCallback? negativeAction,
  String? positiveText,
  VoidCallback? positiveAction,
}) {
  // Apenas executa ação positiva se fornecida
  // NÃO mostra toast automático - a action deve mostrar seu próprio toast
  if (positiveAction != null) {
    positiveAction();
  }
}
