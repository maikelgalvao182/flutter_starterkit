import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo de perfil de participante (usado no PendingReview do owner)
class ParticipantProfile {
  final String name;
  final String? photoUrl;

  const ParticipantProfile({
    required this.name,
    this.photoUrl,
  });

  factory ParticipantProfile.fromMap(Map<String, dynamic> map) {
    return ParticipantProfile(
      name: map['name'] as String? ?? '',
      photoUrl: map['photo'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'photo': photoUrl,
      };
}

/// Modelo de review pendente (aguardando avaliação)
class PendingReviewModel {
  final String pendingReviewId;
  final String eventId;
  final String applicationId;
  final String reviewerId;
  final String revieweeId;
  final String reviewerRole; // 'owner' | 'participant'
  final String eventTitle;
  final String eventEmoji;
  final String? eventLocation;
  final DateTime eventDate;
  final DateTime createdAt;
  final DateTime expiresAt;
  final bool dismissed;
  final String revieweeName;
  final String? revieweePhotoUrl;

  // Campos específicos do OWNER
  final bool? presenceConfirmed; // null para participant
  final List<String>? participantIds; // null para participant
  final List<String>? confirmedParticipantIds; // null para participant
  final Map<String, ParticipantProfile>? participantProfiles; // null para participant

  // Campos específicos do PARTICIPANT
  final bool? allowedToReviewOwner; // null para owner

  const PendingReviewModel({
    required this.pendingReviewId,
    required this.eventId,
    required this.applicationId,
    required this.reviewerId,
    required this.revieweeId,
    required this.reviewerRole,
    required this.eventTitle,
    required this.eventEmoji,
    this.eventLocation,
    required this.eventDate,
    required this.createdAt,
    required this.expiresAt,
    this.dismissed = false,
    required this.revieweeName,
    this.revieweePhotoUrl,
    // Owner fields
    this.presenceConfirmed,
    this.participantIds,
    this.confirmedParticipantIds,
    this.participantProfiles,
    // Participant fields
    this.allowedToReviewOwner,
  });

  /// Cria instância a partir de documento Firestore
  factory PendingReviewModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse participant profiles
    Map<String, ParticipantProfile>? profiles;
    if (data['participant_profiles'] != null) {
      final profilesData = data['participant_profiles'] as Map<String, dynamic>;
      profiles = profilesData.map(
        (key, value) => MapEntry(
          key,
          ParticipantProfile.fromMap(value as Map<String, dynamic>),
        ),
      );
    }

    return PendingReviewModel(
      pendingReviewId: doc.id,
      eventId: data['event_id'] as String,
      applicationId: data['application_id'] as String? ?? '',
      reviewerId: data['reviewer_id'] as String,
      revieweeId: data['reviewee_id'] as String? ?? '',
      reviewerRole: data['reviewer_role'] as String,
      eventTitle: data['event_title'] as String,
      eventEmoji: data['event_emoji'] as String? ?? '🎉',
      eventLocation: data['event_location'] as String?,
      eventDate: (data['event_date'] as Timestamp).toDate(),
      createdAt: (data['created_at'] as Timestamp).toDate(),
      expiresAt: (data['expires_at'] as Timestamp).toDate(),
      dismissed: data['dismissed'] as bool? ?? false,
      revieweeName: data['reviewee_name'] as String? ?? '',
      revieweePhotoUrl: data['reviewee_photo_url'] as String?,
      // Owner fields
      presenceConfirmed: data['presence_confirmed'] as bool?,
      participantIds: (data['participant_ids'] as List<dynamic>?)?.cast<String>(),
      confirmedParticipantIds: (data['confirmed_participant_ids'] as List<dynamic>?)?.cast<String>(),
      participantProfiles: profiles,
      // Participant fields
      allowedToReviewOwner: data['allowed_to_review_owner'] as bool?,
    );
  }

  /// Converte para Map para salvar no Firestore
  Map<String, dynamic> toFirestore() {
    final map = <String, dynamic>{
      'pending_review_id': pendingReviewId,
      'event_id': eventId,
      'application_id': applicationId,
      'reviewer_id': reviewerId,
      'reviewee_id': revieweeId,
      'reviewer_role': reviewerRole,
      'event_title': eventTitle,
      'event_emoji': eventEmoji,
      if (eventLocation != null) 'event_location': eventLocation,
      'event_date': Timestamp.fromDate(eventDate),
      'created_at': Timestamp.fromDate(createdAt),
      'expires_at': Timestamp.fromDate(expiresAt),
      'dismissed': dismissed,
      'reviewee_name': revieweeName,
      if (revieweePhotoUrl != null) 'reviewee_photo_url': revieweePhotoUrl,
    };

    // Owner fields
    if (presenceConfirmed != null) {
      map['presence_confirmed'] = presenceConfirmed;
    }
    if (participantIds != null) {
      map['participant_ids'] = participantIds;
    }
    if (confirmedParticipantIds != null) {
      map['confirmed_participant_ids'] = confirmedParticipantIds;
    }
    if (participantProfiles != null) {
      map['participant_profiles'] = participantProfiles!.map(
        (key, value) => MapEntry(key, value.toMap()),
      );
    }

    // Participant fields
    if (allowedToReviewOwner != null) {
      map['allowed_to_review_owner'] = allowedToReviewOwner;
    }

    return map;
  }

  /// Verifica se o pending review expirou
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Dias restantes para avaliar
  int get daysRemaining {
    final diff = expiresAt.difference(DateTime.now());
    return diff.inDays;
  }

  /// Verifica se é owner avaliando participante
  bool get isOwnerReview => reviewerRole == 'owner';

  /// Verifica se é participante avaliando owner
  bool get isParticipantReview => reviewerRole == 'participant';

  /// Verifica se owner precisa confirmar presença (STEP 0)
  bool get needsPresenceConfirmation =>
      isOwnerReview &&
      presenceConfirmed == false &&
      (participantIds?.isNotEmpty ?? false);

  /// Verifica se participante tem permissão para avaliar
  bool get canReviewOwner =>
      isParticipantReview && (allowedToReviewOwner ?? false);

  PendingReviewModel copyWith({
    String? pendingReviewId,
    String? eventId,
    String? applicationId,
    String? reviewerId,
    String? revieweeId,
    String? reviewerRole,
    String? eventTitle,
    String? eventEmoji,
    String? eventLocation,
    DateTime? eventDate,
    DateTime? createdAt,
    DateTime? expiresAt,
    bool? dismissed,
    String? revieweeName,
    String? revieweePhotoUrl,
    bool? presenceConfirmed,
    List<String>? participantIds,
    List<String>? confirmedParticipantIds,
    Map<String, ParticipantProfile>? participantProfiles,
    bool? allowedToReviewOwner,
  }) {
    return PendingReviewModel(
      pendingReviewId: pendingReviewId ?? this.pendingReviewId,
      eventId: eventId ?? this.eventId,
      applicationId: applicationId ?? this.applicationId,
      reviewerId: reviewerId ?? this.reviewerId,
      revieweeId: revieweeId ?? this.revieweeId,
      reviewerRole: reviewerRole ?? this.reviewerRole,
      eventTitle: eventTitle ?? this.eventTitle,
      eventEmoji: eventEmoji ?? this.eventEmoji,
      eventLocation: eventLocation ?? this.eventLocation,
      eventDate: eventDate ?? this.eventDate,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      dismissed: dismissed ?? this.dismissed,
      revieweeName: revieweeName ?? this.revieweeName,
      revieweePhotoUrl: revieweePhotoUrl ?? this.revieweePhotoUrl,
      presenceConfirmed: presenceConfirmed ?? this.presenceConfirmed,
      participantIds: participantIds ?? this.participantIds,
      confirmedParticipantIds: confirmedParticipantIds ?? this.confirmedParticipantIds,
      participantProfiles: participantProfiles ?? this.participantProfiles,
      allowedToReviewOwner: allowedToReviewOwner ?? this.allowedToReviewOwner,
    );
  }
}
