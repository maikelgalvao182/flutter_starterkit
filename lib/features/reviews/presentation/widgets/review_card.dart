import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/home/presentation/widgets/animated_removal_wrapper.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog.dart';
import 'package:partiu/shared/widgets/glimpse_button.dart';
import 'package:partiu/shared/widgets/stable_avatar.dart';

/// Card para avaliações pendentes
/// 
/// Exibe:
/// - Avatar do usuário a ser avaliado
/// - Nome + "precisa ser avaliado" + activityText
/// - Tempo relativo (há X horas)
/// - Botões: Avaliar (azul) e Dispensar (cinza)
class ReviewCard extends StatefulWidget {
  const ReviewCard({
    required this.pendingReview,
    super.key,
  });

  final PendingReviewModel pendingReview;

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  final ReviewRepository _repo = ReviewRepository();
  final GlobalKey<AnimatedRemovalWrapperState> _animationKey = GlobalKey();
  bool _isProcessing = false;

  Future<void> _handleReview() async {
    if (_isProcessing) return;

    debugPrint('🎯 [ReviewCard] _handleReview iniciado');
    debugPrint('   - pendingReviewId: ${widget.pendingReview.pendingReviewId}');
    
    setState(() => _isProcessing = true);

    try {
      debugPrint('🔍 [ReviewCard] Abrindo ReviewDialog...');
      // Abre o ReviewDialog
      final result = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        isDismissible: false,
        enableDrag: false,
        builder: (dialogContext) => ReviewDialog(
          pendingReview: widget.pendingReview,
        ),
      );

      debugPrint('🔍 [ReviewCard] Dialog retornou: $result');

      // Se completou o review, anima remoção
      if (result == true) {
        debugPrint('✅ [ReviewCard] Review completado, animando remoção...');
        if (mounted) {
          await _animationKey.currentState?.animateRemoval();
        }
        debugPrint('✅ Review enviado: ${widget.pendingReview.pendingReviewId}');
      } else {
        debugPrint('ℹ️ [ReviewCard] Review cancelado ou dispensado');
      }
    } catch (e, stack) {
      debugPrint('❌ Erro ao abrir review dialog: $e');
      debugPrint('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao abrir avaliação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handleDismiss() async {
    if (_isProcessing) return;

    debugPrint('🗑️ [ReviewCard] _handleDismiss iniciado');
    debugPrint('   - pendingReviewId: ${widget.pendingReview.pendingReviewId}');
    
    setState(() => _isProcessing = true);

    try {
      debugPrint('🔍 [ReviewCard] Animando remoção...');
      // Anima remoção primeiro
      await _animationKey.currentState?.animateRemoval();
      
      debugPrint('🔍 [ReviewCard] Marcando como dismissed no backend...');
      // Depois marca como dismissed no backend
      await _repo.dismissPendingReview(widget.pendingReview.pendingReviewId);
      debugPrint('✅ Review dispensado: ${widget.pendingReview.pendingReviewId}');
    } catch (e, stack) {
      debugPrint('❌ Erro ao dispensar review: $e');
      debugPrint('Stack trace: $stack');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao dispensar avaliação'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('🎴 [ReviewCard] build - pendingReviewId: ${widget.pendingReview.pendingReviewId}');
    debugPrint('   - revieweeName: ${widget.pendingReview.revieweeName}');
    debugPrint('   - eventTitle: ${widget.pendingReview.eventTitle}');
    debugPrint('   - reviewerRole: ${widget.pendingReview.reviewerRole}');
    
    return AnimatedRemovalWrapper(
      key: _animationKey,
      onRemove: () {
        // Callback vazio - a remoção real acontece via Stream
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: GlimpseColors.borderColorLight,
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            StableAvatar(
              userId: widget.pendingReview.revieweeId,
              photoUrl: widget.pendingReview.revieweePhotoUrl,
              size: 48,
              borderRadius: BorderRadius.circular(8),
              enableNavigation: true,
            ),

            const SizedBox(width: 12),

            // Informações e Botões
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Nome + texto
                  _NameText(
                    name: widget.pendingReview.revieweeName,
                    eventTitle: widget.pendingReview.eventTitle,
                    emoji: widget.pendingReview.eventEmoji,
                  ),

                  const SizedBox(height: 4),

                  // Tempo relativo
                  Text(
                    _getTimeAgo(),
                    style: GoogleFonts.getFont(
                      FONT_PLUS_JAKARTA_SANS,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: GlimpseColors.textSubTitle,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Botões de ação
                  Row(
                    children: [
                      Expanded(
                        child: GlimpseButton(
                          text: 'Avaliar',
                          backgroundColor: GlimpseColors.approveButtonColor,
                          height: 38,
                          fontSize: 14,
                          noPadding: true,
                          isProcessing: _isProcessing,
                          onPressed: _handleReview,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GlimpseButton(
                          text: 'Dispensar',
                          backgroundColor: GlimpseColors.rejectButtonColor,
                          height: 38,
                          fontSize: 14,
                          noPadding: true,
                          isProcessing: _isProcessing,
                          onPressed: _handleDismiss,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeAgo() {
    final now = DateTime.now();
    final difference = now.difference(widget.pendingReview.createdAt);

    if (difference.inMinutes < 1) {
      return 'agora mesmo';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else {
      return 'há ${difference.inDays} dia${difference.inDays > 1 ? 's' : ''}';
    }
  }
}

/// Widget const para texto formatado
class _NameText extends StatelessWidget {
  const _NameText({
    required this.name,
    required this.eventTitle,
    required this.emoji,
  });

  final String name;
  final String eventTitle;
  final String emoji;

  @override
  Widget build(BuildContext context) {
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: GoogleFonts.getFont(
          FONT_PLUS_JAKARTA_SANS,
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: GlimpseColors.primaryColorLight,
        ),
        children: [
          TextSpan(
            text: name,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
          const TextSpan(text: ' precisa ser avaliado no evento '),
          TextSpan(
            text: '$emoji $eventTitle',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
