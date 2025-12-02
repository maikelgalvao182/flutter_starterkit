import 'package:partiu/features/subscription/domain/subscription_plan.dart';
import 'package:partiu/features/subscription/providers/simple_subscription_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class SubscriptionPurchaseController extends ChangeNotifier {
  SubscriptionPurchaseController({
    required this.provider,
    required this.onSuccess,
    required this.onError,
  });

  final SimpleSubscriptionProvider provider;
  final VoidCallback onSuccess;
  final Function(String error) onError;

  bool _isLoading = false;
  bool _isPurchasing = false;
  String? _error;
  SubscriptionPlan _selectedPlan = SubscriptionPlan.annual;

  bool get isLoading => _isLoading;
  bool get isPurchasing => _isPurchasing;
  String? get error => _error;
  SubscriptionPlan get selectedPlan => _selectedPlan;

  /// Pacotes direto do provider (não guarda estado duplicado)
  Package? get monthlyPackage {
    try {
      return provider.offering?.availablePackages
          .firstWhere((p) => p.packageType == PackageType.monthly);
    } catch (_) {
      return null;
    }
  }

  Package? get annualPackage {
    try {
      return provider.offering?.availablePackages
          .firstWhere((p) => p.packageType == PackageType.annual);
    } catch (_) {
      return null;
    }
  }

  Package? get selectedPackage =>
      _selectedPlan == SubscriptionPlan.annual ? annualPackage : monthlyPackage;

  bool get hasPlans => provider.offering?.availablePackages.isNotEmpty == true;

  /// Inicializa carregando apenas uma vez
  Future<void> initialize() async {
    if (provider.offering != null) return; // já está pronto

    _isLoading = true;
    notifyListeners();

    try {
      await provider.init(); // provider carrega a offering
    } catch (e) {
      _error = e.toString();
      onError(_error!);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Selecionar plano
  void selectPlan(SubscriptionPlan plan) {
    _selectedPlan = plan;
    notifyListeners();
  }

  /// Realizar compra
  Future<void> purchaseSelected() async {
    final package = selectedPackage;
    if (package == null) {
      onError('No package selected');
      return;
    }

    if (_isPurchasing) return;

    _isPurchasing = true;
    notifyListeners();

    try {
      await provider.purchase(package);

      // Aqui você não verifica mais CustomerInfo
      // MonitoringService + provider já fazem isso

      if (provider.hasVipAccess) {
        onSuccess();
      } else {
        onError('Purchase completed but access not active');
      }
    } catch (e) {
      final msg = e.toString();

      if (msg.contains('PURCHASE_CANCELLED')) {
        onError('Payment cancelled');
      } else {
        onError(msg);
      }
    } finally {
      _isPurchasing = false;
      notifyListeners();
    }
  }

  /// Restaurar compras
  Future<void> restorePurchases() async {
    try {
      await provider.restorePurchases();

      if (provider.hasVipAccess) {
        onSuccess();
      } else {
        onError('No previous purchases found');
      }
    } catch (e) {
      onError(e.toString());
    }
  }

  Future<void> retry() => initialize();
}
