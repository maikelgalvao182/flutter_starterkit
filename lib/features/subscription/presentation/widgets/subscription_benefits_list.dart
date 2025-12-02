import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_plus/iconsax_plus.dart';

/// Lista de benefícios da assinatura VIP
/// 
/// Responsabilidades:
/// - Exibir lista de benefícios do Wedconnex Pro
/// - Ícones e descrições dos recursos
/// 
/// Uso:
/// ```dart
/// const SubscriptionBenefitsList()
/// ```
class SubscriptionBenefitsList extends StatelessWidget {
  const SubscriptionBenefitsList({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final benefits = _getBenefits(i18n);

    return ColoredBox(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: benefits
            .map((benefit) => _BenefitItem(benefit: benefit))
            .toList(),
      ),
    );
  }

  List<_Benefit> _getBenefits(AppLocalizations i18n) {
    return [
      // Passport
      _Benefit(
        icon: IconsaxPlusLinear.airplane,
        title: i18n.translate('passport'),
        subtitle: i18n.translate(
            'travel_to_any_country_or_city_and_match_with_people_there'),
      ),

      // Discover more people
      _Benefit(
        icon: IconsaxPlusLinear.location,
        title: i18n.translate('discover_more_people'),
        subtitle: "${i18n.translate('get')} "
            '100 km ' // Valor fixo, pode ser substituído por config
            "${i18n.translate('radius_away')}",
      ),

      // See who visited you
      _Benefit(
        icon: IconsaxPlusLinear.eye,
        title: i18n.translate('see_people_who_visited_your_profile'),
        subtitle: i18n.translate(
            'unravel_the_mystery_and_find_out_who_visited_your_profile'),
      ),

      // Verified account badge
      _Benefit(
        icon: IconsaxPlusLinear.verify,
        title: i18n.translate('verified_account_badge'),
        subtitle: i18n.translate(
            'get_verified_and_increase_your_credibility_on_the_platform'),
      ),
    ];
  }
}

/// Modelo de benefício
class _Benefit {

  const _Benefit({
    required this.icon,
    required this.title,
    required this.subtitle,
  });
  final IconData icon;
  final String title;
  final String subtitle;
}

/// Widget individual de benefício
class _BenefitItem extends StatelessWidget {

  const _BenefitItem({required this.benefit});
  final _Benefit benefit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.black,
            child: Icon(
              benefit.icon,
              color: Colors.white,
            ),
          ),
          title: Text(
            benefit.title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
            ),
          ),
          subtitle: Text(benefit.subtitle),
        ),
        const Divider(height: 10),
      ],
    );
  }
}
