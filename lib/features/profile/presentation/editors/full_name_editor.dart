import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Editor para o campo "Full Name"
class FullNameEditor extends StatelessWidget {
  const FullNameEditor({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GlimpseTextField(
      labelText: i18n.translate('full_name_label'),
      hintText: i18n.translate('enter_full_name_placeholder'),
      controller: controller,
      textCapitalization: TextCapitalization.words,
      labelStyle: GlimpseStyles.fieldLabelStyle(
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }
}
