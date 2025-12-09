import 'package:partiu/features/reviews/domain/constants/review_criteria.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';

/// Serviço responsável por lógica de UI e apresentação
class ReviewUIService {
  /// Label do step atual
  static String getStepLabel(ReviewDialogState state) {
    switch (state.currentReviewStep) {
      case ReviewStep.presence:
        return 'Confirme quem apareceu';
      case ReviewStep.ratings:
        return 'Deixe uma avaliação';
      case ReviewStep.badges:
        return 'Deixe um elogio';
      case ReviewStep.comment:
        return 'Deixe um comentário';
    }
  }

  /// Texto do botão principal
  static String getButtonText(ReviewDialogState state, bool hasCommentText) {
    switch (state.currentReviewStep) {
      case ReviewStep.presence:
        final count = state.selectedParticipants.length;
        return count > 0 ? 'Confirmar ($count)' : 'Confirmar';
      case ReviewStep.ratings:
      case ReviewStep.badges:
        return 'Continuar';
      case ReviewStep.comment:
        if (state.isOwnerReview && !state.isLastParticipant) {
          return 'Próximo Participante';
        }
        return 'Enviar Avaliação';
    }
  }

  /// Se deve mostrar botão "Pular"
  static bool shouldShowSkipButton(ReviewDialogState state, bool hasCommentText) {
    return state.currentReviewStep == ReviewStep.comment && !hasCommentText;
  }

  /// Lista de critérios para exibir
  static List<Map<String, String>> get criteriaList => ReviewCriteria.all;

  /// Obtém ratings do participante atual (ou do participant)
  static Map<String, int> getCurrentRatings(ReviewDialogState state) {
    if (state.isOwnerReview) {
      final participantId = state.currentParticipantId;
      if (participantId == null) return {};
      state.ratingsPerParticipant[participantId] ??= {};
      // Retornar uma cópia para que o Flutter detecte mudanças
      return Map<String, int>.from(state.ratingsPerParticipant[participantId]!);
    }
    // Retornar uma cópia para que o Flutter detecte mudanças
    return Map<String, int>.from(state.ratings);
  }

  /// Obtém badges do participante atual (ou do participant)
  static List<String> getCurrentBadges(ReviewDialogState state) {
    if (state.isOwnerReview) {
      final participantId = state.currentParticipantId;
      if (participantId == null) return [];
      state.badgesPerParticipant[participantId] ??= [];
      // Retornar uma cópia para que o Flutter detecte mudanças
      return List<String>.from(state.badgesPerParticipant[participantId]!);
    }
    // Retornar uma cópia para que o Flutter detecte mudanças
    return List<String>.from(state.selectedBadges);
  }

  /// Traduz exceções para mensagens amigáveis
  static String getErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('já avaliou')) {
      return 'Você já avaliou esta pessoa neste evento';
    } else if (errorString.contains('autenticado')) {
      return 'Você precisa estar logado para avaliar';
    } else if (errorString.contains('network')) {
      return 'Erro de conexão. Verifique sua internet';
    } else {
      return 'Erro ao enviar avaliação. Tente novamente';
    }
  }
}
