import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_plus/iconsax_plus.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

/// Card de plano de assinatura (mensal ou anual)
/// 
/// Responsabilidades:
/// - Exibir informações do plano (título, descrição, preço)
/// - Indicar visualmente se está selecionado
/// - Responder a taps para seleção
/// 
/// Uso:
/// ```dart
/// SubscriptionPlanCard(
///   package: annualPackage,
///   isSelected: selectedPlan == SubscriptionPlan.annual,
///   onTap: () => setState(() => selectedPlan = SubscriptionPlan.annual),
/// )
/// ```
class SubscriptionPlanCard extends StatelessWidget {

  const SubscriptionPlanCard({
    required this.package, required this.isSelected, required this.onTap, super.key,
  });
  final Package package;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final product = package.storeProduct;
    
    // Cores dinâmicas baseadas no estado de seleção
    final borderColor = isSelected ? Colors.black : Colors.grey.shade300;
    final iconBg = isSelected ? Colors.black : Colors.white;
    final iconBorder = isSelected ? Colors.black : Colors.grey.shade300;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 2),
          color: Colors.white,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone de estrela
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: iconBorder, width: 2),
              ),
              padding: const EdgeInsets.all(10),
              child: Icon(
                IconsaxPlusBold.star_1,
                color: isSelected ? Colors.white : Colors.black,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Informações do plano
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título do plano
                  Text(
                    product.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.2,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Descrição do plano
                  Text(
                    _getDescription(i18n, product),
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.visible,
                  ),
                ],
              ),
            ),
            
            // Preço
            Text(
              product.priceString,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Retorna descrição do plano (usa description do produto ou fallback)
  String _getDescription(AppLocalizations i18n, StoreProduct product) {
    if (product.description.isNotEmpty) {
      return product.description;
    }

    // Fallback baseado no tipo de pacote
    return package.packageType == PackageType.annual
        ? i18n.translate('auto_renews_annually')
        : i18n.translate('auto_renews_monthly');
  }
}
