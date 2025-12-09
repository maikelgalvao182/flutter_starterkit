import 'package:flutter/material.dart';
import 'package:partiu/core/constants/glimpse_colors.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/presentation/dialogs/review_dialog.dart';
import 'package:partiu/shared/widgets/action_card.dart';

/// Card para avaliações pendentes
/// 
/// Wrapper específico do domínio que usa o ActionCard genérico
class ReviewCard extends StatelessWidget {
  const ReviewCard({
    required this.pendingReview,
    super.key,
  });

  final PendingReviewModel pendingReview;

  @override
  Widget build(BuildContext context) {
    final repo = ReviewRepository();

    debugPrint('🎴 ReviewCard build');
    debugPrint('   pendingReviewId: ${pendingReview.pendingReviewId}');
    debugPrint('   reviewerId: "${pendingReview.reviewerId}"');
    debugPrint('   revieweeId: "${pendingReview.revieweeId}"');
    debugPrint('   revieweeName: ${pendingReview.revieweeName}');
    debugPrint('   revieweePhotoUrl: ${pendingReview.revieweePhotoUrl}');
    
    // VALIDAÇÃO CRÍTICA: Detectar autoavaliação
    if (pendingReview.reviewerId == pendingReview.revieweeId) {
      debugPrint('❌ [ReviewCard] ERRO: Autoavaliação detectada!');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: GlimpseColors.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: GlimpseColors.error,
            width: 2,
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
                'Erro: Review inválido detectado (autoavaliação). Entre em contato com o suporte.',
                style: TextStyle(
                  color: GlimpseColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.close, color: GlimpseColors.error),
              onPressed: () async {
                await repo.dismissPendingReview(pendingReview.pendingReviewId);
              },
            ),
          ],
        ),
      );
    }

    return ActionCard(
      userId: pendingReview.revieweeId,
      userPhotoUrl: pendingReview.revieweePhotoUrl,
      textSpans: [
        TextSpan(
          text: pendingReview.revieweeName,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        const TextSpan(text: ' precisa ser avaliado no evento '),
        TextSpan(
          text: '${pendingReview.eventEmoji} ${pendingReview.eventTitle}',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ],
      timeAgo: _getTimeAgo(pendingReview.createdAt),
      primaryButtonText: 'Avaliar',
      primaryButtonColor: GlimpseColors.approveButtonColor,
      onPrimaryAction: () async {
        debugPrint('🎯 [ReviewCard] Abrindo ReviewDialog...');
        
        // Abre o ReviewDialog
        final result = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          isDismissible: false,
          enableDrag: false,
          builder: (dialogContext) => ReviewDialog(
            pendingReview: pendingReview,
          ),
        );

        debugPrint('🔍 [ReviewCard] Dialog retornou: $result');

        // Se não completou, lança erro para evitar remoção
        if (result != true) {
          throw Exception('Review cancelado');
        }
        
        debugPrint('✅ Review completado: ${pendingReview.pendingReviewId}');
      },
      secondaryButtonText: 'Dispensar',
      secondaryButtonColor: GlimpseColors.rejectButtonColor,
      onSecondaryAction: () async {
        await repo.dismissPendingReview(pendingReview.pendingReviewId);
        debugPrint('🗑️ Review dispensado: ${pendingReview.pendingReviewId}');
      },
    );
  }

  String _getTimeAgo(DateTime createdAt) {
    final now = DateTime.now();
    final difference = now.difference(createdAt);

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
