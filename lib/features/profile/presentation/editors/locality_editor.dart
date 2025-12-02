import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Editor para o campo "Locality"
class LocalityEditor extends StatelessWidget {
  const LocalityEditor({
    required this.controller,
    required this.onTap,
    super.key,
  });

  final TextEditingController controller;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GlimpseTextField(
      labelText: i18n.translate('locality'),
      hintText: i18n.translate('select_locality'),
      controller: controller,
      readOnly: true,
      onTap: onTap,
      labelStyle: GlimpseStyles.fieldLabelStyle(
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }
}
