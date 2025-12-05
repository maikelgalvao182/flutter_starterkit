import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/constants/glimpse_variables.dart';
import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/screens/conversation_tab/utils/conversation_styles.dart';
import 'package:dating_app/widgets/reactive/reactive_widgets.dart';
import 'package:dating_app/widgets/stable_avatar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/constants/constants.dart';

class RevieweeAvatarInfo extends StatelessWidget {
  const RevieweeAvatarInfo({
    required this.revieweeId,
    required this.categoryName,
    super.key,
  });

  final String revieweeId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final controller = context.watch<ReviewDialogController>();
    final isLoading = controller.isLoadingStats;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 84,
          width: 84,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
            border: Border.all(
              color: Colors.white,
              width: 2,
            ),
          ),
          child: Center(
            child: StableAvatar(
              key: ValueKey('review_avatar_$revieweeId'),
              userId: revieweeId,
              size: 80,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ReactiveUserNameWithBadge(
                userId: revieweeId,
                style: ConversationStyles.title(false),
                iconSize: 14,
              ),
              const SizedBox(height: 2),
              Text(
                categoryName.isNotEmpty
                    ? AppLocalizations.of(context).translate(
                        categoryToI18nKey(categoryName)
                      )
                    : '—',
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF444444),
                ),
              ),
              const SizedBox(height: 8),
              if (isLoading)
                Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CupertinoActivityIndicator(
                        radius: 8,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      i18n.translate('loading'),
                      style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: GlimpseColors.descriptionTextColorLight,
                      ),
                    ),
                  ],
                )
              else
                ReactiveVendorReviewStats(
                  userId: null, // Modo estático para usar valores diretos
                  overallRating: controller.reviewStats?.overallRating ?? 0.0,
                  totalReviews: controller.reviewStats?.totalReviews ?? 0,
                  iconSize: 18,
                  ratingFontSize: 12,
                  reviewsFontSize: 11,
                ),
            ],
          ),
        ),
      ],
    );
  }
}
