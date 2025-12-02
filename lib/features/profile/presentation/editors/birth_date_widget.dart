import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_date_picker_field.dart';
import 'package:flutter/material.dart';

/// Widget de seleção de data de nascimento
/// Usa o GlimpseDatePickerField para seleção modal de data
class BirthDateWidget extends StatelessWidget {
  const BirthDateWidget({
    required this.initialDate,
    required this.onDateChanged,
    super.key,
  });

  final DateTime? initialDate;
  final ValueChanged<DateTime?> onDateChanged;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label
        Padding(
          padding: const EdgeInsets.only(bottom: 0),
          child: Text(
            i18n.translate('birth_date'),
            style: GlimpseStyles.fieldLabelStyle(),
          ),
        ),
        
        // Seletor de data de nascimento estilo Glimpse com i18n automático
        GlimpseDatePickerField(
          initialDate: initialDate,
          onDateChanged: onDateChanged,
          minYear: 1960,
          maxYear: DateTime.now().year,
          // hintText agora é gerado automaticamente baseado no locale
          // en: MM-DD-YYYY, pt/es: DD-MM-YYYY
        ),
      ],
    );
  }
}
