import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:partiu/core/utils/app_logger.dart';
import 'package:partiu/features/notifications/repositories/notifications_repository_interface.dart';

/// Implementação do repositório de notificações com acesso direto ao Firestore
class NotificationsRepository implements INotificationsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Constantes de coleções e campos do Firestore
  static const String _collectionNotifications = 'Notifications';
  static const String _fieldReceiverId = 'n_receiver_id'; // Campo padrão do sistema
  static const String _fieldSenderId = 'n_sender_id';
  static const String _fieldSenderFullname = 'n_sender_fullname';
  static const String _fieldSenderPhotoLink = 'n_sender_photo_link';
  static const String _fieldType = 'n_type';
  static const String _fieldRead = 'n_read';
  static const String _fieldTimestamp = 'timestamp';
  static const String _fieldParams = 'n_params';

  /// Get current user ID
  String? get _currentUserId => _auth.currentUser?.uid;

  /// Get notifications collection reference (root collection)
  CollectionReference<Map<String, dynamic>> get _notificationsCollection {
    return _firestore.collection(_collectionNotifications);
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotifications({String? filterKey}) {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        return const Stream.empty();
      }

      // Query na coleção raiz filtrando por userId
      Query<Map<String, dynamic>> query = _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId);

      // Apply filter if provided
      if (filterKey != null && filterKey.isNotEmpty) {
        // Para filtro "activity", buscar todos os tipos activity_*
        if (filterKey == 'activity') {
          query = query.where(_fieldType, whereIn: [
            'activity_created',
            'activity_join_request',
            'activity_join_approved',
            'activity_join_rejected',
            'activity_new_participant',
            'activity_heating_up',
            'activity_expiring_soon',
            'activity_canceled',
          ]);
        } else if (filterKey == 'reviews') {
          query = query.where(_fieldType, whereIn: [
            'review_pending',
            'new_review_received',
          ]);
        } else {
          query = query.where(_fieldType, isEqualTo: filterKey);
        }
      }

      // Try with orderBy, fallback without if index not ready
      return query.orderBy(_fieldTimestamp, descending: true).snapshots().handleError((error) {
        if (error is FirebaseException &&
            (error.code == 'failed-precondition' || (error.message?.contains('index') == true))) {
          print('[NOTIFICATIONS] Fallback sem orderBy (índice em construção): ${error.message}');
          return query.snapshots();
        } else {
          print('[NOTIFICATIONS] Fallback genérico: $error');
          return query.snapshots();
        }
      });
    } catch (e) {
      print('[NOTIFICATIONS] Error in getNotifications: $e');
      return const Stream.empty();
    }
  }

  @override
  Future<QuerySnapshot<Map<String, dynamic>>> getNotificationsPaginated({
    int limit = 20,
    DocumentSnapshot? lastDocument,
    String? filterKey,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        throw Exception('User not authenticated');
      }

      // Query na coleção raiz filtrando por userId
      Query<Map<String, dynamic>> query = _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId);

      // Apply filter if provided
      if (filterKey != null && filterKey.isNotEmpty) {
        // Para filtro "activity", buscar todos os tipos activity_*
        if (filterKey == 'activity') {
          query = query.where(_fieldType, whereIn: [
            'activity_created',
            'activity_join_request',
            'activity_join_approved',
            'activity_join_rejected',
            'activity_new_participant',
            'activity_heating_up',
            'activity_expiring_soon',
            'activity_canceled',
          ]);
        } else if (filterKey == 'reviews') {
          query = query.where(_fieldType, whereIn: [
            'review_pending',
            'new_review_received',
          ]);
        } else {
          query = query.where(_fieldType, isEqualTo: filterKey);
        }
      }

      // Pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      query = query.limit(limit);

      // Try with orderBy
      QuerySnapshot<Map<String, dynamic>> result;
      try {
        final queryWithOrder = query.orderBy(_fieldTimestamp, descending: true);
        result = await queryWithOrder.get();
      } on FirebaseException catch (e) {
        if (e.code == 'failed-precondition' || (e.message?.contains('index') == true)) {
          print('[NOTIFICATIONS] Fallback sem orderBy na paginação: ${e.message}');
          result = await query.get();
        } else {
          print('[NOTIFICATIONS] Fallback genérico na paginação: ${e.message}');
          result = await query.get();
        }
      }

      return result;
    } catch (e) {
      print('[NOTIFICATIONS] Error in getNotificationsPaginated: $e');
      rethrow;
    }
  }

  @override
  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsPaginatedStream({
    int limit = 20,
    String? filterKey,
  }) {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        return const Stream.empty();
      }

      Query<Map<String, dynamic>> query = _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId)
          .limit(limit);

      // Apply filter if provided
      if (filterKey != null && filterKey.isNotEmpty) {
        query = query.where(_fieldType, isEqualTo: filterKey);
      }

      // Try with orderBy, fallback without if index not ready
      return query.orderBy(_fieldTimestamp, descending: true).snapshots().handleError((error) {
        if (error is FirebaseException &&
            (error.code == 'failed-precondition' || (error.message?.contains('index') == true))) {
          print('[NOTIFICATIONS] Stream fallback sem orderBy: ${error.message}');
          return query.snapshots();
        } else {
          print('[NOTIFICATIONS] Stream fallback genérico: $error');
          return query.snapshots();
        }
      });
    } catch (e) {
      print('[NOTIFICATIONS] Error in getNotificationsPaginatedStream: $e');
      return const Stream.empty();
    }
  }

  @override
  Future<void> saveNotification({
    required String nReceiverId,
    required String nType,
    required String nMessage,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        print('[NOTIFICATIONS] Tentativa de salvar notificação sem usuário logado');
        return;
      }

      final notificationData = <String, dynamic>{
        _fieldReceiverId: nReceiverId, // Campo padrão
        'userId': nReceiverId,          // Campo duplicado para compatibilidade
        _fieldSenderId: currentUser.uid,
        _fieldSenderFullname: currentUser.displayName ?? 'Unknown',
        // ✅ NUNCA usar FirebaseAuth.photoURL (avatar do Google)
        // Deixar vazio - o StableAvatar vai buscar no UserStore/Firestore
        _fieldSenderPhotoLink: '',
        _fieldType: nType,
        _fieldRead: false,
        _fieldTimestamp: FieldValue.serverTimestamp(),
        _fieldParams: {'message': nMessage},
      };

      // Save to root collection
      await _notificationsCollection.add(notificationData);
    } catch (e) {
      print('[NOTIFICATIONS] Error saving notification: $e');
    }
  }

  @override
  Future<void> onPurchaseNotification({
    required String nMessage,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        print('[NOTIFICATIONS] Tentativa de notificação de compra sem usuário logado');
        return;
      }

      await saveNotification(
        nReceiverId: userId,
        nType: 'alert',
        nMessage: nMessage,
      );
    } catch (e) {
      print('[NOTIFICATIONS] Error in onPurchaseNotification: $e');
    }
  }

  @override
  Future<void> deleteUserNotifications() async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        print('[NOTIFICATIONS] Tentativa de deletar notificações sem usuário logado');
        return;
      }

      final snapshot = await _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return;

      // Usar WriteBatch para operações em lote
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting user notifications: $e');
    }
  }

  @override
  Future<void> deleteUserSentNotifications() async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        print('[NOTIFICATIONS] Tentativa de deletar notificações enviadas sem usuário logado');
        return;
      }

      // Buscar todas as notificações onde o usuário é o sender
      final snapshot = await _notificationsCollection
          .where(_fieldSenderId, isEqualTo: userId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting sent notifications: $e');
    }
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    try {
      await _notificationsCollection.doc(notificationId).delete();
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting notification: $e');
      rethrow;
    }
  }

  @override
  Future<void> readNotification(String notificationId) async {
    try {
      await _notificationsCollection
          .doc(notificationId)
          .update({_fieldRead: true});
    } catch (e) {
      // Silencioso - não é crítico
      print('[NOTIFICATIONS] Error marking as read: $e');
    }
  }

  // ===============================================
  // MÉTODOS ESPECÍFICOS PARA ATIVIDADES
  // ===============================================

  @override
  Future<void> createActivityNotification({
    required String receiverId,
    required String type,
    required Map<String, dynamic> params,
    String? senderId,
    String? senderName,
    String? senderPhotoUrl,
    String? relatedId,
  }) async {
    try {
      final currentUser = _auth.currentUser;

      if (currentUser == null) {
        AppLogger.warning(
          'createActivityNotification ignorada: usuário deslogado',
          tag: 'NOTIFICATIONS',
        );
        throw FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Not authenticated',
        );
      }
      
      final actualSenderId = senderId ?? currentUser?.uid;
      final actualSenderName = senderName ?? currentUser?.displayName ?? 'Sistema';
      // ✅ NUNCA usar FirebaseAuth.photoURL (avatar do Google)
      // Se não foi passado senderPhotoUrl, deixar vazio
      final actualSenderPhoto = senderPhotoUrl ?? '';

      final notificationData = <String, dynamic>{
        _fieldReceiverId: receiverId, // Campo padrão
        'userId': receiverId,          // Campo duplicado para compatibilidade
        _fieldSenderId: actualSenderId ?? '',
        _fieldSenderFullname: actualSenderName,
        _fieldSenderPhotoLink: actualSenderPhoto,
        _fieldType: type,
        _fieldRead: false,
        _fieldTimestamp: FieldValue.serverTimestamp(),
        _fieldParams: params,
      };

      // Adiciona relatedId se fornecido (ID da atividade)
      if (relatedId != null) {
        notificationData['n_related_id'] = relatedId;
      }

      // Salva na coleção raiz
      final docRef = await _notificationsCollection.add(notificationData);

      AppLogger.success(
        'Notificação criada (docId=${docRef.id})',
        tag: 'NOTIFICATIONS',
      );
    } catch (e, stackTrace) {
      final isPermissionDenied = e is FirebaseException && e.code == 'permission-denied';

      // Escrita de notificações de atividade deve ser feita via Cloud Function.
      // Silencia graciosamente sem logar (esperado).
      if (isPermissionDenied) {
        return;
      }

      AppLogger.error(
        'Erro ao criar notificação',
        tag: 'NOTIFICATIONS',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  @override
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> fetchNotificationsByActivity({
    required String activityId,
    int limit = 50,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        return [];
      }

      final snapshot = await _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId)
          .where('n_related_id', isEqualTo: activityId)
          .orderBy(_fieldTimestamp, descending: true)
          .limit(limit)
          .get();

      return snapshot.docs;
    } catch (e) {
      print('[NOTIFICATIONS] Error fetching activity notifications: $e');
      return [];
    }
  }

  @override
  Future<void> markAllActivityNotificationsAsRead({
    required String activityId,
  }) async {
    try {
      final userId = _currentUserId;
      if (userId == null || userId.isEmpty) {
        return;
      }

      final snapshot = await _notificationsCollection
          .where(_fieldReceiverId, isEqualTo: userId)
          .where('n_related_id', isEqualTo: activityId)
          .where(_fieldRead, isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(doc.reference, {_fieldRead: true});
      }

      await batch.commit();
      print('[NOTIFICATIONS] Marked ${snapshot.docs.length} activity notifications as read');
    } catch (e) {
      print('[NOTIFICATIONS] Error marking activity notifications as read: $e');
    }
  }

  @override
  Future<void> deleteActivityNotifications({
    required String activityId,
  }) async {
    try {
      final snapshot = await _notificationsCollection
          .where('n_related_id', isEqualTo: activityId)
          .get();

      if (snapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      print('[NOTIFICATIONS] Deleted ${snapshot.docs.length} activity notifications');
    } catch (e) {
      print('[NOTIFICATIONS] Error deleting activity notifications: $e');
    }
  }
}
