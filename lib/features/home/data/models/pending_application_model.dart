import 'package:cloud_firestore/cloud_firestore.dart';

/// Modelo para aplicação pendente com dados do usuário e evento
class PendingApplicationModel {
  final String applicationId;
  final String eventId;
  final String userId;
  final String userFullName;
  final String? userPhotoUrl;
  final String activityText;
  final String eventEmoji;
  final DateTime appliedAt;

  const PendingApplicationModel({
    required this.applicationId,
    required this.eventId,
    required this.userId,
    required this.userFullName,
    this.userPhotoUrl,
    required this.activityText,
    required this.eventEmoji,
    required this.appliedAt,
  });

  /// Cria instância com dados combinados de application + user + event
  factory PendingApplicationModel.fromCombined({
    required String applicationId,
    required Map<String, dynamic> applicationData,
    required Map<String, dynamic> userData,
    required Map<String, dynamic> eventData,
  }) {
    return PendingApplicationModel(
      applicationId: applicationId,
      eventId: applicationData['eventId'] as String,
      userId: applicationData['userId'] as String,
      userFullName: userData['fullName'] as String? ?? 'Usuário',
      userPhotoUrl: userData['photoUrl'] as String?,
      activityText: eventData['activityText'] as String? ?? 'um evento',
      eventEmoji: eventData['emoji'] as String? ?? '🎉',
      appliedAt: (applicationData['appliedAt'] as Timestamp).toDate(),
    );
  }

  /// Retorna tempo relativo formatado (ex: "há 5 minutos")
  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(appliedAt);

    if (difference.inMinutes < 1) {
      return 'agora';
    } else if (difference.inMinutes < 60) {
      return 'há ${difference.inMinutes}min';
    } else if (difference.inHours < 24) {
      return 'há ${difference.inHours}h';
    } else if (difference.inDays < 7) {
      return 'há ${difference.inDays}d';
    } else {
      return 'há ${(difference.inDays / 7).floor()}sem';
    }
  }
}
