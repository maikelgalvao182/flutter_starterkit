import 'package:partiu/features/subscription/services/subscription_monitoring_service.dart';
import 'package:partiu/features/subscription/services/vip_access_service.dart';
import 'package:flutter/widgets.dart';

/// Centraliza checagens de acesso VIP.
class VipAccessHelper {
  VipAccessHelper._();
  /// Usa SubscriptionMonitoringService como fonte da verdade para acesso VIP.
  /// Evita dependência direta no UserModel().userIsVip.
  static bool isVip() => SubscriptionMonitoringService.hasVipAccess;

  /// Garante acesso VIP ou apresenta o paywall. Retorna true se acesso liberado.
  /// Use em ações gated: botões de ver quem curtiu, ver perfis, etc.
  static Future<bool> ensureVip(BuildContext context, {String? source}) async {
    return VipAccessService.checkAccessOrShowDialog(context, source: source);
  }

  /// Força verificação imediata com RevenueCat/monitoramento.
  static Future<void> forceCheck() => SubscriptionMonitoringService.refresh();

  /// Atualiza informações de assinatura e propaga listeners.
  static Future<void> refreshCustomerInfo() => SubscriptionMonitoringService.refresh();

  /// Observa mudanças de acesso VIP em tempo real.
  static void addListener(Function(bool hasAccess) listener) =>
      SubscriptionMonitoringService.addVipListener(listener);

  /// Remove listener previamente registrado.
  static void removeListener(Function(bool hasAccess) listener) =>
      SubscriptionMonitoringService.removeVipListener(listener);
}
