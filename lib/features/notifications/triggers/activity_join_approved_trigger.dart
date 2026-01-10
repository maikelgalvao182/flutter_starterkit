import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/utils/app_localizations.dart';

/// TRIGGER 3: Dono aprovou entrada na atividade privada
/// 
/// Notificação enviada para: O membro que foi aprovado
/// Remetente: O dono da atividade (createdBy)
/// Mensagem: "Você foi aprovado para participar de {emoji} {activityText}!"
class ActivityJoinApprovedTrigger extends BaseActivityTrigger {
  const ActivityJoinApprovedTrigger({
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

      final approvedUserId = context['approvedUserId'] as String?;

      if (approvedUserId == null) {
        AppLogger.warning(
          'ActivityJoinApprovedTrigger: approvedUserId não fornecido',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      // Buscar dados do owner (quem aprovou)
      final ownerInfo = await getUserInfo(activity.createdBy);

      // Gera mensagem usando template
      final template = NotificationTemplates.activityJoinApproved(
        i18n: i18n,
        activityName: activity.name,
        emoji: activity.emoji,
      );

      // Notifica o usuário aprovado
      final ok = await createNotification(
        receiverId: approvedUserId,
        type: ActivityNotificationTypes.activityJoinApproved,
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
          'ActivityJoinApprovedTrigger: notificação criada',
          tag: 'NOTIFICATIONS',
        );
      }
    } catch (e, stackTrace) {
      AppLogger.error(
        'ActivityJoinApprovedTrigger: erro ao executar',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
