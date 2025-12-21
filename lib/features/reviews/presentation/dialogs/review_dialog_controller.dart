import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_batch_service.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_navigation_service.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_ui_service.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_validation_service.dart';

export 'controller/review_dialog_state.dart';

/// Controller refatorado para o ReviewDialog
/// Delega responsabilidades para serviços especializados
class ReviewDialogController extends ChangeNotifier {
  final ReviewRepository _repository = ReviewRepository();
  final TextEditingController commentController = TextEditingController();
  
  late ReviewDialogState _state;
  ReviewDialogState get state => _state;

  ReviewDialogController({
    required String eventId,
    required String revieweeId,
    required String reviewerRole,
    String reviewerId = '',
    String eventTitle = '',
    String eventEmoji = '🎉',
    String? eventLocationName,
    DateTime? eventScheduleDate,
  }) {
    _state = ReviewDialogState(
      eventId: eventId,
      revieweeId: revieweeId,
      reviewerRole: reviewerRole,
      reviewerId: reviewerId,
      eventTitle: eventTitle,
      eventEmoji: eventEmoji,
      eventLocationName: eventLocationName,
      eventScheduleDate: eventScheduleDate,
    );
  }

  // ==================== BATCH UPDATES ====================
  
  bool _isBatchUpdating = false;
  bool _needsNotification = false;

  void _batchUpdate(void Function() updates) {
    _isBatchUpdating = true;
    _needsNotification = false;
    try {
      updates();
      // Sempre notificar após batch updates
      _needsNotification = true;
    } finally {
      _isBatchUpdating = false;
      if (_needsNotification) {
        super.notifyListeners();
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

  @override
  void dispose() {
    commentController.dispose();
    super.dispose();
  }

  // ==================== DELEGATES TO UI SERVICE ====================

  String get currentStepLabel => ReviewUIService.getStepLabel(_state);
  String get buttonText => ReviewUIService.getButtonText(_state, commentController.text.isNotEmpty);
  bool get shouldShowSkipButton => ReviewUIService.shouldShowSkipButton(_state, commentController.text.isNotEmpty);
  List<Map<String, String>> criteriaList(BuildContext context) => ReviewUIService.criteriaList(context);
  Map<String, int> getCurrentRatings() => ReviewUIService.getCurrentRatings(_state);
  List<String> getCurrentBadges() => ReviewUIService.getCurrentBadges(_state);

  // ==================== DELEGATES TO VALIDATION SERVICE ====================

  bool get canProceed => ReviewValidationService.canProceed(_state);
  bool get hasCompletedRatings => ReviewValidationService.hasCompletedRatings(_state);
  bool get hasEvaluatedAllParticipants => ReviewValidationService.hasEvaluatedAllParticipants(_state);
  bool get canGoBack => ReviewValidationService.canGoBack(_state);

  // ==================== GETTERS PARA COMPATIBILIDADE COM COMPONENTS ====================

  // Expõe propriedades do state para os components
  bool get isOwnerReview => _state.isOwnerReview;
  bool get isParticipantReview => _state.isParticipantReview;
  bool get presenceConfirmed => _state.presenceConfirmed;
  bool get needsPresenceConfirmation => _state.needsPresenceConfirmation;

  /// Retorna a lista de participantes que ainda faltam ser avaliados (apenas para Owner)
  List<Map<String, String>> get remainingParticipants {
    if (!_state.isOwnerReview) return [];
    
    final remaining = <Map<String, String>>[];
    // Começa do próximo participante
    for (int i = _state.currentParticipantIndex + 1; i < _state.selectedParticipants.length; i++) {
      final id = _state.selectedParticipants[i];
      final profile = _state.participantProfiles[id];
      if (profile != null) {
        remaining.add({
          'id': id,
          'name': profile.name,
          'photoUrl': profile.photoUrl ?? '',
        });
      }
    }
    return remaining;
  }

  int get currentStep => _state.currentStep;
  int get totalSteps => _state.totalSteps;
  String? get currentParticipantId => _state.currentParticipantId;
  int get currentParticipantIndex => _state.currentParticipantIndex;
  List<String> get selectedParticipants => _state.selectedParticipants;
  List<String> get participantIds => _state.participantIds;
  Map<String, ParticipantProfile> get participantProfiles => _state.participantProfiles;
  String get eventId => _state.eventId;
  String get revieweeId => _state.revieweeId;
  String get reviewerRole => _state.reviewerRole;
  String get reviewerId => _state.reviewerId;
  String get eventTitle => _state.eventTitle;
  String get eventEmoji => _state.eventEmoji;
  String? get eventLocationName => _state.eventLocationName;
  DateTime? get eventScheduleDate => _state.eventScheduleDate;
  bool get isSubmitting => _state.isSubmitting;
  bool get isTransitioning => _state.isTransitioning;
  String? get errorMessage => _state.errorMessage;
  bool get allowedToReviewOwner => _state.allowedToReviewOwner;
  ReviewStep get currentReviewStep => _state.currentReviewStep;
  bool get isLastParticipant => _state.isLastParticipant;
  
  // Progress calculado
  double get progress => (currentStep + 1) / totalSteps;

  // ==================== PRÉ-CARREGAMENTO DE DADOS DO REVIEWEE ====================
  // Seguindo o padrão do AppInitializerService para evitar queries durante a UI
  // Dados são pré-carregados do PendingReviewModel e acessados via getters
  
  /// ID do usuário sendo avaliado
  String get currentRevieweeId {
    if (_state.isOwnerReview && _state.presenceConfirmed) {
      return _state.currentParticipantId ?? '';
    }
    return _state.revieweeId;
  }

  /// Nome do usuário sendo avaliado (pré-carregado)
  /// 
  /// - Owner avaliando participante: Retorna nome do participante atual
  /// - Participant avaliando owner: Retorna nome do owner
  /// 
  /// PERFORMANCE: Dados já estão em memória via PendingReviewModel
  String get currentRevieweeName {
    if (_state.isOwnerReview && _state.presenceConfirmed) {
      // Owner avaliando participante
      final participantId = _state.currentParticipantId;
      if (participantId != null) {
        final profile = _state.participantProfiles[participantId];
        return profile?.name ?? 'Participante';
      }
      return 'Participante';
    } else {
      // Participant avaliando owner (ou owner no step 0)
      // revieweeId já foi enriquecido pelo ReviewRepository com dados do owner
      return _state.revieweeName ?? 'Usuário';
    }
  }
  
  /// Foto do usuário sendo avaliado (pré-carregada)
  /// 
  /// - Owner avaliando participante: Retorna foto do participante atual
  /// - Participant avaliando owner: Retorna foto do owner
  /// 
  /// PERFORMANCE: Dados já estão em memória via PendingReviewModel
  String? get currentRevieweePhotoUrl {
    if (_state.isOwnerReview && _state.presenceConfirmed) {
      // Owner avaliando participante
      final participantId = _state.currentParticipantId;
      if (participantId != null) {
        final profile = _state.participantProfiles[participantId];
        return profile?.photoUrl;
      }
      return null;
    } else {
      // Participant avaliando owner (ou owner no step 0)
      // revieweePhotoUrl já foi enriquecido pelo ReviewRepository
      return _state.revieweePhotoUrl;
    }
  }

  // ==================== INICIALIZAÇÃO ====================
  // Métodos puros e testáveis para inicialização do estado
  // 
  // Hierarquia:
  // initializeFromPendingReview()
  //   ├─ _initializeBaseState()           → Estado comum (owner + participant)
  //   ├─ _initializeOwnerState()          → Estado específico owner
  //   │   └─ _restoreOwnerConfirmedState()
  //   │       ├─ _restoreWithConfirmedParticipants()
  //   │       │   ├─ _initializeParticipantDataStructures()
  //   │       │   └─ _resetToPresenceConfirmation()
  //   │       └─ _recoverFromMissingConfirmedParticipants()
  //   │           ├─ _initializeParticipantDataStructures()
  //   │           ├─ _syncConfirmedParticipantsToFirestore()
  //   │           └─ _resetToPresenceConfirmation()
  //   └─ _initializeParticipantState()    → Estado específico participant

  /// Inicializa controller a partir de PendingReview
  /// Delega para métodos especializados baseado no tipo de review
  void initializeFromPendingReview(PendingReviewModel pendingReview) {
    // VALIDAÇÃO CRÍTICA: Impedir autoavaliação
    if (pendingReview.reviewerId == pendingReview.revieweeId) {
      debugPrint('❌ [Init] ERRO: Tentativa de autoavaliação detectada!');
      debugPrint('   - reviewerId: ${pendingReview.reviewerId}');
      debugPrint('   - revieweeId: ${pendingReview.revieweeId}');
      debugPrint('   - eventId: ${pendingReview.eventId}');
      
      _state.errorMessage = 'Erro: Não é possível avaliar a si mesmo';
      notifyListeners();
      return;
    }
    
    _initializeBaseState(pendingReview);

    if (pendingReview.isOwnerReview) {
      _initializeOwnerState(pendingReview);
    } else {
      _initializeParticipantState(pendingReview);
    }

    notifyListeners();
  }

  /// Inicializa estado base (comum para owner e participant)
  void _initializeBaseState(PendingReviewModel pendingReview) {
    _state.eventId = pendingReview.eventId;
    _state.reviewerId = pendingReview.reviewerId;
    _state.revieweeId = pendingReview.revieweeId;
    _state.reviewerRole = pendingReview.reviewerRole;
    _state.eventTitle = pendingReview.eventTitle;
    _state.eventEmoji = pendingReview.eventEmoji;
    _state.eventLocationName = pendingReview.eventLocation;
    _state.eventScheduleDate = pendingReview.eventDate;
    
    // PRÉ-CARREGAMENTO: Armazenar dados enriquecidos do reviewee (nome e foto)
    // Estes dados já foram enriquecidos pelo ReviewRepository via ActionsRepository
    _state.revieweeName = pendingReview.revieweeName;
    _state.revieweePhotoUrl = pendingReview.revieweePhotoUrl;
    
    debugPrint('📦 [Init] Dados do reviewee pré-carregados:');
    debugPrint('   - revieweeName: ${_state.revieweeName}');
    debugPrint('   - revieweePhotoUrl: ${_state.revieweePhotoUrl}');
  }

  /// Inicializa estado específico do Owner
  void _initializeOwnerState(PendingReviewModel pendingReview) {
    _state.participantIds = pendingReview.participantIds ?? [];
    _state.participantProfiles = pendingReview.participantProfiles ?? {};
    
    // Verificar se há pelo menos um participante confirmado nos perfis
    final hasConfirmedParticipants = _state.participantProfiles.values
        .any((profile) => profile.presenceConfirmed);
    _state.presenceConfirmed = hasConfirmedParticipants;
    
    // VALIDAÇÃO CRÍTICA: Filtrar o owner dos participantIds (defesa em profundidade)
    if (_state.participantIds.contains(_state.reviewerId)) {
      debugPrint('⚠️ [Init] AVISO: Owner detectado na lista de participantes, removendo...');
      _state.participantIds = _state.participantIds
          .where((id) => id != _state.reviewerId)
          .toList();
      debugPrint('   ✅ Lista corrigida: ${_state.participantIds.length} participantes');
    }

    if (_state.presenceConfirmed) {
      _restoreOwnerConfirmedState(pendingReview);
    } else {
      debugPrint('📋 [Init] Owner precisa confirmar presença de ${_state.participantIds.length} participantes');
    }
  }

  /// Restaura estado de Owner que já confirmou presença
  void _restoreOwnerConfirmedState(PendingReviewModel pendingReview) {
    if (pendingReview.confirmedParticipantIds != null && 
        pendingReview.confirmedParticipantIds!.isNotEmpty) {
      _restoreWithConfirmedParticipants(pendingReview.confirmedParticipantIds!);
    } else {
      _recoverFromMissingConfirmedParticipants(pendingReview.pendingReviewId);
    }
  }

  /// Restaura estado com participantes confirmados válidos
  void _restoreWithConfirmedParticipants(List<String> confirmedIds) {
    _state.currentStep = 1;
    _state.selectedParticipants = List<String>.from(confirmedIds);
    
    debugPrint('🔄 [Init] Inicializando estruturas para ${_state.selectedParticipants.length} participantes');
    
    // Inicializar estruturas de dados para cada participante
    _initializeParticipantDataStructures(_state.selectedParticipants);
    
    // Validar estado resultante
    if (_state.currentParticipantId == null) {
      debugPrint('❌ [Init] ERRO: currentParticipantId é null após inicialização!');
      _resetToPresenceConfirmation();
    } else {
      debugPrint('✅ [Init] Inicialização completa. Primeiro participante: ${_state.currentParticipantId}');
    }
  }

  /// Tenta recuperar de estado inconsistente (presenceConfirmed=true mas sem IDs)
  void _recoverFromMissingConfirmedParticipants(String pendingReviewId) {
    debugPrint('⚠️ [Init] presenceConfirmed=true mas sem confirmedParticipantIds');
    
    if (_state.participantIds.isNotEmpty) {
      debugPrint('   🔧 RECUPERAÇÃO: Usando todos os participantIds como confirmados');
      _state.selectedParticipants = List<String>.from(_state.participantIds);
      _initializeParticipantDataStructures(_state.selectedParticipants);
      _state.currentStep = 1;
      
      debugPrint('   ✅ Recuperação bem-sucedida: ${_state.selectedParticipants.length} participantes restaurados');
      _syncConfirmedParticipantsToFirestore(pendingReviewId);
    } else {
      debugPrint('   ❌ Sem participantIds disponíveis. Resetando para Step 0');
      _resetToPresenceConfirmation();
    }
  }

  /// Inicializa estruturas de dados vazias para cada participante
  void _initializeParticipantDataStructures(List<String> participantIds) {
    for (final id in participantIds) {
      _state.ratingsPerParticipant[id] = {};
      _state.badgesPerParticipant[id] = [];
      _state.commentPerParticipant[id] = '';
    }
  }

  /// Reseta estado para step de confirmação de presença
  void _resetToPresenceConfirmation() {
    _state.presenceConfirmed = false;
    _state.currentStep = 0;
  }

  /// Inicializa estado específico do Participant
  /// 
  /// IMPORTANTE: `allowedToReviewOwner` é definido pelo BACKEND
  /// O controller apenas lê e reage ao valor recebido.
  /// 
  /// Responsabilidades:
  /// - Backend: Define regras de negócio (confirmação de presença, etc)
  /// - Frontend: Exibe mensagem de erro apropriada
  /// 
  /// TODO (Futuro): Backend pode enviar `denialReason` explícita
  /// Exemplos: "presence_not_confirmed", "event_not_attended", "already_reviewed"
  /// Isso eliminaria necessidade de mensagem genérica no frontend
  void _initializeParticipantState(PendingReviewModel pendingReview) {
    // FONTE DE VERDADE: Backend define permissão
    _state.allowedToReviewOwner = pendingReview.allowedToReviewOwner ?? false;
    
    if (!_state.allowedToReviewOwner) {
      debugPrint('⚠️ [Init] Participante NÃO tem permissão para avaliar owner');
      debugPrint('   Backend negou permissão (allowed_to_review_owner = false)');
      
      // LIMITAÇÃO ATUAL: Mensagem genérica
      // Backend não envia razão específica
      _state.errorMessage = 'Você não tem permissão para avaliar este evento';
      
      // IDEAL FUTURO: Backend envia denialReason
      // _state.errorMessage = _getErrorMessageForReason(pendingReview.denialReason);
    } else {
      debugPrint('✅ [Init] Participante autorizado a avaliar owner');
    }
  }

  /// Sincroniza participantes confirmados recuperados de volta para o Firestore
  /// Usado quando presenceConfirmed=true mas confirmedParticipantIds estava vazio
  Future<void> _syncConfirmedParticipantsToFirestore(String pendingReviewId) async {
    try {
      debugPrint('🔄 [Sync] Atualizando PendingReview com participantes recuperados');
      await _repository.updatePendingReview(
        pendingReviewId: pendingReviewId,
        data: {
          'confirmed_participant_ids': _state.selectedParticipants,
        },
      );
      debugPrint('✅ [Sync] PendingReview sincronizado com sucesso');
    } catch (e) {
      debugPrint('⚠️ [Sync] Falha ao sincronizar (não crítico): $e');
    }
  }

  // ==================== HELPERS PARA EVOLUÇÃO FUTURA ====================
  
  /// FUTURO: Converter razão do backend em mensagem amigável
  /// Backend enviaria: denialReason = "presence_not_confirmed"
  /// Frontend converte para: "Sua presença ainda não foi confirmada pelo organizador"
  /* 
  String _getErrorMessageForReason(String? reason) {
    switch (reason) {
      case 'presence_not_confirmed':
        return 'Sua presença ainda não foi confirmada pelo organizador';
      case 'event_not_attended':
        return 'Você não participou deste evento';
      case 'already_reviewed':
        return 'Você já avaliou este evento';
      case 'event_cancelled':
        return 'Este evento foi cancelado';
      case 'review_period_expired':
        return 'O período para avaliar este evento expirou';
      default:
        return 'Você não tem permissão para avaliar este evento';
    }
  }
  */

  // ==================== STEP 0: CONFIRMAÇÃO DE PRESENÇA ====================

  void toggleParticipant(String participantId) {
    debugPrint('🔄 toggleParticipant called: $participantId');
    debugPrint('   - Before: selectedParticipants = ${_state.selectedParticipants}');
    debugPrint('   - contains? ${_state.selectedParticipants.contains(participantId)}');
    
    if (_state.selectedParticipants.contains(participantId)) {
      debugPrint('   ➖ Removing participant');
      _state.selectedParticipants.remove(participantId);
      _state.ratingsPerParticipant.remove(participantId);
      _state.badgesPerParticipant.remove(participantId);
      _state.commentPerParticipant.remove(participantId);
    } else {
      debugPrint('   ➕ Adding participant');
      _state.selectedParticipants.add(participantId);
      _state.ratingsPerParticipant[participantId] = {};
      _state.badgesPerParticipant[participantId] = [];
      _state.commentPerParticipant[participantId] = '';
    }
    
    debugPrint('   - After: selectedParticipants = ${_state.selectedParticipants}');
    debugPrint('   - Calling notifyListeners()');
    notifyListeners();
  }

  Future<bool> confirmPresenceAndProceed(String pendingReviewId) async {
    debugPrint('🔍 [confirmPresenceAndProceed] iniciado');
    
    if (_state.selectedParticipants.isEmpty) {
      _batchUpdate(() {
        _state.errorMessage = 'Selecione pelo menos um participante';
      });
      return false;
    }

    if (_state.isTransitioning) return false;

    try {
      _batchUpdate(() {
        _state.isTransitioning = true;
        _state.errorMessage = null;
      });

      // OTIMIZAÇÃO: Para poucos participantes (≤10), operações sequenciais são aceitáveis
      // Para muitos (>10), usar WriteBatch seria mais eficiente
      // Regra de negócio: eventos geralmente têm ≤10 participantes
      
      final participantCount = _state.selectedParticipants.length;
      debugPrint('📊 Confirmando presença de $participantCount participantes');

      if (participantCount > 15) {
        // CAMINHO OTIMIZADO: WriteBatch para muitos participantes
        debugPrint('⚡ Usando WriteBatch (muitos participantes)');
        await _confirmPresenceWithBatch(pendingReviewId);
      } else {
        // CAMINHO PADRÃO: Operações sequenciais (mais simples, suficiente para ≤15)
        debugPrint('📝 Usando operações sequenciais (poucos participantes)');
        
        // Atualizar presence_confirmed por participante em participant_profiles
        final Map<String, dynamic> participantProfilesUpdate = {};
        for (final participantId in _state.selectedParticipants) {
          participantProfilesUpdate['participant_profiles.$participantId.presence_confirmed'] = true;
        }
        
        await _repository.updatePendingReview(
          pendingReviewId: pendingReviewId,
          data: {
            'confirmed_participant_ids': _state.selectedParticipants,
            ...participantProfilesUpdate,
          },
        );

        for (final participantId in _state.selectedParticipants) {
          await _repository.saveConfirmedParticipant(
            eventId: _state.eventId,
            participantId: participantId,
            confirmedBy: _state.reviewerId,
          );
        }
      }

      _batchUpdate(() {
        _state.presenceConfirmed = true;
        _state.currentStep = 1;
        _state.currentParticipantIndex = 0;
        _state.isTransitioning = false;
      });
      
      debugPrint('✅ Confirmação de presença concluída');
      return true;
    } catch (e, stack) {
      debugPrint('❌ Erro ao confirmar presença: $e\n$stack');
      _batchUpdate(() {
        _state.errorMessage = 'Erro ao confirmar presença: $e';
        _state.isTransitioning = false;
      });
      return false;
    }
  }

  /// Método otimizado com WriteBatch para confirmar presença de muitos participantes
  Future<void> _confirmPresenceWithBatch(String pendingReviewId) async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();

    // 1. Atualizar PendingReview com presence_confirmed por participante
    final Map<String, dynamic> participantProfilesUpdate = {
      'confirmed_participant_ids': _state.selectedParticipants,
    };
    
    for (final participantId in _state.selectedParticipants) {
      participantProfilesUpdate['participant_profiles.$participantId.presence_confirmed'] = true;
    }
    
    batch.update(
      firestore.collection('PendingReviews').doc(pendingReviewId),
      participantProfilesUpdate,
    );

    // 2. Criar ConfirmedParticipants em batch
    for (final participantId in _state.selectedParticipants) {
      final confirmedRef = firestore
          .collection('events')
          .doc(_state.eventId)
          .collection('ConfirmedParticipants')
          .doc(participantId);
      
      batch.set(confirmedRef, {
        'confirmed_at': FieldValue.serverTimestamp(),
        'confirmed_by': _state.reviewerId,
        'presence': 'Vou',
        'reviewed': false,
      });
    }

    // 3. Commit único
    await batch.commit();
    debugPrint('✅ WriteBatch commit realizado: ${_state.selectedParticipants.length} participantes');
  }

  // ==================== STEP 1: RATINGS ====================

  void setRating(String criterion, int value) {
    if (_state.isTransitioning) return;
    
    // VALIDAÇÃO: Backend define permissão via allowedToReviewOwner
    // Frontend apenas bloqueia UI e mostra mensagem
    if (_state.isParticipantReview && !_state.allowedToReviewOwner) {
      _batchUpdate(() {
        _state.errorMessage = 'Você não tem permissão para avaliar este evento';
      });
      return;
    }
    
    _batchUpdate(() {
      if (_state.isOwnerReview) {
        final participantId = _state.currentParticipantId;
        if (participantId == null) {
          _state.errorMessage = 'Erro: nenhum participante selecionado';
          return;
        }

        _state.ratingsPerParticipant[participantId] ??= {};
        _state.ratingsPerParticipant[participantId]![criterion] = value;
      } else {
        _state.ratings[criterion] = value;
      }
      
      _state.errorMessage = null;
    });
  }

  void goToBadgesStep() {
    final error = ReviewNavigationService.goToBadgesStep(_state);
    if (error != null) {
      _batchUpdate(() {
        _state.errorMessage = error;
      });
      return;
    }

    _batchUpdate(() {
      _state.errorMessage = null;
      _state.currentStep = 2;
    });
  }

  // ==================== STEP 2: BADGES ====================

  void toggleBadge(String badgeKey) {
    if (_state.isTransitioning) return;
    
    // VALIDAÇÃO: Backend define permissão via allowedToReviewOwner
    // Frontend apenas bloqueia UI e mostra mensagem
    if (_state.isParticipantReview && !_state.allowedToReviewOwner) {
      _batchUpdate(() {
        _state.errorMessage = 'Você não tem permissão para avaliar este evento';
      });
      return;
    }
    
    if (_state.isOwnerReview) {
      final participantId = _state.currentParticipantId;
      if (participantId == null) return;

      _state.badgesPerParticipant[participantId] ??= [];
      if (_state.badgesPerParticipant[participantId]!.contains(badgeKey)) {
        _state.badgesPerParticipant[participantId]!.remove(badgeKey);
      } else {
        _state.badgesPerParticipant[participantId]!.add(badgeKey);
      }
    } else {
      if (_state.selectedBadges.contains(badgeKey)) {
        _state.selectedBadges.remove(badgeKey);
      } else {
        _state.selectedBadges.add(badgeKey);
      }
    }
    notifyListeners();
  }

  void goToCommentStep() {
    _batchUpdate(() {
      _state.errorMessage = null;
      // Owner: step 3 é comment, Participant: step 2 é comment
      _state.currentStep = _state.isOwnerReview ? 3 : 2;
    });
  }

  // ==================== STEP 3: COMENTÁRIO ====================

  Future<void> nextParticipant() async {
    // PROTEÇÃO: Bloquear múltiplas chamadas simultâneas
    if (_state.isTransitioning) {
      debugPrint('⚠️ [nextParticipant] Já em transição, ignorando');
      return;
    }

    final result = ReviewNavigationService.prepareNextParticipant(_state, commentController);
    
    if (result['shouldTransition'] != true) return;

    _batchUpdate(() {
      _state.isTransitioning = true;
    });

    // Pequeno delay para garantir que o UI receba a notificação antes de atualizar estado
    await Future.delayed(const Duration(milliseconds: 50));

    _batchUpdate(() {
      _state.currentParticipantIndex = result['newIndex'];
      _state.currentStep = result['newStep'];
      
      commentController.clear();
      if (result['nextComment'] != null && result['nextComment'].isNotEmpty) {
        commentController.text = result['nextComment'];
      }
      
      _state.isTransitioning = false;
    });
  }

  // ==================== SUBMIT ====================

  Future<bool> submitReview({String? pendingReviewId}) async {
    if (_state.isOwnerReview) {
      return submitAllReviews(pendingReviewId: pendingReviewId);
    } else {
      return submitSingleReview(pendingReviewId: pendingReviewId);
    }
  }

  Future<bool> submitSingleReview({String? pendingReviewId}) async {
    // VALIDAÇÃO CRÍTICA: Backend define permissão via allowedToReviewOwner
    // Esta é a última linha de defesa antes de tentar salvar no Firestore
    // Backend deve validar novamente nas Security Rules
    if (!_state.allowedToReviewOwner) {
      debugPrint('❌ [submitSingleReview] BLOQUEADO: Participante sem permissão');
      _batchUpdate(() {
        _state.errorMessage = 'Você não tem permissão para avaliar este evento. Sua presença pode não ter sido confirmada pelo organizador.';
      });
      return false;
    }
    
    if (_state.ratings.length < MINIMUM_REQUIRED_RATINGS) {
      _batchUpdate(() {
        _state.errorMessage = 'Por favor, avalie todos os $MINIMUM_REQUIRED_RATINGS critérios obrigatórios antes de enviar.';
      });
      return false;
    }
    
    final comment = commentController.text.trim();

    _batchUpdate(() {
      _state.isSubmitting = true;
      _state.errorMessage = null;
    });

    try {
      await _repository.createReview(
        eventId: _state.eventId,
        revieweeId: _state.revieweeId,
        reviewerRole: _state.reviewerRole,
        criteriaRatings: _state.ratings,
        badges: _state.selectedBadges,
        comment: comment.isEmpty ? null : comment,
        pendingReviewId: pendingReviewId,
      );

      _batchUpdate(() {
        _state.isSubmitting = false;
      });
      return true;
    } catch (e) {
      _batchUpdate(() {
        _state.errorMessage = ReviewUIService.getErrorMessage(e);
        _state.isSubmitting = false;
      });
      return false;
    }
  }

  Future<bool> submitAllReviews({String? pendingReviewId}) async {
    debugPrint('📤 [submitAllReviews] Iniciado. participantes: ${_state.selectedParticipants.length}');
    
    // 1. VALIDAR: Todos os participantes foram avaliados?
    if (!_validateAllParticipantsBeforeSubmit()) {
      return false;
    }

    // 2. PREPARAR: Salvar comentário do último participante
    _saveLastParticipantComment();

    // 3. INICIAR: Marcar estado de submissão
    _batchUpdate(() {
      _state.isSubmitting = true;
      _state.errorMessage = null;
    });

    // 4. EXECUTAR: Criar todos os reviews em batch
    try {
      await _executeAllReviewsBatch(pendingReviewId);
      
      _batchUpdate(() {
        _state.isSubmitting = false;
      });
      return true;
    } catch (e, stackTrace) {
      debugPrint('❌ [submitAllReviews] Erro: $e\n$stackTrace');
      
      _batchUpdate(() {
        _state.errorMessage = ReviewUIService.getErrorMessage(e);
        _state.isSubmitting = false;
      });
      return false;
    }
  }

  /// Valida se todos os participantes confirmados foram avaliados
  bool _validateAllParticipantsBeforeSubmit() {
    final missingParticipants = ReviewValidationService.validateAllParticipantsReviewed(_state);
    
    if (missingParticipants != null) {
      _batchUpdate(() {
        if (missingParticipants.length == 1 && missingParticipants.first == 'Nenhum participante avaliado') {
          _state.errorMessage = 'Avalie pelo menos um participante';
        } else {
          _state.errorMessage = 'Você precisa avaliar todos os participantes antes de enviar.\nFaltam: ${missingParticipants.join(", ")}';
        }
      });
      return false;
    }
    
    return true;
  }

  /// Salva comentário do último participante sendo avaliado
  void _saveLastParticipantComment() {
    final lastParticipantId = _state.currentParticipantId;
    if (lastParticipantId != null) {
      _state.commentPerParticipant[lastParticipantId] = commentController.text.trim();
      debugPrint('💬 [Submit] Comentário do último participante salvo');
    }
  }

  /// Executa criação de todos os reviews em lote (WriteBatch)
  Future<void> _executeAllReviewsBatch(String? pendingReviewId) async {
    final firestore = FirebaseFirestore.instance;
    
    // 1. Buscar dados do owner
    final ownerData = await ReviewBatchService.prepareOwnerData(_state.reviewerId, firestore);
    final ownerName = ownerData['ownerName']!;
    final ownerPhotoUrl = ownerData['ownerPhotoUrl'];

    // 2. Criar batches para todos os participantes
    var batch = firestore.batch();
    int operationCount = 0;
    const maxBatchSize = 490; // Margem de segurança (limite Firestore: 500)
    
    for (final participantId in _state.selectedParticipants) {
      // Adicionar 1 operação por participante (Review)
      // PendingReview do participante agora é criada via Cloud Function (createPendingReviewsScheduled)
      ReviewBatchService.createReviewBatch(
        batch, 
        participantId, 
        _state, 
        firestore,
        reviewerName: ownerName,
        reviewerPhotoUrl: ownerPhotoUrl,
      );
      operationCount++;

      // Commit parcial se atingir limite
      if (operationCount >= maxBatchSize) {
        await batch.commit();
        debugPrint('✅ [Batch] Commit parcial: $operationCount operações');
        batch = firestore.batch();
        operationCount = 0;
      }
    }

    // 3. Deletar PendingReview do owner
    if (pendingReviewId != null && pendingReviewId.isNotEmpty) {
      debugPrint('🗑️ [Batch] Deletando PendingReview do owner');
      debugPrint('   - pendingReviewId: $pendingReviewId');
      debugPrint('   - userId atual: ${_state.reviewerId}');
      batch.delete(firestore.collection('PendingReviews').doc(pendingReviewId));
      operationCount++;
    }

    // 4. Commit final
    if (operationCount > 0) {
      debugPrint('🚀 [Batch] Preparando commit final com $operationCount operações');
      debugPrint('   - userId atual: ${_state.reviewerId}');
      debugPrint('   - eventId: ${_state.eventId}');
      await batch.commit();
      debugPrint('✅ [Batch] Commit final: $operationCount operações');
    }

    // 5. Marcar participantes como avaliados (separado do batch principal)
    debugPrint('📝 [Post-Batch] Marcando ${_state.selectedParticipants.length} participantes como avaliados');
    for (final participantId in _state.selectedParticipants) {
      try {
        await ReviewBatchService.markParticipantReviewedSeparate(
          participantId, 
          _state.eventId, 
          firestore,
        );
      } catch (e) {
        debugPrint('⚠️ [Post-Batch] Erro ao marcar participante $participantId: $e');
        // Não falhar o fluxo todo se essa operação falhar
      }
    }

    debugPrint('✅ [submitAllReviews] ${_state.selectedParticipants.length} reviews criados com sucesso');
  }

  Future<bool> skipCommentAndSubmit({String? pendingReviewId}) async {
    return submitReview(pendingReviewId: pendingReviewId);
  }

  Future<bool> dismissReview(String pendingReviewId) async {
    try {
      await _repository.dismissPendingReview(pendingReviewId);
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==================== NAVEGAÇÃO ====================

  void previousStep() {
    final result = ReviewNavigationService.preparePreviousStep(_state, commentController);
    
    if (result['canGoBack'] == false) {
      debugPrint('⚠️ Não pode voltar');
      return;
    }

    _batchUpdate(() {
      if (result.containsKey('newIndex')) {
        _state.currentParticipantIndex = result['newIndex'];
      }
      if (result.containsKey('newStep')) {
        _state.currentStep = result['newStep'];
      }
      if (result.containsKey('previousComment')) {
        commentController.text = result['previousComment'];
      }
      _state.errorMessage = null;
    });
  }
}
