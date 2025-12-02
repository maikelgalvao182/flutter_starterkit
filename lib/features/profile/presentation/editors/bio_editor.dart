import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Editor para o campo "Bio"
class BioEditor extends StatelessWidget {
  const BioEditor({
    required this.controller,
    required this.validator,
    required this.hintText,
    super.key,
  });

  final TextEditingController controller;
  final String? Function(String?)? validator;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GlimpseTextField(
      labelText: i18n.translate('bio_label'),
      hintText: hintText,
      controller: controller,
      maxLines: 8,
      textCapitalization: TextCapitalization.sentences,
      validator: validator,
      labelStyle: GlimpseStyles.fieldLabelStyle(
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }
}
