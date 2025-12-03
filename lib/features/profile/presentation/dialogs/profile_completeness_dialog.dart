import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:partiu/shared/widgets/profile_completeness_ring.dart';
import 'package:partiu/shared/widgets/dialogs/dialog_styles.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';

/// Bottom-sheet content que exibe o progresso de completude do perfil
/// e permite navegar para edição ou dispensar permanentemente
class ProfileCompletenessDialog extends StatelessWidget {
  const ProfileCompletenessDialog({
    required this.onEditProfile,
    required this.onDontShow,
    super.key,
    this.photoUrl,
    this.percentage, // Percentual de completude (0-100)
    this.title,
    this.subtitle,
  });

  final VoidCallback onEditProfile;
  final VoidCallback onDontShow;
  final String? photoUrl;
  final int? percentage; // Percentual de completude (0-100)
  final String? title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    
    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Close button
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GlimpseCloseButton(
                  onPressed: () {
                    if (Navigator.of(context).canPop()) {
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            
            // User avatar com Progress Ring
            ProfileCompletenessRing(
              size: 90,
              strokeWidth: 4,
              percentage: percentage ?? 0,
              child: CircleAvatar(
                radius: 41,
                backgroundColor: GlimpseColors.lightTextField,
                backgroundImage: photoUrl != null && photoUrl!.isNotEmpty
                    ? CachedNetworkImageProvider(photoUrl!)
                    : null,
                child: photoUrl == null || photoUrl!.isEmpty
                    ? const Icon(Icons.person, size: 40, color: Colors.grey)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            
            // Title
            DialogStyles.buildTitle(
              title ?? i18n.translate('complete_your_profile'),
            ),
            const SizedBox(height: 12),
            
            // Message with highlighted percentage
            _buildMessageWithHighlight(
              context,
              subtitle ?? i18n.translate('profile_completeness_subtitle'),
            ),
            const SizedBox(height: 20),
            
            // Buttons
            Row(
              children: [
                DialogStyles.buildNegativeButton(
                  text: i18n.translate('dont_show'),
                  onPressed: onDontShow,
                ),
                const SizedBox(width: DialogStyles.buttonSpacing),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onEditProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: GlimpseColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: DialogStyles.buttonBorderRadius,
                      ),
                      padding: DialogStyles.buttonPadding,
                      elevation: 0,
                    ),
                    child: Text(
                      i18n.translate('edit_profile_button'),
                      style: DialogStyles.buttonTextStyle.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Builds message with percentage highlighted in actionColor
  Widget _buildMessageWithHighlight(BuildContext context, String message) {
    // Regex para capturar o número seguido de %
    final percentageRegex = RegExp(r'(\d+)%');
    final match = percentageRegex.firstMatch(message);
    
    final baseStyle = DialogStyles.messageStyle;
    
    if (match == null) {
      // Se não houver porcentagem, retorna mensagem normal
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          message,
          style: baseStyle,
          textAlign: TextAlign.center,
        ),
      );
    }
    
    final percentageText = match.group(0)!; // Ex: "75%"
    final beforePercentage = message.substring(0, match.start);
    final afterPercentage = message.substring(match.end);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: baseStyle,
          children: [
            TextSpan(text: beforePercentage),
            TextSpan(
              text: percentageText,
              style: const TextStyle(
                color: GlimpseColors.actionColor,
                fontWeight: FontWeight.w700,
              ),
            ),
            TextSpan(text: afterPercentage),
          ],
        ),
      ),
    );
  }
}
