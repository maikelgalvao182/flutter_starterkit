import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// TRIGGER 7: Atividade quase expirando
/// 
/// Notificação: "A atividade {emoji} {activityText} está quase acabando. Última chance!"
class ActivityExpiringSoonTrigger extends BaseActivityTrigger {
  const ActivityExpiringSoonTrigger({
    required super.notificationRepository,
    required super.firestore,
  });

  @override
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  ) async {
    try {
      final hoursRemaining = context['hoursRemaining'] as int?;

      if (hoursRemaining == null) {
        AppLogger.warning(
          'ActivityExpiringSoonTrigger: hoursRemaining não fornecido',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Busca participantes da atividade
      final participants = await _getActivityParticipants(activity.id);
      
      if (participants.isEmpty) {
        AppLogger.info(
          'ActivityExpiringSoonTrigger: nenhum participante encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Gera mensagem usando template
      final template = NotificationTemplates.activityExpiringSoon(
        activityName: activity.name,
        emoji: activity.emoji,
        hoursRemaining: hoursRemaining,
      );

      // Notifica todos os participantes
      AppLogger.info(
        'ActivityExpiringSoonTrigger: enviando para ${participants.length} participantes',
        tag: 'NOTIFICATIONS',
      );
      var sent = 0;
      for (final participantId in participants) {
        final ok = await createNotification(
          receiverId: participantId,
          type: ActivityNotificationTypes.activityExpiringSoon,
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
        'ActivityExpiringSoonTrigger concluído: $sent/${participants.length} notificações criadas',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityExpiringSoonTrigger: erro ao executar',
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
    } catch (e) {
      AppLogger.error(
        'ActivityExpiringSoonTrigger: erro ao buscar participantes',
        tag: 'NOTIFICATIONS',
        error: e,
      );
      return [];
    }
  }
}
