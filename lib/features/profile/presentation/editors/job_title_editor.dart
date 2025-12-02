import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Editor para o campo "Job Title"
class JobTitleEditor extends StatelessWidget {
  const JobTitleEditor({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GlimpseTextField(
      labelText: i18n.translate('job_title_label'),
      hintText: i18n.translate('enter_your_profession'),
      controller: controller,
      textCapitalization: TextCapitalization.words,
      labelStyle: GlimpseStyles.fieldLabelStyle(
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
    );
  }
}
