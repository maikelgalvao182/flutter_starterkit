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
import 'package:partiu/features/reviews/presentation/components/review_dialog_header.dart';
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

class _ReviewDialogContent extends StatefulWidget {
  final PendingReviewModel pendingReview;

  const _ReviewDialogContent({
    required this.pendingReview,
  });

  @override
  State<_ReviewDialogContent> createState() => _ReviewDialogContentState();
}

class _ReviewDialogContentState extends State<_ReviewDialogContent> {
  final ScrollController _scrollController = ScrollController();
  
  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Usar read() aqui para evitar rebuilds desnecessários do container principal
    // Os widgets filhos usarão Selector ou Consumer conforme necessário
    final controller = context.read<ReviewDialogController>();
    final screenHeight = MediaQuery.of(context).size.height;
    final maxHeight = screenHeight * 0.85; // 85% da altura da tela
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

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
              // Header componente reutilizável
              ReviewDialogHeader(
                onClose: () => _handleDismiss(context, controller),
              ),

              if (!isKeyboardOpen) ...[
                const SizedBox(height: 16),

                // Progress bar
                ReviewDialogProgressBar(controller: controller),
              ],

              const SizedBox(height: 24),

              // Content (steps)
              Flexible(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    children: [
                      // Aviso de permissão negada (apenas para participant)
                      Selector<ReviewDialogController, (bool, bool)>(
                        selector: (_, c) => (c.isParticipantReview, c.allowedToReviewOwner),
                        builder: (_, data, __) {
                          final isParticipant = data.$1;
                          final allowed = data.$2;
                          
                          if (isParticipant && !allowed) {
                            return Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: GlimpseColors.error.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: GlimpseColors.error.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: GlimpseColors.error,
                                        size: 24,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'Você não tem permissão para avaliar este evento. Sua presença pode não ter sido confirmada pelo organizador.',
                                          style: GoogleFonts.getFont(
                                            FONT_PLUS_JAKARTA_SANS,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                            color: GlimpseColors.error,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 24),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      
                      if (!isKeyboardOpen)
                        // Avatar e info do reviewee (apenas se não for STEP 0)
                        Selector<ReviewDialogController, bool>(
                          selector: (_, c) => !c.needsPresenceConfirmation || c.currentStep > 0,
                          builder: (_, showInfo, __) {
                            if (showInfo) {
                              return Column(
                                children: [
                                  ReviewDialogRevieweeInfo(
                                    controller: controller,
                                    pendingReview: widget.pendingReview,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        ),

                      // Step content com transição animada
                      Selector<ReviewDialogController, ReviewStep>(
                        selector: (_, c) => c.currentReviewStep,
                        builder: (_, currentStep, __) {
                          // Resetar scroll para o topo quando mudar de step
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (_scrollController.hasClients) {
                              _scrollController.jumpTo(0);
                            }
                          });
                          
                          return AnimatedSwitcher(
                            duration: const Duration(milliseconds: 250),
                            switchInCurve: Curves.easeInOut,
                            switchOutCurve: Curves.easeInOut,
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0.1, 0),
                                    end: Offset.zero,
                                  ).animate(animation),
                                  child: child,
                                ),
                              );
                            },
                            child: ReviewDialogStepContent(
                              key: ValueKey<ReviewStep>(currentStep),
                              controller: controller,
                            ),
                          );
                        },
                      ),

                      // Error message
                      Selector<ReviewDialogController, String?>(
                        selector: (_, c) => c.errorMessage,
                        builder: (_, errorMessage, __) {
                          if (errorMessage != null) {
                            return Column(
                              children: [
                                const SizedBox(height: 16),
                                ReviewDialogErrorMessage(
                                  errorMessage: errorMessage,
                                ),
                              ],
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Botão principal
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Selector<ReviewDialogController, (String, bool, bool)>(
                      selector: (_, c) => (
                        c.buttonText,  // Usando getter centralizado
                        c.isSubmitting || c.isTransitioning,
                        c.canProceed   // Usando getter centralizado
                      ),
                      builder: (_, data, __) {
                        final buttonText = data.$1;
                        final isProcessing = data.$2;
                        final canProceed = data.$3;
                        
                        return GlimpseButton(
                          text: buttonText,
                          isProcessing: isProcessing,
                          onPressed: canProceed
                              ? () => _handleButtonPress(context, controller)
                              : null,
                        );
                      },
                    ),
                  ],
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

  // ==================== HANDLERS ====================

  /// Handler unificado para botão principal - usa currentReviewStep do controller
  Future<void> _handleButtonPress(
    BuildContext context,
    ReviewDialogController controller,
  ) async {
    // PROTEÇÃO: Bloquear cliques durante processamento
    if (controller.isSubmitting || controller.isTransitioning) {
      debugPrint('⚠️ [_handleButtonPress] Processamento em andamento, ignorando clique');
      return;
    }
    
    // Usar o getter centralizado do controller para determinar ação
    switch (controller.currentReviewStep) {
      case ReviewStep.presence:
        final success = await controller.confirmPresenceAndProceed(
          widget.pendingReview.pendingReviewId,
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
        break;

      case ReviewStep.ratings:
        controller.goToBadgesStep();
        break;

      case ReviewStep.badges:
        controller.goToCommentStep();
        break;

      case ReviewStep.comment:
        // Verificar se owner tem mais participantes para avaliar
        if (controller.isOwnerReview && !controller.isLastParticipant) {
          // UI gerencia transição visual (não o controller)
          controller.nextParticipant();
          // Opcional: adicionar animação aqui se necessário
          // await Future.delayed(const Duration(milliseconds: 300));
        } else {
          // Submit final
          final success = controller.isOwnerReview
              ? await controller.submitAllReviews(
                  pendingReviewId: widget.pendingReview.pendingReviewId,
                )
              : await controller.submitReview(
                  pendingReviewId: widget.pendingReview.pendingReviewId,
                );

          if (success && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop(true);
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (context.mounted) {
                _showSuccessMessage(context, controller);
              }
            });
          }
        }
        break;
    }
  }

  Future<void> _handleDismiss(
    BuildContext context,
    ReviewDialogController controller,
  ) async {
    await controller.dismissReview(widget.pendingReview.pendingReviewId);
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