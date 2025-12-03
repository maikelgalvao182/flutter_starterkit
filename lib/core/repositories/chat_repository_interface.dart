import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:partiu/core/models/user.dart';
import 'package:partiu/screens/chat/models/message.dart';


/// Interface para o repositório de chat
abstract class IChatRepository {
  /// Obtém as mensagens entre o usuário atual e outro usuário
  Stream<List<Message>> getMessages(String withUserId);
  
  /// Salva uma mensagem
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
  });
  
  /// Envia uma mensagem de texto
  Future<void> sendTextMessage({
    required String text,
    required User receiver,
  });
  
  /// Envia uma mensagem com imagem
  Future<void> sendImageMessage({
    required File imageFile,
    required User receiver,
  });
  
  /// Verifica se o usuário está bloqueado
  Future<bool> isUserBlocked({
    required String blockedUserId,
    required String blockedByUserId,
  });
  
  /// Bloqueia um usuário
  Future<bool> blockUser({
    required String blockedUserId,
  });
  
  /// Desbloqueia um usuário
  Future<void> unblockUser({
    required String blockedUserId,
  });
  
  /// Obtém atualizações do usuário remoto
  Stream<DocumentSnapshot<Map<String, dynamic>>> getUserUpdates(String userId);
  
  /// Deleta o chat com um usuário
  Future<void> deleteChat(String withUserId, {bool isDoubleDel = false});
}
