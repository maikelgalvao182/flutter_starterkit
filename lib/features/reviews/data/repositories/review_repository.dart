import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/features/reviews/data/models/review_model.dart';
import 'package:partiu/features/reviews/data/models/pending_review_model.dart';
import 'package:partiu/features/reviews/data/models/review_stats_model.dart';
import 'package:partiu/features/reviews/presentation/services/pending_reviews_listener_service.dart';
import 'package:partiu/features/reviews/data/repositories/actions_repository.dart';

/// Repository para gerenciar reviews no Firestore
class ReviewRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ActionsRepository _actionsRepo = ActionsRepository();

  // ==================== PENDING REVIEWS ====================

  /// Busca reviews pendentes do usuário atual
  /// 
  /// Retorna apenas reviews que:
  /// - Ainda não expiraram
  /// - Não foram dismissed
  /// - Pertencem ao usuário logado
  Future<List<PendingReviewModel>> getPendingReviews() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      throw Exception('Usuário não autenticado');
    }

    final now = Timestamp.now();

    // Query simplificada - apenas os filtros essenciais
    final snapshot = await _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('dismissed', isEqualTo: false)
        .where('expires_at', isGreaterThan: now)
        .orderBy('expires_at')
        .orderBy('created_at', descending: true)
        .limit(20)
        .get();

    // Converte diretamente sem verificação extra
    // (A verificação de duplicata será feita no momento do submit)
    return snapshot.docs
        .map((doc) => PendingReviewModel.fromFirestore(doc))
        .toList();
  }

  /// Stream de reviews pendentes (para ActionsTab)
  Stream<List<PendingReviewModel>> getPendingReviewsStream() async* {
    final userId = _auth.currentUser?.uid;
    debugPrint('🔍 [ReviewRepository] getPendingReviewsStream');
    debugPrint('   - userId: $userId');
    
    if (userId == null) {
      debugPrint('   ❌ userId é null, retornando stream vazio');
      yield [];
      return;
    }

    final now = Timestamp.now();
    debugPrint('   - now: ${now.toDate()}');

    // Query de DEBUG: buscar TODOS os reviews do usuário (ignorando filtros)
    _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .get()
        .then((snapshot) {
          debugPrint('🔍 [DEBUG] Total de PendingReviews para este usuário (sem filtros): ${snapshot.docs.length}');
          for (var doc in snapshot.docs) {
            final data = doc.data();
            final expiresAt = data['expires_at'] as Timestamp?;
            final dismissed = data['dismissed'] as bool?;
            debugPrint('   📄 Doc ${doc.id}:');
            debugPrint('      - reviewer_id: ${data['reviewer_id']}');
            debugPrint('      - dismissed: $dismissed');
            debugPrint('      - expires_at: ${expiresAt?.toDate()}');
            debugPrint('      - now > expires_at? ${expiresAt != null ? now.compareTo(expiresAt) > 0 : 'null'}');
            debugPrint('      - event_title: ${data['event_title']}');
          }
        });

    await for (final snapshot in _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('dismissed', isEqualTo: false)
        .where('expires_at', isGreaterThan: now)
        .orderBy('expires_at')
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()) {
      
      debugPrint('📦 [ReviewRepository] Stream snapshot recebido: ${snapshot.docs.length} docs');
      
      if (snapshot.docs.isEmpty) {
        debugPrint('   ✅ Nenhum review, retornando lista vazia');
        yield [];
        continue;
      }
      
      // Criar modelos base dos reviews
      final reviews = snapshot.docs
          .map((doc) => PendingReviewModel.fromFirestore(doc))
          .toList();
      
      // Coletar event IDs únicos
      final eventIds = reviews
          .map((r) => r.eventId)
          .toSet()
          .toList();
      
      debugPrint('🔍 [ReviewRepository] Buscando dados de ${eventIds.length} eventos');
      
      // Buscar dados dos owners em batch
      final ownersData = await _actionsRepo.getMultipleEventOwnersData(eventIds);
      
      // Enriquecer APENAS reviews de PARTICIPANTS (que avaliam owner)
      // Owner reviews já vêm com revieweeId correto do Firestore
      final enrichedReviews = reviews.map((review) {
        // Se é PARTICIPANT avaliando, enriquecer com dados do owner
        if (review.reviewerRole == 'participant') {
          final ownerData = ownersData[review.eventId];
          
          if (ownerData != null) {
            debugPrint('✅ [ReviewRepository] Enriquecendo review PARTICIPANT ${review.pendingReviewId} com owner: ${ownerData['fullName']}');
            return review.copyWith(
              revieweeId: ownerData['userId'] as String,
              revieweeName: ownerData['fullName'] as String,
              revieweePhotoUrl: ownerData['photoUrl'] as String?,
            );
          } else {
            debugPrint('⚠️ [ReviewRepository] Owner não encontrado para evento ${review.eventId}');
            return review;
          }
        }
        
        // Owner reviews mantêm revieweeId original (participantId)
        debugPrint('✅ [ReviewRepository] Mantendo review OWNER ${review.pendingReviewId} com revieweeId original: ${review.revieweeId}');
        return review;
      }).toList();
      
      // VALIDAÇÃO CRÍTICA: Filtrar reviews de autoavaliação (defesa em profundidade)
      final validReviews = enrichedReviews.where((review) {
        if (review.reviewerId == review.revieweeId) {
          debugPrint('❌ [ReviewRepository] BLOQUEADO: Autoavaliação detectada!');
          debugPrint('   - pendingReviewId: ${review.pendingReviewId}');
          debugPrint('   - reviewerId: ${review.reviewerId}');
          debugPrint('   - revieweeId: ${review.revieweeId}');
          return false;
        }
        return true;
      }).toList();
      
      debugPrint('   ✅ Retornando ${validReviews.length} reviews válidos (${enrichedReviews.length - validReviews.length} autoavaliações bloqueadas)');
      yield validReviews;
    }
  }

  /// Busca count de reviews pendentes (para badge)
  Future<int> getPendingReviewsCount() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return 0;

    final now = Timestamp.now();

    final snapshot = await _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('dismissed', isEqualTo: false)
        .where('expires_at', isGreaterThan: now)
        .get();

    return snapshot.docs.length;
  }

  /// Marca pending review como dismissed
  Future<void> dismissPendingReview(String pendingReviewId) async {
    await _firestore.collection('PendingReviews').doc(pendingReviewId).update({
      'dismissed': true,
      'dismissed_at': FieldValue.serverTimestamp(),
    });
    
    // Notifica o listener para remover do cache local
    PendingReviewsListenerService.instance.clearPendingReview(pendingReviewId);
  }

  /// Atualiza PendingReview (ex: presenceConfirmed)
  Future<void> updatePendingReview({
    required String pendingReviewId,
    required Map<String, dynamic> data,
  }) async {
    debugPrint('🔍 [ReviewRepository] updatePendingReview');
    debugPrint('   - pendingReviewId: $pendingReviewId');
    debugPrint('   - data: $data');
    
    try {
      await _firestore
          .collection('PendingReviews')
          .doc(pendingReviewId)
          .update(data);
      debugPrint('   ✅ PendingReview atualizado com sucesso');
    } catch (e, stack) {
      debugPrint('   ❌ Erro ao atualizar PendingReview: $e');
      debugPrint('   Stack trace: $stack');
      rethrow;
    }
  }

  /// Salva participante confirmado na subcoleção do evento
  Future<void> saveConfirmedParticipant({
    required String eventId,
    required String participantId,
    required String confirmedBy,
  }) async {
    debugPrint('🔍 [ReviewRepository] saveConfirmedParticipant');
    debugPrint('   - eventId: $eventId');
    debugPrint('   - participantId: $participantId');
    debugPrint('   - confirmedBy: $confirmedBy');
    
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .collection('ConfirmedParticipants')
          .doc(participantId)
          .set({
        'confirmed_at': FieldValue.serverTimestamp(),
        'confirmed_by': confirmedBy,
        'presence': 'Vou',
        'reviewed': false,
      });
      debugPrint('   ✅ Participante confirmado salvo com sucesso');
    } catch (e, stack) {
      debugPrint('   ❌ Erro ao salvar participante confirmado: $e');
      debugPrint('   Stack trace: $stack');
      rethrow;
    }
  }

  /// Marca participante como avaliado
  Future<void> markParticipantAsReviewed({
    required String eventId,
    required String participantId,
  }) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('ConfirmedParticipants')
        .doc(participantId)
        .update({'reviewed': true});
  }

  /// Cria PendingReview para participante avaliar owner
  Future<void> createParticipantPendingReview({
    required String eventId,
    required String participantId,
    required String ownerId,
    required String ownerName,
    required String? ownerPhotoUrl,
    required String eventTitle,
    required String eventEmoji,
    required String? eventLocationName,
    required DateTime? eventScheduleDate,
  }) async {
    final pendingReviewId = '${eventId}_participant_$participantId';
    final expiresAt = DateTime.now().add(const Duration(days: 30));

    await _firestore.collection('PendingReviews').doc(pendingReviewId).set({
      'pending_review_id': pendingReviewId,
      'event_id': eventId,
      'application_id': '',
      'reviewer_id': participantId,
      'reviewee_id': ownerId,
      'reviewee_name': ownerName,
      'reviewee_photo_url': ownerPhotoUrl,
      'reviewer_role': 'participant',
      'event_title': eventTitle,
      'event_emoji': eventEmoji,
      'event_location': eventLocationName,
      'event_date': eventScheduleDate != null
          ? Timestamp.fromDate(eventScheduleDate)
          : FieldValue.serverTimestamp(),
      'allowed_to_review_owner': true,
      'created_at': FieldValue.serverTimestamp(),
      'expires_at': Timestamp.fromDate(expiresAt),
      'dismissed': false,
    });
  }

  /// Deleta PendingReview
  Future<void> deletePendingReview(String pendingReviewId) async {
    await _firestore
        .collection('PendingReviews')
        .doc(pendingReviewId)
        .delete();
    
    // Notifica o listener
    PendingReviewsListenerService.instance.clearPendingReview(pendingReviewId);
  }

  // ==================== REVIEWS ====================

  /// Cria uma nova review
  Future<void> createReview({
    required String eventId,
    required String revieweeId,
    required String reviewerRole,
    required Map<String, int> criteriaRatings,
    List<String> badges = const [],
    String? comment,
    String? pendingReviewId,
  }) async {
    debugPrint('🔍 [createReview] Iniciando...');
    debugPrint('   eventId: $eventId');
    debugPrint('   revieweeId: $revieweeId');
    debugPrint('   reviewerRole: $reviewerRole');
    debugPrint('   criteriaRatings: $criteriaRatings');
    debugPrint('   pendingReviewId: $pendingReviewId');
    
    final userId = _auth.currentUser?.uid;
    debugPrint('   userId (reviewer): $userId');
    
    if (userId == null) {
      debugPrint('❌ [createReview] Usuário não autenticado');
      throw Exception('Usuário não autenticado');
    }

    // VALIDAÇÃO CRÍTICA: Bloquear autoavaliação
    if (userId == revieweeId) {
      debugPrint('❌ [createReview] BLOQUEADO: Tentativa de autoavaliação!');
      debugPrint('   reviewerId: $userId');
      debugPrint('   revieweeId: $revieweeId');
      throw Exception('Você não pode avaliar a si mesmo');
    }

    // Verifica duplicata
    debugPrint('🔍 [createReview] Verificando duplicata...');
    final existing = await _firestore
        .collection('Reviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('reviewee_id', isEqualTo: revieweeId)
        .where('event_id', isEqualTo: eventId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      debugPrint('❌ [createReview] Review duplicado encontrado');
      throw Exception('Você já avaliou esta pessoa neste evento');
    }
    debugPrint('   ✅ Nenhum duplicado encontrado');

    // Busca dados do reviewer
    debugPrint('🔍 [createReview] Buscando dados do reviewer...');
    final userDoc = await _firestore.collection('Users').doc(userId).get();
    final userData = userDoc.data();
    debugPrint('   reviewerName: ${userData?['fullname']}');
    debugPrint('   reviewerPhotoUrl: ${userData?['user_photo_link']}');

    // Calcula overall rating
    final overallRating = ReviewModel.calculateOverallRating(criteriaRatings);
    debugPrint('   overallRating calculado: $overallRating');

    // Cria review
    final now = DateTime.now();
    final review = ReviewModel(
      reviewId: '', // Será preenchido após criação
      eventId: eventId,
      reviewerId: userId,
      revieweeId: revieweeId,
      reviewerRole: reviewerRole,
      criteriaRatings: criteriaRatings,
      overallRating: overallRating,
      badges: badges,
      comment: comment?.trim().isEmpty == true ? null : comment?.trim(),
      createdAt: now,
      updatedAt: now,
      reviewerName: userData?['fullname'] as String?,
      reviewerPhotoUrl: userData?['user_photo_link'] as String?,
    );

    // Converte para Firestore e loga
    final firestoreData = review.toFirestore();
    debugPrint('📤 [createReview] Dados a serem salvos no Firestore:');
    debugPrint('   ${firestoreData.toString()}');
    
    // Validação final de segurança
    if (firestoreData['reviewer_id'] != userId) {
      debugPrint('❌ [createReview] ERRO CRÍTICO: reviewer_id não corresponde ao userId autenticado!');
      debugPrint('   reviewer_id no documento: ${firestoreData['reviewer_id']}');
      debugPrint('   userId autenticado: $userId');
      throw Exception('Erro de segurança: reviewer_id inválido');
    }

    // Salva no Firestore
    debugPrint('💾 [createReview] Salvando no Firestore...');
    try {
      await _firestore.collection('Reviews').add(firestoreData);
      debugPrint('   ✅ Review salvo com sucesso');
    } catch (e, stack) {
      debugPrint('❌ [createReview] ERRO ao salvar no Firestore: $e');
      debugPrint('   Stack trace: $stack');
      rethrow;
    }

    // Remove pending review
    if (pendingReviewId != null && pendingReviewId.isNotEmpty) {
      debugPrint('🗑️ [createReview] Removendo PendingReview: $pendingReviewId');
      await _removePendingReviewById(pendingReviewId);
      // Notifica o listener
      PendingReviewsListenerService.instance.clearPendingReview(pendingReviewId);
    } else {
      debugPrint('🗑️ [createReview] Removendo PendingReview por query');
      await _removePendingReview(userId, revieweeId, eventId);
    }
    
    debugPrint('✅ [createReview] Processo completo!');
  }

  /// Busca reviews de um usuário
  Future<List<ReviewModel>> getUserReviews(
    String userId, {
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    Query query = _firestore
        .collection('Reviews')
        .where('reviewee_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit);

    if (startAfter != null) {
      query = query.startAfterDocument(startAfter);
    }

    final snapshot = await query.get();

    return snapshot.docs.map((doc) => ReviewModel.fromFirestore(doc)).toList();
  }

  /// Busca estatísticas de reviews (calculadas dinamicamente)
  Future<ReviewStatsModel?> getReviewStats(String userId) async {
    final reviewsSnapshot = await _firestore
        .collection('Reviews')
        .where('reviewee_id', isEqualTo: userId)
        .get();

    if (reviewsSnapshot.docs.isEmpty) {
      return null;
    }

    final reviews = reviewsSnapshot.docs
        .map((doc) => ReviewModel.fromFirestore(doc))
        .toList();

    // Calcula estatísticas dinamicamente
    return ReviewStatsModel.calculate(userId, reviews);
  }

  /// Stream de reviews pendentes (para atualização em tempo real)
  Stream<List<PendingReviewModel>> watchPendingReviews() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      return Stream.value([]);
    }

    final now = Timestamp.now();

    return _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: userId)
        .where('dismissed', isEqualTo: false)
        .where('expires_at', isGreaterThan: now)
        .orderBy('expires_at')
        .orderBy('created_at', descending: true)
        .limit(20)
        .snapshots()
        .asyncMap((snapshot) async {
      final pendingReviews = <PendingReviewModel>[];

      for (final doc in snapshot.docs) {
        final pending = PendingReviewModel.fromFirestore(doc);

        // Verifica se já existe review
        final existingReview = await _firestore
            .collection('Reviews')
            .where('reviewer_id', isEqualTo: userId)
            .where('reviewee_id', isEqualTo: pending.revieweeId)
            .where('event_id', isEqualTo: pending.eventId)
            .limit(1)
            .get();

        if (existingReview.docs.isEmpty) {
          pendingReviews.add(pending);
        }
      }

      return pendingReviews;
    });
  }

  /// Stream de reviews de um usuário (para atualização em tempo real)
  Stream<List<ReviewModel>> watchUserReviews(String userId, {int limit = 10}) {
    return _firestore
        .collection('Reviews')
        .where('reviewee_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ReviewModel.fromFirestore(doc))
            .toList());
  }

  /// Stream de estatísticas de reviews de um usuário (lê de Users.overallRating)
  Stream<ReviewStatsModel> watchUserStats(String userId) {
    debugPrint('🔍 [ReviewRepository] Iniciando watchUserStats para userId: ${userId.substring(0, 8)}...');
    
    return _firestore
        .collection('Users')
        .doc(userId)
        .snapshots()
        .asyncMap((userDoc) async {
          try {
            debugPrint('📊 [ReviewRepository] watchUserStats snapshot recebido do Users');
            
            final userData = userDoc.data();
            if (userData == null) {
              debugPrint('  ⚠️  Documento Users não existe');
              return ReviewStatsModel(
                userId: userId,
                totalReviews: 0,
                overallRating: 0.0,
                ratingsBreakdown: {},
                badgesCount: {},
                last30DaysCount: 0,
                last90DaysCount: 0,
                lastUpdated: DateTime.now(),
              );
            }

            final overallRating = (userData['overallRating'] as num?)?.toDouble() ?? 0.0;
            final totalReviews = (userData['totalReviews'] as num?)?.toInt() ?? 0;
            
            debugPrint('  - overallRating: $overallRating');
            debugPrint('  - totalReviews: $totalReviews');

            if (totalReviews == 0) {
              debugPrint('  ⚠️  Nenhuma review, retornando stats vazias');
              return ReviewStatsModel(
                userId: userId,
                totalReviews: 0,
                overallRating: 0.0,
                ratingsBreakdown: {},
                badgesCount: {},
                last30DaysCount: 0,
                last90DaysCount: 0,
                lastUpdated: DateTime.now(),
              );
            }

            // Buscar reviews para calcular breakdown e badges
            debugPrint('  🔍 Buscando reviews para breakdown e badges...');
            final reviewsSnapshot = await _firestore
                .collection('Reviews')
                .where('reviewee_id', isEqualTo: userId)
                .get();

            debugPrint('  - Reviews encontradas: ${reviewsSnapshot.docs.length}');

            final reviews = <ReviewModel>[];
            for (final doc in reviewsSnapshot.docs) {
              try {
                final review = ReviewModel.fromFirestore(doc);
                reviews.add(review);
              } catch (e) {
                debugPrint('  ❌ Erro ao parsear review ${doc.id}: $e');
                // Continua processando outras reviews
              }
            }

            debugPrint('  ✅ Reviews parseadas com sucesso: ${reviews.length}');

            // Calcula breakdown por critério
            final Map<String, List<int>> criteriaValues = {};
            for (final review in reviews) {
              for (final entry in review.criteriaRatings.entries) {
                criteriaValues.putIfAbsent(entry.key, () => []).add(entry.value);
              }
            }

            final ratingsBreakdown = criteriaValues.map((key, values) {
              final sum = values.reduce((a, b) => a + b);
              return MapEntry(key, double.parse((sum / values.length).toStringAsFixed(1)));
            });

            // Conta badges
            final Map<String, int> badgesCount = {};
            for (final review in reviews) {
              for (final badge in review.badges) {
                badgesCount[badge] = (badgesCount[badge] ?? 0) + 1;
              }
            }

            final now = DateTime.now();
            final thirtyDaysAgo = now.subtract(const Duration(days: 30));
            final ninetyDaysAgo = now.subtract(const Duration(days: 90));

            int last30DaysCount = 0;
            int last90DaysCount = 0;
            for (final review in reviews) {
              if (review.createdAt.isAfter(thirtyDaysAgo)) {
                last30DaysCount++;
              }
              if (review.createdAt.isAfter(ninetyDaysAgo)) {
                last90DaysCount++;
              }
            }

            final stats = ReviewStatsModel(
              userId: userId,
              totalReviews: totalReviews,
              overallRating: overallRating, // Usa valor de Users, não calcula
              ratingsBreakdown: ratingsBreakdown,
              badgesCount: badgesCount,
              last30DaysCount: last30DaysCount,
              last90DaysCount: last90DaysCount,
              lastUpdated: DateTime.now(),
            );

            debugPrint('  📈 Stats finais criadas: totalReviews=${stats.totalReviews}, overallRating=${stats.overallRating}, hasReviews=${stats.hasReviews}');
            
            return stats;
          } catch (e, stackTrace) {
            debugPrint('  ❌ ERRO em watchUserStats: $e');
            debugPrint('  Stack: $stackTrace');
            // Retorna stats vazias em caso de erro
            return ReviewStatsModel(
              userId: userId,
              totalReviews: 0,
              overallRating: 0.0,
              ratingsBreakdown: {},
              badgesCount: {},
              last30DaysCount: 0,
              last90DaysCount: 0,
              lastUpdated: DateTime.now(),
            );
          }
        });
  }

  // ==================== PRIVATE HELPERS ====================

  Future<void> _removePendingReview(
    String reviewerId,
    String revieweeId,
    String eventId,
  ) async {
    final snapshot = await _firestore
        .collection('PendingReviews')
        .where('reviewer_id', isEqualTo: reviewerId)
        .where('reviewee_id', isEqualTo: revieweeId)
        .where('event_id', isEqualTo: eventId)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.delete();
    }
  }

  /// Remove pending review por ID direto
  Future<void> _removePendingReviewById(String pendingReviewId) async {
    try {
      await _firestore
          .collection('PendingReviews')
          .doc(pendingReviewId)
          .delete();
    } catch (e) {
      // Falha silenciosa - o documento pode já ter sido deletado
    }
  }
}
