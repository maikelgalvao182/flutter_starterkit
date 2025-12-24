import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/features/home/domain/models/activity_model.dart';
import 'package:partiu/features/notifications/repositories/notifications_repository_interface.dart';
import 'package:partiu/core/utils/app_logger.dart';

/// Interface base para triggers de notificação de atividades
/// 
/// Padrão Strategy: cada trigger implementa lógica específica
/// de quando e para quem disparar notificações.
abstract class BaseActivityTrigger {
  const BaseActivityTrigger({
    required this.notificationRepository,
    required this.firestore,
  });

  final INotificationsRepository notificationRepository;
  final FirebaseFirestore firestore;

  /// Executa o trigger
  /// 
  /// @param activity - Modelo da atividade que disparou o evento
  /// @param context - Dados contextuais do evento (ex: requesterId, currentCount)
  Future<void> execute(
    ActivityModel activity,
    Map<String, dynamic> context,
  );

  /// Helper: Obtém dados do usuário (nome + foto)
  Future<Map<String, String>> getUserInfo(String userId) async {
    try {
      final userDoc = await firestore.collection('Users').doc(userId).get();
      if (!userDoc.exists) {
        AppLogger.warning(
          'getUserInfo: usuário não encontrado',
          tag: 'NOTIFICATIONS',
        );
        return {'fullName': 'Usuário', 'photoUrl': ''};
      }

      final data = userDoc.data()!;
      
      // Nome do usuário - campo oficial do Firestore Users
      final fullName = data['fullName'] as String? ?? 'Usuário';
      
      // Foto do usuário - campo oficial do Firestore Users
      // ⚠️ IMPORTANTE: Filtrar URLs do Google OAuth (lh3.googleusercontent.com)
      // Essas URLs são do login social e não devem ser usadas como avatar
      var rawPhotoUrl = data['photoUrl'] as String? ?? '';
      
      // Ignorar URL se for do Google OAuth (dados legados)
      if (rawPhotoUrl.contains('googleusercontent.com') || 
          rawPhotoUrl.contains('lh3.google')) {
        AppLogger.info(
          'getUserInfo: photoUrl do Google OAuth ignorada',
          tag: 'NOTIFICATIONS',
        );
        rawPhotoUrl = '';
      }
      
      final result = {
        'fullName': fullName,
        'photoUrl': rawPhotoUrl,
      };
      
      return result;
    } catch (e, stackTrace) {
      AppLogger.error(
        'getUserInfo: erro ao buscar dados do usuário',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
      return {'fullName': 'Usuário', 'photoUrl': ''};
    }
  }

  /// Helper: Cria notificação padronizada
  Future<bool> createNotification({
    required String receiverId,
    required String type,
    required Map<String, dynamic> params,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? relatedId,
  }) async {
    try {
      await notificationRepository.createActivityNotification(
        receiverId: receiverId,
        type: type,
        params: params,
        senderId: senderId,
        senderName: senderName,
        senderPhotoUrl: senderPhotoUrl,
        relatedId: relatedId,
      );
      return true;
    } catch (e, stackTrace) {
      final isPermissionDenied = e is FirebaseException && e.code == 'permission-denied';

      // permission-denied é esperado quando client tenta escrever notificações
      // (deve ser feito via Cloud Function). Retorna silenciosamente.
      if (isPermissionDenied) {
        return false;
      }

      AppLogger.error(
        'Erro ao criar notificação',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
      return false;
    }
  }
}
