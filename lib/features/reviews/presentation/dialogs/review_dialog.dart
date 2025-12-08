import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog_controller.dart';
import 'package:partiu/features/reviews/presentation/components/review_dialog_progress_bar.dart';
import 'package:partiu/features/reviews/presentation/components/review_dialog_reviewee_info.dart';
import 'package:partiu/features/reviews/presentation/components/review_dialog_error_message.dart';
import 'package:partiu/features/reviews/presentation/components/review_dialog_step_content.dart';
import 'package:partiu/shared/widgets/glimpse_back_button.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/glimpse_close_button.dart';

/// Bottom sheet para avaliar um participante/owner após um evento
class ReviewDialog extends StatelessWidget {
  final PendingReviewModel pendingReview;

  const ReviewDialog({
    required this.pendingReview,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final controller = ReviewDialogController(
          eventId: pendingReview.eventId,
          revieweeId: pendingReview.revieweeId,
          reviewerRole: pendingReview.reviewerRole,
        );
        controller.initializeFromPendingReview(pendingReview);
        return controller;
      },
      child: _ReviewDialogContent(
        pendingReview: pendingReview,
      ),
    );
  }
}

class _ReviewDialogContent extends StatelessWidget {
  final PendingReviewModel pendingReview;

  const _ReviewDialogContent({
    required this.pendingReview,
  });

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReviewDialogController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // 85% da altura da tela

    return Container(
      constraints: BoxConstraints(
        maxHeight: maxHeight,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle e header
              Padding(
                padding: const EdgeInsets.only(
                  top: 12,
                  left: 20,
                  right: 20,
                ),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: GlimpseColors.borderColorLight,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Header: Back + Título + Close
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Botão voltar
                        if (controller.canGoBack)
                          GlimpseBackButton(
                            onTap: controller.previousStep,
                          )
                        else
                          const SizedBox(width: 32),

                        // Título centralizado
                        Expanded(
                          child: Text(
                            controller.currentStepLabel,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.getFont(
                              FONT_PLUS_JAKARTA_SANS,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: GlimpseColors.primaryColorLight,
                            ),
                          ),
                        ),

                        // Botão fechar
                        GlimpseCloseButton(
                          size: 32,
                          onPressed: () => _handleDismiss(context, controller),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Progress bar
              ReviewDialogProgressBar(controller: controller),

              const SizedBox(height: 24),

              // Content (steps)
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Avatar e info do reviewee (apenas se não for STEP 0)
                      if (!controller.needsPresenceConfirmation ||
                          controller.currentStep > 0) ...[
                        ReviewDialogRevieweeInfo(
                          controller: controller,
                          pendingReview: pendingReview,
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Step content
                      ReviewDialogStepContent(controller: controller),

                      // Error message
                      if (controller.errorMessage != null) ...[
                        const SizedBox(height: 16),
                        ReviewDialogErrorMessage(
                          errorMessage: controller.errorMessage!,
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GlimpseButton(
                  text: _getButtonText(controller),
                  isProcessing: controller.isSubmitting || controller.isTransitioning,
                  onPressed: _canProceed(controller)
                      ? () => _handleButtonPress(context, controller)
                      : null,
                ),
              ),

              // Padding bottom para safe area
              SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
            ],
          ),
        ),
      ),
    );
  }

  String _getButtonText(ReviewDialogController controller) {
    // STEP 0 (Owner): Confirmar presença
    if (controller.needsPresenceConfirmation && controller.currentStep == 0) {
      final count = controller.selectedParticipants.length;
      return count > 0 ? 'Confirmar ($count)' : 'Confirmar';
    }

    final isCommentStep = controller.currentStep == 3 ||
        (controller.currentStep == 2 && !controller.needsPresenceConfirmation);

    if (isCommentStep) {
      if (controller.isOwnerReview && !controller.isLastParticipant) {
        return 'Próximo Participante';
      }
      return 'Enviar Avaliação';
    }

    return 'Continuar';
  }

  bool _shouldShowSkipButton(ReviewDialogController controller) {
    final isCommentStep = controller.currentStep == 3 ||
        (controller.currentStep == 2 && !controller.needsPresenceConfirmation);
    return isCommentStep && controller.commentController.text.isEmpty;
  }

  bool _canProceed(ReviewDialogController controller) {
    // STEP 0 (Owner): Precisa selecionar pelo menos 1 participante
    if (controller.needsPresenceConfirmation && controller.currentStep == 0) {
      return controller.selectedParticipants.isNotEmpty;
    }

    // STEP 1 (Ratings): Precisa ter avaliado todos os critérios
    if ((controller.needsPresenceConfirmation && controller.currentStep == 1) ||
        (!controller.needsPresenceConfirmation && controller.currentStep == 0)) {
      if (controller.isOwnerReview) {
        final participantId = controller.currentParticipantId;
        if (participantId == null) return false;
        final ratings = controller.ratingsPerParticipant[participantId] ?? {};
        return ratings.length >= 5; // Todos os 5 critérios avaliados
      } else {
        return controller.ratings.length >= 5;
      }
    }

    // STEP 2 (Badges): Opcional, sempre pode prosseguir
    if ((controller.needsPresenceConfirmation && controller.currentStep == 2) ||
        (!controller.needsPresenceConfirmation && controller.currentStep == 1)) {
      return true;
    }

    // STEP 3 (Comentário): Opcional, sempre pode prosseguir
    return true;
  }

  // ==================== HANDLERS ====================
  Future<void> _handleButtonPress(
    BuildContext context,
    ReviewDialogController controller,
  ) async {
    // STEP 0 (Owner): Confirmar presença
    if (controller.needsPresenceConfirmation && controller.currentStep == 0) {
      final success = await controller.confirmPresenceAndProceed(
        pendingReview.pendingReviewId,
      );
      if (!success && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              controller.errorMessage ?? 'Erro ao confirmar presença',
              style: GoogleFonts.getFont(
                FONT_PLUS_JAKARTA_SANS,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: GlimpseColors.error,
          ),
        );
      }
      return;
    }

    final isRatingStep = controller.currentStep == 1 ||
        (controller.currentStep == 0 && !controller.needsPresenceConfirmation);
    final isBadgeStep = controller.currentStep == 2 ||
        (controller.currentStep == 1 && !controller.needsPresenceConfirmation);
    final isCommentStep = controller.currentStep == 3 ||
        (controller.currentStep == 2 && !controller.needsPresenceConfirmation);

    if (isRatingStep) {
      controller.goToBadgesStep();
    } else if (isBadgeStep) {
      controller.goToCommentStep();
    } else if (isCommentStep) {
      // Verificar se owner tem mais participantes para avaliar
      if (controller.isOwnerReview && !controller.isLastParticipant) {
        await controller.nextParticipant();
      } else {
        // Submit final
        final success = await controller.submitReview(
          pendingReviewId: pendingReview.pendingReviewId,
        );
        if (success && context.mounted) {
          Navigator.of(context, rootNavigator: true).pop(true);
          await Future.delayed(const Duration(milliseconds: 100));
          if (context.mounted) {
            _showSuccessMessage(context, controller);
          }
        }
      }
    }
  }

  Future<void> _handleSkipComment(
    BuildContext context,
    ReviewDialogController controller,
  ) async {
    final success = await controller.skipCommentAndSubmit(
      pendingReviewId: pendingReview.pendingReviewId,
    );
    if (success && context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(true);
      await Future.delayed(const Duration(milliseconds: 100));
      if (context.mounted) {
        _showSuccessMessage(context, controller);
      }
    }
  }

  Future<void> _handleDismiss(
    BuildContext context,
    ReviewDialogController controller,
  ) async {
    final success = await controller.dismissReview(pendingReview.pendingReviewId);
    if (context.mounted) {
      Navigator.of(context, rootNavigator: true).pop(false);
    }
  }

  void _showSuccessMessage(BuildContext context, ReviewDialogController controller) {
    String message;
    if (controller.isOwnerReview && controller.selectedParticipants.length > 1) {
      message = '✅ ${controller.selectedParticipants.length} avaliações enviadas com sucesso!';
    } else {
      message = '✅ Avaliação enviada com sucesso!';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.getFont(
            FONT_PLUS_JAKARTA_SANS,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: GlimpseColors.success,
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
