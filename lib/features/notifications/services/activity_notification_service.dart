import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/core/services/geo_index_service.dart';
import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/models/activity_notification_types.dart';
import 'package:partiu/features/notifications/repositories/notifications_repository_interface.dart';
import 'package:partiu/features/notifications/services/notification_targeting_service.dart';
import 'package:partiu/features/notifications/services/notification_orchestrator.dart';
import 'package:partiu/features/notifications/services/user_affinity_service.dart';
import 'package:partiu/features/notifications/triggers/base_activity_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_created_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_join_request_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_join_approved_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_join_rejected_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_new_participant_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_heating_up_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_expiring_soon_trigger.dart';
import 'package:partiu/features/notifications/triggers/activity_canceled_trigger.dart';

/// Serviço orquestrador de notificações de atividades
/// 
/// Responsável por:
/// - Escutar eventos de atividades (criação, edição, cancelamento)
/// - Delegar para triggers específicos usando padrão Strategy
/// - Buscar usuários no raio de 30km (FREE_ACCOUNT_MAX_EVENT_DISTANCE_KM)
/// - Disparar notificações via NotificationRepository
/// 
/// Arquitetura:
/// ```
/// ActivityNotificationService (Orquestrador)
///         ↓
///   [Triggers Modulares]
///   - ActivityCreatedTrigger
///   - ActivityJoinRequestTrigger
///   - ActivityHeatingUpTrigger
///   - etc...
///         ↓
/// NotificationRepository (Persiste no Firestore)
/// ```
class ActivityNotificationService {
  ActivityNotificationService({
    required INotificationsRepository notificationRepository,
    required NotificationTargetingService targetingService,
    required NotificationOrchestrator orchestrator,
    required GeoIndexService geoIndexService,
    required UserAffinityService affinityService,
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _notificationRepository = notificationRepository,
        _targetingService = targetingService,
        _orchestrator = orchestrator,
        _geoIndexService = geoIndexService,
        _affinityService = affinityService,
        _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance {
    _initializeTriggers();
  }

  final INotificationsRepository _notificationRepository;
  final NotificationTargetingService _targetingService;
  final NotificationOrchestrator _orchestrator;
  final GeoIndexService _geoIndexService;
  final UserAffinityService _affinityService;
  final FirebaseFirestore _firestore;
  // ignore: unused_field
  final FirebaseAuth _auth;

  // Mapa de triggers indexado por tipo
  late final Map<String, BaseActivityTrigger> _triggers;

  /// Inicializa todos os triggers modulares
  void _initializeTriggers() {
    _triggers = {
      ActivityNotificationTypes.activityCreated: ActivityCreatedTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
        targetingService: _targetingService,
        orchestrator: _orchestrator,
      ),
      ActivityNotificationTypes.activityJoinRequest: ActivityJoinRequestTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
      ActivityNotificationTypes.activityJoinApproved: ActivityJoinApprovedTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
      ActivityNotificationTypes.activityJoinRejected: ActivityJoinRejectedTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
      ActivityNotificationTypes.activityNewParticipant: ActivityNewParticipantTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
      ActivityNotificationTypes.activityHeatingUp: ActivityHeatingUpTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
        geoIndexService: _geoIndexService,
        affinityService: _affinityService,
      ),
      ActivityNotificationTypes.activityExpiringSoon: ActivityExpiringSoonTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
      ActivityNotificationTypes.activityCanceled: ActivityCanceledTrigger(
        notificationRepository: _notificationRepository,
        firestore: _firestore,
      ),
    };
  }

  /// Dispara notificação para nova atividade criada
  /// 
  /// Notifica todos os usuários dentro de FREE_ACCOUNT_MAX_EVENT_DISTANCE_KM (30km)
  Future<void> notifyActivityCreated(ActivityModel activity) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityCreated];
      
      if (trigger == null) {
        AppLogger.warning(
          'notifyActivityCreated: trigger não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      AppLogger.info(
        'notifyActivityCreated: executando trigger',
        tag: 'NOTIFICATIONS',
      );
      
      await trigger.execute(activity, {});

      AppLogger.info(
        'notifyActivityCreated: trigger finalizado',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyActivityCreated: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação de pedido de entrada em atividade privada
  /// 
  /// Notifica apenas o dono da atividade
  Future<void> notifyJoinRequest({
    required ActivityModel activity,
    required String requesterId,
    required String requesterName,
  }) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityJoinRequest];
      if (trigger == null) return;

      await trigger.execute(activity, {
        'requesterId': requesterId,
        'requesterName': requesterName,
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyJoinRequest: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação de aprovação de entrada
  /// 
  /// Notifica o usuário que foi aprovado
  Future<void> notifyJoinApproved({
    required ActivityModel activity,
    required String approvedUserId,
  }) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityJoinApproved];
      if (trigger == null) return;

      await trigger.execute(activity, {
        'approvedUserId': approvedUserId,
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyJoinApproved: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação de rejeição de entrada
  /// 
  /// Notifica o usuário que foi rejeitado
  Future<void> notifyJoinRejected({
    required ActivityModel activity,
    required String rejectedUserId,
  }) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityJoinRejected];
      if (trigger == null) return;

      await trigger.execute(activity, {
        'rejectedUserId': rejectedUserId,
      });
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyJoinRejected: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação quando novo participante entra em atividade aberta
  /// 
  /// Notifica todos os participantes existentes (exceto o novo)
  Future<void> notifyNewParticipant({
    required ActivityModel activity,
    required String participantId,
    required String participantName,
  }) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityNewParticipant];
      
      if (trigger == null) {
        AppLogger.warning(
          'notifyNewParticipant: trigger não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      await trigger.execute(activity, {
        'participantId': participantId,
        'participantName': participantName,
      });

      AppLogger.info(
        'notifyNewParticipant: trigger finalizado',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyNewParticipant: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação quando atividade atinge threshold de participantes
  /// 
  /// Thresholds: 3, 5, 10 participantes
  /// Notifica todos os participantes da atividade
  Future<void> notifyActivityHeatingUp({
    required ActivityModel activity,
    required int currentCount,
  }) async {
    try {
      AppLogger.info(
        'notifyActivityHeatingUp: chamado (count=$currentCount)',
        tag: 'NOTIFICATIONS',
      );
      
      // Verifica se atingiu um threshold
      if (!ActivityNotificationTypes.heatingUpThresholds.contains(currentCount)) {
        AppLogger.info(
          'notifyActivityHeatingUp: count não é threshold, ignorando',
          tag: 'NOTIFICATIONS',
        );
        return;
      }
      
      AppLogger.info(
        'notifyActivityHeatingUp: threshold atingido, disparando trigger',
        tag: 'NOTIFICATIONS',
      );

      final trigger = _triggers[ActivityNotificationTypes.activityHeatingUp];
      if (trigger == null) {
        AppLogger.warning(
          'notifyActivityHeatingUp: trigger não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      await trigger.execute(activity, {
        'currentCount': currentCount,
      });

      AppLogger.info(
        'notifyActivityHeatingUp: trigger finalizado',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyActivityHeatingUp: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }

  /// Dispara notificação quando atividade está próxima da expiração
  /// 
  /// Notifica todos os participantes quando faltam X horas
  Future<void> notifyActivityExpiringSoon({
    required ActivityModel activity,
    required int hoursRemaining,
  }) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityExpiringSoon];
      if (trigger == null) return;

      await trigger.execute(activity, {
        'hoursRemaining': hoursRemaining,
      });
    } catch (e) {
      print('[ActivityNotificationService] Erro ao notificar expiração: $e');
    }
  }

  /// Dispara notificação quando atividade é cancelada
  /// 
  /// Notifica todos os participantes
  Future<void> notifyActivityCanceled(ActivityModel activity) async {
    try {
      final trigger = _triggers[ActivityNotificationTypes.activityCanceled];
      
      if (trigger == null) {
        AppLogger.warning(
          'notifyActivityCanceled: trigger não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return;
      }

      await trigger.execute(activity, {});

      AppLogger.info(
        'notifyActivityCanceled: trigger finalizado',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'notifyActivityCanceled: erro ao executar trigger',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
    }
  }
}
