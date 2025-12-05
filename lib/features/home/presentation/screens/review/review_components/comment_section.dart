import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/widgets/glimpse_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/constants/constants.dart';

class CommentSection extends StatelessWidget {
  const CommentSection({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final controller = context.read<ReviewDialogController>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          i18n.translate('additional_comments_optional'),
          style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: GlimpseColors.textColorLight,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 8),
        GlimpseTextField(
          controller: controller.commentController,
          hintText: i18n.translate('share_your_experience'),
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
