import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';

/// Serviço responsável por navegação entre steps
class ReviewNavigationService {
  /// Avança para step de badges
  static String? goToBadgesStep(ReviewDialogState state) {
    // Validação extra: Verificar se temos um participante válido (owner mode)
    if (state.isOwnerReview && state.currentParticipantId == null) {
      debugPrint('❌ [goToBadgesStep] currentParticipantId é null');
      return 'Erro: nenhum participante selecionado';
    }

    // Validação: exigir ratings completos
    final currentRatings = state.isOwnerReview
        ? (state.ratingsPerParticipant[state.currentParticipantId] ?? {})
        : state.ratings;
        
    if (currentRatings.length < MINIMUM_REQUIRED_RATINGS) {
      debugPrint('❌ [goToBadgesStep] Ratings insuficientes: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS');
      return 'Por favor, avalie todos os $MINIMUM_REQUIRED_RATINGS critérios obrigatórios';
    }

    debugPrint('✅ [goToBadgesStep] Avançando para badges. Ratings: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS');
    return null; // Sem erro
  }

  /// Prepara transição para próximo participante
  static Map<String, dynamic> prepareNextParticipant(
    ReviewDialogState state,
    TextEditingController commentController,
  ) {
    final result = <String, dynamic>{};
    
    if (!state.isOwnerReview || state.currentParticipantIndex >= state.selectedParticipants.length - 1) {
      result['shouldTransition'] = false;
      return result;
    }

    // Salvar comentário do participante atual
    final participantId = state.currentParticipantId;
    if (participantId != null) {
      state.commentPerParticipant[participantId] = commentController.text.trim();
    }

    result['shouldTransition'] = true;
    result['newIndex'] = state.currentParticipantIndex + 1;
    result['newStep'] = 1; // Voltar para ratings
    
    // Preparar dados do próximo participante
    state.currentParticipantIndex++;
    final nextParticipantId = state.currentParticipantId;
    
    if (nextParticipantId != null) {
      state.ratingsPerParticipant[nextParticipantId] ??= {};
      state.badgesPerParticipant[nextParticipantId] ??= [];
      state.commentPerParticipant[nextParticipantId] ??= '';
      
      result['nextComment'] = state.commentPerParticipant[nextParticipantId] ?? '';
    }
    
    debugPrint('🔄 [prepareNextParticipant] Próximo participante:');
    debugPrint('   - Index: ${state.currentParticipantIndex}');
    debugPrint('   - ID: $nextParticipantId');
    
    return result;
  }

  /// Lógica para voltar step
  static Map<String, dynamic> preparePreviousStep(
    ReviewDialogState state,
    TextEditingController commentController,
  ) {
    debugPrint('⬅️ [preparePreviousStep] Voltando step');
    debugPrint('   - currentStep: ${state.currentStep}');
    debugPrint('   - isOwnerReview: ${state.isOwnerReview}');
    debugPrint('   - currentParticipantIndex: ${state.currentParticipantIndex}');

    final result = <String, dynamic>{};

    // OWNER: Se estiver no primeiro step de avaliação (Ratings = step 1)
    if (state.isOwnerReview && state.currentStep == 1) {
      // Se não for o primeiro participante, volta para o comentário do anterior
      if (state.currentParticipantIndex > 0) {
        // Salvar comentário do participante atual
        final currentId = state.currentParticipantId;
        if (currentId != null) {
          state.commentPerParticipant[currentId] = commentController.text.trim();
        }
        
        result['newIndex'] = state.currentParticipantIndex - 1;
        result['newStep'] = 3;
        
        // Restaurar comentário do participante anterior
        state.currentParticipantIndex--;
        final previousId = state.currentParticipantId;
        if (previousId != null) {
          result['previousComment'] = state.commentPerParticipant[previousId] ?? '';
        }
        
        debugPrint('   ✅ Voltou para comentário do participante ${state.currentParticipantIndex}');
        return result;
      }
      
      // Se for o primeiro participante e tiver confirmação de presença
      if (state.needsPresenceConfirmation) {
        result['newStep'] = 0;
        debugPrint('   ✅ Voltou para confirmação de presença');
        return result;
      }
      
      debugPrint('   ⚠️ Já está no primeiro step, não pode voltar');
      result['canGoBack'] = false;
      return result;
    }

    // PARTICIPANT ou OWNER em outros steps
    if (state.currentStep > 0) {
      result['newStep'] = state.currentStep - 1;
      debugPrint('   ✅ Voltou para step ${state.currentStep - 1}');
      return result;
    }

    debugPrint('   ⚠️ Já está no step 0, não pode voltar');
    result['canGoBack'] = false;
    return result;
  }
}
