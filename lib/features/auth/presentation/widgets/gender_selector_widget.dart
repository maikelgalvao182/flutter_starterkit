import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_dropdown.dart';
import 'package:flutter/material.dart';

/// Widget de seleção de gênero
/// Extraído para reutilização no wizard
class GenderSelectorWidget extends StatelessWidget {
  const GenderSelectorWidget({
    required this.initialGender,
    required this.onGenderChanged,
    super.key,
  });

  final String initialGender;
  final ValueChanged<String?> onGenderChanged;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    final genderOptions = [
      i18n.translate('gender_male'),
      i18n.translate('gender_female'),
      i18n.translate('gender_non_binary'),
    ];
    
    return GlimpseDropdown(
      labelText: i18n.translate('gender_label'),
      hintText: i18n.translate('select_gender'),
      items: genderOptions,
      selectedValue: initialGender.isNotEmpty ? initialGender : null,
      onChanged: onGenderChanged,
    );
  }
}
