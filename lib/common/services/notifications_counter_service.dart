import 'package:flutter/foundation.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/features/home/data/repositories/pending_applications_repository.dart';
import 'package:partiu/features/reviews/data/repositories/review_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

/// Serviço centralizado para gerenciar contadores de notificações
/// 
/// Responsabilidades:
/// - Contar aplicações pendentes (Actions Tab)
/// - Contar reviews pendentes (Actions Tab)
/// - Contar mensagens não lidas (Conversations Tab)
/// - Expor streams reativos para badges
class NotificationsCounterService {
  NotificationsCounterService._();
  
  static final NotificationsCounterService instance = NotificationsCounterService._();

  final _pendingApplicationsRepo = PendingApplicationsRepository();
  final _reviewRepository = ReviewRepository();
  final _firestore = FirebaseFirestore.instance;

  // ValueNotifiers para badges reativos
  final pendingActionsCount = ValueNotifier<int>(0);
  final unreadConversationsCount = ValueNotifier<int>(0);
  final unreadNotificationsCount = ValueNotifier<int>(0);

  // StreamSubscriptions para cancelar no logout
  StreamSubscription<List<dynamic>>? _pendingApplicationsSubscription;
  StreamSubscription<List<dynamic>>? _pendingReviewsSubscription;
  StreamSubscription<QuerySnapshot>? _conversationsSubscription;
  StreamSubscription<QuerySnapshot>? _notificationsSubscription;

  // Contadores internos
  int _applicationsCount = 0;
  int _reviewsCount = 0;

  /// Verifica se os listeners estão ativos
  bool get isActive => _notificationsSubscription != null;

  /// Inicializa os listeners de contadores
  void initialize() {
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🚀 [NotificationsCounter] Inicializando serviço...');
    debugPrint('🚀 [NotificationsCounter] AppState.currentUserId: ${AppState.currentUserId}');
    debugPrint('🚀 [NotificationsCounter] AppState.unreadNotifications.value ANTES: ${AppState.unreadNotifications.value}');
    
    // Cancelar listeners anteriores se existirem
    _cancelAllSubscriptions();
    
    _listenToPendingApplications();
    _listenToPendingReviews();
    _listenToUnreadConversations();
    _listenToUnreadNotifications();
    
    debugPrint('🚀 [NotificationsCounter] Serviço inicializado');
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
  }

  /// Cancela todas as subscriptions ativas
  void _cancelAllSubscriptions() {
    _pendingApplicationsSubscription?.cancel();
    _pendingReviewsSubscription?.cancel();
    _conversationsSubscription?.cancel();
    _notificationsSubscription?.cancel();
    
    _pendingApplicationsSubscription = null;
    _pendingReviewsSubscription = null;
    _conversationsSubscription = null;
    _notificationsSubscription = null;
  }

  /// Atualiza o contador total de ações (applications + reviews)
  void _updateActionsCount() {
    final total = _applicationsCount + _reviewsCount;
    pendingActionsCount.value = total;
    debugPrint('📊 [NotificationsCounter] Total ações: $total (applications: $_applicationsCount, reviews: $_reviewsCount)');
  }

  /// Escuta aplicações pendentes (Actions Tab)
  void _listenToPendingApplications() {
    _pendingApplicationsSubscription = _pendingApplicationsRepo.getPendingApplicationsStream().listen(
      (applications) {
        _applicationsCount = applications.length;
        _updateActionsCount();
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar aplicações: $error');
        _applicationsCount = 0;
        _updateActionsCount();
      },
    );
  }

  /// Escuta reviews pendentes (Actions Tab)
  void _listenToPendingReviews() {
    _pendingReviewsSubscription = _reviewRepository.getPendingReviewsStream().listen(
      (reviews) {
        _reviewsCount = reviews.length;
        _updateActionsCount();
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar reviews: $error');
        _reviewsCount = 0;
        _updateActionsCount();
      },
    );
  }

  /// Escuta conversas não lidas (Conversations Tab)
  void _listenToUnreadConversations() {
    final currentUserId = AppState.currentUserId;
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('💬 [NotificationsCounter] _listenToUnreadConversations() CHAMADO!');
    debugPrint('💬 [NotificationsCounter] UserId: $currentUserId');
    
    if (currentUserId == null) {
      debugPrint('⚠️ [NotificationsCounter] Usuário não autenticado - não pode iniciar listener');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    debugPrint('💬 [NotificationsCounter] Criando listener: Connections/$currentUserId/Conversations');
    
    _conversationsSubscription = _firestore
        .collection('Connections')
        .doc(currentUserId)
        .collection('Conversations')
        .snapshots()
        .listen(
      (snapshot) {
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('💬 [NotificationsCounter] 🔥 CONVERSATIONS LISTENER DISPARADO!');
        debugPrint('💬 [NotificationsCounter] Total de conversas: ${snapshot.docs.length}');
        
        int unreadCount = 0;
        
        for (final doc in snapshot.docs) {
          final data = doc.data();
          
          // Verificar se há mensagem não lida usando AMBOS os campos (compatibilidade)
          final hasUnreadMessage = data['has_unread_message'] as bool? ?? false;
          final messageRead = data['message_read'] as bool? ?? true;
          final unreadCountField = data['unread_count'] as int? ?? 0;
          
          // Considera não lida se:
          // 1. has_unread_message == true OU
          // 2. message_read == false OU
          // 3. unread_count > 0
          final hasUnread = hasUnreadMessage || !messageRead || unreadCountField > 0;
          
          // Verificar se a última mensagem não é do usuário atual
          final lastMessageSender = data['last_message_sender'] as String?;
          
          // Se há mensagens não lidas (unread_count > 0), assume que são de outra pessoa
          // Caso contrário, verifica o last_message_sender
          final isFromOther = unreadCountField > 0 || 
                             (lastMessageSender != null && lastMessageSender != currentUserId);
          
          debugPrint('💬 [NotificationsCounter]   - Doc ${doc.id}:');
          debugPrint('💬 [NotificationsCounter]     has_unread_message: $hasUnreadMessage');
          debugPrint('💬 [NotificationsCounter]     message_read: $messageRead');
          debugPrint('💬 [NotificationsCounter]     unread_count: $unreadCountField');
          debugPrint('💬 [NotificationsCounter]     last_message_sender: $lastMessageSender');
          debugPrint('💬 [NotificationsCounter]     isFromOther: $isFromOther');
          debugPrint('💬 [NotificationsCounter]     hasUnread (combinado): $hasUnread');
          debugPrint('💬 [NotificationsCounter]     conta?: ${hasUnread && isFromOther}');
          
          if (hasUnread && isFromOther) {
            unreadCount++;
          }
        }
        
        debugPrint('💬 [NotificationsCounter] Valor ANTES: unreadConversationsCount.value = ${unreadConversationsCount.value}');
        unreadConversationsCount.value = unreadCount;
        AppState.unreadMessages.value = unreadCount; // Atualiza AppState também
        debugPrint('💬 [NotificationsCounter] Valor DEPOIS: unreadConversationsCount.value = ${unreadConversationsCount.value}');
        debugPrint('💬 [NotificationsCounter] ✅ Conversas não lidas: $unreadCount');
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar conversas: $error');
        unreadConversationsCount.value = 0;
      },
    );
  }

  /// Escuta notificações não lidas (Notification Icon)
  void _listenToUnreadNotifications() {
    final currentUserId = AppState.currentUserId;
    
    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('🔥 [NotificationsCounter] _listenToUnreadNotifications() CHAMADO!');
    debugPrint('📊 [NotificationsCounter] Iniciando listener de notificações não lidas');
    debugPrint('🔥 [NotificationsCounter] UserId: $currentUserId');
    
    if (currentUserId == null) {
      debugPrint('⚠️ [NotificationsCounter] Usuário não autenticado - não pode iniciar listener');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      return;
    }

    debugPrint('📊 [NotificationsCounter] Criando query: Notifications.n_receiver_id == $currentUserId && n_read == false');
    debugPrint('📊 [NotificationsCounter] Criando snapshot listener...');
    
    _notificationsSubscription = _firestore
        .collection('Notifications')
        .where('n_receiver_id', isEqualTo: currentUserId)
        .where('n_read', isEqualTo: false)
        .snapshots()
        .listen(
      (snapshot) {
        final count = snapshot.docs.length;
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
        debugPrint('📡 [NotificationsCounter] 🔥 LISTENER DISPARADO!');
        debugPrint('📡 [NotificationsCounter] snapshot.docs.length = $count');
        debugPrint('📡 [NotificationsCounter] Valor ANTES: AppState.unreadNotifications.value = ${AppState.unreadNotifications.value}');
        
        // Atualizar AppState diretamente (padrão Advanced-Dating)
        AppState.unreadNotifications.value = count;
        unreadNotificationsCount.value = count;
        
        debugPrint('📡 [NotificationsCounter] Valor DEPOIS: AppState.unreadNotifications.value = ${AppState.unreadNotifications.value}');
        debugPrint('📡 [NotificationsCounter] ✅ Notificações não lidas atualizadas: $count');
        debugPrint('📡 [NotificationsCounter] Documentos IDs: ${snapshot.docs.map((d) => d.id).take(5).toList()}');
        
        if (snapshot.docs.isNotEmpty) {
          final firstDoc = snapshot.docs.first.data();
          debugPrint('📡 [NotificationsCounter] Primeiro doc campos: ${firstDoc.keys.toList()}');
          debugPrint('📡 [NotificationsCounter] n_receiver_id: ${firstDoc['n_receiver_id']}');
          debugPrint('📡 [NotificationsCounter] n_read: ${firstDoc['n_read']}');
        }
        debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
      },
      onError: (error) {
        debugPrint('❌ [NotificationsCounter] Erro ao contar notificações: $error');
        AppState.unreadNotifications.value = 0;
        unreadNotificationsCount.value = 0;
      },
    );
  }

  /// Limpa os contadores (usar no logout)
  void reset() {
    debugPrint('🗑️ [NotificationsCounter] Resetando serviço...');
    
    // Cancelar todas as subscriptions
    _cancelAllSubscriptions();
    
    // Resetar contadores internos
    _applicationsCount = 0;
    _reviewsCount = 0;
    
    // Atualizar AppState (padrão Advanced-Dating)
    AppState.unreadNotifications.value = 0;
    pendingActionsCount.value = 0;
    unreadConversationsCount.value = 0;
    unreadNotificationsCount.value = 0;
    
    debugPrint('✅ [NotificationsCounter] Contadores resetados e listeners cancelados');
  }

  /// Dispose dos listeners
  void dispose() {
    _cancelAllSubscriptions();
    pendingActionsCount.dispose();
    unreadConversationsCount.dispose();
    unreadNotificationsCount.dispose();
  }
}
