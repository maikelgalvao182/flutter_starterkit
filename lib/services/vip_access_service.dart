import 'package:partiu/dialogs/vip_dialog.dart';
import 'package:partiu/services/simple_revenue_cat_service.dart';
import 'package:partiu/services/subscription_monitoring_service.dart';
import 'package:flutter/material.dart';

/// Serviço para verificar status VIP e controlar acesso a funcionalidades premium
/// IMPORTANTE: Não usa cache próprio, confia 100% no SubscriptionMonitoringService
class VipAccessService {
  /// Ativa/desativa verbosidade de logs (pode ser mudado em runtime se necessário)
  static bool verbose = true;

  static void _log(String msg, {String? traceId}) {
    if (!verbose) return;
    // Log message (timestamp not needed for this implementation)
  }
  
  /// Limpa o cache (mantido para compatibilidade, mas não faz nada)
  @Deprecated('VipAccessService não usa mais cache próprio')
  static void clearCache() {
    // Método vazio mantido para compatibilidade com código existente
    // Não imprime nada para evitar poluir os logs
  }

  /// Inicializa o serviço VIP
  static Future<void> initialize() async {
    try {
  // Aguarda RevenueCat pronto para evitar chamadas precoces
  await SimpleRevenueCatService.awaitReady();
      // Inicializa o serviço de monitoramento em tempo real
      await SubscriptionMonitoringService.initialize();
      
      
      // Adiciona listener para mudanças de status (sem log desnecessário)
      SubscriptionMonitoringService.addVipListener((hasAccess) {
        // Status mudou, cache é limpo automaticamente no SubscriptionMonitoringService
      });
      
    } catch (e) {
      // Ignore initialization errors
    }
  }

  /// Realiza verificação inicial do status VIP sem mostrar dialog
  /// Útil para pré-carregar o status ao iniciar o app
  static Future<bool> checkInitialStatus() async {
    try {
  await SimpleRevenueCatService.awaitReady();
      // Força verificação via monitoramento
      await SubscriptionMonitoringService.refresh();
      final hasAccess = SubscriptionMonitoringService.hasVipAccess;
      
      return hasAccess;
    } catch (e) {
      return false;
    }
  }

  /// Verificação híbrida: combina dados do Firestore com monitoramento em tempo real
  /// Usa o serviço de monitoramento para detectar mudanças automaticamente
  static Future<bool> hasVipAccess(BuildContext context, {String? traceId, String? source}) async {
    _log('→ hasVipAccess (RevenueCat only) source=${source ?? 'unspecified'}', traceId: traceId);
    
    try {
  await SimpleRevenueCatService.awaitReady();
      // Verificação via monitoramento em tempo real (RevenueCat)
      final realtimeAccess = SubscriptionMonitoringService.hasVipAccess;
      _log('Status RevenueCat: $realtimeAccess', traceId: traceId);
      
      return realtimeAccess;
      
    } catch (e) {
      _log('ERRO em hasVipAccess: $e', traceId: traceId);
      
      // Fallback: usa apenas o monitoramento em tempo real
      return SubscriptionMonitoringService.hasVipAccess;
    }
  }

  /// Adiciona um listener para mudanças no status VIP
  static void addAccessListener(void Function(bool) listener) {
    SubscriptionMonitoringService.addVipListener(listener);
  }

  /// Remove um listener de mudanças no status VIP
  static void removeAccessListener(void Function(bool) listener) {
    SubscriptionMonitoringService.removeVipListener(listener);
  }

  /// Força verificação manual imediata
  static Future<void> forceCheck() async {
    await SubscriptionMonitoringService.refresh();
  }

  /// Verifica o acesso ou mostra o diálogo VIP
  /// IMPORTANTE: Força atualização do CustomerInfo antes de verificar (baseado no ViewTex)
  static Future<bool> checkAccessOrShowDialog(BuildContext context, {String? source}) async {
    _log('→ checkAccessOrShowDialog source=${source ?? 'unspecified'}');
    
    try {
      // [OK] CRÍTICO: Força atualização do CustomerInfo antes de verificar
      await SimpleRevenueCatService.awaitReady();
      await SubscriptionMonitoringService.refresh();
      
      // Verifica status atual após refresh
      final hasAccess = SubscriptionMonitoringService.hasVipAccess;
      
      if (!hasAccess) {
        _log('No access, showing VIP dialog');
        // ignore: use_build_context_synchronously
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (context) => const VipDialog(),
        );
        
        // Se o dialog retornou true, significa que o usuário completou a compra
        final accessGranted = result ?? false;
        _log('Dialog closed with result: $result, accessGranted: $accessGranted');
        
        return accessGranted;
      }
      
      _log('Has access, no dialog needed');
      return true;
      
    } catch (e) {
      _log('Erro em checkAccessOrShowDialog: $e');
      // Em caso de erro, mostra o dialog para segurança
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const VipDialog(),
      );
      return result ?? false;
    }
  }
}
