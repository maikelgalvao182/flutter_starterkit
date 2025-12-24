import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// TRIGGER 8: Atividade cancelada
/// 
/// Notificação: "A atividade {emoji} {activityText} foi cancelada."
class ActivityCanceledTrigger extends BaseActivityTrigger {
  const ActivityCanceledTrigger({
    required super.notificationRepository,
    required super.firestore,
  });

  @override
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  ) async {
    try {
      // Busca participantes da atividade
      final participants = await _getActivityParticipants(activity.id);
      
      if (participants.isEmpty) {
        AppLogger.info(
          'ActivityCanceledTrigger: nenhum participante encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Gera mensagem usando template
      final template = NotificationTemplates.activityCanceled(
        activityName: activity.name,
        emoji: activity.emoji,
      );

      // Notifica todos os participantes
      AppLogger.info(
        'ActivityCanceledTrigger: enviando para ${participants.length} participantes',
        tag: 'NOTIFICATIONS',
      );
      var sent = 0;
      for (final participantId in participants) {
        final ok = await createNotification(
          receiverId: participantId,
          type: ActivityNotificationTypes.activityCanceled,
          params: {
            'title': template.title,
            'body': template.body,
            'preview': template.preview,
            ...template.extra,
          },
          relatedId: activity.id,
        );
        if (ok) sent++;
      }

      AppLogger.success(
        'ActivityCanceledTrigger concluído: $sent/${participants.length} notificações criadas',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityCanceledTrigger: erro ao executar',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Busca IDs dos participantes aprovados do evento
  Future<List<String>> _getActivityParticipants(String activityId) async {
    try {
      final querySnapshot = await firestore
          .collection('EventApplications')
          .where('eventId', isEqualTo: activityId)
          .where('status', whereIn: ['approved', 'autoApproved'])
          .get();

      if (querySnapshot.docs.isEmpty) return [];

      final participantIds = querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      return participantIds;
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityCanceledTrigger: erro ao buscar participantes',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
      return [];
    }
  }
}
