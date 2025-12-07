import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/repositories/notifications_repository_interface.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';

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
    print('⏰ [ActivityExpiringSoonTrigger.execute] INICIANDO');
    print('⏰ [ActivityExpiringSoonTrigger.execute] Activity: ${activity.id} - ${activity.name} ${activity.emoji}');
    print('⏰ [ActivityExpiringSoonTrigger.execute] Context: $context');
    
    try {
      final hoursRemaining = context['hoursRemaining'] as int?;
      print('⏰ [ActivityExpiringSoonTrigger.execute] HoursRemaining: $hoursRemaining');

      if (hoursRemaining == null) {
        print('❌ [ActivityExpiringSoonTrigger.execute] hoursRemaining não fornecido');
        return;
      }

      // Busca participantes da atividade
      print('⏰ [ActivityExpiringSoonTrigger.execute] Buscando participantes da atividade...');
      final participants = await _getActivityParticipants(activity.id);
      print('⏰ [ActivityExpiringSoonTrigger.execute] Participantes encontrados: ${participants.length}');
      
      if (participants.isEmpty) {
        print('⚠️ [ActivityExpiringSoonTrigger.execute] Nenhum participante encontrado');
        return;
      }

      // Gera mensagem usando template
      final template = NotificationTemplates.activityExpiringSoon(
        activityName: activity.name,
        emoji: activity.emoji,
        hoursRemaining: hoursRemaining,
      );

      print('⏰ [ActivityExpiringSoonTrigger.execute] Template gerado: ${template.title}');

      // Notifica todos os participantes
      print('⏰ [ActivityExpiringSoonTrigger.execute] Enviando notificações para ${participants.length} participantes...');
      for (final participantId in participants) {
        print('⏰ [ActivityExpiringSoonTrigger.execute] Criando notificação para: $participantId');
        await createNotification(
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
        print('✅ [ActivityExpiringSoonTrigger.execute] Notificação criada para: $participantId');
      }

      print('✅ [ActivityExpiringSoonTrigger.execute] CONCLUÍDO - ${participants.length} notificações enviadas');
    } catch (e, stackTrace) {
      print('❌ [ActivityExpiringSoonTrigger.execute] ERRO: $e');
      print('❌ [ActivityExpiringSoonTrigger.execute] StackTrace: $stackTrace');
    }
  }

  /// Busca IDs dos participantes aprovados do evento
  Future<List<String>> _getActivityParticipants(String activityId) async {
    print('⏰ [ActivityExpiringSoonTrigger._getActivityParticipants] Buscando aplicações aprovadas para: $activityId');
    try {
      final querySnapshot = await firestore
          .collection('EventApplications')
          .where('eventId', isEqualTo: activityId)
          .where('status', whereIn: ['approved', 'autoApproved'])
          .get();

      print('⏰ [ActivityExpiringSoonTrigger._getActivityParticipants] Encontradas ${querySnapshot.docs.length} aplicações aprovadas');

      if (querySnapshot.docs.isEmpty) return [];

      final participantIds = querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      print('⏰ [ActivityExpiringSoonTrigger._getActivityParticipants] ParticipantIds: $participantIds');
      return participantIds;
    } catch (e) {
      print('❌ [ActivityExpiringSoonTrigger._getActivityParticipants] Erro ao buscar participantes: $e');
      return [];
    }
  }
}
