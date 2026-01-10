import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// TRIGGER 2: Solicitação de entrada em atividade privada
/// 
/// Notificação (para o dono): "{fullName} pediu para entrar na sua atividade {emoji} {activityText}."
/// 
/// Exemplo: "Júlia pediu para entrar na sua atividade 🍕 Pizza e conversa."
class ActivityJoinRequestTrigger extends BaseActivityTrigger {
  const ActivityJoinRequestTrigger({
    required super.notificationRepository,
    required super.firestore,
  });

  @override
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  ) async {
    try {
      final i18n = await AppLocalizations.loadForLanguageCode(AppLocalizations.currentLocale);

      final requesterId = context['requesterId'] as String?;
      final requesterName = context['requesterName'] as String?;
      
      if (requesterId == null || requesterName == null) {
        AppLogger.warning(
          'ActivityJoinRequestTrigger: dados incompletos no context',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Busca owner da atividade
      final ownerId = await _getActivityOwner(activity.id);
      
      if (ownerId == null) {
        AppLogger.warning(
          'ActivityJoinRequestTrigger: owner não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Busca dados do solicitante
      final requesterInfo = await getUserInfo(requesterId);

      // Gera mensagem usando template
      final template = NotificationTemplates.activityJoinRequest(
        i18n: i18n,
        requesterName: requesterInfo['fullName'] ?? i18n.translate('someone'),
        activityName: activity.name,
        emoji: activity.emoji,
      );

      // Notifica apenas o dono
      final ok = await createNotification(
        receiverId: ownerId,
        type: ActivityNotificationTypes.activityJoinRequest,
        params: {
          'title': template.title,
          'body': template.body,
          'preview': template.preview,
          ...template.extra,
        },
        senderId: requesterId,
        senderName: requesterInfo['fullName'],
        senderPhotoUrl: requesterInfo['photoUrl'],
        relatedId: activity.id,
      );

      if (ok) {
        AppLogger.success(
          'ActivityJoinRequestTrigger: notificação criada',
          tag: 'NOTIFICATIONS',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityJoinRequestTrigger: erro ao executar',
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

      if (!activityDoc.exists) return null;

      return activityDoc.data()?['createdBy'] as String?;
    } catch (e) {
      AppLogger.error(
        'ActivityJoinRequestTrigger: erro ao buscar owner',
        tag: 'NOTIFICATIONS',
        error: e,
      );
      return null;
    }
  }
}
