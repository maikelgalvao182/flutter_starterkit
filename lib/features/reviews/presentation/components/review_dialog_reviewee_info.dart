import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/core/utils/app_localizations.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';
import 'package:partiu/shared/widgets/reactive/reactive_user_name_with_badge.dart';

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
    final i18n = AppLocalizations.of(context);

    // PRÉ-CARREGAMENTO: Usar getters do controller
    // Dados já estão em memória via PendingReviewModel enriquecido
    final displayName = controller.currentRevieweeName;
    final displayPhotoUrl = controller.currentRevieweePhotoUrl;

    debugPrint('🔍 [RevieweeInfo] build (PRÉ-CARREGADO)');
    debugPrint('   - isOwnerReview: ${controller.isOwnerReview}');
    debugPrint('   - presenceConfirmed: ${controller.presenceConfirmed}');
    debugPrint('   - currentStep: ${controller.currentStep}');
    debugPrint('   ✅ displayName: $displayName');
    debugPrint('   ✅ displayPhotoUrl: $displayPhotoUrl');

    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 32,
          backgroundColor: GlimpseColors.primary.withValues(alpha: 0.2),
          backgroundImage: displayPhotoUrl != null
              ? NetworkImage(displayPhotoUrl)
              : null,
          child: displayPhotoUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: GoogleFonts.getFont(
                    FONT_PLUS_JAKARTA_SANS,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: GlimpseColors.primary,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 12),

        // Nome
        ReactiveUserNameWithBadge(
          userId: controller.currentRevieweeId,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 16,
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
            i18n
                .translate('review_dialog_step_counter')
                .replaceAll('{current}', (controller.currentParticipantIndex + 1).toString())
                .replaceAll('{total}', controller.selectedParticipants.length.toString()),
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
