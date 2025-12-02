import 'dart:developer' as dev;
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:partiu/core/constants/constants.dart';

/// Serviço de monitoramento extremamente seguro e minimalista.
/// Responsável por detectar **somente** mudanças REAIS no acesso VIP.
///
/// NADA de loops, timers, repetições, lógica duplicada.
/// Não causa rebuilds globais.
/// Notifica apenas quando o status VIP mudar de verdade.
class SubscriptionMonitoringService {
  static const String _entitlementId = REVENUE_CAT_ENTITLEMENT_ID;

  static CustomerInfo? _lastCustomerInfo;
  static bool _initialized = false;

  /// Listeners que querem saber apenas mudanças no status VIP.
  static final Set<void Function(bool hasAccess)> _vipListeners = {};

  /// Inicializa serviço uma única vez
  static Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    dev.log('[SubscriptionMonitoring] Inicializando...');

    try {
      // Carrega estado inicial
      _lastCustomerInfo = await Purchases.getCustomerInfo();

      // Registra listener global da SDK
      Purchases.addCustomerInfoUpdateListener(_handleUpdate);

      dev.log('[SubscriptionMonitoring] Inicializado com sucesso.');
    } catch (e) {
      dev.log('[SubscriptionMonitoring] Erro na inicialização: $e');
    }
  }

  /// Handler principal que roda SOMENTE quando RevenueCat mandar update.
  static void _handleUpdate(CustomerInfo info) {
    final previous = _lastCustomerInfo;
    _lastCustomerInfo = info;

    final oldAccess = _extractVip(previous);
    final newAccess = _extractVip(info);

    // 🔥 IMPORTANTÍSSIMO: só dispara se tiver MUDANÇA REAL
    if (oldAccess == newAccess) {
      dev.log('[SubscriptionMonitoring] Ignorado — nada mudou.');
      return;
    }

    dev.log('[SubscriptionMonitoring] Mudança REAL detectada: $oldAccess → $newAccess');

    for (final listener in _vipListeners) {
      listener(newAccess);
    }
  }

  /// Extrai status VIP corretamente
  static bool _extractVip(CustomerInfo? info) {
    if (info == null) return false;

    final entitlement = info.entitlements.active[_entitlementId];
    if (entitlement == null) return false;

    // Acesso ativo + não expirado
    if (entitlement.billingIssueDetectedAt != null) return false;

    if (entitlement.expirationDate != null) {
      try {
        final exp = DateTime.parse(entitlement.expirationDate!);
        if (exp.isBefore(DateTime.now())) return false;
      } catch (_) {}
    }

    return entitlement.isActive;
  }

  /// Lê status VIP atual
  static bool get hasVipAccess => _extractVip(_lastCustomerInfo);

  /// Registrar listener - idealmente usado por SimpleSubscriptionProvider
  static void addVipListener(void Function(bool) listener) {
    _vipListeners.add(listener);

    // Notifica imediatamente com estado atual
    listener(hasVipAccess);
  }

  /// Remover listener
  static void removeVipListener(void Function(bool) listener) {
    _vipListeners.remove(listener);
  }

  /// Força refresh manual — quase nunca necessário
  static Future<void> refresh() async {
    try {
      final info = await Purchases.getCustomerInfo();
      _handleUpdate(info);
    } catch (e) {
      dev.log("[SubscriptionMonitoring] Erro no refresh: $e");
    }
  }

  /// Encerrar serviço
  static void dispose() {
    _vipListeners.clear();
    _lastCustomerInfo = null;
    _initialized = false;
  }
}
