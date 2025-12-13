import 'package:flutter/material.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_dropdown.dart';

/// Editor de orientação sexual reutilizável
class SexualOrientationEditor extends StatelessWidget {
  const SexualOrientationEditor({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

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
      selectedValue: controller.text.isNotEmpty ? controller.text : null,
      onChanged: (value) {
        controller.text = value ?? '';
      },
    );
  }
}