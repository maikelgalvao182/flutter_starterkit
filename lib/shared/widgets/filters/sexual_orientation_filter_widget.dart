import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_dropdown.dart';

/// Widget de filtro de orientação sexual
/// Segue o padrão visual dos outros filtros em shared/widgets/filters
class SexualOrientationFilterWidget extends StatelessWidget {
  const SexualOrientationFilterWidget({
    super.key,
    required this.selectedOrientation,
    required this.onChanged,
  });

  final String? selectedOrientation;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    // Valores internos (NÃO traduzir): usados em persistência/filtros
    const valueAll = 'all';
    const valueHeterosexual = 'Heterossexual';
    const valueHomosexual = 'Homossexual';
    const valueBisexual = 'Bissexual';
    const valueOther = 'Outro';

    final items = [
      valueAll,
      valueHeterosexual,
      valueHomosexual,
      valueBisexual,
      valueOther,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.translate('sexual_orientation_label'),
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: GlimpseColors.primaryColorLight,
          ),
        ),
        const SizedBox(height: 12),
        GlimpseDropdown(
          labelText: '',
          hintText: i18n.translate('select'),
          items: items,
          selectedValue: _getSelectedValue(selectedOrientation),
          itemBuilder: (item) {
            if (item == valueAll) {
              return i18n.translate('sexual_orientation_filter_all');
            }
            if (item == valueHeterosexual) {
              return i18n.translate('sexual_orientation_heterosexual');
            }
            if (item == valueHomosexual) {
              return i18n.translate('sexual_orientation_homosexual');
            }
            if (item == valueBisexual) {
              return i18n.translate('sexual_orientation_bisexual');
            }
            if (item == valueOther) {
              return i18n.translate('sexual_orientation_other');
            }
            return item;
          },
          onChanged: (value) {
            onChanged(value);
          },
        ),
      ],
    );
  }

  String _getSelectedValue(String? internalValue) {
    if (internalValue == null || internalValue == 'all' || internalValue.isEmpty) {
      return 'all';
    }
    return internalValue;
  }
}
