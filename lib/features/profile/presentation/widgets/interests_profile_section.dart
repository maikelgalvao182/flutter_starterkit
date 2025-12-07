import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/constants/glimpse_styles.dart';
import 'package:partiu/core/constants/glimpse_variables.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/shared/stores/user_store.dart';
import 'package:partiu/shared/widgets/tag_vendor.dart';

/// Interests section widget exibindo tags com TagVendor
/// 
/// - Espaçamento superior: 24px
/// - Espaçamento inferior: 36px  
/// - Padding horizontal: 20px
/// - Auto-oculta se lista vazia
class InterestsProfileSection extends StatelessWidget {

  const InterestsProfileSection({
    required this.userId, 
    super.key,
    this.title,
    this.titleColor,
  });
  
  final String userId;
  final String? title;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final effectiveTitleColor = titleColor ?? GlimpseColors.primaryColorLight;
    
    final interestsNotifier = UserStore.instance.getInterestsNotifier(userId);
    
    return ValueListenableBuilder<List<String>?>(
      valueListenable: interestsNotifier,
      builder: (context, interests, _) {
        // ✅ AUTO-OCULTA: não renderiza seção vazia
        if (interests == null || interests.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return Container(
          padding: GlimpseStyles.profileSectionPadding,
          width: double.infinity,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title ?? i18n.translate('interests_section_title'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  color: effectiveTitleColor,
                ),
                textAlign: TextAlign.left,
              ),
              const SizedBox(height: 12),
              
              // Tags with Wrap
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: interests.map((interestId) {
                  final tag = getInterestById(interestId.trim());
                  final label = tag != null 
                      ? '${tag.icon} ${i18n.translate(tag.nameKey)}'
                      : interestId.trim();
                  return TagVendor(
                    label: label,
                    isSelected: false,
                    onTap: null,
                    backgroundColor: GlimpseColors.lightTextField,
                    textColor: Colors.black,
                    borderColor: Colors.transparent,
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }
}
