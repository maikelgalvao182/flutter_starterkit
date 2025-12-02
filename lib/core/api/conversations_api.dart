import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/constants.dart';

/// API de conversas (limpa, sem código legado).
class ConversationsApi {
  // Singleton pattern
  static final ConversationsApi _instance = ConversationsApi._internal();
  factory ConversationsApi() {
    return _instance;
  }
  ConversationsApi._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cache for stream removed to ensure replay on new subscriptions
  // Stream<QuerySnapshot<Map<String, dynamic>>>? _cachedStream;
  // Stream<QuerySnapshot<Map<String, dynamic>>>? get cachedStream => _cachedStream;

  Future<void> saveConversation({
    required String type,
    required String senderId,
    required String receiverId,
    required String userPhotoLink,
    required String userFullName,
    required String textMsg,
    required bool isRead,
  }) async {
    final batch = _firestore.batch();
    
    // 1️⃣ Documento do SENDER (quem enviou)
    // Mostra dados do RECEIVER (com quem está conversando)
    final senderDoc = _firestore
        .collection(C_CONNECTIONS)
        .doc(senderId)
        .collection(C_CONVERSATIONS)
        .doc(receiverId);
    
    batch.set(senderDoc, <String, dynamic>{
      USER_ID: receiverId,
      USER_PROFILE_PHOTO: userPhotoLink, // foto do receiver
      USER_FULLNAME: userFullName,       // nome do receiver
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: true, // Sender sempre vê como lido (enviou ele mesmo)
      TIMESTAMP: FieldValue.serverTimestamp(),
    });
    
    // 2️⃣ Documento do RECEIVER (quem vai receber)
    // Mostra dados do SENDER (quem enviou)
    // Mas precisamos buscar os dados do sender!
    final senderData = await _firestore
        .collection('Users')
        .doc(senderId)
        .get();
    
    final senderPhotoUrl = senderData.data()?['user_profile_photo'] ?? '';
    final senderFullName = senderData.data()?['user_fullname'] ?? '';
    
    final receiverDoc = _firestore
        .collection(C_CONNECTIONS)
        .doc(receiverId)
        .collection(C_CONVERSATIONS)
        .doc(senderId);
    
    batch.set(receiverDoc, <String, dynamic>{
      USER_ID: senderId,
      USER_PROFILE_PHOTO: senderPhotoUrl, // foto do sender
      USER_FULLNAME: senderFullName,      // nome do sender
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: isRead, // false para receiver (nova mensagem não lida)
      TIMESTAMP: FieldValue.serverTimestamp(),
    });
    
    await batch.commit();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConversations() {
    final uid = AppState.currentUserId;
    if (uid == null || uid.isEmpty) return const Stream.empty();
    return _firestore
        .collection(C_CONNECTIONS)
        .doc(uid)
        .collection(C_CONVERSATIONS)
        .orderBy(TIMESTAMP, descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getConversationsFirstPage({int limit = 20}) {
    // REMOVIDO CACHE DE STREAM: Streams broadcast do Dart não fazem replay de eventos passados.
    // Ao retornar uma nova stream do Firestore, garantimos que o listener receba
    // o estado atual imediatamente.
    
    final uid = AppState.currentUserId;
    if (uid == null || uid.isEmpty) {
      print("⚠️ [ConversationService] UID vazio, retornando stream vazia");
      return const Stream.empty();
    }
    
    print("🔥 [ConversationService] Criando nova stream para UID: $uid");
    
    return _firestore
        .collection(C_CONNECTIONS)
        .doc(uid)
        .collection(C_CONVERSATIONS)
        .orderBy(TIMESTAMP, descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          print("📥 [ConversationService] snapshot received: ${snapshot.docs.length} docs, fromCache=${snapshot.metadata.isFromCache}");
          return snapshot;
        });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchConversationsPage({
    required DocumentSnapshot<Map<String, dynamic>> startAfter,
    int limit = 20,
  }) async {
    // TEMPORÁRIO: Performance Monitoring desabilitado
    // await _perfService.startTrace(PerformanceTraces.loadConversationPage);
    
    try {
      final uid = AppState.currentUserId;
      if (uid == null || uid.isEmpty) {
        // _perfService.setAttribute(PerformanceTraces.loadConversationPage, 'error', 'no_user_id');
        // await _perfService.stopTrace(PerformanceTraces.loadConversationPage);
        return _firestore.collection(C_CONNECTIONS).where('noop', isEqualTo: 'noop').limit(0).get();
      }
      
      // _perfService.setAttribute(PerformanceTraces.loadConversationPage, 'limit', limit.toString());
      
      final result = await _firestore
          .collection(C_CONNECTIONS)
          .doc(uid)
          .collection(C_CONVERSATIONS)
          .orderBy(TIMESTAMP, descending: true)
          .startAfterDocument(startAfter)
          .limit(limit)
          .get();
      
      // _perfService.incrementMetric(PerformanceTraces.loadConversationPage, 'docs_fetched', result.docs.length);
      // await _perfService.stopTrace(PerformanceTraces.loadConversationPage);
      
      return result;
    } catch (e) {
      // _perfService.setAttribute(PerformanceTraces.loadConversationPage, 'error', e.toString());
      // await _perfService.stopTrace(PerformanceTraces.loadConversationPage);
      rethrow;
    }
  }

  Future<void> deleteConversation(String withUserId) async {
    final uid = AppState.currentUserId;
    if (uid == null || uid.isEmpty) return;
    await _firestore
        .collection(C_CONNECTIONS)
        .doc(uid)
        .collection(C_CONVERSATIONS)
        .doc(withUserId)
        .delete();
  }

  /// Exclui documentos de conversa dos dois usuários (atual e alvo) de forma segura.
  /// Não apaga mensagens (isso é responsabilidade de MessagesApi).
  Future<void> deleteConversationForBothSides(String withUserId) async {
    final uid = AppState.currentUserId;
    if (uid == null || uid.isEmpty) return;

    final batch = _firestore.batch();

    final myDoc = _firestore
        .collection(C_CONNECTIONS)
        .doc(uid)
        .collection(C_CONVERSATIONS)
        .doc(withUserId);
    batch.delete(myDoc);

    final otherDoc = _firestore
        .collection(C_CONNECTIONS)
        .doc(withUserId)
        .collection(C_CONVERSATIONS)
        .doc(uid);
    batch.delete(otherDoc);

    try {
      await batch.commit();
    } catch (_) {
      // Em caso de falha silenciosa, tenta pelo menos excluir o lado local.
      try {
        await myDoc.delete();
      } catch (_) {}
    }
  }

  /// Conta conversas com mensagens não lidas (heurística simples).
  Stream<int> getUnreadConversationsCount() {
    final uid = AppState.currentUserId;
    if (uid == null || uid.isEmpty) return Stream.value(0);
    return _firestore
        .collection(C_CONNECTIONS)
        .doc(uid)
        .collection(C_CONVERSATIONS)
        .snapshots()
        .map((snapshot) {
      var unread = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dynamic readFlag = data[MESSAGE_READ];
        final isUnreadByFlag = (readFlag is bool) ? (readFlag == false) : false;
        final unreadCount = _toIntSafe(data['unread_count']) ?? _toIntSafe(data['unreadCount']) ?? 0;
        if (isUnreadByFlag || unreadCount > 0) unread++;
      }
      return unread;
    }).handleError((_) => 0);
  }
}

int? _toIntSafe(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}
