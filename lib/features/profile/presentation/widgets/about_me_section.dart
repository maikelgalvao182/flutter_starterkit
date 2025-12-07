import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/stores/user_store.dart';

/// About Me section widget com espaçamento interno
/// 
/// - Espaçamento superior: 24px
/// - Espaçamento inferior: 16px  
/// - Padding horizontal: 20px
/// - Auto-oculta se bio vazia
class AboutMeSection extends StatelessWidget {

  const AboutMeSection({
    required this.userId, 
    super.key,
    this.title,
    this.titleColor,
    this.textColor,
  });
  
  final String userId;
  final String? title;
  final Color? titleColor;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final effectiveTitleColor = titleColor ?? GlimpseColors.primaryColorLight;
    final effectiveTextColor = textColor ?? GlimpseColors.primaryColorLight;
    
    final bioNotifier = UserStore.instance.getBioNotifier(userId);
    
    return ValueListenableBuilder<String?>(
      valueListenable: bioNotifier,
      builder: (context, bio, _) {
        final trimmed = bio?.trim() ?? '';
        
        // ✅ AUTO-OCULTA: não renderiza seção vazia
        if (trimmed.isEmpty) return const SizedBox.shrink();
        
        return Container(
          padding: const EdgeInsets.only(
            left: 20,
            right: 20,
            bottom: 16,
          ),
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title ?? i18n.translate('about_me_title'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: GlimpseColors.primaryColorLight,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 8),
              Text(
                trimmed,
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 14,
                  color: effectiveTextColor,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
        );
      },
    );
  }
}
