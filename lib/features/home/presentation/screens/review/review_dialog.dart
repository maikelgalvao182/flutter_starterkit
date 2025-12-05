import 'package:dating_app/dialogs/review_components/comment_section.dart';
import 'package:dating_app/dialogs/review_components/error_message_box.dart';
import 'package:dating_app/dialogs/review_components/rating_criteria_list.dart';
import 'package:dating_app/dialogs/review_components/review_actions.dart';
import 'package:dating_app/dialogs/review_components/review_header.dart';
import 'package:dating_app/dialogs/review_components/reviewee_avatar_info.dart';
import 'package:dating_app/dialogs/review_dialog_controller.dart';
import 'package:dating_app/helpers/app_localizations.dart';
import 'package:dating_app/widgets/glimpse_button.dart';
import 'package:dating_app/widgets/wedding/event_header_card.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ReviewDialog extends StatelessWidget {
  const ReviewDialog({
    required this.announcementId,
    required this.applicationId,
    required this.revieweeId,
    required this.revieweeName,
    required this.revieweeRole,
    required this.eventName,
    required this.categoryName,
    required this.eventDate,
    required this.pendingReviewId,
    super.key,
    this.revieweePhoto,
    this.eventCity,
    this.eventCountry,
    this.eventState,
  });

  final String announcementId;
  final String applicationId;
  final String revieweeId;
  final String revieweeName;
  final String? revieweePhoto;
  final String revieweeRole;
  final String eventName;
  final String categoryName;
  final DateTime eventDate;
  final String pendingReviewId;
  final String? eventCity;
  final String? eventCountry;
  final String? eventState;

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ReviewDialogController(
        revieweeId: revieweeId,
        revieweeRole: revieweeRole,
      ),
      child: _ReviewDialogContent(
        announcementId: announcementId,
        applicationId: applicationId,
        pendingReviewId: pendingReviewId,
        categoryName: categoryName,
      ),
    );
  }
}

class _ReviewDialogContent extends StatelessWidget {
  const _ReviewDialogContent({
    required this.announcementId,
    required this.applicationId,
    required this.pendingReviewId,
    required this.categoryName,
  });

  final String announcementId;
  final String applicationId;
  final String pendingReviewId;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    final i18n = AppLocalizations.of(context);
    final controller = context.watch<ReviewDialogController>();
    final currentStep = controller.currentStep;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12),
      child: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Container(
          constraints: BoxConstraints(
            maxWidth: 600,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const ReviewHeader(),
              
              if (currentStep == 0)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        RevieweeAvatarInfo(
                          revieweeId: controller.revieweeId,
                          categoryName: categoryName,
                        ),
                        const SizedBox(height: 16),
                        EventHeaderCard(announcementId: announcementId),
                        const SizedBox(height: 20),
                        const RatingCriteriaList(),
                        const SizedBox(height: 16),
                        const ErrorMessageBox(),
                      ],
                    ),
                  ),
                )
              else
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        RevieweeAvatarInfo(
                          revieweeId: controller.revieweeId,
                          categoryName: categoryName,
                        ),
                        const SizedBox(height: 20),
                        const CommentSection(),
                        const SizedBox(height: 16),
                        const ErrorMessageBox(),
                      ],
                    ),
                  ),
                ),
              
              if (currentStep == 0)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: GlimpseButton(
                    text: i18n.translate('continue'),
                    onPressed: () => controller.nextStep(i18n),
                  ),
                )
              else
                ReviewActions(
                  announcementId: announcementId,
                  applicationId: applicationId,
                  pendingReviewId: pendingReviewId,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
