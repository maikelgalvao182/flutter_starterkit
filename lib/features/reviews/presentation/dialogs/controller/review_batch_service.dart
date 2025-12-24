import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:partiu/features/reviews/data/models/review_model.dart';
import 'package:partiu/features/reviews/presentation/dialogs/controller/review_dialog_state.dart';

/// Serviço responsável por operações em lote (batch) no Firestore
class ReviewBatchService {
  /// Cria review no batch (owner → participant)
  static void createReviewBatch(
    WriteBatch batch,
    String participantId,
    ReviewDialogState state,
    FirebaseFirestore firestore, {
    required String reviewerName,
    String? reviewerPhotoUrl,
  }) {
    final reviewRef = firestore.collection('Reviews').doc();
    final criteriaRatings = state.ratingsPerParticipant[participantId] ?? {};
    final overallRating = ReviewModel.calculateOverallRating(criteriaRatings);
    
    final reviewData = {
      'event_id': state.eventId,
      'reviewee_id': participantId,
      'reviewer_id': state.reviewerId,
      'reviewer_role': 'owner',
      'criteria_ratings': criteriaRatings,
      'overall_rating': overallRating,
      'badges': state.badgesPerParticipant[participantId] ?? [],
      'comment': state.commentPerParticipant[participantId]?.trim().isEmpty == true
          ? null
          : state.commentPerParticipant[participantId]?.trim(),
      'created_at': FieldValue.serverTimestamp(),
      'updated_at': FieldValue.serverTimestamp(),
      'reviewer_name': reviewerName,
      if (reviewerPhotoUrl != null) 'reviewer_photo_url': reviewerPhotoUrl,
    };
    
    debugPrint('📝 [Batch] Criando Review');
    debugPrint('   - reviewId: ${reviewRef.id}');
    debugPrint('   - reviewee_id: $participantId');
    debugPrint('   - reviewer_id: ${state.reviewerId}');
    debugPrint('   - reviewer_role: owner');
    debugPrint('   - reviewer_name: $reviewerName');
    debugPrint('   - overall_rating: $overallRating');
    
    batch.set(reviewRef, reviewData);
  }

  /// Cria pending review para participante no batch
  static void createPendingReviewBatch(
    WriteBatch batch,
    String participantId,
    String ownerName,
    String? ownerPhotoUrl,
    ReviewDialogState state,
    FirebaseFirestore firestore,
  ) {
    final pendingRef = firestore.collection('PendingReviews').doc();
    final pendingData = {
      'event_id': state.eventId,
      'reviewer_id': participantId,
      'reviewee_id': state.reviewerId,
      'reviewer_role': 'participant',
      'event_title': state.eventTitle,
      'event_emoji': state.eventEmoji,
      'event_location': state.eventLocationName,
      'event_date': state.eventScheduleDate,
      'owner_name': ownerName,
      'owner_photo_url': ownerPhotoUrl,
      'allowed_to_review_owner': true,
      'created_at': FieldValue.serverTimestamp(),
      'status': 'pending',
    };
    
    debugPrint('📋 [Batch] Criando PendingReview');
    debugPrint('   - pendingId: ${pendingRef.id}');
    debugPrint('   - reviewer_id: $participantId');
    debugPrint('   - reviewee_id: ${state.reviewerId}');
    debugPrint('   - reviewer_role: participant');
    
    batch.set(pendingRef, pendingData);
  }

  /// Marca participante como avaliado no batch
  static void markParticipantReviewedBatch(
    WriteBatch batch,
    String participantId,
    String eventId,
    FirebaseFirestore firestore,
  ) {
    final confirmedRef = firestore
        .collection('Events')
        .doc(eventId)
        .collection('ConfirmedParticipants')
        .doc(participantId);
    
    debugPrint('✅ [Batch] Marcando participante como avaliado');
    debugPrint('   - eventId: $eventId');
    debugPrint('   - participantId: $participantId');
    debugPrint('   - path: Events/$eventId/ConfirmedParticipants/$participantId');
    
    // Usar set com merge para criar/atualizar o documento
    batch.set(confirmedRef, {
      'reviewed': true,
      'reviewed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Marca participante como avaliado (operação separada, não em batch)
  static Future<void> markParticipantReviewedSeparate(
    String participantId,
    String eventId,
    FirebaseFirestore firestore,
  ) async {
    debugPrint('✅ [Separate] Marcando participante como avaliado');
    debugPrint('   - eventId: $eventId');
    debugPrint('   - participantId: $participantId');
    
    final confirmedRef = firestore
        .collection('Events')
        .doc(eventId)
        .collection('ConfirmedParticipants')
        .doc(participantId);
    
    await confirmedRef.set({
      'reviewed': true,
      'reviewed_at': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    
    debugPrint('   ✅ Participante $participantId marcado como avaliado');
  }

  /// Busca e prepara dados do owner para os pending reviews
  static Future<Map<String, String?>> prepareOwnerData(
    String reviewerId,
    FirebaseFirestore firestore,
  ) async {
    debugPrint('👤 [prepareOwnerData] Buscando dados do owner');
    
    final ownerDoc = await firestore.collection('Users').doc(reviewerId).get();
    final ownerData = ownerDoc.data();
    final ownerName = ownerData?['fullName'] as String? ?? 'Organizador';
    final ownerPhotoUrl = ownerData?['photoUrl'] as String?;

    debugPrint('✅ Dados do owner: $ownerName');
    
    return {
      'ownerName': ownerName,
      'ownerPhotoUrl': ownerPhotoUrl,
    };
  }
}
