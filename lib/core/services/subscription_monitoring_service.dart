import 'package:flutter/foundation.dart';

/// Service para monitorar status de assinatura
/// TODO: Implementar funcionalidade completa com RevenueCat
class SubscriptionMonitoringService extends ChangeNotifier {
  static final SubscriptionMonitoringService instance = SubscriptionMonitoringService._internal();
  factory SubscriptionMonitoringService() => instance;
  SubscriptionMonitoringService._internal();

  bool _isVip = false;

  bool get isVip => _isVip;
  bool get hasVipAccess => _isVip;

  /// Inicializa o serviço e verifica status de assinatura
  Future<void> initialize() async {
    // TODO: Implementar verificação real com RevenueCat
    _isVip = false;
    notifyListeners();
  }

  /// Atualiza status de assinatura
  void updateVipStatus(bool isVip) {
    if (_isVip != isVip) {
      _isVip = isVip;
      notifyListeners();
    }
  }
}
