import 'package:partiu/features/reviews/data/models/pending_review_model.dart';

/// REGRA DE NEGÓCIO: Número mínimo de critérios obrigatórios para avançar
const int MINIMUM_REQUIRED_RATINGS = 4;

/// Tipos de steps no fluxo de review
enum ReviewStep {
  presence,  // Apenas owner
  ratings,
  badges,
  comment,
}

/// Estado do ReviewDialog - Gerencia todos os dados da review
class ReviewDialogState {
  // ==================== IDENTIFICAÇÃO DO EVENTO ====================
  
  String eventId;
  String revieweeId;
  String reviewerRole;
  String reviewerId;
  String eventTitle;
  String eventEmoji;
  String? eventLocationName;
  DateTime? eventScheduleDate;
  
  // PRÉ-CARREGAMENTO: Dados enriquecidos do reviewee (owner)
  // Preenchidos pelo ReviewRepository via ActionsRepository
  String? revieweeName;
  String? revieweePhotoUrl;

  // ==================== NAVEGAÇÃO ====================
  
  int currentStep = 0;

  // ==================== OWNER: CONFIRMAÇÃO DE PRESENÇA (STEP 0) ====================
  
  bool presenceConfirmed = false;
  List<String> selectedParticipants = []; // CRÍTICO: List para garantir ordem estável
  List<String> participantIds = [];
  Map<String, ParticipantProfile> participantProfiles = {};

  // ==================== RATINGS POR PARTICIPANTE (OWNER) ====================
  
  Map<String, Map<String, int>> ratingsPerParticipant = {};
  Map<String, List<String>> badgesPerParticipant = {};
  Map<String, String> commentPerParticipant = {};
  
  int currentParticipantIndex = 0;
  
  // ==================== RATINGS SIMPLES (PARTICIPANT) ====================
  
  final Map<String, int> ratings = {};
  final List<String> selectedBadges = [];

  // ==================== CONTROLE DE PERMISSÃO (PARTICIPANT) ====================
  
  bool allowedToReviewOwner = true;

  // ==================== ESTADO DE UI ====================
  
  bool isSubmitting = false;
  bool isTransitioning = false;
  String? errorMessage;

  ReviewDialogState({
    required this.eventId,
    required this.revieweeId,
    required this.reviewerRole,
    this.reviewerId = '',
    this.eventTitle = '',
    this.eventEmoji = '🎉',
    this.eventLocationName,
    this.eventScheduleDate,
  });

  // ==================== GETTERS ====================

  bool get isOwnerReview => reviewerRole == 'owner';
  bool get isParticipantReview => reviewerRole == 'participant';
  
  bool get needsPresenceConfirmation =>
      isOwnerReview && !presenceConfirmed && participantIds.isNotEmpty;
  
  int get totalSteps => needsPresenceConfirmation ? 4 : 3;
  
  bool get isLastParticipant =>
      currentParticipantIndex >= selectedParticipants.length - 1;

  String? get currentParticipantId {
    if (selectedParticipants.isEmpty) return null;
    if (currentParticipantIndex < 0 || currentParticipantIndex >= selectedParticipants.length) {
      return null;
    }
    return selectedParticipants[currentParticipantIndex]; // Acesso direto por índice
  }

  /// Converte currentStep (int) para ReviewStep (enum)
  ReviewStep get currentReviewStep {
    if (isOwnerReview) {
      switch (currentStep) {
        case 0: return ReviewStep.presence;
        case 1: return ReviewStep.ratings;
        case 2: return ReviewStep.badges;
        case 3: return ReviewStep.comment;
        default: return ReviewStep.comment;
      }
    } else {
      switch (currentStep) {
        case 0: return ReviewStep.ratings;
        case 1: return ReviewStep.badges;
        case 2: return ReviewStep.comment;
        default: return ReviewStep.comment;
      }
    }
  }

  /// Progresso atual (0.0 a 1.0)
  double get progress => (currentStep + 1) / totalSteps;

  /// Nome do participante atual (owner mode)
  String getCurrentParticipantName() {
    if (!isOwnerReview) return '';
    final participantId = currentParticipantId;
    if (participantId == null) return '';
    return participantProfiles[participantId]?.name ?? 'Participante';
  }

  /// Cria cópia do estado com valores atualizados
  ReviewDialogState copyWith({
    String? eventId,
    String? revieweeId,
    String? reviewerRole,
    String? reviewerId,
    String? eventTitle,
    String? eventEmoji,
    String? eventLocationName,
    DateTime? eventScheduleDate,
    int? currentStep,
    bool? presenceConfirmed,
    List<String>? selectedParticipants,
    List<String>? participantIds,
    Map<String, ParticipantProfile>? participantProfiles,
    Map<String, Map<String, int>>? ratingsPerParticipant,
    Map<String, List<String>>? badgesPerParticipant,
    Map<String, String>? commentPerParticipant,
    int? currentParticipantIndex,
    Map<String, int>? ratings,
    List<String>? selectedBadges,
    bool? allowedToReviewOwner,
    bool? isSubmitting,
    bool? isTransitioning,
    String? errorMessage,
  }) {
    return ReviewDialogState(
      eventId: eventId ?? this.eventId,
      revieweeId: revieweeId ?? this.revieweeId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      reviewerId: reviewerId ?? this.reviewerId,
      eventTitle: eventTitle ?? this.eventTitle,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      eventLocationName: eventLocationName ?? this.eventLocationName,
      eventScheduleDate: eventScheduleDate ?? this.eventScheduleDate,
    )
      ..currentStep = currentStep ?? this.currentStep
      ..presenceConfirmed = presenceConfirmed ?? this.presenceConfirmed
      ..selectedParticipants = selectedParticipants ?? this.selectedParticipants
      ..participantIds = participantIds ?? this.participantIds
      ..participantProfiles = participantProfiles ?? this.participantProfiles
      ..ratingsPerParticipant = ratingsPerParticipant ?? this.ratingsPerParticipant
      ..badgesPerParticipant = badgesPerParticipant ?? this.badgesPerParticipant
      ..commentPerParticipant = commentPerParticipant ?? this.commentPerParticipant
      ..currentParticipantIndex = currentParticipantIndex ?? this.currentParticipantIndex
      ..ratings.addAll(ratings ?? this.ratings)
      ..selectedBadges.addAll(selectedBadges ?? this.selectedBadges)
      ..allowedToReviewOwner = allowedToReviewOwner ?? this.allowedToReviewOwner
      ..isSubmitting = isSubmitting ?? this.isSubmitting
      ..isTransitioning = isTransitioning ?? this.isTransitioning
      ..errorMessage = errorMessage ?? this.errorMessage;
  }
}
