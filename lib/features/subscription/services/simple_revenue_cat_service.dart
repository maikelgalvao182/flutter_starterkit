// simple_revenue_cat_service.dart
// ----------------------------------------------------------------------------
// Serviço simplificado do RevenueCat — versão enxuta e estável.
// ----------------------------------------------------------------------------
// Responsabilidade deste arquivo:
//   • Inicializar o SDK
//   • Buscar Offering
//   • Buscar CustomerInfo
//   • Escutar mudanças reais do CustomerInfo (listener oficial)
//   • Comprar / Restaurar
//
// O QUE NÃO FAZ MAIS (porque gerava instabilidade):
//   ✘ timers
//   ✘ polling
//   ✘ loops com retry
//   ✘ watchers duplicados
//   ✘ verificações paranoicas de iOS
//   ✘ análises complexas de entitlement
//
// O restante da lógica (detectar expiração, cancelamento etc.)
// fica no SubscriptionMonitoringService ou no Provider.
// ----------------------------------------------------------------------------

import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/common/utils/app_logger.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SimpleRevenueCatService {
  // --------------------------------------------------------------------------
  // ESTADO INTERNO
  // --------------------------------------------------------------------------
  static bool _initialized = false;
  static CustomerInfo? _lastInfo;

  static String? _entitlementId;
  static String? _offeringId;

  // Listeners locais registrados pela aplicação
  static final _listeners = <void Function(CustomerInfo)>{};

  // --------------------------------------------------------------------------
  // INITIALIZE
  // --------------------------------------------------------------------------
  static Future<void> initialize() async {
    if (_initialized) return;

    AppLogger.info('RevenueCat: inicializando...');

    // 1. Carrega configs (entitlement + offering)
    await _loadConfiguration();

    // 2. Busca API key do Firestore
    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('RevenueCat API key não encontrada no Firestore');
    }

    // 3. Configura o SDK
    final conf = PurchasesConfiguration(apiKey)
      ..entitlementVerificationMode = EntitlementVerificationMode.informational
      ..shouldShowInAppMessagesAutomatically = true;

    await Purchases.configure(conf);

    // 4. Listener oficial de mudanças
    Purchases.addCustomerInfoUpdateListener((info) {
      AppLogger.info('[RevenueCat] CustomerInfo listener acionado.');

      _lastInfo = info;

      // notifica listeners locais
      for (final l in _listeners) {
        l(info);
      }
    });

    // 5. Carrega CustomerInfo inicial
    _lastInfo = await Purchases.getCustomerInfo();

    _initialized = true;

    AppLogger.success('RevenueCat inicializado com sucesso.');
  }

  // --------------------------------------------------------------------------
  // PUBLIC LISTENERS
  // --------------------------------------------------------------------------
  static void addCustomerInfoUpdateListener(void Function(CustomerInfo) listener) {
    _listeners.add(listener);

    // notifica instantaneamente com o último CustomerInfo disponível
    if (_lastInfo != null) {
      listener(_lastInfo!);
    }
  }

  static void removeCustomerInfoUpdateListener(void Function(CustomerInfo) listener) {
    _listeners.remove(listener);
  }

  // --------------------------------------------------------------------------
  // OFFERINGS
  // --------------------------------------------------------------------------
  static Future<Offering?> getOffering() async {
    if (!_initialized) await initialize();

    final offerings = await Purchases.getOfferings();

    // tenta offering atual
    final current = offerings.current;
    if (current != null) return current;

    // fallback: offering configurado no Firestore
    if (_offeringId != null && offerings.all.containsKey(_offeringId)) {
      return offerings.all[_offeringId];
    }

    return null;
  }

  // --------------------------------------------------------------------------
  // CUSTOMER INFO
  // --------------------------------------------------------------------------
  static Future<CustomerInfo> getCustomerInfo() async {
    if (!_initialized) await initialize();

    _lastInfo = await Purchases.getCustomerInfo();
    return _lastInfo!;
  }

  // --------------------------------------------------------------------------
  // HAS ACCESS (usado externamente pelo Provider/Monitoring)
  // --------------------------------------------------------------------------
  static bool hasAccess(CustomerInfo info) {
    try {
      final entId = _entitlementId ?? REVENUE_CAT_ENTITLEMENT_ID;
      final ent = info.entitlements.active[entId];

      if (ent == null) return false;

      // billing issue → sem acesso
      if (ent.billingIssueDetectedAt != null) return false;

      // expiração com margem de tolerância de 5 minutos
      // Isso evita problemas de sincronização de relógio
      if (ent.expirationDate != null) {
        final exp = DateTime.parse(ent.expirationDate!);
        final now = DateTime.now();
        // Adiciona 5 minutos de margem para evitar rejeições por diferença de relógio
        final expWithMargin = exp.add(const Duration(minutes: 5));
        if (expWithMargin.isBefore(now)) return false;
      }

      // se isActive = true → acesso OK
      return ent.isActive;
    } catch (_) {
      return false;
    }
  }

  // --------------------------------------------------------------------------
  // COMPRAR
  // --------------------------------------------------------------------------
  static Future<CustomerInfo> purchasePackage(Package package) async {
    if (!_initialized) await initialize();

    AppLogger.info('Iniciando compra: ${package.storeProduct.identifier}');
    final result = await Purchases.purchaseStoreProduct(package.storeProduct);

    _lastInfo = result.customerInfo;

    return result.customerInfo;
  }

  // --------------------------------------------------------------------------
  // RESTORE
  // --------------------------------------------------------------------------
  static Future<CustomerInfo> restorePurchases() async {
    if (!_initialized) await initialize();

    final info = await Purchases.restorePurchases();
    _lastInfo = info;
    return info;
  }

  // --------------------------------------------------------------------------
  // LOGIN / LOGOUT
  // --------------------------------------------------------------------------
  static Future<void> login(String userId) async {
    if (!_initialized) await initialize();
    await Purchases.logIn(userId);
    _lastInfo = await Purchases.getCustomerInfo();
  }

  static Future<void> logout() async {
    if (!_initialized) return;
    await Purchases.logOut();
    _lastInfo = null;
  }

  // --------------------------------------------------------------------------
  // FIRESTORE CONFIG
  // --------------------------------------------------------------------------
  static Future<String?> _getApiKey() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(C_APP_INFO)
          .doc('revenue_cat')
          .get();

      final data = snap.data();
      if (data == null) return null;

      if (Platform.isAndroid) {
        return data['android_public_api_key'];
      } else if (Platform.isIOS) {
        return data['ios_public_api_key'];
      }

      return data['public_api_key'];
    } catch (_) {
      return null;
    }
  }

  static Future<void> _loadConfiguration() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection(C_APP_INFO)
          .doc('revenue_cat')
          .get();

      final data = doc.data();
      if (data == null) {
        _entitlementId = REVENUE_CAT_ENTITLEMENT_ID;
        return;
      }

      final ent = data['REVENUE_CAT_ENTITLEMENT_ID'];
      final off = data['REVENUE_CAT_OFFERINGS_ID'];

      _entitlementId = (ent is String && ent.isNotEmpty)
          ? ent
          : REVENUE_CAT_ENTITLEMENT_ID;

      _offeringId = (off is String && off.isNotEmpty)
          ? off
          : REVENUE_CAT_OFFERINGS_ID;

    } catch (_) {
      _entitlementId = REVENUE_CAT_ENTITLEMENT_ID;
    }
  }

  // --------------------------------------------------------------------------
  // MÉTODOS AUXILIARES PARA COMPATIBILIDADE
  // --------------------------------------------------------------------------
  
  /// Getter público para último CustomerInfo
  static CustomerInfo? get lastCustomerInfo => _lastInfo;

  /// Aguarda SDK estar pronto (compatibilidade)
  static Future<void> awaitReady({Duration timeout = const Duration(seconds: 5)}) async {
    if (_initialized) return;
    await Future.delayed(const Duration(milliseconds: 100));
  }

  /// Garante que SDK está configurado (compatibilidade)
  static Future<bool> ensureConfigured() async {
    if (!_initialized) {
      await initialize();
    }
    return _initialized;
  }

  /// Inicia refresh periódico (compatibilidade - não faz nada na versão simplificada)
  static void startPeriodicRefresh({Duration? interval}) {
    // Versão simplificada não usa refresh periódico
    AppLogger.info('startPeriodicRefresh: ignorado (versão simplificada)');
  }

  /// Logs de diagnóstico seguros para getCustomerInfo (compatibilidade)
  static Future<void> getCustomerInfoSafeLog() async {
    try {
      await getCustomerInfo();
    } catch (e) {
      AppLogger.info('getCustomerInfoSafeLog: erro ignorado ($e)');
    }
  }
}
