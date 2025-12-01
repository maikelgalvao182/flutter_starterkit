import 'package:flutter/material.dart';

/// Serviço para controle de acesso VIP
class VipAccessService {
  VipAccessService._();

  /// Verifica se o usuário tem acesso VIP ou mostra diálogo
  static Future<bool> checkAccessOrShowDialog(
    BuildContext context, {
    required String source,
  }) async {
    // TODO: Implementar lógica real de verificação VIP
    // Por agora, sempre retorna true (acesso liberado)
    return true;
  }
}