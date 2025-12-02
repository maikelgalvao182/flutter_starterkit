import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/widgets/glimpse_confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

/// Reusable delete button for media items with confirmation dialog
class MediaDeleteButton extends StatelessWidget {

  const MediaDeleteButton({
    required this.onDelete, super.key,
    this.title,
    this.message,
    this.confirmLabel,
    this.cancelLabel,
  });
  final VoidCallback onDelete;
  final String? title;
  final String? message;
  final String? confirmLabel;
  final String? cancelLabel;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return Positioned(
      top: 4,
      right: 4,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(6),
          onTap: () async {
            final confirm = await showGlimpseConfirmDialog(
              context,
              title: title ?? i18n.translate('remove_image'),
              message: message ?? i18n.translate('delete_image_confirmation'),
              confirmLabel: confirmLabel ?? i18n.translate('remove'),
              cancelLabel: cancelLabel ?? i18n.translate('cancel'),
              isDestructive: true,
            );
            if (confirm ?? false) {
              onDelete();
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(
              Iconsax.trash, 
              color: Colors.white, 
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}