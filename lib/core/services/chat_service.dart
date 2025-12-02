import 'package:cloud_firestore/cloud_firestore.dart';

/// Service para gerenciar funcionalidades de chat
/// TODO: Implementar funcionalidade completa
class ChatService {
  static final ChatService instance = ChatService._internal();
  factory ChatService() => instance;
  ChatService._internal();

  /// Abre conversa com um usuário
  Future<void> openChat({
    required String userId,
    required String userName,
    String? userPhotoUrl,
  }) async {
    // TODO: Implementar navegação para tela de chat
    print('TODO: Abrir chat com usuário $userId');
  }

  /// Marca mensagens como lidas
  Future<void> markMessagesAsRead(String conversationId) async {
    // TODO: Implementar marcação de leitura
  }

  /// Envia mensagem
  Future<void> sendMessage({
    required String conversationId,
    required String message,
    String? messageType,
  }) async {
    // TODO: Implementar envio de mensagem
  }

  /// Retorna stream de resumo da conversa
  Stream<DocumentSnapshot<Map<String, dynamic>>>? getConversationSummary(String userId) {
    // TODO: Implementar stream real do Firestore
    return null;
  }
}
