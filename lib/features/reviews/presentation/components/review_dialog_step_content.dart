import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/presentation/components/badge_selection_step.dart';
import 'package:partiu/features/reviews/presentation/components/comment_step.dart';
import 'package:partiu/features/reviews/presentation/components/participant_confirmation_step.dart';
import 'package:partiu/features/reviews/presentation/components/rating_criteria_step.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';

/// Renderiza o conteúdo do step atual do ReviewDialog
class ReviewDialogStepContent extends StatelessWidget {
  final ReviewDialogController controller;

  const ReviewDialogStepContent({
    required this.controller,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // STEP 0 (Owner): Confirmar presença
    if (controller.needsPresenceConfirmation && controller.currentStep == 0) {
      return ParticipantConfirmationStep(
        participantIds: controller.participantIds,
        participantProfiles: controller.participantProfiles,
        selectedParticipants: controller.selectedParticipants,
        onToggleParticipant: controller.toggleParticipant,
        eventTitle: controller.eventTitle,
        eventEmoji: controller.eventEmoji,
        eventDate: controller.eventScheduleDate,
      );
    }

    final isRatingStep = controller.currentStep == 1 ||
        (controller.currentStep == 0 && !controller.needsPresenceConfirmation);
    final isBadgeStep = controller.currentStep == 2 ||
        (controller.currentStep == 1 && !controller.needsPresenceConfirmation);

    // STEP 1 (ou 0 para participant): Ratings
    if (isRatingStep) {
      return RatingCriteriaStep(
        ratings: controller.getCurrentRatings(),
        onRatingChanged: controller.setRating,
      );
    }

    // STEP 2 (ou 1 para participant): Badges
    if (isBadgeStep) {
      return BadgeSelectionStep(
        selectedBadges: controller.getCurrentBadges(),
        onBadgeToggle: controller.toggleBadge,
      );
    }

    // STEP 3 (ou 2 para participant): Comentário
    return CommentStep(
      controller: controller.commentController,
    );
  }
}
