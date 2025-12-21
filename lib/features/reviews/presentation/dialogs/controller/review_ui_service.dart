import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
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
  static List<Map<String, String>> criteriaList(BuildContext context) => ReviewCriteria.all(context);

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

    // Erro de autorização do Firestore (mais específico)
    if (errorString.contains('permission-denied') || 
        errorString.contains('insufficient permissions') ||
        errorString.contains('missing or insufficient permissions')) {
      return 'Erro de autorização: Você não tem permissão para enviar esta avaliação. Sua presença pode não ter sido confirmada pelo organizador.';
    }
    
    // Erro de duplicata
    if (errorString.contains('já avaliou')) {
      return 'Você já avaliou esta pessoa neste evento';
    }
    
    // Erro de autoavaliação
    if (errorString.contains('avaliar a si mesmo')) {
      return 'Erro: Você não pode avaliar a si mesmo';
    }
    
    // Erro de autenticação
    if (errorString.contains('autenticado')) {
      return 'Você precisa estar logado para avaliar';
    }
    
    // Erro de rede
    if (errorString.contains('network') || errorString.contains('conexão')) {
      return 'Erro de conexão. Verifique sua internet';
    }
    
    // Erro genérico
    debugPrint('⚠️ [ReviewUIService] Erro não reconhecido: $error');
    return 'Erro ao enviar avaliação. Tente novamente ou contate o suporte.';
  }
}
