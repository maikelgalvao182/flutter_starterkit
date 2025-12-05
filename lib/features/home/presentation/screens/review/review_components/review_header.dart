import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dating_app/constants/constants.dart';

class ReviewHeader extends StatelessWidget {
  const ReviewHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              i18n.translate('leave_a_review'),
              style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: GlimpseColors.textColorLight,
              ),
            ),
          ),
          Container(
            height: 32,
            width: 32,
            decoration: BoxDecoration(
              color: GlimpseColors.lightTextField,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: const Icon(Icons.close, size: 24, color: Colors.black87),
              onPressed: () {
                Navigator.of(context, rootNavigator: true).pop(false);
              },
              splashRadius: 18,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
      ),
    );
  }
}
