import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/domain/constants/review_criteria.dart';

/// REGRA DE NEGÓCIO: Número mínimo de critérios obrigatórios para avançar
const int MINIMUM_REQUIRED_RATINGS = 4;

/// Tipos de steps no fluxo de review
enum ReviewStep {
  presence,  // Apenas owner
  ratings,
  badges,
  comment,
}

/// Controller para o ReviewDialog
/// Owner: 4 steps (0: Confirmar presença, 1: Ratings, 2: Badges, 3: Comentário)
/// Participant: 3 steps (0: Ratings, 1: Badges, 2: Comentário)
class ReviewDialogController extends ChangeNotifier {
  final ReviewRepository _repository = ReviewRepository();
  
  String eventId;
  String revieweeId;
  String reviewerRole;
  String reviewerId;
  String eventTitle;
  String eventEmoji;
  String? eventLocationName;
  DateTime? eventScheduleDate;

  ReviewDialogController({
    required this.eventId,
    required this.revieweeId,
    required this.reviewerRole,
    this.reviewerId = '',
    this.eventTitle = '',
    this.eventEmoji = '🎉',
    this.eventLocationName,
    this.eventScheduleDate,
  });

  // Step atual
  int currentStep = 0;

  // ==================== OWNER: CONFIRMAÇÃO DE PRESENÇA (STEP 0) ====================
  
  bool presenceConfirmed = false;
  Set<String> selectedParticipants = {};
  List<String> participantIds = [];
  Map<String, ParticipantProfile> participantProfiles = {};

  // ==================== RATINGS POR PARTICIPANTE (OWNER) ====================
  
  // Owner avalia cada participante com notas diferentes
  Map<String, Map<String, int>> ratingsPerParticipant = {};
  Map<String, List<String>> badgesPerParticipant = {};
  Map<String, String> commentPerParticipant = {};
  
  // Participante atual sendo avaliado (owner mode)
  int currentParticipantIndex = 0;
  String? get currentParticipantId {
    if (selectedParticipants.isEmpty) {
      debugPrint('⚠️ [currentParticipantId] selectedParticipants está vazio');
      return null;
    }
    
    if (currentParticipantIndex < 0 || currentParticipantIndex >= selectedParticipants.length) {
      debugPrint('❌ [currentParticipantId] Índice inválido: $currentParticipantIndex de ${selectedParticipants.length}');
      return null;
    }
    
    return selectedParticipants.elementAt(currentParticipantIndex);
  }
  
  // ==================== RATINGS SIMPLES (PARTICIPANT) ====================
  
  // Participant avalia owner com ratings únicos
  final Map<String, int> ratings = {};
  final List<String> selectedBadges = [];
  final TextEditingController commentController = TextEditingController();

  // ==================== CONTROLE DE PERMISSÃO (PARTICIPANT) ====================
  
  bool allowedToReviewOwner = true; // Default true para compatibilidade

  // Estado
  bool isSubmitting = false;
  bool isTransitioning = false;
  String? errorMessage;
  
  // Flag para agrupar notificações
  bool _isBatchUpdating = false;
  bool _needsNotification = false;

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }
  
  /// Executa múltiplas atualizações sem notificar até o final
  /// Reduz rebuilds desnecessários
  void _batchUpdate(void Function() updates) {
    _isBatchUpdating = true;
    _needsNotification = false;
    try {
      updates();
    } finally {
      _isBatchUpdating = false;
      if (_needsNotification) {
        notifyListeners();
      }
    }
  }
  
  @override
  void notifyListeners() {
    if (_isBatchUpdating) {
      _needsNotification = true;
    } else {
      super.notifyListeners();
    }
  }

  // ==================== GETTERS ====================

  bool get isOwnerReview => reviewerRole == 'owner';
  bool get isParticipantReview => reviewerRole == 'participant';
  
  bool get needsPresenceConfirmation =>
      isOwnerReview && !presenceConfirmed && participantIds.isNotEmpty;
  
  int get totalSteps => needsPresenceConfirmation ? 4 : 3;
  
  bool get isLastParticipant =>
      currentParticipantIndex >= selectedParticipants.length - 1;

  /// FONTE ÚNICA DE VERDADE: Converte currentStep (int) para ReviewStep (enum)
  /// Esta é a ÚNICA lógica que decide qual step estamos
  ReviewStep get currentReviewStep {
    if (isOwnerReview) {
      // Owner: 4 steps (0: Presence, 1: Ratings, 2: Badges, 3: Comment)
      switch (currentStep) {
        case 0:
          return ReviewStep.presence;
        case 1:
          return ReviewStep.ratings;
        case 2:
          return ReviewStep.badges;
        case 3:
          return ReviewStep.comment;
        default:
          return ReviewStep.comment;
      }
    } else {
      // Participant: 3 steps (0: Ratings, 1: Badges, 2: Comment)
      switch (currentStep) {
        case 0:
          return ReviewStep.ratings;
        case 1:
          return ReviewStep.badges;
        case 2:
          return ReviewStep.comment;
        default:
          return ReviewStep.comment;
      }
    }
  }

  /// Label do step atual - DERIVADO de currentReviewStep
  String get currentStepLabel {
    switch (currentReviewStep) {
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

  /// Validação se pode prosseguir - DERIVADA de currentReviewStep
  bool get canProceed {
    // VALIDAÇÃO DE PERMISSÃO: Participante sem permissão não pode avaliar
    if (isParticipantReview && !allowedToReviewOwner) {
      debugPrint('❌ [canProceed] Participante sem permissão para avaliar owner');
      return false;
    }
    
    switch (currentReviewStep) {
      case ReviewStep.presence:
        return selectedParticipants.isNotEmpty;
      case ReviewStep.ratings:
        // BUG #11/#12 FIX: Exigir ratings completos (mínimo MINIMUM_REQUIRED_RATINGS)
        return hasCompletedRatings;
      case ReviewStep.badges:
        // BUG #11 FIX: Não permitir pular badges sem ter ratings
        return hasCompletedRatings;
      case ReviewStep.comment:
        // BUG #11 FIX: Não permitir finalizar sem ratings obrigatórios
        return hasCompletedRatings;
    }
  }

  /// Texto do botão principal - DERIVADO de currentReviewStep
  String get buttonText {
    switch (currentReviewStep) {
      case ReviewStep.presence:
        final count = selectedParticipants.length;
        return count > 0 ? 'Confirmar ($count)' : 'Confirmar';
      case ReviewStep.ratings:
      case ReviewStep.badges:
        return 'Continuar';
      case ReviewStep.comment:
        if (isOwnerReview && !isLastParticipant) {
          return 'Próximo Participante';
        }
        return 'Enviar Avaliação';
    }
  }

  /// Se deve mostrar botão "Pular" - DERIVADO de currentReviewStep
  bool get shouldShowSkipButton {
    return currentReviewStep == ReviewStep.comment &&
        commentController.text.isEmpty;
  }

  /// Se ratings estão completos
  /// BUG #11/#12 FIX: Validação rigorosa com constante MINIMUM_REQUIRED_RATINGS
  bool get hasCompletedRatings {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      if (participantId == null) {
        debugPrint('⚠️ [hasCompletedRatings] currentParticipantId é null');
        return false;
      }
      final currentRatings = ratingsPerParticipant[participantId] ?? {};
      final isComplete = currentRatings.length >= MINIMUM_REQUIRED_RATINGS;
      
      if (!isComplete) {
        debugPrint('❌ [hasCompletedRatings] Participante $participantId: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
      }
      return isComplete;
    } else {
      final isComplete = ratings.length >= MINIMUM_REQUIRED_RATINGS;
      if (!isComplete) {
        debugPrint('❌ [hasCompletedRatings] Owner: ${ratings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
      }
      return isComplete;
    }
  }

  /// BUG #11 FIX: Verifica se TODOS os participantes confirmados foram avaliados (owner mode)
  bool get hasEvaluatedAllParticipants {
    if (!isOwnerReview) return true; // Participant só avalia 1 pessoa
    
    if (selectedParticipants.isEmpty) {
      debugPrint('⚠️ [hasEvaluatedAllParticipants] Nenhum participante confirmado');
      return false;
    }
    
    // Verificar se CADA participante tem ratings completos
    for (final participantId in selectedParticipants) {
      final participantRatings = ratingsPerParticipant[participantId] ?? {};
      if (participantRatings.length < MINIMUM_REQUIRED_RATINGS) {
        debugPrint('❌ [hasEvaluatedAllParticipants] Participante $participantId não foi avaliado completamente');
        debugPrint('   Tem ${participantRatings.length}/$MINIMUM_REQUIRED_RATINGS critérios');
        return false;
      }
    }
    
    debugPrint('✅ [hasEvaluatedAllParticipants] Todos os ${selectedParticipants.length} participantes foram avaliados');
    return true;
  }

  // ==================== INICIALIZAÇÃO ====================

  /// Inicializa controller a partir de PendingReview
  void initializeFromPendingReview(PendingReviewModel pendingReview) {
    eventId = pendingReview.eventId;
    reviewerId = pendingReview.reviewerId;
    revieweeId = pendingReview.revieweeId;
    reviewerRole = pendingReview.reviewerRole;
    eventTitle = pendingReview.eventTitle;
    eventEmoji = pendingReview.eventEmoji;
    eventLocationName = pendingReview.eventLocation;
    eventScheduleDate = pendingReview.eventDate;

    if (pendingReview.isOwnerReview) {
      participantIds = pendingReview.participantIds ?? [];
      participantProfiles = pendingReview.participantProfiles ?? {};
      presenceConfirmed = pendingReview.presenceConfirmed ?? false;

      if (presenceConfirmed) {
        // Restaurar participantes confirmados
        if (pendingReview.confirmedParticipantIds != null && pendingReview.confirmedParticipantIds!.isNotEmpty) {
          currentStep = 1; // Pular STEP 0
          selectedParticipants = pendingReview.confirmedParticipantIds!.toSet();
          
          // Inicializar estruturas de dados para os participantes confirmados
          // IMPORTANTE: Sempre inicializar vazias para garantir estado consistente
          debugPrint('🔄 [ReviewDialog] Inicializando estruturas para ${selectedParticipants.length} participantes');
          for (final id in selectedParticipants) {
            ratingsPerParticipant[id] = {};
            badgesPerParticipant[id] = [];
            commentPerParticipant[id] = '';
            debugPrint('   - Participante $id: ratings={}, badges=[], comment=""');
          }
          
          // Validação: Garantir que currentParticipantId é válido
          if (currentParticipantId == null) {
            debugPrint('❌ [ReviewDialog] ERRO: currentParticipantId é null após inicialização!');
            presenceConfirmed = false;
            currentStep = 0;
          } else {
            debugPrint('✅ [ReviewDialog] Inicialização completa. Primeiro participante: $currentParticipantId');
          }
        } else {
          // FALLBACK INTELIGENTE: presenceConfirmed=true mas sem confirmedParticipantIds
          // Tentamos recuperar participantes do evento antes de resetar tudo
          debugPrint('⚠️ [ReviewDialog] presenceConfirmed=true mas sem confirmedParticipantIds');
          debugPrint('   📊 Dados disponíveis: participantIds=${participantIds.length}, profiles=${participantProfiles.length}');
          
          // Estratégia 1: Se participantIds existe, usar todos como confirmados (assume que todos vieram)
          if (participantIds.isNotEmpty) {
            debugPrint('   🔧 RECUPERAÇÃO: Usando todos os participantIds como confirmados');
            selectedParticipants = participantIds.toSet();
            
            // Inicializar estruturas
            for (final id in selectedParticipants) {
              ratingsPerParticipant[id] = {};
              badgesPerParticipant[id] = [];
              commentPerParticipant[id] = '';
            }
            
            currentStep = 1; // Avançar para ratings
            debugPrint('   ✅ Recuperação bem-sucedida: ${selectedParticipants.length} participantes restaurados');
            
            // IMPORTANTE: Atualizar PendingReview no Firestore com dados recuperados
            _syncConfirmedParticipantsToFirestore(pendingReview.pendingReviewId);
          } else {
            // Estratégia 2: Sem participantes disponíveis - resetar presença (última opção)
            debugPrint('   ❌ Sem participantIds disponíveis. Resetando para Step 0');
            debugPrint('   ⚠️ Owner terá que reconfirmar presença manualmente');
            presenceConfirmed = false;
            currentStep = 0;
          }
        }
      } else {
        // presenceConfirmed = false - fluxo normal, mostrar step de confirmação
        debugPrint('📋 [ReviewDialog] Owner precisa confirmar presença de ${participantIds.length} participantes');
      }
    } else {
      allowedToReviewOwner = pendingReview.allowedToReviewOwner ?? false;
      
      // VALIDAÇÃO DE PERMISSÃO: Se participante não pode avaliar, mostrar erro
      if (!allowedToReviewOwner) {
        debugPrint('⚠️ [ReviewDialog] Participante NÃO tem permissão para avaliar owner');
        debugPrint('   Razões possíveis: presença não confirmada, não participou do evento');
        errorMessage = 'Você não tem permissão para avaliar este evento';
      } else {
        debugPrint('✅ [ReviewDialog] Participante autorizado a avaliar owner');
      }
    }

    notifyListeners();
  }

  /// Sincroniza participantes confirmados recuperados de volta para o Firestore
  /// Usado quando presenceConfirmed=true mas confirmedParticipantIds estava vazio
  Future<void> _syncConfirmedParticipantsToFirestore(String pendingReviewId) async {
    try {
      debugPrint('🔄 [Sync] Atualizando PendingReview com participantes recuperados');
      await _repository.updatePendingReview(
        pendingReviewId: pendingReviewId,
        data: {
          'confirmed_participant_ids': selectedParticipants.toList(),
        },
      );
      debugPrint('✅ [Sync] PendingReview sincronizado com sucesso');
    } catch (e) {
      debugPrint('⚠️ [Sync] Falha ao sincronizar (não crítico): $e');
      // Não bloqueia o fluxo - usuário pode continuar avaliando
    }
  }

  // ==================== STEP 0: CONFIRMAÇÃO DE PRESENÇA (OWNER) ====================

  /// Toggle participante (STEP 0)
  void toggleParticipant(String participantId) {
    if (selectedParticipants.contains(participantId)) {
      // Remover participante e limpar todos os dados dele
      selectedParticipants.remove(participantId);
      ratingsPerParticipant.remove(participantId);
      badgesPerParticipant.remove(participantId);
      commentPerParticipant.remove(participantId);
    } else {
      // Adicionar participante e inicializar estruturas VAZIAS
      // Importante: Estruturas vazias garantem que cada participante começa do zero
      selectedParticipants.add(participantId);
      ratingsPerParticipant[participantId] = {};
      badgesPerParticipant[participantId] = [];
      commentPerParticipant[participantId] = '';
    }
    notifyListeners();
  }

  /// Confirmar presença e avançar (STEP 0 → STEP 1)
  Future<bool> confirmPresenceAndProceed(String pendingReviewId) async {
    debugPrint('🔍 [ReviewDialog] confirmPresenceAndProceed iniciado');
    debugPrint('   - pendingReviewId: $pendingReviewId');
    debugPrint('   - selectedParticipants: ${selectedParticipants.length}');
    
    if (selectedParticipants.isEmpty) {
      debugPrint('   ❌ Nenhum participante selecionado');
      errorMessage = 'Selecione pelo menos um participante';
      notifyListeners();
      return false;
    }

    // Bloquear múltiplas tentativas simultâneas
    if (isTransitioning) {
      debugPrint('   ⏳ Transição já em andamento, ignorando');
      return false;
    }

    try {
      // Iniciar transição - bloqueia a UI
      _batchUpdate(() {
        isTransitioning = true;
        errorMessage = null;
      });

      debugPrint('   📝 Atualizando PendingReview...');
      // Atualizar PendingReview
      await _repository.updatePendingReview(
        pendingReviewId: pendingReviewId,
        data: {
          'presence_confirmed': true,
          'confirmed_participant_ids': selectedParticipants.toList(),
        },
      );
      debugPrint('   ✅ PendingReview atualizado');

      // Salvar presença confirmada no evento
      debugPrint('   💾 Salvando participantes confirmados...');
      for (final participantId in selectedParticipants) {
        debugPrint('      - Salvando participante: $participantId');
        await _repository.saveConfirmedParticipant(
          eventId: eventId,
          participantId: participantId,
          confirmedBy: reviewerId,
        );
      }
      debugPrint('   ✅ ${selectedParticipants.length} participantes salvos');

      // ATUALIZAÇÃO ATÔMICA: Todos os estados são atualizados juntos
      _batchUpdate(() {
        presenceConfirmed = true;
        currentStep = 1; // Avançar para ratings
        currentParticipantIndex = 0; // Primeiro participante
        isTransitioning = false;
      });
      
      debugPrint('   🎯 Estados atualizados atomicamente:');
      debugPrint('      - presenceConfirmed: $presenceConfirmed');
      debugPrint('      - currentStep: $currentStep');
      debugPrint('      - currentParticipantIndex: $currentParticipantIndex');
      debugPrint('      - currentParticipantId: $currentParticipantId');
      
      debugPrint('   ✅ Confirmação concluída, avançando para STEP 1');
      return true;
    } catch (e, stack) {
      debugPrint('   ❌ Erro ao confirmar presença: $e');
      debugPrint('   Stack trace: $stack');
      
      _batchUpdate(() {
        errorMessage = 'Erro ao confirmar presença: $e';
        isTransitioning = false;
      });
      return false;
    }
  }

  // ==================== STEP 1: RATINGS ====================

  /// Define rating para um critério (PARTICIPANT mode ou OWNER avaliando participante atual)
  void setRating(String criterion, int value) {
    debugPrint('⭐ [Controller] setRating chamado!');
    debugPrint('   - criterion: $criterion');
    debugPrint('   - value: $value');
    debugPrint('   - isOwnerReview: $isOwnerReview');
    debugPrint('   - isTransitioning: $isTransitioning');
    
    // Bloquear alterações durante transições para evitar race conditions
    if (isTransitioning) {
      debugPrint('   ⏳ Transição em andamento, ignorando setRating');
      return;
    }
    
    // VALIDAÇÃO DE PERMISSÃO: Participante sem permissão não pode avaliar
    if (isParticipantReview && !allowedToReviewOwner) {
      debugPrint('   ❌ Participante sem permissão, ignorando setRating');
      errorMessage = 'Você não tem permissão para avaliar este evento';
      notifyListeners();
      return;
    }
    
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      debugPrint('   - currentParticipantId: $participantId');
      
      if (participantId == null) {
        debugPrint('   ❌ participantId é null, ignorando');
        errorMessage = 'Erro: nenhum participante selecionado';
        notifyListeners();
        return;
      }

      // Garantir que o map existe antes de salvar
      ratingsPerParticipant[participantId] ??= {};
      ratingsPerParticipant[participantId]![criterion] = value;
      debugPrint('   ✅ Rating salvo para participante $participantId: $criterion=$value');
      debugPrint('   📊 Total ratings para $participantId: ${ratingsPerParticipant[participantId]!.length}');
    } else {
      ratings[criterion] = value;
      debugPrint('   ✅ Rating salvo (participant mode): $criterion=$value');
      debugPrint('   📊 Total ratings: ${ratings.length}');
    }
    errorMessage = null;
    notifyListeners();
    debugPrint('   ✅ notifyListeners() chamado');
  }

  /// Obtém ratings do participante atual (ou do participant)
  Map<String, int> getCurrentRatings() {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      if (participantId == null) {
        debugPrint('⚠️ [getCurrentRatings] currentParticipantId é null');
        return {};
      }
      
      // Garantir que o map existe para esse participante
      ratingsPerParticipant[participantId] ??= {};
      return ratingsPerParticipant[participantId]!;
    }
    return ratings;
  }

  /// Avança para step de badges
  void goToBadgesStep() {
    // Validação extra: Verificar se temos um participante válido (owner mode)
    if (isOwnerReview && currentParticipantId == null) {
      _batchUpdate(() {
        errorMessage = 'Erro: nenhum participante selecionado';
      });
      debugPrint('❌ [goToBadgesStep] currentParticipantId é null');
      return;
    }

    // BUG #11/#12 FIX: Validação rigorosa - exigir ratings completos
    final currentRatings = getCurrentRatings();
    if (currentRatings.length < MINIMUM_REQUIRED_RATINGS) {
      _batchUpdate(() {
        errorMessage = 'Por favor, avalie todos os $MINIMUM_REQUIRED_RATINGS critérios obrigatórios';
      });
      debugPrint('❌ [goToBadgesStep] Ratings insuficientes: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS');
      return;
    }

    _batchUpdate(() {
      errorMessage = null;
      currentStep = 2;
    });
    debugPrint('✅ [goToBadgesStep] Avançando para badges. Ratings: ${currentRatings.length}/$MINIMUM_REQUIRED_RATINGS');
  }

  // ==================== STEP 2: BADGES ====================

  /// Toggle badge (seleciona/deseleciona)
  void toggleBadge(String badgeKey) {
    // Bloquear alterações durante transições para evitar race conditions
    if (isTransitioning) {
      debugPrint('   ⏳ Transição em andamento, ignorando toggleBadge');
      return;
    }
    
    // VALIDAÇÃO DE PERMISSÃO: Participante sem permissão não pode avaliar
    if (isParticipantReview && !allowedToReviewOwner) {
      debugPrint('   ❌ Participante sem permissão, ignorando toggleBadge');
      errorMessage = 'Você não tem permissão para avaliar este evento';
      notifyListeners();
      return;
    }
    
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      if (participantId == null) {
        debugPrint('❌ [toggleBadge] participantId é null, ignorando');
        errorMessage = 'Erro: nenhum participante selecionado';
        notifyListeners();
        return;
      }

      // Garantir que a lista existe antes de modificar
      badgesPerParticipant[participantId] ??= [];
      if (badgesPerParticipant[participantId]!.contains(badgeKey)) {
        badgesPerParticipant[participantId]!.remove(badgeKey);
        debugPrint('🏷️ [toggleBadge] Badge "$badgeKey" removido de $participantId');
      } else {
        badgesPerParticipant[participantId]!.add(badgeKey);
        debugPrint('🏷️ [toggleBadge] Badge "$badgeKey" adicionado a $participantId');
      }
    } else {
      if (selectedBadges.contains(badgeKey)) {
        selectedBadges.remove(badgeKey);
        debugPrint('🏷️ [toggleBadge] Badge "$badgeKey" removido (participant mode)');
      } else {
        selectedBadges.add(badgeKey);
        debugPrint('🏷️ [toggleBadge] Badge "$badgeKey" adicionado (participant mode)');
      }
    }
    notifyListeners();
  }

  /// Obtém badges do participante atual (ou do participant)
  List<String> getCurrentBadges() {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      if (participantId == null) {
        debugPrint('⚠️ [getCurrentBadges] currentParticipantId é null');
        return [];
      }
      
      // Garantir que a lista existe para esse participante
      badgesPerParticipant[participantId] ??= [];
      return badgesPerParticipant[participantId]!;
    }
    return selectedBadges;
  }

  /// Avança para step de comentário
  void goToCommentStep() {
    _batchUpdate(() {
      errorMessage = null;
      currentStep = 3;
    });
  }

  // ==================== STEP 3: COMENTÁRIO ====================

  /// Avançar para próximo participante ou finalizar (OWNER)
  Future<void> nextParticipant() async {
    if (isOwnerReview && currentParticipantIndex < selectedParticipants.length - 1) {
      // Salvar comentário do participante atual
      final participantId = currentParticipantId;
      if (participantId != null) {
        commentPerParticipant[participantId] = commentController.text.trim();
      }

      // Iniciar transição
      isTransitioning = true;
      notifyListeners();

      // Delay para feedback visual
      await Future.delayed(const Duration(milliseconds: 600));

      // ATUALIZAÇÃO ATÔMICA: Todos os estados são atualizados juntos
      // antes de notifyListeners() para evitar race condition
      _batchUpdate(() {
        currentParticipantIndex++;
        currentStep = 1; // Voltar para ratings
        isTransitioning = false;
        
        // Limpar campos para próximo participante
        commentController.clear();
        
        // Garantir que o próximo participante tem estruturas inicializadas (vazias se ainda não avaliado)
        final nextParticipantId = currentParticipantId;
        if (nextParticipantId != null) {
          ratingsPerParticipant[nextParticipantId] ??= {};
          badgesPerParticipant[nextParticipantId] ??= [];
          commentPerParticipant[nextParticipantId] ??= '';
          
          // Restaurar comentário se já foi preenchido antes (usuário voltou)
          if (commentPerParticipant[nextParticipantId]!.isNotEmpty) {
            commentController.text = commentPerParticipant[nextParticipantId]!;
          }
        }
      });
      
      debugPrint('🔄 [Controller] Próximo participante:');
      debugPrint('   - currentParticipantIndex: $currentParticipantIndex');
      debugPrint('   - currentParticipantId: $currentParticipantId');
      debugPrint('   - currentStep: $currentStep');
      debugPrint('   - ratings vazios: ${ratingsPerParticipant[currentParticipantId]?.isEmpty ?? true}');
      debugPrint('   - badges vazios: ${badgesPerParticipant[currentParticipantId]?.isEmpty ?? true}');
    }
  }

  /// Submete review (PARTICIPANT) ou todos os reviews (OWNER)
  Future<bool> submitReview({String? pendingReviewId}) async {
    if (isOwnerReview) {
      return submitAllReviews(pendingReviewId: pendingReviewId);
    } else {
      return submitSingleReview(pendingReviewId: pendingReviewId);
    }
  }

  /// Submete review único (PARTICIPANT)
  Future<bool> submitSingleReview({String? pendingReviewId}) async {
    // VALIDAÇÃO CRÍTICA DE PERMISSÃO: Bloquear submit se não tem permissão
    if (!allowedToReviewOwner) {
      debugPrint('❌ [submitSingleReview] BLOQUEADO: Participante sem permissão');
      _batchUpdate(() {
        errorMessage = 'Você não tem permissão para avaliar este evento. Sua presença pode não ter sido confirmada pelo organizador.';
      });
      return false;
    }
    
    // BUG #11/#12 FIX: Validação rigorosa de ratings completos antes do submit
    if (ratings.length < MINIMUM_REQUIRED_RATINGS) {
      debugPrint('❌ [submitSingleReview] BLOQUEADO: Ratings insuficientes (${ratings.length}/$MINIMUM_REQUIRED_RATINGS)');
      _batchUpdate(() {
        errorMessage = 'Por favor, avalie todos os $MINIMUM_REQUIRED_RATINGS critérios obrigatórios antes de enviar.';
      });
      return false;
    }
    
    final comment = commentController.text.trim();

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      await _repository.createReview(
        eventId: eventId,
        revieweeId: revieweeId,
        reviewerRole: reviewerRole,
        criteriaRatings: ratings,
        badges: selectedBadges,
        comment: comment.isEmpty ? null : comment,
        pendingReviewId: pendingReviewId,
      );

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = _getErrorMessage(e);
      isSubmitting = false;
      notifyListeners();
      return false;
    }
  }

  /// Valida se todos os participantes confirmados foram avaliados
  /// Retorna lista de participantes não avaliados ou null se todos foram avaliados
  List<String>? _validateAllParticipantsReviewed() {
    debugPrint('🔍 [_validateAllParticipantsReviewed] Validando avaliações');
    
    if (ratingsPerParticipant.isEmpty) {
      debugPrint('❌ ratingsPerParticipant vazio');
      return ['Nenhum participante avaliado'];
    }
    
    if (!hasEvaluatedAllParticipants) {
      debugPrint('❌ Nem todos os participantes foram avaliados');
      debugPrint('   Total confirmados: ${selectedParticipants.length}');
      debugPrint('   Avaliados: ${ratingsPerParticipant.length}');
      
      // Identificar quem falta avaliar
      final missingParticipants = <String>[];
      for (final participantId in selectedParticipants) {
        final participantRatings = ratingsPerParticipant[participantId] ?? {};
        if (participantRatings.length < MINIMUM_REQUIRED_RATINGS) {
          final profile = participantProfiles[participantId];
          final name = profile?.name ?? 'Participante';
          missingParticipants.add(name);
        }
      }
      
      return missingParticipants;
    }
    
    debugPrint('✅ Todos os participantes foram avaliados');
    return null;
  }

  /// Busca e prepara dados do owner para os pending reviews
  /// Retorna Map com ownerName e ownerPhotoUrl
  Future<Map<String, String?>> _prepareOwnerData() async {
    debugPrint('👤 [_prepareOwnerData] Buscando dados do owner');
    
    final firestore = FirebaseFirestore.instance;
    final ownerDoc = await firestore.collection('Users').doc(reviewerId).get();
    final ownerData = ownerDoc.data();
    final ownerName = ownerData?['fullName'] as String? ?? 'Organizador';
    final ownerPhotoUrl = ownerData?['user_photo_link'] as String?;

    debugPrint('✅ Dados do owner: $ownerName');
    
    return {
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
    };
  }

  /// Cria review no batch (owner → participant)
  void _createReviewBatch(
    WriteBatch batch,
    String participantId,
    FirebaseFirestore firestore,
  ) {
    final reviewRef = firestore.collection('Reviews').doc();
    batch.set(reviewRef, {
      'event_id': eventId,
      'reviewee_id': participantId,
      'reviewer_id': reviewerId,
      'reviewer_role': 'owner',
      'criteria_ratings': ratingsPerParticipant[participantId] ?? {},
      'badges': badgesPerParticipant[participantId] ?? [],
      'comment': commentPerParticipant[participantId]?.trim().isEmpty == true
          ? null
          : commentPerParticipant[participantId]?.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
    });
    
    debugPrint('📝 Review criado para participante: $participantId');
  }

  /// Cria pending review para participante no batch
  void _createPendingReviewBatch(
    WriteBatch batch,
    String participantId,
    String ownerName,
    String? ownerPhotoUrl,
    FirebaseFirestore firestore,
  ) {
    final pendingRef = firestore.collection('PendingReviews').doc();
    batch.set(pendingRef, {
      'event_id': eventId,
      'reviewer_id': participantId,
      'reviewee_id': reviewerId,
      'reviewer_role': 'participant',
      'event_title': eventTitle,
      'event_emoji': eventEmoji,
      'event_location': eventLocationName,
      'event_date': eventScheduleDate,
      'owner_name': ownerName,
      'owner_photo_url': ownerPhotoUrl,
      'allowed_to_review_owner': true,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
    
    debugPrint('📋 PendingReview criado para participante: $participantId');
  }

  /// Marca participante como avaliado no batch
  void _markParticipantReviewedBatch(
    WriteBatch batch,
    String participantId,
    FirebaseFirestore firestore,
  ) {
    final confirmedRef = firestore
        .collection('Events')
        .doc(eventId)
        .collection('ConfirmedParticipants')
        .doc(participantId);
    
    batch.update(confirmedRef, {
      'reviewed': true,
      'reviewed_at': FieldValue.serverTimestamp(),
    });
    
    debugPrint('✅ Participante marcado como avaliado: $participantId');
  }

  /// Submete TODOS os reviews (OWNER → cada participante)
  /// OTIMIZADO: Usa WriteBatch para melhor performance
  Future<bool> submitAllReviews({String? pendingReviewId}) async {
    debugPrint('📤 [submitAllReviews] Iniciado. participantes: ${selectedParticipants.length}');
    
    // VALIDAÇÃO: Verificar se todos foram avaliados
    final missingParticipants = _validateAllParticipantsReviewed();
    if (missingParticipants != null) {
      _batchUpdate(() {
        if (missingParticipants.length == 1 && missingParticipants.first == 'Nenhum participante avaliado') {
          errorMessage = 'Avalie pelo menos um participante';
        } else {
          errorMessage = 'Você precisa avaliar todos os participantes antes de enviar.\nFaltam: ${missingParticipants.join(", ")}';
        }
      });
      return false;
    }

    // Salvar comentário do último participante
    final lastParticipantId = currentParticipantId;
    if (lastParticipantId != null) {
      commentPerParticipant[lastParticipantId] = commentController.text.trim();
    }

    _batchUpdate(() {
      isSubmitting = true;
      errorMessage = null;
    });

    try {
      final firestore = FirebaseFirestore.instance;
      
      // 1. PREPARAR: Buscar dados do owner
      final ownerData = await _prepareOwnerData();
      final ownerName = ownerData['ownerName']!;
      final ownerPhotoUrl = ownerData['ownerPhotoUrl'];

      // 2. PROCESSAR: Criar batches de operações
      var batch = firestore.batch();
      int operationCount = 0;
      const maxBatchSize = 490; // Margem de segurança (limite Firestore: 500)
      
      for (final participantId in selectedParticipants) {
        debugPrint('📝 [submitAllReviews] Processando: $participantId');
        
        // 2.1. Criar Review (owner → participant)
        _createReviewBatch(batch, participantId, firestore);
        operationCount++;

        // 2.2. Criar PendingReview para participante
        _createPendingReviewBatch(batch, participantId, ownerName, ownerPhotoUrl, firestore);
        operationCount++;

        // 2.3. Marcar participante como avaliado
        _markParticipantReviewedBatch(batch, participantId, firestore);
        operationCount++;

        // Se atingir limite, commitar e criar novo batch
        if (operationCount >= maxBatchSize) {
          debugPrint('💾 [submitAllReviews] Commitando batch ($operationCount ops)');
          await batch.commit();
          batch = firestore.batch(); // Criar novo batch
          operationCount = 0;
        }
      }

      // 3. FINALIZAR: Deletar PendingReview do owner
      if (pendingReviewId != null && pendingReviewId.isNotEmpty) {
        batch.delete(firestore.collection('PendingReviews').doc(pendingReviewId));
        operationCount++;
        debugPrint('🗑️ [submitAllReviews] PendingReview do owner deletado');
      }

      // 4. COMMIT FINAL
      if (operationCount > 0) {
        debugPrint('💾 [submitAllReviews] Commit final ($operationCount ops)');
        await batch.commit();
      }

      debugPrint('✅ [submitAllReviews] ${selectedParticipants.length} reviews criados com sucesso');
      
      _batchUpdate(() {
        isSubmitting = false;
      });
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [submitAllReviews] Erro: $e');
      debugPrint('Stack trace: $stackTrace');
      
      _batchUpdate(() {
        errorMessage = _getErrorMessage(e);
        isSubmitting = false;
      });
      return false;
    }
  }

  /// Pula comentário e submete direto
  Future<bool> skipCommentAndSubmit({String? pendingReviewId}) async {
    return submitReview(pendingReviewId: pendingReviewId);
  }

  /// Marca pending review como dismissed (não avaliar agora)
  Future<bool> dismissReview(String pendingReviewId) async {
    try {
      await _repository.dismissPendingReview(pendingReviewId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== NAVEGAÇÃO ====================

  /// Volta para step anterior
  void previousStep() {
    debugPrint('⬅️ [Controller] previousStep chamado');
    debugPrint('   - currentStep: $currentStep');
    debugPrint('   - isOwnerReview: $isOwnerReview');
    debugPrint('   - currentParticipantIndex: $currentParticipantIndex');
    debugPrint('   - needsPresenceConfirmation: $needsPresenceConfirmation');

    // OWNER: Se estiver no primeiro step de avaliação (Ratings = step 1)
    if (isOwnerReview && currentStep == 1) {
      // Se não for o primeiro participante, volta para o comentário do anterior
      if (currentParticipantIndex > 0) {
        // Salvar comentário do participante atual antes de voltar
        final currentId = currentParticipantId;
        if (currentId != null) {
          commentPerParticipant[currentId] = commentController.text.trim();
        }
        
        currentParticipantIndex--;
        currentStep = 3; // Volta para comentário do participante anterior
        errorMessage = null;
        
        // Restaurar comentário do participante anterior
        final previousId = currentParticipantId;
        if (previousId != null) {
          commentController.text = commentPerParticipant[previousId] ?? '';
        }
        
        debugPrint('   ✅ Voltou para comentário do participante $currentParticipantIndex');
        debugPrint('   - participantId: $previousId');
        debugPrint('   - comentário restaurado: ${commentController.text.isNotEmpty}');
        notifyListeners();
        return;
      }
      
      // Se for o primeiro participante e tiver confirmação de presença, volta para presença
      if (needsPresenceConfirmation) {
        currentStep = 0;
        errorMessage = null;
        debugPrint('   ✅ Voltou para confirmação de presença');
        notifyListeners();
        return;
      }
      
      // Se for o primeiro participante e NÃO tiver confirmação de presença, não pode voltar
      debugPrint('   ⚠️ Já está no primeiro step, não pode voltar');
      return;
    }

    // PARTICIPANT ou OWNER em outros steps: Simplesmente volta um step
    if (currentStep > 0) {
      currentStep--;
      errorMessage = null;
      debugPrint('   ✅ Voltou para step $currentStep');
      notifyListeners();
    } else {
      debugPrint('   ⚠️ Já está no step 0, não pode voltar');
    }
  }

  /// Verifica se pode voltar
  bool get canGoBack {
    // Step 0: Só pode voltar se for owner avaliando múltiplos participantes e não for o primeiro
    if (currentStep == 0) {
      // Owner em confirmação de presença → nunca pode voltar
      if (needsPresenceConfirmation) return false;
      
      // Participant no step 0 (ratings) → nunca pode voltar
      // Owner no step 0 sem presence confirmation → nunca pode voltar
      return false;
    }
    
    // Step 1 (Ratings para owner, Badges para participant):
    if (currentStep == 1) {
      // OWNER: Pode voltar se:
      // - Não for o primeiro participante (volta para comentário do anterior), OU
      // - For o primeiro participante mas tiver confirmação de presença (volta para step 0)
      if (isOwnerReview) {
        return currentParticipantIndex > 0 || needsPresenceConfirmation;
      }
      
      // PARTICIPANT: Sempre pode voltar do step 1 (badges) para step 0 (ratings)
      return true;
    }
    
    // Steps 2 e 3: Sempre podem voltar
    return true;
  }

  // ==================== HELPERS ====================

  /// Lista de critérios para exibir
  List<Map<String, String>> get criteriaList => ReviewCriteria.all;

  /// Progresso atual (0.0 a 1.0)
  double get progress => (currentStep + 1) / totalSteps;

  /// Nome do participante atual (owner mode)
  String getCurrentParticipantName() {
    if (!isOwnerReview) return '';
    final participantId = currentParticipantId;
    if (participantId == null) return '';
    return participantProfiles[participantId]?.name ?? 'Participante';
  }

  String _getErrorMessage(dynamic error) {
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
