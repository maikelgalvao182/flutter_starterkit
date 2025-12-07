import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/domain/constants/review_criteria.dart';

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
    if (selectedParticipants.isEmpty) return null;
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // ==================== GETTERS ====================

  bool get isOwnerReview => reviewerRole == 'owner';
  bool get isParticipantReview => reviewerRole == 'participant';
  
  bool get needsPresenceConfirmation =>
      isOwnerReview && !presenceConfirmed && participantIds.isNotEmpty;
  
  int get totalSteps => needsPresenceConfirmation ? 4 : 3;
  
  bool get isLastParticipant =>
      currentParticipantIndex >= selectedParticipants.length - 1;

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
          for (final id in selectedParticipants) {
            ratingsPerParticipant[id] = {};
            badgesPerParticipant[id] = [];
            commentPerParticipant[id] = '';
          }
        } else {
          // Fallback: Se não tiver lista de confirmados (dados antigos/corrompidos),
          // força o usuário a confirmar novamente
          debugPrint('⚠️ [ReviewDialog] presenceConfirmed=true mas sem confirmedParticipantIds. Resetando para Step 0.');
          presenceConfirmed = false;
          currentStep = 0;
        }
      }
    } else {
      allowedToReviewOwner = pendingReview.allowedToReviewOwner ?? false;
    }

    notifyListeners();
  }

  // ==================== STEP 0: CONFIRMAÇÃO DE PRESENÇA (OWNER) ====================

  /// Toggle participante (STEP 0)
  void toggleParticipant(String participantId) {
    if (selectedParticipants.contains(participantId)) {
      selectedParticipants.remove(participantId);
      ratingsPerParticipant.remove(participantId);
      badgesPerParticipant.remove(participantId);
      commentPerParticipant.remove(participantId);
    } else {
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

    try {
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

      presenceConfirmed = true;
      currentStep = 1; // Avançar para ratings
      
      // Inicializar avaliação do primeiro participante
      currentParticipantIndex = 0;
      debugPrint('   🎯 Iniciando avaliação do participante 0: ${currentParticipantId}');
      
      errorMessage = null;
      notifyListeners();
      debugPrint('   ✅ Confirmação concluída, avançando para STEP 1');
      return true;
    } catch (e, stack) {
      debugPrint('   ❌ Erro ao confirmar presença: $e');
      debugPrint('   Stack trace: $stack');
      errorMessage = 'Erro ao confirmar presença: $e';
      notifyListeners();
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
    
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      debugPrint('   - currentParticipantId: $participantId');
      
      if (participantId == null) {
        debugPrint('   ❌ participantId é null, ignorando');
        return;
      }

      ratingsPerParticipant[participantId] ??= {};
      ratingsPerParticipant[participantId]![criterion] = value;
      debugPrint('   ✅ Rating salvo para participante $participantId');
    } else {
      ratings[criterion] = value;
      debugPrint('   ✅ Rating salvo (participant mode)');
    }
    errorMessage = null;
    notifyListeners();
    debugPrint('   ✅ notifyListeners() chamado');
  }

  /// Obtém ratings do participante atual (ou do participant)
  Map<String, int> getCurrentRatings() {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      return ratingsPerParticipant[participantId] ?? {};
    }
    return ratings;
  }

  /// Avança para step de badges
  void goToBadgesStep() {
    final currentRatings = getCurrentRatings();
    if (currentRatings.isEmpty) {
      errorMessage = 'Por favor, avalie pelo menos um critério';
      notifyListeners();
      return;
    }

    errorMessage = null;
    currentStep = 2;
    notifyListeners();
  }

  // ==================== STEP 2: BADGES ====================

  /// Toggle badge (seleciona/deseleciona)
  void toggleBadge(String badgeKey) {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      if (participantId == null) return;

      badgesPerParticipant[participantId] ??= [];
      if (badgesPerParticipant[participantId]!.contains(badgeKey)) {
        badgesPerParticipant[participantId]!.remove(badgeKey);
      } else {
        badgesPerParticipant[participantId]!.add(badgeKey);
      }
    } else {
      if (selectedBadges.contains(badgeKey)) {
        selectedBadges.remove(badgeKey);
      } else {
        selectedBadges.add(badgeKey);
      }
    }
    notifyListeners();
  }

  /// Obtém badges do participante atual (ou do participant)
  List<String> getCurrentBadges() {
    if (isOwnerReview) {
      final participantId = currentParticipantId;
      return badgesPerParticipant[participantId] ?? [];
    }
    return selectedBadges;
  }

  /// Avança para step de comentário
  void goToCommentStep() {
    errorMessage = null;
    currentStep = 3;
    notifyListeners();
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

      // Avançar para próximo
      currentParticipantIndex++;
      currentStep = 1; // Voltar para ratings
      
      // Limpar comentário para próximo participante
      commentController.clear();
      
      isTransitioning = false;
      notifyListeners();
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

  /// Submete TODOS os reviews (OWNER → cada participante)
  Future<bool> submitAllReviews({String? pendingReviewId}) async {
    print('ReviewDialogController: submitAllReviews called. pendingReviewId: $pendingReviewId');
    if (ratingsPerParticipant.isEmpty) {
      print('ReviewDialogController: ratingsPerParticipant is empty');
      errorMessage = 'Avalie pelo menos um participante';
      notifyListeners();
      return false;
    }

    // Salvar comentário do último participante
    final lastParticipantId = currentParticipantId;
    if (lastParticipantId != null) {
      commentPerParticipant[lastParticipantId] = commentController.text.trim();
    }

    print('ReviewDialogController: selectedParticipants: $selectedParticipants');
    print('ReviewDialogController: ratingsPerParticipant keys: ${ratingsPerParticipant.keys}');

    isSubmitting = true;
    errorMessage = null;
    notifyListeners();

    try {
      // Buscar dados do owner para criar PendingReviews dos participantes
      final firestore = FirebaseFirestore.instance;
      final ownerDoc = await firestore.collection('Users').doc(reviewerId).get();
      final ownerData = ownerDoc.data();
      final ownerName = ownerData?['fullName'] as String? ?? 'Organizador';
      final ownerPhotoUrl = ownerData?['user_photo_link'] as String?;

      print('ReviewDialogController: Owner data fetched. Name: $ownerName');

      // Criar reviews e PendingReviews para cada participante
      for (final participantId in selectedParticipants) {
        print('ReviewDialogController: Processing participant $participantId');
        // 1. Criar Review (owner → participant)
        try {
          await _repository.createReview(
            eventId: eventId,
            revieweeId: participantId,
            reviewerRole: 'owner',
            criteriaRatings: ratingsPerParticipant[participantId] ?? {},
            badges: badgesPerParticipant[participantId] ?? [],
            comment: commentPerParticipant[participantId]?.isEmpty == true
                ? null
                : commentPerParticipant[participantId],
            pendingReviewId: null, // Não deletar PendingReview do owner ainda
          );
          print('ReviewDialogController: Review created for $participantId');
        } catch (e) {
          if (e.toString().contains('Você já avaliou esta pessoa neste evento')) {
            print('ReviewDialogController: Review already exists for $participantId. Continuing...');
          } else {
            rethrow;
          }
        }

        // 2. Criar PendingReview para participante avaliar owner
        await _repository.createParticipantPendingReview(
          eventId: eventId,
          participantId: participantId,
          ownerId: reviewerId,
          ownerName: ownerName,
          ownerPhotoUrl: ownerPhotoUrl,
          eventTitle: eventTitle,
          eventEmoji: eventEmoji,
          eventLocationName: eventLocationName,
          eventScheduleDate: eventScheduleDate,
        );
        print('ReviewDialogController: PendingReview created for $participantId');

        // 3. Atualizar ConfirmedParticipants (reviewed = true)
        await _repository.markParticipantAsReviewed(
          eventId: eventId,
          participantId: participantId,
        );
        print('ReviewDialogController: Participant marked as reviewed: $participantId');
      }

      // 4. Deletar PendingReview do owner
      if (pendingReviewId != null && pendingReviewId.isNotEmpty) {
        await _repository.deletePendingReview(pendingReviewId);
        print('ReviewDialogController: PendingReview deleted: $pendingReviewId');
      }

      isSubmitting = false;
      notifyListeners();
      return true;
    } catch (e, stackTrace) {
      print('ReviewDialogController: Error submitting reviews: $e');
      print('ReviewDialogController: StackTrace: $stackTrace');
      errorMessage = _getErrorMessage(e);
      isSubmitting = false;
      notifyListeners();
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
    if (currentStep > (needsPresenceConfirmation ? 0 : 1)) {
      currentStep--;
      errorMessage = null;
      notifyListeners();
    }
  }

  /// Verifica se pode voltar
  bool get canGoBack => currentStep > (needsPresenceConfirmation ? 0 : 1);

  // ==================== HELPERS ====================

  /// Lista de critérios para exibir
  List<Map<String, String>> get criteriaList => ReviewCriteria.all;

  /// Progresso atual (0.0 a 1.0)
  double get progress => (currentStep + 1) / totalSteps;

  /// Label do step atual
  String get currentStepLabel {
    if (needsPresenceConfirmation) {
      // Owner: 4 steps (0: Presença, 1: Ratings, 2: Badges, 3: Comentário)
      switch (currentStep) {
        case 0:
          return 'Confirme quem apareceu';
        case 1:
          return 'Deixe uma avaliação';
        case 2:
          return 'Deixe um elogio';
        case 3:
          return 'Deixe um comentário';
        default:
          return '';
      }
    } else {
      // Participant: 3 steps (0: Ratings, 1: Badges, 2: Comentário)
      switch (currentStep) {
        case 1:
          return 'Deixe uma avaliação';
        case 2:
          return 'Deixe um elogio';
        case 3:
          return 'Deixe um comentário';
        default:
          return '';
      }
    }
  }

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
