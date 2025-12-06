import 'package:flutter/foundation.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/features/home/data/repositories/pending_applications_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Serviço centralizado para gerenciar contadores de notificações
/// 
/// Responsabilidades:
/// - Contar aplicações pendentes (Actions Tab)
/// - Contar mensagens não lidas (Conversations Tab)
/// - Expor streams reativos para badges
class NotificationsCounterService {
  NotificationsCounterService._();
  
  static final NotificationsCounterService instance = NotificationsCounterService._();

  final _pendingApplicationsRepo = PendingApplicationsRepository();
  final _firestore = FirebaseFirestore.instance;

  // ValueNotifiers para badges reativos
  final pendingActionsCount = ValueNotifier<int>(0);
  final unreadConversationsCount = ValueNotifier<int>(0);

  /// Inicializa os listeners de contadores
  void initialize() {
    _listenToPendingApplications();
    _listenToUnreadConversations();
  }

  /// Escuta aplicações pendentes (Actions Tab)
  void _listenToPendingApplications() {
    _pendingApplicationsRepo.getPendingApplicationsStream().listen(
      (applications) {
        pendingActionsCount.value = applications.length;
        debugPrint('📊 [NotificationsCounter] Ações pendentes: ${applications.length}');
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar ações: $error');
        pendingActionsCount.value = 0;
      },
    );
  }

  /// Escuta conversas não lidas (Conversations Tab)
  void _listenToUnreadConversations() {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) {
      debugPrint('⚠️ [NotificationsCounter] Usuário não autenticado');
      return;
    }

    _firestore
        .collection('Connections')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen(
      (snapshot) {
        int unreadCount = 0;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          
          // Verificar se há mensagem não lida
          final hasUnread = data['has_unread_message'] as bool? ?? false;
          
          // Verificar se a última mensagem não é do usuário atual
          final lastMessageSender = data['last_message_sender'] as String?;
          final isFromOther = lastMessageSender != null && lastMessageSender != currentUserId;
          
          if (hasUnread && isFromOther) {
            unreadCount++;
          }
        }
        
        unreadConversationsCount.value = unreadCount;
        AppState.unreadMessages.value = unreadCount; // Atualiza AppState também
        
        debugPrint('📊 [NotificationsCounter] Conversas não lidas: $unreadCount');
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar conversas: $error');
        unreadConversationsCount.value = 0;
      },
    );
  }

  /// Limpa os contadores (usar no logout)
  void reset() {
    pendingActionsCount.value = 0;
    unreadConversationsCount.value = 0;
    debugPrint('🗑️ [NotificationsCounter] Contadores resetados');
  }

  /// Dispose dos listeners
  void dispose() {
    pendingActionsCount.dispose();
    unreadConversationsCount.dispose();
  }
}
