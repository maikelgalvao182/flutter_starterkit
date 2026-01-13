import 'package:partiu/common/state/app_state.dart';
import 'package:cloud_functions/cloud_functions.dart';

class ChatMessageDeletionService {
  ChatMessageDeletionService({FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  /// Deleta mensagem "para todos" (sender + receiver). Implementado via Cloud Function
  /// porque as rules não permitem que o client delete no nó do outro usuário.
  Future<void> deleteMessageForEveryone({
    required String conversationId,
    required String messageId,
  }) async {
    final currentUserId = AppState.currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) {
      throw StateError('Usuário não autenticado');
    }

    if (conversationId.isEmpty || messageId.isEmpty) return;

    final callable = _functions.httpsCallable('deleteChatMessage');
    await callable.call(<String, dynamic>{
      'conversationId': conversationId,
      'messageId': messageId,
    });
  }
}
