// Imports dos módulos criados
import 'package:partiu/features/subscription/domain/subscription_plan.dart';
import 'package:partiu/features/subscription/presentation/animations/dialog_slide_animation.dart';
import 'package:partiu/features/subscription/presentation/controllers/subscription_purchase_controller.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_active_badge.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_benefits_list.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_footer.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_header.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_plan_card.dart';
import 'package:partiu/features/subscription/presentation/widgets/subscription_states.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/core/helpers/toast_messages_helper.dart';
import 'package:partiu/features/subscription/providers/simple_subscription_provider.dart';
import 'package:partiu/features/subscription/services/simple_revenue_cat_service.dart';
import 'package:partiu/shared/services/toast_service.dart';
import 'package:partiu/features/subscription/services/vip_access_service.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Dialog de assinatura VIP - Versão Modularizada
/// 
/// Responsabilidades:
/// - Orquestrar widgets modulares
/// - Gerenciar estado do dialog
/// - Coordenar animações
/// - Responder a mudanças de assinatura
class VipDialog extends StatefulWidget {
  const VipDialog({super.key});

  @override
  State<VipDialog> createState() => _VipDialogState();
}

class _VipDialogState extends State<VipDialog> with SingleTickerProviderStateMixin {
  late final DialogSlideAnimation _animation;
  late final SubscriptionPurchaseController _controller;
  bool _isInitialized = false;
  
  // Listener de acesso VIP (via SubscriptionMonitoringService)
  void _onVipAccessChanged(bool hasAccess) {
    if (!mounted) return;
    if (hasAccess && !_animation.isClosing) {
      // Fecha o diálogo assim que acesso VIP for concedido
      _animation.close(context, returnSuccess: true);
    }
  }

  @override
  void initState() {
    super.initState();

    // Inicializa animação
    _animation = DialogSlideAnimation(vsync: this);
    _animation.enter();

    // Aguarda build completar para acessar context
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Observa mudanças de acesso VIP globalmente (sem Consumer)
      VipAccessService.addAccessListener(_onVipAccessChanged);

      final simpleProvider = context.read<SimpleSubscriptionProvider>();

      // Inicializa controller
      _controller = SubscriptionPurchaseController(
        provider: simpleProvider,
        onSuccess: _handleSuccess,
        onError: _handleError,
      );

      // Garante que provider está inicializado
      if (!simpleProvider.isInitialized) {
        await simpleProvider.init();
      }

      // Verifica se já tem acesso e fecha imediatamente
      if (mounted && SimpleRevenueCatService.lastCustomerInfo != null) {
        final hasAccess = SimpleRevenueCatService.hasAccess(SimpleRevenueCatService.lastCustomerInfo!);
        if (hasAccess) {
          _animation.close(context, returnSuccess: true);
          return;
        }
      }

      // Carrega planos
      if (mounted) {
        await _controller.initialize();
        setState(() => _isInitialized = true);
      }
    });
  }

  @override
  void dispose() {
    _animation.dispose();
    _controller.dispose();
  // Remove listener de acesso VIP
  VipAccessService.removeAccessListener(_onVipAccessChanged);
    super.dispose();
  }

  /// Trata sucesso na compra/restore
  void _handleSuccess() {
    if (!mounted) return;

    final tm = ToastMessagesHelper(context);
    ToastService.showSuccess(
      context: context,
      title: tm.vipSubscriptionRestored,
    );

    _animation.close(context, returnSuccess: true);
  }

  /// Trata erro na compra/restore
  void _handleError(String error) {
    if (!mounted) return;

    final tm = ToastMessagesHelper(context);

    if (error.contains('cancelled')) {
      ToastService.showInfo(
        context: context,
        title: tm.paymentCancelled,
        subtitle: tm.paymentCancelledByUser,
      );
    } else if (error.contains('No previous')) {
      ToastService.showError(
        context: context,
        title: tm.error,
        subtitle: AppLocalizations.of(context).translate('no_previous_purchase_found'),
      );
    } else {
      ToastService.showError(
        context: context,
        title: tm.error,
        subtitle: error,
      );
    }
  }

  /// Trata restore de compras
  Future<void> _handleRestore() async {
    if (!mounted) return;

    ToastService.showInfo(
      context: context,
      title: AppLocalizations.of(context).translate('processing'),
    );

    await _controller.restorePurchases();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    // Sem Consumer: animação e UI reagem ao controller/listeners locais
    return AnimatedBuilder(
      animation: _animation.controller,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation.fadeAnimation,
          child: SlideTransition(
            position: _animation.slideAnimation,
            child: child,
          ),
        );
      },
      child: _buildDialogContent(i18n),
    );
  }

  /// Constrói conteúdo principal do dialog
  Widget _buildDialogContent(AppLocalizations i18n) {
    final customerInfo = SimpleRevenueCatService.lastCustomerInfo;
    final hasVipAccess = customerInfo != null && SimpleRevenueCatService.hasAccess(customerInfo);
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 5),
      child: RepaintBoundary(
        child: Card(
          clipBehavior: Clip.antiAlias,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)),
          ),
          child: Column(
            children: [
              SubscriptionHeader(
                onClose: () => _animation.close(context),
              ),
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasVipAccess)
                        SubscriptionActiveBadge(
                          expirationDate: customerInfo.latestExpirationDate,
                        ),
                      if (!_isInitialized || _controller.isLoading)
                        const SubscriptionLoadingState()
                      else if (_controller.error != null)
                        SubscriptionErrorState(
                          error: _controller.error!,
                          onRetry: () => _controller.retry(),
                        )
                      else if (!_controller.hasPlans)
                        const SubscriptionEmptyState()
                      else
                        _buildPlansSection(i18n),
                    ],
                  ),
                ),
              ),
              const SubscriptionBenefitsList(),
            ],
          ),
        ),
      ),
    );
  }

  /// Constrói seção de planos
  Widget _buildPlansSection(AppLocalizations i18n) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        return Column(
          children: [
            // Card plano mensal (se disponível)
            if (_controller.monthlyPackage != null)
              SubscriptionPlanCard(
                package: _controller.monthlyPackage!,
                isSelected: _controller.selectedPlan == SubscriptionPlan.monthly,
                onTap: () => _controller.selectPlan(SubscriptionPlan.monthly),
              ),

            const SizedBox(height: 0),

            // Card plano anual (se disponível)
            if (_controller.annualPackage != null)
              SubscriptionPlanCard(
                package: _controller.annualPackage!,
                isSelected: _controller.selectedPlan == SubscriptionPlan.annual,
                onTap: () => _controller.selectPlan(SubscriptionPlan.annual),
              ),

            // Botão de compra
            _buildPurchaseButton(i18n),

            // Footer com termos e restore
            SubscriptionFooter(
              onRestore: _handleRestore,
            ),

            const Divider(thickness: 1, height: 30),
          ],
        );
      },
    );
  }

  /// Constrói botão de compra
  Widget _buildPurchaseButton(AppLocalizations i18n) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final isPurchasing = _controller.isPurchasing;
        final selectedPlan = _controller.selectedPlan;

        final buttonText = selectedPlan == SubscriptionPlan.annual
            ? i18n.translate('subscribe_annual_plan')
            : i18n.translate('subscribe_monthly_plan');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: GlimpseButton(
            text: buttonText,
            backgroundColor: Colors.black,
            isProcessing: isPurchasing,
            onPressed: isPurchasing ? null : _controller.purchaseSelected,
          ),
        );
      },
    );
  }
}
