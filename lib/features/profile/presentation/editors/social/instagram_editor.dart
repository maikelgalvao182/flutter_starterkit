import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Editor para campo Instagram
/// Permite editar o URL do perfil do Instagram
class InstagramEditor extends StatelessWidget {
  const InstagramEditor({
    required this.controller,
    super.key,
  });

  final TextEditingController controller;

  /// Validação básica de URL
  bool _isValidUrl(String url) {
    if (url.isEmpty) return true; // Opcional
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return GlimpseTextField(
      labelText: i18n.translate('instagram'),
      hintText: i18n.translate('url_instagram_placeholder'),
      controller: controller,
      keyboardType: TextInputType.url,
      maxLines: 1,
      labelStyle: GlimpseStyles.fieldLabelStyle(
        color: Theme.of(context).textTheme.titleMedium?.color,
      ),
      validator: (value) {
        if (value != null && value.isNotEmpty && !_isValidUrl(value)) {
          return i18n.translate('please_enter_valid_url');
        }
        return null;
      },
    );
  }
}
