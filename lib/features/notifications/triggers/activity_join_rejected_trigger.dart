import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// TRIGGER 4: Dono recusou entrada na atividade privada
/// 
/// Notificação enviada para: O membro que foi rejeitado
/// Remetente: O dono da atividade (createdBy)
/// Mensagem: "{fullName} recusou seu pedido para entrar em {emoji} {activityText}."
class ActivityJoinRejectedTrigger extends BaseActivityTrigger {
  const ActivityJoinRejectedTrigger({
    required super.notificationRepository,
    required super.firestore,
  });

  @override
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  ) async {
    try {
      final rejectedUserId = context['rejectedUserId'] as String?;

      if (rejectedUserId == null) {
        AppLogger.warning(
          'ActivityJoinRejectedTrigger: rejectedUserId não fornecido',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Buscar dados do owner (quem rejeitou)
      final ownerInfo = await getUserInfo(activity.createdBy);

      // Gera mensagem usando template
      final template = NotificationTemplates.activityJoinRejected(
        activityName: activity.name,
        emoji: activity.emoji,
      );

      // Notifica o usuário rejeitado
      final ok = await createNotification(
        receiverId: rejectedUserId,
        type: ActivityNotificationTypes.activityJoinRejected,
        params: {
          'title': template.title,
          'body': template.body,
          'preview': template.preview,
          ...template.extra,
        },
        senderId: activity.createdBy,
        senderName: ownerInfo['fullName'],
        senderPhotoUrl: ownerInfo['photoUrl'],
        relatedId: activity.id,
      );

      if (ok) {
        AppLogger.success(
          'ActivityJoinRejectedTrigger: notificação criada',
          tag: 'NOTIFICATIONS',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityJoinRejectedTrigger: erro ao executar',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
