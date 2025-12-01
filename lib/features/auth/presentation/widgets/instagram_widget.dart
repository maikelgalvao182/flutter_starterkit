import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';

/// Widget de username do Instagram
/// Extraído para reutilização no wizard
class InstagramWidget extends StatefulWidget {
  const InstagramWidget({
    required this.initialInstagram,
    required this.onInstagramChanged,
    super.key,
  });

  final String initialInstagram;
  final ValueChanged<String> onInstagramChanged;

  @override
  State<InstagramWidget> createState() => _InstagramWidgetState();
}

class _InstagramWidgetState extends State<InstagramWidget> {
  late TextEditingController _instagramController;

  @override
  void initState() {
    super.initState();
    _instagramController = TextEditingController(text: widget.initialInstagram);
  }

  @override
  void dispose() {
    _instagramController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Campo Instagram
        GlimpseTextField(
          labelText: i18n.translate('instagram_label'),
          hintText: i18n.translate('instagram_placeholder'),
          controller: _instagramController,
          textCapitalization: TextCapitalization.none,
          onChanged: (value) {
            // Remove @ se o usuário digitar
            String cleanValue = value.trim();
            if (cleanValue.startsWith('@')) {
              cleanValue = cleanValue.substring(1);
              _instagramController.text = cleanValue;
              _instagramController.selection = TextSelection.fromPosition(
                TextPosition(offset: cleanValue.length),
              );
            }
            widget.onInstagramChanged(cleanValue);
          },
        ),
        
        const SizedBox(height: 8),
        
        // Helper text
        Text(
          i18n.translate('instagram_helper'),
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
