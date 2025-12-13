import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_dropdown.dart';
import 'package:flutter/material.dart';

/// Widget de seleção de orientação sexual
class SexualOrientationWidget extends StatelessWidget {
  const SexualOrientationWidget({
    required this.initialOrientation,
    required this.onOrientationChanged,
    super.key,
  });

  final String initialOrientation;
  final ValueChanged<String?> onOrientationChanged;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    // Constantes para orientação sexual
    const orientationHeterosexual = 'Heterossexual';
    const orientationHomosexual = 'Homossexual';
    const orientationBisexual = 'Bissexual';
    const orientationOther = 'Outro';
    const orientationPreferNotToSay = 'Prefiro não informar';
    
    // Lista de opções
    final orientationOptions = [
      orientationHeterosexual,
      orientationHomosexual,
      orientationBisexual,
      orientationOther,
      orientationPreferNotToSay,
    ];
    
    return GlimpseDropdown(
      labelText: 'Orientação Sexual',
      hintText: 'Selecione sua orientação sexual',
      items: orientationOptions,
      selectedValue: initialOrientation.isNotEmpty ? initialOrientation : null,
      onChanged: onOrientationChanged,
    );
  }
}
