import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/repositories/notifications_repository_interface.dart';
import 'package:partiu/features/notifications/templates/notification_templates.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';

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
    print('🚫 [ActivityCanceledTrigger.execute] INICIANDO');
    print('🚫 [ActivityCanceledTrigger.execute] Activity: ${activity.id} - ${activity.name} ${activity.emoji}');
    
    try {
      // Busca participantes da atividade
      print('🚫 [ActivityCanceledTrigger.execute] Buscando participantes da atividade...');
      final participants = await _getActivityParticipants(activity.id);
      print('🚫 [ActivityCanceledTrigger.execute] Participantes encontrados: ${participants.length}');
      
      if (participants.isEmpty) {
        print('⚠️ [ActivityCanceledTrigger.execute] Nenhum participante encontrado');
        return;
      }

      // Gera mensagem usando template
      final template = NotificationTemplates.activityCanceled(
        activityName: activity.name,
        emoji: activity.emoji,
      );

      print('🚫 [ActivityCanceledTrigger.execute] Template gerado: ${template.title}');

      // Notifica todos os participantes
      print('🚫 [ActivityCanceledTrigger.execute] Enviando notificações para ${participants.length} participantes...');
      for (final participantId in participants) {
        print('🚫 [ActivityCanceledTrigger.execute] Criando notificação para: $participantId');
        await createNotification(
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
        print('✅ [ActivityCanceledTrigger.execute] Notificação criada para: $participantId');
      }

      print('✅ [ActivityCanceledTrigger.execute] CONCLUÍDO - ${participants.length} notificações enviadas');
    } catch (e, stackTrace) {
      print('❌ [ActivityCanceledTrigger.execute] ERRO: $e');
      print('❌ [ActivityCanceledTrigger.execute] StackTrace: $stackTrace');
    }
  }

  /// Busca IDs dos participantes aprovados do evento
  Future<List<String>> _getActivityParticipants(String activityId) async {
    print('🚫 [ActivityCanceledTrigger._getActivityParticipants] Buscando aplicações aprovadas para: $activityId');
    try {
      final querySnapshot = await firestore
          .collection('EventApplications')
          .where('eventId', isEqualTo: activityId)
          .where('status', whereIn: ['approved', 'autoApproved'])
          .get();

      print('🚫 [ActivityCanceledTrigger._getActivityParticipants] Encontradas ${querySnapshot.docs.length} aplicações aprovadas');

      if (querySnapshot.docs.isEmpty) return [];

      final participantIds = querySnapshot.docs
          .map((doc) => doc.data()['userId'] as String)
          .toList();

      print('🚫 [ActivityCanceledTrigger._getActivityParticipants] ParticipantIds: $participantIds');
      return participantIds;
    } catch (e, stackTrace) {
      print('❌ [ActivityCanceledTrigger._getActivityParticipants] ERRO: $e');
      print('❌ [ActivityCanceledTrigger._getActivityParticipants] StackTrace: $stackTrace');
      return [];
    }
  }
}
