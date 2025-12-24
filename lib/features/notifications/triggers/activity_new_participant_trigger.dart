import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// TRIGGER 5: Novo participante entrou em atividade aberta (open)
/// 
/// Notificação (para o dono): "{fullName} entrou na sua atividade {emoji} {activityText}!"
class ActivityNewParticipantTrigger extends BaseActivityTrigger {
  const ActivityNewParticipantTrigger({
    required super.notificationRepository,
    required super.firestore,
  });

  @override
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  ) async {
    try {
      final participantId = context['participantId'] as String?;
      final participantName = context['participantName'] as String?;
      
      if (participantId == null || participantName == null) {
        AppLogger.warning(
          'ActivityNewParticipantTrigger: dados incompletos',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Busca owner da atividade
      final ownerId = await _getActivityOwner(activity.id);
      
      if (ownerId == null || ownerId == participantId) {
        AppLogger.info(
          'ActivityNewParticipantTrigger: owner ausente ou participante é o owner',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      final participantInfo = await getUserInfo(participantId);

      // Gera mensagem usando template
      final template = NotificationTemplates.activityNewParticipant(
        participantName: participantInfo['fullName'] ?? 'Alguém',
        activityName: activity.name,
        emoji: activity.emoji,
      );

      // Notifica apenas o dono
      final ok = await createNotification(
        receiverId: ownerId,
        type: ActivityNotificationTypes.activityNewParticipant,
        params: {
          'title': template.title,
          'body': template.body,
          'preview': template.preview,
          ...template.extra,
        },
        senderId: participantId,
        senderName: participantInfo['fullName'],
        senderPhotoUrl: participantInfo['photoUrl'],
        relatedId: activity.id,
      );

      if (ok) {
        AppLogger.success(
          'ActivityNewParticipantTrigger: notificação criada',
          tag: 'NOTIFICATIONS',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityNewParticipantTrigger: erro ao executar',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  Future<String?> _getActivityOwner(String activityId) async {
    try {
      final activityDoc = await firestore
          .collection('events')
          .doc(activityId)
          .get();

      if (!activityDoc.exists) {
        return null;
      }

      final ownerId = activityDoc.data()?['createdBy'] as String?;
      return ownerId;
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityNewParticipantTrigger: erro ao buscar owner',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
      return null;
    }
  }
}
