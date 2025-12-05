import 'package:dating_app/constants/glimpse_colors.dart';
import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/helpers/toast_messages_helper.dart';
import 'package:dating_app/services/toast_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:dating_app/constants/constants.dart';

class ReviewActions extends StatelessWidget {
  const ReviewActions({
    required this.announcementId,
    required this.applicationId,
    required this.pendingReviewId,
    super.key,
  });

  final String announcementId;
  final String applicationId;
  final String pendingReviewId;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final controller = context.watch<ReviewDialogController>();
    final canSubmit = controller.ratings.isNotEmpty;
    final isSubmitting = controller.isSubmitting;
    
    final submitButtonColor = isSubmitting
        ? GlimpseColors.primaryColor.withValues(alpha: 0.8)
        : (canSubmit ? GlimpseColors.primaryColor : Colors.grey[300]);
    
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: isSubmitting ? null : () => _handleDismiss(context, controller),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: GlimpseColors.borderColorLight),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: Colors.white,
              ),
              child: Text(
                i18n.translate('not_now'),
                style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: canSubmit && !isSubmitting 
                  ? () => _handleSubmit(context, controller) 
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: submitButtonColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                disabledBackgroundColor: submitButtonColor,
              ),
              child: isSubmitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CupertinoActivityIndicator(
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      i18n.translate('submit'),
                      style: GoogleFonts.getFont(FONT_PLUS_JAKARTA_SANS, 
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleDismiss(BuildContext context, ReviewDialogController controller) async {
    final success = await controller.dismissReview(pendingReviewId);
    if (context.mounted) {
      if (success) {
        Navigator.of(context, rootNavigator: true).pop(false);
      } else {
         Navigator.of(context, rootNavigator: true).pop(false);
      }
    }
  }

  Future<void> _handleSubmit(BuildContext context, ReviewDialogController controller) async {
    final i18n = AppLocalizations.of(context);
    
    try {
      final success = await controller.submitReview(
        announcementId: announcementId,
        applicationId: applicationId,
        pendingReviewId: pendingReviewId,
        i18n: i18n,
      );

      if (context.mounted && success) {
        Navigator.of(context, rootNavigator: true).pop(true);
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          final toastMsg = ToastMessagesHelper(context);
          ToastService.showSuccess(
            context: context,
            title: toastMsg.reviewSubmitted,
            subtitle: toastMsg.reviewSubmittedSuccessfully,
          );
        }
      }
    } catch (e) {
      // Duplicate error rethrown
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop(false);
        await Future.delayed(const Duration(milliseconds: 100));
        if (context.mounted) {
          final toastMsg = ToastMessagesHelper(context);
          ToastService.showError(
            context: context,
            title: toastMsg.reviewAlreadySubmitted,
            subtitle: toastMsg.reviewAlreadySubmittedMessage,
          );
        }
      }
    }
  }
}
