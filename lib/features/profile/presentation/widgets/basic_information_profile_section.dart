import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/shared/widgets/basic_information_section.dart';

/// Seção de informações básicas independente
/// 
/// - Espaçamento inferior: 36px
/// - Padding horizontal: 20px
/// 
/// Auto-gerenciada:
/// - Carrega dados reativamente do UserStore
/// - Auto-oculta se não houver dados
/// - Exibe gender, jobTitle, city/state/country
class BasicInformationProfileSection extends StatelessWidget {

  const BasicInformationProfileSection({
    required this.userId, 
    super.key,
  });
  
  final String userId;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);

    // Precisa acessar entry completa para gender e jobTitle
    final user = UserStore.instance.getUser(userId);
    if (user == null) return const SizedBox.shrink();

    final entries = _buildBasicInfoEntries(i18n, user: user);

    // 🎯 AUTO-OCULTA: Se não tem dados, não renderiza
    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: GlimpseStyles.profileSectionPadding,
      child: BasicInformationSection(entries: entries),
    );
  }

  List<BasicInfoEntry> _buildBasicInfoEntries(
    AppLocalizations i18n, {
    required UserEntry user,
  }) {
    final entries = <BasicInfoEntry>[];

    // Idade
    if (user.age != null) {
      entries.add(BasicInfoEntry(
        label: 'Idade',
        value: '${user.age} anos',
      ));
    }

    // Gênero
    if (user.gender != null && user.gender!.trim().isNotEmpty) {
      entries.add(BasicInfoEntry(
        label: i18n.translate('gender_label'),
        value: user.gender!,
      ));
    }

    // Orientação Sexual
    if (user.sexualOrientation != null && user.sexualOrientation!.trim().isNotEmpty) {
      entries.add(BasicInfoEntry(
        label: 'Orientação',
        value: user.sexualOrientation!,
      ));
    }

    // Profissão/Job Title
    if (user.jobTitle != null && user.jobTitle!.trim().isNotEmpty) {
      entries.add(BasicInfoEntry(
        label: i18n.translate('job_title_label'),
        value: user.jobTitle!,
      ));
    }

    // País de origem (from)
    if (user.from != null && user.from!.trim().isNotEmpty) {
      entries.add(BasicInfoEntry(
        label: i18n.translate('from_label'),
        value: user.from!,
      ));
    }

    return entries;
  }
}
