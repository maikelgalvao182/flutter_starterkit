import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/constants/constants.dart';

class RatingCriteriaList extends StatelessWidget {
  const RatingCriteriaList({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final controller = context.watch<ReviewDialogController>();
    final criteriaList = controller.getCriteriaList(i18n);
    
    final rateText = controller.revieweeRole == 'vendor' 
        ? i18n.translate('rate_the_vendor')
        : i18n.translate('rate_the_bride');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          rateText,
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textPrimary,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 16),
        ...criteriaList.asMap().entries.map((entry) {
          final index = entry.key;
          final criterion = entry.value;
          
          return Padding(
            padding: EdgeInsets.only(
              bottom: index < criteriaList.length - 1 ? 20 : 0,
            ),
            child: _buildCriterionRow(context, controller, criterion),
          );
        }),
      ],
    );
  }

  Widget _buildCriterionRow(BuildContext context, ReviewDialogController controller, String criterion) {
    final rating = controller.ratings[criterion] ?? 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          criterion,
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: GlimpseColors.textColorLight,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
              final starValue = index + 1;
              final isFilled = starValue <= rating;
              
              return GestureDetector(
                onTap: () {
                  controller.setRating(criterion, starValue);
                },
                child: Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: SvgPicture.asset(
                    isFilled 
                        ? 'assets/svg/star-dourada.svg'
                        : 'assets/svg/star-outline.svg',
                    width: 32,
                    height: 32,
                  ),
                ),
              );
            }),
        ),
      ],
    );
  }
}
