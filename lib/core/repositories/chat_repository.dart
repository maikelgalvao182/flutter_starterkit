import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:partiu/common/state/app_state.dart';
import 'package:partiu/core/constants/constants.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/core/repositories/chat_repository_interface.dart';
import 'package:partiu/screens/chat/models/message.dart';
import 'package:partiu/core/services/image_compress_service.dart';

/// Implementação do repositório de chat
class ChatRepository implements IChatRepository {

  ChatRepository();
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  @override
  Stream<List<Message>> getMessages(String withUserId) {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty || withUserId.isEmpty) {
      return const Stream.empty();
    }

    // 🎯 EVENTO: Usa EventChats/{eventId}/Messages
    if (withUserId.startsWith('event_')) {
      final eventId = withUserId.replaceFirst('event_', '');
      return _firestore
          .collection('EventChats')
          .doc(eventId)
          .collection('Messages')
          .orderBy(TIMESTAMP, descending: false)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => Message.fromDocument(doc.data(), doc.id))
            .toList();
      });
    }

    // 👤 USUÁRIO: Usa Messages/{userId}/{partnerId}
    return _firestore
        .collection(C_MESSAGES)
        .doc(currentUserId)
        .collection(withUserId)
        .orderBy(TIMESTAMP, descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Message.fromDocument(doc.data(), doc.id))
          .toList();
    });
  }

  @override
  Future<void> saveMessage({
    required String type,
    required String senderId,
    required String receiverId,
    required String fromUserId,
    required String userPhotoLink,
    required String userFullName,
    required String textMsg,
    required String imgLink,
    required bool isRead,
  }) async {
    // 🔍 DIAGNOSTIC LOGS
    print('🔍 [CHAT DEBUG] ===== SAVE MESSAGE OPERATION =====');
    print('🔍 [CHAT DEBUG] Type: $type');
    print('🔍 [CHAT DEBUG] Sender ID: $senderId');
    print('🔍 [CHAT DEBUG] Receiver ID: $receiverId');
    print('🔍 [CHAT DEBUG] Is Event Chat: ${receiverId.startsWith("event_")}');
    print('🔍 [CHAT DEBUG] Message: ${textMsg.substring(0, textMsg.length < 50 ? textMsg.length : 50)}...');
    
    final timestamp = FieldValue.serverTimestamp();
    
    // 🎯 EVENTO: Usa EventChats/{eventId}/Messages (GRUPO)
    if (receiverId.startsWith('event_')) {
      final eventId = receiverId.replaceFirst('event_', '');
      print('🔍 [CHAT DEBUG] 🎯 Using EventChats architecture');
      print('🔍 [CHAT DEBUG] Event ID: $eventId');
      
      final batch = _firestore.batch();
      
      // 1. Adiciona mensagem no chat do evento
      final messageRef = _firestore
          .collection('EventChats')
          .doc(eventId)
          .collection('Messages')
          .doc();
      
      print('🔍 [CHAT DEBUG] Message Path: EventChats/$eventId/Messages/${messageRef.id}');
      
      batch.set(messageRef, {
        'senderId': senderId,
        'senderName': userFullName,
        'senderPhotoUrl': userPhotoLink,
        'message': textMsg,
        'messageType': type,
        'imgLink': imgLink,
        'timestamp': timestamp,
        'readBy': [senderId], // Marca como lido pelo sender
      });
      
      // 2. Atualiza conversa do sender em Connections (para lista de conversas)
      final senderConvRef = _firestore
          .collection(C_CONNECTIONS)
          .doc(senderId)
          .collection(C_CONVERSATIONS)
          .doc(receiverId);
      
      print('🔍 [CHAT DEBUG] Sender Conversation Path: Connections/$senderId/conversations/$receiverId');
      
      batch.set(senderConvRef, {
        USER_ID: receiverId,
        USER_FULLNAME: userFullName,
        USER_PROFILE_PHOTO: userPhotoLink,
        MESSAGE_TYPE: type,
        LAST_MESSAGE: textMsg,
        MESSAGE_READ: true,
        TIMESTAMP: timestamp,
      }, SetOptions(merge: true));
      
      try {
        print('🔍 [CHAT DEBUG] Committing batch write with 2 operations (EventChat)...');
        await batch.commit();
        print('✅ [CHAT DEBUG] EventChat batch commit successful!');
      } catch (e) {
        print('❌ [CHAT DEBUG] EventChat batch commit FAILED!');
        print('❌ [CHAT DEBUG] Error Type: ${e.runtimeType}');
        print('❌ [CHAT DEBUG] Error Message: $e');
        print('❌ [CHAT DEBUG] ===== END ERROR DIAGNOSTIC =====');
        rethrow;
      }
      return;
    }
    
    // 👤 USUÁRIO: Usa Messages/{userId}/{partnerId} (1:1)
    print('🔍 [CHAT DEBUG] 👤 Using Messages/Connections architecture (1:1)');
    
    final batch = _firestore.batch();

    // Mensagem no documento do sender
    final senderMsgRef = _firestore
        .collection(C_MESSAGES)
        .doc(senderId)
        .collection(receiverId)
        .doc();
    
    print('🔍 [CHAT DEBUG] Sender Message Path: Messages/$senderId/$receiverId/${senderMsgRef.id}');

    batch.set(senderMsgRef, {
      SENDER_ID: senderId,
      MESSAGE_TYPE: type,
      MESSAGE: textMsg,
      TIMESTAMP: timestamp,
      IMG_LINK: imgLink,
    });

    // Mensagem no documento do receiver
    final receiverMsgRef = _firestore
        .collection(C_MESSAGES)
        .doc(receiverId)
        .collection(senderId)
        .doc();
    
    print('🔍 [CHAT DEBUG] Receiver Message Path: Messages/$receiverId/$senderId/${receiverMsgRef.id}');

    batch.set(receiverMsgRef, {
      SENDER_ID: senderId,
      MESSAGE_TYPE: type,
      MESSAGE: textMsg,
      TIMESTAMP: timestamp,
      IMG_LINK: imgLink,
    });

    // Atualiza conversa do sender
    final senderConvRef = _firestore
        .collection(C_CONNECTIONS)
        .doc(senderId)
        .collection(C_CONVERSATIONS)
        .doc(receiverId);
    
    print('🔍 [CHAT DEBUG] Sender Conversation Path: Connections/$senderId/conversations/$receiverId');

    batch.set(senderConvRef, {
      USER_ID: receiverId,
      USER_PROFILE_PHOTO: userPhotoLink,
      USER_FULLNAME: userFullName,
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: true,
      TIMESTAMP: timestamp,
    });

    // Atualiza conversa do receiver
    final receiverConvRef = _firestore
        .collection(C_CONNECTIONS)
        .doc(receiverId)
        .collection(C_CONVERSATIONS)
        .doc(senderId);
    
    print('🔍 [CHAT DEBUG] Receiver Conversation Path: Connections/$receiverId/conversations/$senderId');

    final currentUser = AppState.currentUser.value;
    batch.set(receiverConvRef, {
      USER_ID: senderId,
      USER_PROFILE_PHOTO: currentUser?.userProfilePhoto ?? '',
      USER_FULLNAME: currentUser?.userFullname ?? '',
      MESSAGE_TYPE: type,
      LAST_MESSAGE: textMsg,
      MESSAGE_READ: isRead,
      TIMESTAMP: timestamp,
    });

    try {
      print('🔍 [CHAT DEBUG] Committing batch write with 4 operations (1:1)...');
      await batch.commit();
      print('✅ [CHAT DEBUG] 1:1 batch commit successful!');
    } catch (e) {
      print('❌ [CHAT DEBUG] 1:1 batch commit FAILED!');
      print('❌ [CHAT DEBUG] Error Type: ${e.runtimeType}');
      print('❌ [CHAT DEBUG] Error Message: $e');
      print('❌ [CHAT DEBUG] ===== END ERROR DIAGNOSTIC =====');
      rethrow;
    }
  }

  @override
  Future<void> sendTextMessage({
    required String text,
    required User receiver,
  }) async {
    try {
      print('🔍 [CHAT DEBUG] ===== SEND TEXT MESSAGE =====');
      
      final currentUserId = AppState.currentUserId;
      print('🔍 [CHAT DEBUG] Current User ID: $currentUserId');
      
      if (currentUserId == null) {
        print('❌ [CHAT DEBUG] ERRO: Usuário não autenticado!');
        throw Exception('Usuário não autenticado');
      }

      print('🔍 [CHAT DEBUG] Receiver User ID: ${receiver.userId}');
      print('🔍 [CHAT DEBUG] Receiver Full Name: ${receiver.userFullname}');
      print('🔍 [CHAT DEBUG] Is Event Chat: ${receiver.userId.startsWith("event_")}');

      final currentUser = AppState.currentUser.value;
      print('🔍 [CHAT DEBUG] Current User Full Name: ${currentUser?.userFullname}');
      print('🔍 [CHAT DEBUG] Current User Photo: ${currentUser?.userProfilePhoto}');
      
      if (currentUser == null) {
        print('❌ [CHAT DEBUG] ERRO: Dados do usuário não disponíveis!');
        throw Exception('Dados do usuário não disponíveis');
      }

      print('🔍 [CHAT DEBUG] Calling saveMessage...');
      
      // Salva a mensagem
      await saveMessage(
        type: 'text',
        senderId: currentUserId,
        receiverId: receiver.userId,
        fromUserId: currentUserId,
        userPhotoLink: currentUser.userProfilePhoto ?? '',
        userFullName: currentUser.userFullname ?? '',
        textMsg: text,
        imgLink: '',
        isRead: false,
      );
      
      print('✅ [CHAT DEBUG] sendTextMessage completed successfully!');
    } catch (e) {
      print('❌ [CHAT DEBUG] sendTextMessage FAILED: $e');
      rethrow;
    }
  }

  @override
  Future<void> sendImageMessage({
    required File imageFile,
    required User receiver,
  }) async {
    try {
      final currentUserId = AppState.currentUserId;
      if (currentUserId == null) {
        throw Exception('Usuário não autenticado');
      }

      // Comprimir e fazer upload para Firebase Storage
      const compressor = ImageCompressService();
      final compressed = await compressor.compressFileToTempFile(imageFile);
      
      final fileName = 'chat_${currentUserId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final ref = _storage.ref().child('chat_images').child(fileName);
      
      await ref.putFile(compressed);
      final imageUrl = await ref.getDownloadURL();
      
      // Limpar arquivo temporário comprimido
      try {
        if (compressed.path != imageFile.path && await compressed.exists()) {
          await compressed.delete();
        }
      } catch (_) {
        // Ignorar erro de limpeza
      }

      final currentUser = AppState.currentUser.value;
      if (currentUser == null) {
        throw Exception('Dados do usuário não disponíveis');
      }

      // Salva a mensagem
      await saveMessage(
        type: 'image',
        senderId: currentUserId,
        receiverId: receiver.userId,
        fromUserId: currentUserId,
        userPhotoLink: currentUser.userProfilePhoto ?? '',
        userFullName: currentUser.userFullname ?? '',
        textMsg: '',
        imgLink: imageUrl,
        isRead: false,
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<bool> isUserBlocked({
    required String blockedUserId,
    required String blockedByUserId,
  }) async {
    final doc = await _firestore
        .collection(C_BLOCKED_USERS)
        .where('blocked_user_id', isEqualTo: blockedUserId)
        .where('blocked_by_user_id', isEqualTo: blockedByUserId)
        .limit(1)
        .get();
    
    return doc.docs.isNotEmpty;
  }

  @override
  Future<bool> blockUser({
    required String blockedUserId,
  }) async {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) return false;

    await _firestore.collection(C_BLOCKED_USERS).add({
      'blocked_user_id': blockedUserId,
      'blocked_by_user_id': currentUserId,
      TIMESTAMP: FieldValue.serverTimestamp(),
    });
    
    return true;
  }

  @override
  Future<void> unblockUser({
    required String blockedUserId,
  }) async {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) return;

    final docs = await _firestore
        .collection(C_BLOCKED_USERS)
        .where('blocked_user_id', isEqualTo: blockedUserId)
        .where('blocked_by_user_id', isEqualTo: currentUserId)
        .get();

    for (final doc in docs.docs) {
      await doc.reference.delete();
    }
  }

  @override
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserUpdates(String userId) {
    if (userId.isEmpty) return const Stream.empty();
    
    return FirebaseFirestore.instance
        .collection('Users')
        .doc(userId)
        .snapshots();
  }

  @override
  Future<void> deleteChat(String withUserId, {bool isDoubleDel = false}) async {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null) return;

    final batch = _firestore.batch();

    // Deleta mensagens
    final messagesSnapshot = await _firestore
        .collection(C_MESSAGES)
        .doc(currentUserId)
        .collection(withUserId)
        .get();

    for (final doc in messagesSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Deleta conversa
    final convRef = _firestore
        .collection(C_CONNECTIONS)
        .doc(currentUserId)
        .collection(C_CONVERSATIONS)
        .doc(withUserId);

    batch.delete(convRef);

    // Se isDoubleDel, deleta também do outro usuário
    if (isDoubleDel) {
      final otherMessagesSnapshot = await _firestore
          .collection(C_MESSAGES)
          .doc(withUserId)
          .collection(currentUserId)
          .get();

      for (final doc in otherMessagesSnapshot.docs) {
        batch.delete(doc.reference);
      }

      final otherConvRef = _firestore
          .collection(C_CONNECTIONS)
          .doc(withUserId)
          .collection(C_CONVERSATIONS)
          .doc(currentUserId);

      batch.delete(otherConvRef);
    }

    await batch.commit();
  }
}
