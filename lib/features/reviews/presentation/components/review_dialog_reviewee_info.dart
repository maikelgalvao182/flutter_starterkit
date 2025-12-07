import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';

/// Informações do usuário sendo avaliado (avatar, nome, contador)
class ReviewDialogRevieweeInfo extends StatelessWidget {
  final ReviewDialogController controller;
  final PendingReviewModel pendingReview;

  const ReviewDialogRevieweeInfo({
    required this.controller,
    required this.pendingReview,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    // Nome e foto dinâmicos
    String displayName;
    String? displayPhotoUrl;

    if (controller.isOwnerReview && controller.presenceConfirmed) {
      // Owner avaliando participante atual
      final participantId = controller.currentParticipantId;
      if (participantId != null) {
        final profile = controller.participantProfiles[participantId];
        displayName = profile?.name ?? 'Participante';
        displayPhotoUrl = profile?.photoUrl;
      } else {
        displayName = 'Participante';
        displayPhotoUrl = null;
      }
    } else {
      // Participant avaliando owner
      displayName = pendingReview.revieweeName;
      displayPhotoUrl = pendingReview.revieweePhotoUrl;
    }

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 40,
          backgroundColor: GlimpseColors.primary.withOpacity(0.2),
          backgroundImage: displayPhotoUrl != null
              ? NetworkImage(displayPhotoUrl)
              : null,
          child: displayPhotoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: GlimpseColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),

        // Nome
        Text(
          displayName,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: GlimpseColors.textPrimary,
          ),
        ),

        // Contador de participantes (owner mode)
        if (controller.isOwnerReview &&
            controller.presenceConfirmed &&
            controller.selectedParticipants.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            '${controller.currentParticipantIndex + 1} de ${controller.selectedParticipants.length}',
            style: GoogleFonts.getFont(
              FONT_PLUS_JAKARTA_SANS,
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: GlimpseColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
