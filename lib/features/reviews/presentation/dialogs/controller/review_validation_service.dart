import 'package:flutter/foundation.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';

/// Serviço responsável por validações de review
class ReviewValidationService {
  /// Valida se pode prosseguir para próximo step
  static bool canProceed(ReviewDialogState state) {
    // VALIDAÇÃO DE PERMISSÃO: Participante sem permissão não pode avaliar
    if (state.isParticipantReview && !state.allowedToReviewOwner) {
      debugPrint('❌ [canProceed] Participante sem permissão para avaliar owner');
      return false;
    }
    
    switch (state.currentReviewStep) {
      case ReviewStep.presence:
        return state.selectedParticipants.isNotEmpty;
      case ReviewStep.ratings:
        return hasCompletedRatings(state);
      case ReviewStep.badges:
        return hasCompletedRatings(state);
      case ReviewStep.comment:
        return hasCompletedRatings(state);
    }
  }

  /// Verifica se ratings estão completos
  static bool hasCompletedRatings(ReviewDialogState state) {
    if (state.isOwnerReview) {
      final participantId = state.currentParticipantId;
      if (participantId == null) {
        debugPrint('⚠️ [hasCompletedRatings] currentParticipantId é null');
        return false;
      }
      final currentRatings = state.ratingsPerParticipant[participantId] ?? {};
      final isComplete = currentRatings.length >= MINIMUM_REQUIRED_RATINGS;
      
      if (!isComplete) {
        debugPrint('❌ [hasCompletedRatings] Participante $participantId: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
      }
      return isComplete;
    } else {
      final isComplete = state.ratings.length >= MINIMUM_REQUIRED_RATINGS;
      if (!isComplete) {
        debugPrint('❌ [hasCompletedRatings] Owner: ${state.ratings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
      }
      return isComplete;
    }
  }

  /// Verifica se TODOS os participantes confirmados foram avaliados (owner mode)
  static bool hasEvaluatedAllParticipants(ReviewDialogState state) {
    if (!state.isOwnerReview) return true;
    
    if (state.selectedParticipants.isEmpty) {
      debugPrint('⚠️ [hasEvaluatedAllParticipants] Nenhum participante confirmado');
      return false;
    }
    
    for (final participantId in state.selectedParticipants) {
      final participantRatings = state.ratingsPerParticipant[participantId] ?? {};
      if (participantRatings.length < MINIMUM_REQUIRED_RATINGS) {
        debugPrint('❌ [hasEvaluatedAllParticipants] Participante $participantId não foi avaliado completamente');
        debugPrint('   Tem ${participantRatings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
        return false;
      }
    }
    
    debugPrint('✅ [hasEvaluatedAllParticipants] Todos os ${state.selectedParticipants.length} participantes foram avaliados');
    return true;
  }

  /// Valida se todos os participantes foram avaliados (para submit)
  /// Retorna lista de participantes não avaliados ou null se todos foram avaliados
  static List<String>? validateAllParticipantsReviewed(ReviewDialogState state) {
    debugPrint('🔍 [validateAllParticipantsReviewed] Validando avaliações');
    
    if (state.ratingsPerParticipant.isEmpty) {
      debugPrint('❌ ratingsPerParticipant vazio');
      return ['Nenhum participante avaliado'];
    }
    
    if (!hasEvaluatedAllParticipants(state)) {
      debugPrint('❌ Nem todos os participantes foram avaliados');
      debugPrint('   Total confirmados: ${state.selectedParticipants.length}');
      debugPrint('   Avaliados: ${state.ratingsPerParticipant.length}');
      
      final missingParticipants = <String>[];
      for (final participantId in state.selectedParticipants) {
        final participantRatings = state.ratingsPerParticipant[participantId] ?? {};
        if (participantRatings.length < MINIMUM_REQUIRED_RATINGS) {
          final profile = state.participantProfiles[participantId];
          final name = profile?.name ?? 'Participante';
          missingParticipants.add(name);
        }
      }
      
      return missingParticipants;
    }
    
    debugPrint('✅ Todos os participantes foram avaliados');
    return null;
  }

  /// Verifica se pode voltar para step anterior
  static bool canGoBack(ReviewDialogState state) {
    if (state.currentStep == 0) {
      if (state.needsPresenceConfirmation) return false;
      return false;
    }
    
    if (state.currentStep == 1) {
      if (state.isOwnerReview) {
        return state.currentParticipantIndex > 0 || state.needsPresenceConfirmation;
      }
      return true;
    }
    
    return true;
  }
}
